"""Ingenieria de caracteristicas (Feature Engineering) del dataset de Falabella (Parte II).

Transforma el dataset limpio (`data/clean/falabella_cleaned.csv`) agregando las variables
derivadas necesarias para responder los tres objetivos del proyecto, garantizando 0 % de
valores nulos (NA) en todas las columnas del dataset final (`data/processed/falabella_processed.csv`).

Se puede ejecutar de forma independiente desde la raiz del repositorio:

    python pipeline/processing_data.py
"""

import re
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
CLEAN_PATH = ROOT / "data" / "clean" / "falabella_cleaned.csv"
PROCESSED_PATH = ROOT / "data" / "processed" / "falabella_processed.csv"

FALABELLA_DIRECT_SELLERS = frozenset({"FALABELLA", "TOTTUS", "SODIMAC"})
PRICE_TIERS = ("low", "mid", "high")

# Expresiones regulares para banderas del nombre del producto (sobre texto sin tildes en mayusculas)
_REFURBISHED_RE = re.compile(
    r"\b(?:REACONDICIONAD[OA]S?|OPEN\s*BOX|REFURBISHED|SEMI\s*NUEV[OA])\b"
)

# Detecta combos promocionales reales (+ AUDIFONOS, + MOCHILA, + MOUSE, COMBO, PACK, KIT, REGALO)
# evitando falsos positivos tecnicos como "8+256GB", "16GB RAM + 1TB SSD", "FHD+" o "SIM + ESIM".
_BUNDLE_KEYWORDS_RE = re.compile(
    r"\b(?:COMBO|PACK|BUNDLE|OBSEQUIO|REGALO|PROMO)\b|^KIT\b"
)
_BUNDLE_PLUS_RE = re.compile(
    r"\+\s*(?!\d+\s*(?:GB|TB|MB|RAM|SSD|HDD|CORE|NUCLEOS)\b|ESIM\b|5G\b|AI\b)[A-ZÁÉÍÓÚÑ]{3,}"
)

# Extraccion del tamano de pantalla en pulgadas para televisores (ej. 32", 43 PULG, 55'', QN65, 50A400)
_TV_INCHES_RE = re.compile(
    r"\b(15|24|32|40|42|43|48|50|55|58|60|65|70|75|77|83|85|86|98|100)\b"
    r"|(?:QN|UN|UA|UE|OLED|QNED|NANO|LT-|C|V)(\d{2})(?:[A-Z]|\d)"
)


def load_clean(path=CLEAN_PATH):
    """Carga el dataset limpio generado por `pipeline/cleaning.py`."""
    return pd.read_csv(path, encoding="utf-8")


def add_discount_features(df):
    """Calcula las tres variables de descuento entre `list_price` e `internet_price`:
    - `has_discount` (int8): 1 si existe rebaja (`list_price > internet_price`), 0 si no.
    - `discount_amount` (float64): ahorro absoluto en soles (`list_price - internet_price`).
    - `discount_pct` (float64): porcentaje de descuento sobre el precio de lista (0 a 100).
    """
    out = df.copy()
    diff = (out["list_price"] - out["internet_price"]).clip(lower=0.0)
    out["has_discount"] = (diff > 0).astype("int8")
    out["discount_amount"] = diff.round(2)
    out["discount_pct"] = ((diff / out["list_price"]) * 100.0).round(2)
    return out


def add_price_category(df):
    """Segmenta los productos en tres gamas de precio (`prices_category`: `low`, `mid`, `high`)
    calculando los terciles empiricos (percentiles 33.3 % y 66.7 %) de `internet_price`
    de forma independiente dentro de cada categoria (`laptops`, `phones`, `tvs`).
    """
    out = df.copy()

    def _assign_tertiles(series):
        q33 = series.quantile(1.0 / 3.0)
        q66 = series.quantile(2.0 / 3.0)
        return pd.cut(
            series,
            bins=[-float("inf"), q33, q66, float("inf")],
            labels=PRICE_TIERS,
            include_lowest=True,
        )

    out["prices_category"] = (
        out.groupby("category", observed=True)["internet_price"]
        .transform(_assign_tertiles)
        .astype("category")
    )
    return out


def get_price_tier_thresholds(df):
    """Devuelve una tabla con los cortes de terciles (P33 y P66), minimo, mediana y maximo
    de `internet_price` por categoria.
    """
    rows = []
    for cat, g in df.groupby("category", observed=True):
        s = g["internet_price"]
        q33 = float(s.quantile(1.0 / 3.0))
        q66 = float(s.quantile(2.0 / 3.0))
        rows.append(
            {
                "category": cat,
                "min_price": round(float(s.min()), 2),
                "p33_cutoff": round(q33, 2),
                "median_price": round(float(s.median()), 2),
                "p66_cutoff": round(q66, 2),
                "max_price": round(float(s.max()), 2),
                "low_count": int((g["prices_category"] == "low").sum()) if "prices_category" in g else int((s <= q33).sum()),
                "mid_count": int((g["prices_category"] == "mid").sum()) if "prices_category" in g else int(((s > q33) & (s <= q66)).sum()),
                "high_count": int((g["prices_category"] == "high").sum()) if "prices_category" in g else int((s > q66).sum()),
            }
        )
    return pd.DataFrame(rows)


def add_seller_type(df):
    """Clasifica al vendedor (`seller_type`) en:
    - `FALABELLA_DIRECT`: venta directa de Falabella y filiales oficiales del grupo (FALABELLA, TOTTUS, SODIMAC).
    - `MARKETPLACE_SELLER`: vendedores terceros independientes del marketplace.
    """
    out = df.copy()
    is_direct = out["seller"].isin(FALABELLA_DIRECT_SELLERS)
    out["seller_type"] = is_direct.map(
        {True: "FALABELLA_DIRECT", False: "MARKETPLACE_SELLER"}
    ).astype("category")
    return out


def add_product_flags_and_specs(df):
    """Extrae banderas comerciales y especificaciones tecnicas desde `product` mediante regex:
    - `is_refurbished` (int8): 1 si es reacondicionado / open box / refurbished, 0 si es nuevo.
    - `is_bundle` (int8): 1 si incluye accesorios o productos adicionales en combo/pack, 0 si es individual.
    - `inches` (int64): tamano de pantalla en pulgadas en televisores (`tvs`), y `0` en celulares/laptops
      (indicando "no aplica", lo que conserva 0 % de valores nulos en todo el dataset procesado).
    """
    out = df.copy()
    prod = out["product"].astype(str)

    out["is_refurbished"] = prod.str.contains(_REFURBISHED_RE, regex=True).astype("int8")

    has_bundle_kw = prod.str.contains(_BUNDLE_KEYWORDS_RE, regex=True)
    has_bundle_plus = prod.str.contains(_BUNDLE_PLUS_RE, regex=True)
    out["is_bundle"] = (has_bundle_kw | has_bundle_plus).astype("int8")

    # Pulgadas en televisores (0 para otras categorias donde no aplica)
    inches = pd.Series(0, index=out.index, dtype="int64")
    is_tv = out["category"].astype(str).eq("tvs")
    extracted = prod.loc[is_tv].str.extract(_TV_INCHES_RE)
    tv_inches = extracted[0].fillna(extracted[1]).fillna("0").astype("int64")
    inches.loc[is_tv] = tv_inches
    out["inches"] = inches

    return out


def run(clean_path=CLEAN_PATH, processed_path=PROCESSED_PATH):
    """Ejecuta el pipeline completo de Feature Engineering, verifica que ninguna columna
    tenga valores nulos (0 % NA) y guarda `data/processed/falabella_processed.csv`.
    """
    df = load_clean(clean_path)
    df = add_discount_features(df)
    df = add_price_category(df)
    df = add_seller_type(df)
    df = add_product_flags_and_specs(df)

    # Verificacion estricta de 0 % de valores nulos en todas las columnas
    null_counts = df.isna().sum()
    if (null_counts > 0).any():
        bad = null_counts[null_counts > 0].to_dict()
        raise ValueError(f"Se encontraron valores nulos en el dataset procesado: {bad}")

    processed_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(processed_path, index=False, encoding="utf-8")
    return df


if __name__ == "__main__":
    processed = run()
    print(f"falabella_processed.csv: {processed.shape[0]} filas x {processed.shape[1]} columnas")
    print("Nulos por columna:", int(processed.isna().sum().sum()))
    print("\nUmbrales de gamas por categoria (terciles):")
    print(get_price_tier_thresholds(processed).to_string(index=False))
