"""Etapa 4 del pipeline: generacion y compilacion del Reporte Automatizado (Typst -> PDF).

No realiza calculos estadisticos ni graficos: consume exclusivamente las salidas
generadas por cleaning.py, processing_data.py y analysis.py en <output-dir>.
"""

import argparse
import shutil
import subprocess
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUTPUT_DIR = ROOT / "data" / "pipeline"

HEADER_LABELS = {
    "etapa": "Etapa",
    "registros": "Registros",
    "columnas": "Cols.",
    "nulos_totales": "Nulos",
    "paso": "Paso de preprocesamiento",
    "filas_antes": "Antes",
    "filas_despues": "Despues",
    "filas_afectadas": "Afectadas",
    "motivo_remocion": "Motivo de remocion",
    "pct_sobre_removidos": "% Remov.",
    "pct_sobre_crudo": "% Crudo",
    "category": "Cat.",
    "prices_category": "Gama",
    "brand": "Marca",
    "seller": "Vendedor",
    "seller_type": "Tipo vend.",
    "product": "Producto",
    "min_price": "Min (S/)",
    "p33_cutoff": "P33 (S/)",
    "median_price": "Mediana (S/)",
    "p66_cutoff": "P66 (S/)",
    "max_price": "Max (S/)",
    "low_count": "Low",
    "mid_count": "Mid",
    "high_count": "High",
    "pct_falabella_direct": "% Directo",
    "pct_con_descuento": "% c/ Desc.",
    "n_reacondicionados": "Reac.",
    "pct_reacondicionados": "% Reac.",
    "n_combos": "Combos",
    "pct_combos": "% Combos",
    "n_outliers_precio": "Outliers",
    "min_soles": "Min (S/)",
    "q1_soles": "Q1 (S/)",
    "median_soles": "Mediana (S/)",
    "mediana_soles": "Mediana (S/)",
    "q3_soles": "Q3 (S/)",
    "max_soles": "Max (S/)",
    "iqr_soles": "IQR (S/)",
    "iqr_relativo_pct": "IQR rel. (%)",
    "mean_soles": "Media (S/)",
    "std_soles": "DE (S/)",
    "mediana_precio_soles": "Med. Precio",
    "mediana_desc_pct": "Med. Desc. (%)",
    "iqr_desc_pct": "IQR Desc.",
    "mediana_ahorro_soles": "Med. Ahorro",
    "iqr_ahorro_soles": "IQR Ahorro",
    "pearson_r": "Pearson r",
    "pearson_pvalue": "p (Pearson)",
    "spearman_rho": "Spearman rho",
    "spearman_pvalue": "p (Spearman)",
    "list_price": "Lista (S/)",
    "internet_price": "Internet (S/)",
    "discount_pct": "Desc. (%)",
    "FALABELLA_DIRECT": "Falabella Direct",
    "MARKETPLACE_SELLER": "Marketplace",
    "total": "Total",
    "refurbished_marketplace": "Reac. Mkt.",
    "publicaciones": "Pub.",
    "vendedores_distintos": "Vend. dist.",
    "vendedores_con_1_publicacion": "Vend. 1 pub.",
    "vendedor_lider": "Vendedor lider",
    "pct_lider": "% Lider",
    "pct_top5": "% Top 5",
    "hhi": "HHI",
    "n_falabella": "n Fal.",
    "n_marketplace": "n Mkt.",
    "mediana_falabella": "Med. Fal.",
    "mediana_marketplace": "Med. Mkt.",
    "dif_medianas_F_menos_M": "Dif. (F-M)",
    "p_value": "p-valor",
    "r_rank_biserial": "r RB",
    "p_holm": "p Holm",
    "significativo_p005": "Sig. p<0.05",
    "significativo_holm": "Sig. Holm",
    "n_nuevos": "n Nuevos",
    "marcas_comparadas": "Marcas",
    "cobertura_publicaciones_pct": "Cobertura (%)",
    "inches": "Pulg.",
    "mediana_soles_por_pulgada": "S/ / pulg.",
}

INT_COLS = {
    "n",
    "registros",
    "columnas",
    "nulos_totales",
    "filas_antes",
    "filas_despues",
    "filas_afectadas",
    "low_count",
    "mid_count",
    "high_count",
    "n_reacondicionados",
    "n_combos",
    "n_outliers_precio",
    "FALABELLA_DIRECT",
    "MARKETPLACE_SELLER",
    "total",
    "refurbished_marketplace",
    "publicaciones",
    "vendedores_distintos",
    "vendedores_con_1_publicacion",
    "hhi",
    "n_falabella",
    "n_marketplace",
    "n_nuevos",
    "marcas_comparadas",
    "inches",
}

PVAL_COLS = {"p_value", "p_holm", "pearson_pvalue", "spearman_pvalue", "kruskal_p", "spearman_p"}

PRICE_COLS = {
    "min_price",
    "p33_cutoff",
    "median_price",
    "p66_cutoff",
    "max_price",
    "min_soles",
    "q1_soles",
    "median_soles",
    "mediana_soles",
    "q3_soles",
    "max_soles",
    "iqr_soles",
    "mean_soles",
    "std_soles",
    "mediana_precio_soles",
    "mediana_ahorro_soles",
    "iqr_ahorro_soles",
    "list_price",
    "internet_price",
    "mediana_falabella",
    "mediana_marketplace",
    "dif_medianas_F_menos_M",
    "U",
}


def _typst_escape(val):
    s = str(val)
    for ch in ("\\", "#", "$", "@", "*", "_", "<", ">", "`"):
        s = s.replace(ch, "\\" + ch)
    return s


def _format_cell(col, val):
    if pd.isna(val):
        return "-"
    if isinstance(val, (bool, np.bool_)):
        return "Si" if val else "No"
    if col == "seller_type":
        if val == "FALABELLA_DIRECT":
            return "Falabella"
        if val == "MARKETPLACE_SELLER":
            return "Marketplace"
    if isinstance(val, (int, float, np.number)):
        num = float(val)
        if col in INT_COLS:
            return f"{int(round(num)):,}"
        if col in PVAL_COLS:
            if num == 0:
                return "0.0000"
            if abs(num) < 0.0001:
                return f"{num:.2e}"
            return f"{num:.4f}"
        if col in PRICE_COLS:
            return f"{num:,.1f}" if abs(num) >= 1000 else f"{num:,.2f}"
        if col in {"pearson_r", "spearman_rho", "r_rank_biserial"}:
            return f"{num:.3f}"
        return f"{num:.2f}".rstrip("0").rstrip(".") if col not in {"discount_pct", "mediana_desc_pct", "iqr_desc_pct"} else f"{num:.2f}"
    text = str(val).strip()
    if col == "product" and len(text) > 58:
        text = text[:55].rstrip() + "..."
    elif col == "seller" and len(text) > 26:
        text = text[:23].rstrip() + "..."
    return text


def _column_specs(cols, wide=False):
    text_weights = {
        "paso": "2.4fr",
        "motivo_remocion": "2.2fr",
        "product": "2.8fr" if wide else "2.2fr",
        "seller": "1.3fr" if wide else "1.1fr",
        "vendedor_lider": "1.4fr",
    }
    specs = []
    for c in cols:
        if c in text_weights:
            specs.append(text_weights[c])
        elif wide:
            specs.append("1fr")
        else:
            specs.append("auto")
    return "(" + ", ".join(specs) + ")"


def _csv_to_typst_table(csv_path, caption, max_rows=25, font_size="7.5pt", wide=False, col_specs=None):
    if not csv_path.exists():
        return ""
    df = pd.read_csv(csv_path).head(max_rows)
    if df.empty:
        return f"_Sin registros para {_typst_escape(csv_path.name)}._\n"

    cols = list(df.columns)
    headers = [HEADER_LABELS.get(c, c.replace("_", " ")) for c in cols]
    header_line = ", ".join(f"[*{_typst_escape(h)}*]" for h in headers)

    aligns = []
    for c in cols:
        if c in {"paso", "motivo_remocion", "product", "seller", "vendedor_lider", "etapa"}:
            aligns.append("left")
        else:
            aligns.append("center")

    body_rows = []
    for _, row in df.iterrows():
        cells = ", ".join(f"[{_typst_escape(_format_cell(c, row[c]))}]" for c in cols)
        body_rows.append(f"      {cells},")
    body = "\n".join(body_rows)

    columns_arg = col_specs if col_specs else _column_specs(cols, wide=wide)
    inset_arg = "(x: 3pt, y: 3pt)" if wide or len(cols) >= 8 else "(x: 5pt, y: 4pt)"

    return (
        "#align(center)[\n"
        "  #figure(\n"
        f"    text(size: {font_size})[\n"
        "      #table(\n"
        f"        columns: {columns_arg},\n"
        f"        inset: {inset_arg},\n"
        f"        align: ({', '.join(aligns)}),\n"
        f"        {header_line},\n"
        f"{body}\n"
        "      )\n"
        "    ],\n"
        f"    caption: [{_typst_escape(caption)}],\n"
        "  )\n"
        "]\n"
    )


def _img_figure(img_dir, fname, caption, width="92%"):
    if not (img_dir / fname).exists():
        return ""
    return f'#figure(image("img/{fname}", width: {width}), caption: [{_typst_escape(caption)}])'


def _landscape_block(items):
    content = "\n".join(x for x in items if x)
    if not content.strip():
        return ""
    return f"#page(flipped: true, margin: 1.2cm)[\n{content}\n]\n"


def _generate_typst_report(df, output_dir, data_dir, img_dir, compile_pdf=True):
    typ_path = output_dir / "reporte_analitico.typ"
    pdf_path = output_dir / "reporte_analitico.pdf"

    sections = [
        "#set par(justify: true)",
        '#set text(size: 10pt, lang: "es", font: "New Computer Modern")',
        '#set heading(numbering: "1.")',
        "#set page(margin: 1.6cm)",
        "#show figure.where(kind: table): set block(breakable: true)",
        "#show table.cell.where(y: 0): set text(weight: \"bold\")",
        "",
        "#align(center)[",
        '  #text(size: 18pt, weight: "bold")[Reporte Automatizado]',
        "  \\ ",
        f"  _Dataset procesado: {len(df):,} registros, {df.shape[1]} variables, {int(df.isna().sum().sum())} valores nulos_",
        "]",
        "",
        "= Resumen de Volumen y Preprocesamiento",
        "Resultados objetivos de la depuracion, remocion de registros e imputacion ejecutadas por `cleaning.py`.",
        _csv_to_typst_table(data_dir / "resumen_volumen_etapas.csv", "Volumen del dataset por etapa del pipeline", font_size="8pt"),
        _csv_to_typst_table(data_dir / "cleaning_log.csv", "Registro de filas afectadas por paso de limpieza", font_size="8pt"),
        _csv_to_typst_table(data_dir / "resumen_motivos_remocion.csv", "Desglose de registros removidos por motivo", font_size="8pt"),
        _img_figure(img_dir, "pre_01_accesorios_antes_despues.png", "Comparacion antes y despues de filtrar accesorios"),
        _img_figure(img_dir, "pre_02_outliers_precio.png", "Precios atipicos marcados por IQR 1.5"),
        _img_figure(img_dir, "pre_03_filas_afectadas_por_paso.png", "Filas afectadas por paso de limpieza"),
        "",
        "= Feature Engineering",
        "Umbrales empiricos por terciles y distribucion de banderas generadas por `processing_data.py`.",
        _csv_to_typst_table(data_dir / "umbrales_gamas_terciles.csv", "Cortes de terciles por categoria", font_size="7.2pt"),
        _csv_to_typst_table(data_dir / "resumen_banderas_vendedores.csv", "Distribucion de vendedores y banderas derivadas por categoria", font_size="7.2pt"),
        _img_figure(img_dir, "fe_01_gamas_terciles.png", "Segmentacion de gamas por terciles empiricos"),
        _img_figure(img_dir, "fe_02_banderas_y_vendedores.png", "Tipo de vendedor, banderas y pulgadas en TVs"),
        "",
        "= Analisis de Precios, Dispersion y Descuentos (Objetivo 1)",
        _landscape_block([
            _csv_to_typst_table(
                data_dir / "dispersion_precios_por_categoria.csv",
                "Dispersion relativa de precios por categoria",
                font_size="7pt",
                wide=True,
            ),
            _csv_to_typst_table(
                data_dir / "descuentos_por_categoria_y_gama.csv",
                "Descuentos por categoria y gama",
                font_size="7pt",
                wide=True,
            ),
        ]),
        _csv_to_typst_table(
            data_dir / "correlacion_precio_descuento.csv",
            "Correlacion entre precio internet y descuento (%)",
            font_size="8pt",
        ),
        _landscape_block([
            _csv_to_typst_table(
                data_dir / "descuentos_extremos_auditados.csv",
                "Publicaciones con descuento >= 60 % (top 15)",
                max_rows=15,
                font_size="6.8pt",
                wide=True,
                col_specs="(0.7fr, 0.9fr, 1.3fr, 0.9fr, 0.7fr, 0.7fr, 0.6fr, 2.5fr)",
            ),
        ]),
        _img_figure(img_dir, "ana_01_violin_precios_categoria.png", "Violines de precio internet y descuento por categoria"),
        _img_figure(img_dir, "ana_02_boxplots_descuento_gama.png", "Descuentos (%) y ahorro nominal por gama"),
        _img_figure(img_dir, "ana_03_scatter_precio_descuento.png", "Dispersion entre precio internet y descuento (%)"),
        _img_figure(img_dir, "ana_04_anomalias_reacondicionados_combos.png", "Efecto de reacondicionados y combos promocionales"),
        "",
        "= Competitividad entre Tipos de Vendedor (Objetivo 2)",
        _csv_to_typst_table(
            data_dir / "vendedores_composicion_por_categoria.csv",
            "Composicion de vendedores por categoria",
            font_size="7.5pt",
        ),
        _csv_to_typst_table(
            data_dir / "vendedores_concentracion_por_categoria.csv",
            "Concentracion e indice HHI por categoria",
            font_size="7.2pt",
        ),
        _landscape_block([
            _csv_to_typst_table(
                data_dir / "mannwhitney_precio_por_vendedor_gama.csv",
                "Prueba Mann-Whitney de precio por gama (equipos nuevos)",
                font_size="6.8pt",
                wide=True,
            ),
            _csv_to_typst_table(
                data_dir / "mannwhitney_descuento_por_vendedor_gama.csv",
                "Prueba Mann-Whitney de descuento por gama (equipos nuevos)",
                font_size="6.8pt",
                wide=True,
            ),
        ]),
        _img_figure(img_dir, "ana_05_composicion_vendedores.png", "Participacion y top vendedores del catalogo"),
        _img_figure(img_dir, "ana_06_precio_vendedor_por_gama.png", "Precio internet por tipo de vendedor y gama"),
        _img_figure(img_dir, "ana_07_descuento_vendedor_por_gama.png", "Descuento declarado por tipo de vendedor y gama"),
        "",
        "= Posicionamiento por Marca y Tamano en TVs (Objetivo 3)",
        _landscape_block([
            _csv_to_typst_table(
                data_dir / "marcas_ranking_por_categoria.csv",
                "Ranking de precios por marca (equipos nuevos)",
                max_rows=25,
                font_size="6.8pt",
                wide=True,
            ),
        ]),
        _csv_to_typst_table(
            data_dir / "marcas_kruskal_por_categoria.csv",
            "Prueba Kruskal-Wallis entre marcas por categoria",
            font_size="8pt",
        ),
        _csv_to_typst_table(
            data_dir / "tvs_precio_por_pulgadas.csv",
            "Precio de televisores segun tamano de pantalla",
            font_size="7.5pt",
        ),
        _img_figure(img_dir, "ana_08_ranking_precio_marcas.png", "Distribucion de precios por marca (equipos nuevos)"),
        _img_figure(img_dir, "ana_09_marcas_por_gama.png", "Porcentaje del portafolio de cada marca por gama"),
        _img_figure(img_dir, "ana_10_precio_pulgadas_tvs.png", "Precio frente a tamano de pantalla en televisores"),
    ]

    typ_path.write_text("\n".join(s for s in sections if s is not None), encoding="utf-8")
    print(f"[report] Documento base generado: {typ_path}")

    if compile_pdf:
        if shutil.which("typst"):
            subprocess.run(["typst", "compile", str(typ_path), str(pdf_path)], cwd=output_dir, check=True)
            print(f"[report] PDF compilado: {pdf_path}")
        else:
            print("[report] 'typst' no encontrado en PATH; se omite compilacion PDF.")


def run(processed_path=None, output_dir=DEFAULT_OUTPUT_DIR, compile_pdf=True):
    """Genera reporte_analitico.typ y reporte_analitico.pdf usando las salidas del pipeline."""
    output_dir = Path(output_dir).resolve()
    data_dir = output_dir / "data"
    img_dir = output_dir / "img"
    processed_path = Path(processed_path) if processed_path else (data_dir / "falabella_processed.csv")

    df = pd.read_csv(processed_path, encoding="utf-8")
    _generate_typst_report(df, output_dir, data_dir, img_dir, compile_pdf=compile_pdf)
    print(f"[report] Reporte completo generado en {output_dir}")
    return output_dir / "reporte_analitico.typ"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compila el Reporte Automatizado desde <output-dir>")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--no-pdf", action="store_true")
    args = parser.parse_args()
    run(output_dir=args.output_dir, compile_pdf=not args.no_pdf)