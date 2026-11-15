"""Etapa 3 del pipeline: analitica estadistica y generacion de los 15 graficos.

Consume las salidas reales de cleaning.py (raw, cleaned, removed_rows, cleaning_log)
y processing_data.py (falabella_processed) para generar de forma agnostica al dataset
las tablas CSV en <output-dir>/data/ y las figuras PNG en <output-dir>/img/.
"""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats

import cleaning
import processing_data as fe

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUTPUT_DIR = ROOT / "data" / "pipeline"
DEFAULT_RAW = ROOT / "data" / "raw" / "falabella_raw.csv"

PREFERRED_CATS = ["laptops", "phones", "tvs"]
TIERS = ["low", "mid", "high"]
SELLER_TYPES = ["FALABELLA_DIRECT", "MARKETPLACE_SELLER"]
PAL_CAT = {"laptops": "#1f4e79", "phones": "#2b8cbe", "tvs": "#bf0140"}
PAL_TIERS = {"low": "#7fb3d5", "mid": "#2980b9", "high": "#bf0140"}
PAL_SELLER = {"FALABELLA_DIRECT": "#2a78d6", "MARKETPLACE_SELLER": "#eb6834"}


def _ordered_cats(df):
    present = list(df["category"].astype(str).unique())
    ordered = [c for c in PREFERRED_CATS if c in present]
    ordered.extend(sorted(c for c in present if c not in ordered))
    return ordered


def _holm(pvals):
    p = np.asarray(pvals, dtype=float)
    adj = np.full(len(p), np.nan)
    valid = np.where(~np.isnan(p))[0]
    if len(valid) == 0:
        return adj
    sub = p[valid]
    m = len(sub)
    running = 0.0
    sub_adj = np.empty(m)
    for rank, idx in enumerate(np.argsort(sub)):
        running = max(running, (m - rank) * sub[idx])
        sub_adj[idx] = min(running, 1.0)
    adj[valid] = sub_adj
    return adj


def _mann_whitney(a, b):
    if len(a) < 2 or len(b) < 2:
        return np.nan, np.nan, np.nan
    u, p = stats.mannwhitneyu(a, b, alternative="two-sided")
    r_rb = 2 * u / (len(a) * len(b)) - 1
    return float(u), float(p), float(r_rb)


def _comparar_vendedores(data, cats, variable):
    rows = []
    for cat in cats:
        for tier in TIERS:
            sub = data[(data["category"] == cat) & (data["prices_category"] == tier)]
            a = sub.loc[sub["seller_type"] == "FALABELLA_DIRECT", variable]
            b = sub.loc[sub["seller_type"] == "MARKETPLACE_SELLER", variable]
            u, p, r_rb = _mann_whitney(a, b)
            med_a = round(float(a.median()), 2) if len(a) else np.nan
            med_b = round(float(b.median()), 2) if len(b) else np.nan
            rows.append({
                "category": cat,
                "prices_category": tier,
                "n_falabella": len(a),
                "n_marketplace": len(b),
                "mediana_falabella": med_a,
                "mediana_marketplace": med_b,
                "dif_medianas_F_menos_M": round(med_a - med_b, 2) if not (np.isnan(med_a) or np.isnan(med_b)) else np.nan,
                "U": round(u, 1) if not np.isnan(u) else np.nan,
                "p_value": p,
                "r_rank_biserial": round(r_rb, 3) if not np.isnan(r_rb) else np.nan,
            })
    out = pd.DataFrame(rows)
    out["p_holm"] = _holm(out["p_value"])
    out["significativo_p005"] = out["p_value"] < 0.05
    out["significativo_holm"] = out["p_holm"] < 0.05
    out["p_value"] = out["p_value"].round(4)
    out["p_holm"] = out["p_holm"].round(4)
    return out


def _save(fig, path):
    fig.savefig(path, dpi=160, bbox_inches="tight")
    plt.close(fig)


def _generate_preprocessing_stage(raw, clean, removed, log_df, df, cats, data_dir, img_dir):
    vol_rows = []
    if raw is not None and not raw.empty:
        vol_rows.append({
            "etapa": "Crudo (raw)",
            "registros": len(raw),
            "columnas": raw.shape[1],
            "nulos_totales": int(raw.isna().sum().sum()),
        })
    vol_rows.append({
        "etapa": "Limpio (cleaned)",
        "registros": len(clean),
        "columnas": clean.shape[1],
        "nulos_totales": int(clean.isna().sum().sum()),
    })
    vol_rows.append({
        "etapa": "Procesado (processed)",
        "registros": len(df),
        "columnas": df.shape[1],
        "nulos_totales": int(df.isna().sum().sum()),
    })
    pd.DataFrame(vol_rows).to_csv(data_dir / "resumen_volumen_etapas.csv", index=False, encoding="utf-8")

    # Desglose de motivos de remocion registrados por cleaning.py
    if removed is not None and not removed.empty and "removal_reason" in removed.columns:
        motivos = removed["removal_reason"].value_counts().rename_axis("motivo_remocion").reset_index(name="registros")
        total_base = len(raw) if raw is not None and len(raw) else len(removed)
        motivos["pct_sobre_removidos"] = (motivos["registros"] / len(removed) * 100).round(1)
        motivos["pct_sobre_crudo"] = (motivos["registros"] / total_base * 100).round(1)
        motivos.to_csv(data_dir / "resumen_motivos_remocion.csv", index=False, encoding="utf-8")

    # pre_01: filas por categoria y boxplot antes vs despues de retirar accesorios
    if raw is not None and not raw.empty:
        non_dup_raw, _ = cleaning.drop_exact_duplicates(raw)
        sin_acc = clean
        fig, axes = plt.subplots(1, 2, figsize=(13, 5.0), gridspec_kw={"width_ratios": [1, 1.25]})
        etapas = pd.DataFrame({
            "Crudo": raw["category"].value_counts(),
            "Sin duplicados": non_dup_raw["category"].value_counts(),
            "Solo equipos": sin_acc["category"].value_counts(),
        }).reindex(cats).fillna(0).astype(int)
        etapas.plot.bar(ax=axes[0], color=["#b9b9b9", "#7f9cb5", "#1f4e79"], width=0.8, rot=0)
        for cont in axes[0].containers:
            axes[0].bar_label(cont, fontsize=8, padding=2)
        axes[0].set_title("Filas por categoria en cada etapa")
        axes[0].set_xlabel("")
        axes[0].set_ylabel("Filas")
        axes[0].set_ylim(0, max(10, int(etapas.max().max() * 1.25)))
        axes[0].legend(title="", frameon=False, loc="upper center", ncol=3)

        datos = pd.concat([
            non_dup_raw.assign(etapa="Sin duplicados (con accesorios)"),
            sin_acc.assign(etapa="Limpio (solo equipos)"),
        ])
        sns.boxplot(
            data=datos, x="category", y="internet_price", hue="etapa", order=cats,
            palette=["#b9b9b9", "#1f4e79"], fliersize=2, linewidth=0.9, ax=axes[1],
        )
        axes[1].set_yscale("log")
        axes[1].set_title("Precio internet por categoria antes y despues del filtro")
        axes[1].set_xlabel("")
        axes[1].set_ylabel("S/ (escala logaritmica)")
        axes[1].legend(title="", frameon=False, loc="upper center", bbox_to_anchor=(0.5, -0.1), ncol=2)
        plt.tight_layout()
        _save(fig, img_dir / "pre_01_accesorios_antes_despues.png")

    # pre_02: outliers marcados con IQR 1.5
    fig, ax = plt.subplots(figsize=(10, 4.6))
    sns.boxplot(data=clean, x="category", y="internet_price", order=cats, color="#e6e6e6", fliersize=0, linewidth=0.9, ax=ax)
    sns.stripplot(data=clean[clean["is_price_outlier"] == 0], x="category", y="internet_price", order=cats, color="#7f9cb5", size=2.5, alpha=0.5, jitter=0.25, ax=ax)
    if (clean["is_price_outlier"] == 1).any():
        sns.stripplot(data=clean[clean["is_price_outlier"] == 1], x="category", y="internet_price", order=cats, color="#c0392b", size=7, edgecolor="white", linewidth=0.8, jitter=0.1, ax=ax)
    ax.set_yscale("log")
    ax.set_xlabel("")
    ax.set_ylabel("Precio internet, S/ (escala logaritmica)")
    ax.set_title("Precios atipicos marcados por IQR 1.5 dentro de cada categoria (rojo)")
    plt.tight_layout()
    _save(fig, img_dir / "pre_02_outliers_precio.png")

    # pre_03: filas afectadas por paso
    if log_df is not None and not log_df.empty:
        n_base = len(raw) if raw is not None and len(raw) else len(clean)
        fig, ax = plt.subplots(figsize=(10, 3.8))
        orden = log_df.assign(pct=log_df["filas_afectadas"] / max(1, n_base) * 100)
        ax.barh(orden["paso"][::-1], orden["filas_afectadas"][::-1], color="#7f9cb5")
        for y, (v, p) in enumerate(zip(orden["filas_afectadas"][::-1], orden["pct"][::-1])):
            ax.text(v + max(1, orden["filas_afectadas"].max() * 0.015), y, f"{int(v)} ({p:.1f} %)", va="center", fontsize=9)
        ax.set_xlim(0, max(10, orden["filas_afectadas"].max() * 1.45))
        ax.set_xlabel("Filas afectadas")
        ax.set_title("Filas afectadas por cada paso del preprocesamiento")
        plt.tight_layout()
        _save(fig, img_dir / "pre_03_filas_afectadas_por_paso.png")


def _generate_fe_stage(df, cats, data_dir, img_dir):
    umbrales = fe.get_price_tier_thresholds(df)
    umbrales.to_csv(data_dir / "umbrales_gamas_terciles.csv", index=False, encoding="utf-8")

    resumen_flags = (
        df.groupby("category", observed=True)
        .agg(
            n=("product", "size"),
            pct_falabella_direct=("seller_type", lambda s: round(float((s == "FALABELLA_DIRECT").mean() * 100), 1)),
            pct_con_descuento=("has_discount", lambda s: round(float(s.mean() * 100), 1)),
            n_reacondicionados=("is_refurbished", "sum"),
            pct_reacondicionados=("is_refurbished", lambda s: round(float(s.mean() * 100), 1)),
            n_combos=("is_bundle", "sum"),
            pct_combos=("is_bundle", lambda s: round(float(s.mean() * 100), 1)),
            n_outliers_precio=("is_price_outlier", "sum"),
        )
        .reindex(cats)
        .reset_index()
    )
    resumen_flags.to_csv(data_dir / "resumen_banderas_vendedores.csv", index=False, encoding="utf-8")

    # fe_01: distribucion por categoria y terciles
    fig, axes = plt.subplots(1, len(cats), figsize=(4.7 * len(cats), 4.5), sharey=False)
    if len(cats) == 1:
        axes = [axes]
    for ax, cat in zip(axes, cats):
        sub = df[df["category"] == cat]
        row = umbrales[umbrales["category"] == cat].iloc[0]
        sns.histplot(
            data=sub, x="internet_price", hue="prices_category", hue_order=TIERS,
            palette=PAL_TIERS, bins=28, alpha=0.85, ax=ax, log_scale=True,
        )
        ax.axvline(row["p33_cutoff"], color="#222222", linestyle="--", linewidth=1.4)
        ax.axvline(row["p66_cutoff"], color="#222222", linestyle="--", linewidth=1.4)
        ax.set_title(f"{cat}\nP33: S/ {row['p33_cutoff']:,.0f} | P66: S/ {row['p66_cutoff']:,.0f}", fontsize=10.5)
        ax.set_xlabel("Precio internet en S/ (escala log)")
        ax.set_ylabel("Publicaciones" if ax is axes[0] else "")
    fig.suptitle("Segmentacion de gamas (low, mid, high) por terciles empiricos", fontsize=12, y=1.03)
    plt.tight_layout()
    _save(fig, img_dir / "fe_01_gamas_terciles.png")

    # fe_02: vendedores, banderas y pulgadas
    fig, axes = plt.subplots(1, 3, figsize=(14, 4.2))
    ct_seller = pd.crosstab(df["category"], df["seller_type"], normalize="index").reindex(index=cats, columns=SELLER_TYPES, fill_value=0) * 100
    ct_seller.plot(kind="bar", stacked=True, ax=axes[0], color=["#1f4e79", "#b9c6d2"], width=0.68, rot=0)
    axes[0].set_title("Tipo de vendedor por categoria (%)")
    axes[0].set_xlabel("")
    axes[0].set_ylabel("Porcentaje (%)")
    axes[0].legend(["FALABELLA_DIRECT", "MARKETPLACE_SELLER"], frameon=False, loc="upper right", fontsize=8.5)
    axes[0].set_ylim(0, 115)

    flags_pct = pd.DataFrame({
        "Reacondicionado": df.groupby("category", observed=True)["is_refurbished"].mean() * 100,
        "Combo / Pack": df.groupby("category", observed=True)["is_bundle"].mean() * 100,
    }).reindex(cats).fillna(0)
    flags_pct.plot(kind="bar", ax=axes[1], color=["#bf0140", "#4a6fa5"], width=0.68, rot=0)
    for cont in axes[1].containers:
        axes[1].bar_label(cont, fmt="%.1f%%", fontsize=8, padding=2)
    axes[1].set_title("Incidencia de reacondicionados y combos (%)")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Porcentaje (%)")
    axes[1].set_ylim(0, max(10, float(flags_pct.max().max()) * 1.3))
    axes[1].legend(frameon=False, fontsize=8.5)

    tvs_inches = df[(df["category"] == "tvs") & (df["inches"] > 0)]["inches"].value_counts().sort_index()
    principales = tvs_inches[tvs_inches >= 2] if (tvs_inches >= 2).any() else tvs_inches
    if len(principales):
        axes[2].bar(principales.index.astype(str) + '"', principales.values, color="#2b5c8f", width=0.65)
        for idx, val in enumerate(principales.values):
            axes[2].text(idx, val + max(0.5, principales.max() * 0.02), str(val), ha="center", va="bottom", fontsize=8.5)
        axes[2].set_ylim(0, principales.max() * 1.2)
    axes[2].set_title(f"Tamanos de pantalla en TVs (n={int((df['category'] == 'tvs').sum())})")
    axes[2].set_xlabel("Pulgadas")
    axes[2].set_ylabel("Publicaciones")
    plt.tight_layout()
    _save(fig, img_dir / "fe_02_banderas_y_vendedores.png")


def _generate_obj1_stage(df, cats, data_dir, img_dir):
    rows_disp = []
    for cat in cats:
        s = df.loc[df["category"] == cat, "internet_price"]
        q1, med, q3 = s.quantile(0.25), s.median(), s.quantile(0.75)
        iqr = q3 - q1
        iqr_rel = (iqr / med) * 100.0 if med else 0.0
        rows_disp.append({
            "category": cat, "n": len(s), "min_soles": round(float(s.min()), 2),
            "q1_soles": round(float(q1), 2), "median_soles": round(float(med), 2),
            "q3_soles": round(float(q3), 2), "max_soles": round(float(s.max()), 2),
            "iqr_soles": round(float(iqr), 2), "iqr_relativo_pct": round(float(iqr_rel), 1),
            "mean_soles": round(float(s.mean()), 2), "std_soles": round(float(s.std()), 2),
        })
    disp_df = pd.DataFrame(rows_disp)
    disp_df.to_csv(data_dir / "dispersion_precios_por_categoria.csv", index=False, encoding="utf-8")

    # ana_01: violines precio y descuento con Med + IQR
    fig, axes = plt.subplots(1, 2, figsize=(13.5, 5.0))
    sns.violinplot(
        data=df, x="category", y="internet_price", hue="category", order=cats,
        palette=PAL_CAT, inner="quartile", cut=0, alpha=0.82, dodge=False, legend=False, ax=axes[0],
    )
    axes[0].set_yscale("log")
    axes[0].set_title("Distribucion y silueta de Precio Internet por categoria")
    axes[0].set_xlabel("")
    axes[0].set_ylabel("Precio internet en S/ (escala logaritmica)")
    for idx, row in disp_df.iterrows():
        axes[0].text(
            idx, row["median_soles"] * 1.07,
            f"Med: S/ {row['median_soles']:,.0f}\nIQR rel: {row['iqr_relativo_pct']}%",
            ha="center", va="bottom", fontsize=8.5, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="white", alpha=0.85, edgecolor="none"),
        )

    sns.violinplot(
        data=df, x="category", y="discount_pct", hue="category", order=cats,
        palette=PAL_CAT, inner="quartile", cut=0, alpha=0.82, dodge=False, legend=False, ax=axes[1],
    )
    for idx, cat in enumerate(cats):
        s_desc = df.loc[df["category"] == cat, "discount_pct"]
        med_d = float(s_desc.median())
        iqr_d = float(s_desc.quantile(0.75) - s_desc.quantile(0.25))
        axes[1].text(
            idx, med_d + 2.0, f"Med: {med_d:.2f}%\nIQR: {iqr_d:.2f} pp",
            ha="center", va="bottom", fontsize=8.5, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="white", alpha=0.85, edgecolor="none"),
        )
    axes[1].set_title("Distribucion del Porcentaje de Descuento (discount_pct)")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Descuento sobre precio de lista (%)")
    axes[1].set_ylim(-2, 100)
    plt.tight_layout()
    _save(fig, img_dir / "ana_01_violin_precios_categoria.png")

    # Tabla y grafico ana_02: descuentos por categoria y gama (con redondeo consistente)
    resumen_gamas = (
        df.groupby(["category", "prices_category"], observed=True)
        .agg(
            n=("product", "size"),
            pct_con_descuento=("has_discount", lambda s: round(float(s.mean() * 100), 1)),
            mediana_precio_soles=("internet_price", lambda s: round(float(s.median()), 2)),
            mediana_desc_pct=("discount_pct", lambda s: round(float(s.median()), 2)),
            iqr_desc_pct=("discount_pct", lambda s: round(float(s.quantile(0.75) - s.quantile(0.25)), 2)),
            mediana_ahorro_soles=("discount_amount", lambda s: round(float(s.median()), 2)),
            iqr_ahorro_soles=("discount_amount", lambda s: round(float(s.quantile(0.75) - s.quantile(0.25)), 2)),
        )
        .reindex(pd.MultiIndex.from_product([cats, TIERS], names=["category", "prices_category"]))
        .reset_index()
    )
    resumen_gamas.to_csv(data_dir / "descuentos_por_categoria_y_gama.csv", index=False, encoding="utf-8")

    fig, axes = plt.subplots(1, 2, figsize=(13.5, 4.8))
    sns.boxplot(data=df, x="category", y="discount_pct", hue="prices_category", order=cats, hue_order=TIERS, palette=PAL_TIERS, fliersize=3, ax=axes[0])
    axes[0].set_title("Porcentaje de descuento por categoria y gama")
    axes[0].set_xlabel("")
    axes[0].set_ylabel("Descuento (%)")
    axes[0].legend(title="Gama", frameon=False)

    sns.boxplot(data=df, x="category", y="discount_amount", hue="prices_category", order=cats, hue_order=TIERS, palette=PAL_TIERS, fliersize=3, ax=axes[1])
    axes[1].set_yscale("symlog", linthresh=100)
    axes[1].set_title("Ahorro nominal en soles por categoria y gama")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Ahorro en S/ (escala symlog)")
    axes[1].legend(title="Gama", frameon=False)
    plt.tight_layout()
    _save(fig, img_dir / "ana_02_boxplots_descuento_gama.png")

    # Correlacion precio vs descuento y ana_03
    corr_rows = []
    for cat in cats:
        sub = df[df["category"] == cat]
        if len(sub) >= 3 and sub["internet_price"].nunique() > 1 and sub["discount_pct"].nunique() > 1:
            r_p, p_p = stats.pearsonr(sub["internet_price"], sub["discount_pct"])
            r_s, p_s = stats.spearmanr(sub["internet_price"], sub["discount_pct"])
        else:
            r_p, p_p, r_s, p_s = np.nan, np.nan, np.nan, np.nan
        corr_rows.append({
            "category": cat, "n": len(sub),
            "pearson_r": round(float(r_p), 3) if not np.isnan(r_p) else np.nan,
            "pearson_pvalue": round(float(p_p), 6) if not np.isnan(p_p) else np.nan,
            "spearman_rho": round(float(r_s), 3) if not np.isnan(r_s) else np.nan,
            "spearman_pvalue": round(float(p_s), 6) if not np.isnan(p_s) else np.nan,
        })
    corr_df = pd.DataFrame(corr_rows)
    corr_df.to_csv(data_dir / "correlacion_precio_descuento.csv", index=False, encoding="utf-8")

    fig, axes = plt.subplots(1, len(cats), figsize=(4.8 * len(cats), 4.5), sharey=True)
    if len(cats) == 1:
        axes = [axes]
    for ax, cat in zip(axes, cats):
        sub = df[df["category"] == cat]
        row = corr_df[corr_df["category"] == cat].iloc[0]
        sns.scatterplot(data=sub, x="internet_price", y="discount_pct", hue="prices_category", hue_order=TIERS, palette=PAL_TIERS, alpha=0.65, s=36, ax=ax)
        if len(sub) >= 3:
            sns.regplot(data=sub, x="internet_price", y="discount_pct", scatter=False, color="#111111", line_kws={"linewidth": 1.8, "linestyle": "--"}, ax=ax)
        ax.set_title(f"{cat.upper()} (r={row['pearson_r']}, rho={row['spearman_rho']}, p={row['pearson_pvalue']})")
        ax.set_xlabel("Precio internet (S/)")
        ax.set_ylabel("Descuento (%)" if ax is axes[0] else "")
        ax.set_ylim(-3, 98)
        ax.legend(title="Gama", frameon=False, fontsize=8)
    fig.suptitle("Relacion Precio Internet vs. Descuento Porcentual por categoria", fontsize=12, y=1.03)
    plt.tight_layout()
    _save(fig, img_dir / "ana_03_scatter_precio_descuento.png")

    # Descuentos extremos y ana_04
    inflados = df[df["discount_pct"] >= 60.0].sort_values("discount_pct", ascending=False)[
        ["category", "brand", "seller", "seller_type", "list_price", "internet_price", "discount_pct", "product"]
    ].copy()
    inflados["discount_pct"] = inflados["discount_pct"].round(2)
    inflados.to_csv(data_dir / "descuentos_extremos_auditados.csv", index=False, encoding="utf-8")

    fig, axes = plt.subplots(1, 2, figsize=(13.5, 4.6))
    phones_df = df[df["category"] == "phones"].copy()
    if not phones_df.empty:
        ref_counts = phones_df[phones_df["is_refurbished"] == 1]["brand"].value_counts()
        top_ref_brand = ref_counts.index[0] if len(ref_counts) else phones_df["brand"].value_counts().index[0]
        phones_df["segmento_marca"] = np.where(phones_df["brand"] == top_ref_brand, top_ref_brand, "Otras Marcas")
        phones_df["condicion"] = phones_df["is_refurbished"].map({0: "Nuevo", 1: "Reacondicionado"})
        sns.boxplot(data=phones_df, x="segmento_marca", y="internet_price", hue="condicion", palette={"Nuevo": "#1f4e79", "Reacondicionado": "#bf0140"}, fliersize=3, ax=axes[0])
        axes[0].set_title(f"Celulares: Precio Internet por condicion ({top_ref_brand} vs. Otras)")
        axes[0].set_xlabel("")
        axes[0].set_ylabel("Precio internet (S/)")
        axes[0].legend(title="Condicion", frameon=False)

    df_bundle = df.copy()
    df_bundle["Modalidad"] = df_bundle["is_bundle"].map({0: "Equipo individual", 1: "Combo / Pack"})
    sns.boxplot(data=df_bundle, x="category", y="discount_pct", hue="Modalidad", order=cats, palette={"Equipo individual": "#7f9cb5", "Combo / Pack": "#2b5c8f"}, fliersize=3, ax=axes[1])
    axes[1].set_title("Porcentaje de descuento: Individual vs. Combo (is_bundle)")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Descuento (%)")
    axes[1].legend(title="", frameon=False)
    plt.tight_layout()
    _save(fig, img_dir / "ana_04_anomalias_reacondicionados_combos.png")


def _generate_obj2_stage(df, cats, data_dir, img_dir):
    df_nuevos = df[df["is_refurbished"] == 0].copy()

    comp = df.groupby(["category", "seller_type"], observed=True).size().unstack(fill_value=0).reindex(index=cats, columns=SELLER_TYPES, fill_value=0)
    comp["total"] = comp.sum(axis=1)
    comp["pct_falabella_direct"] = (comp["FALABELLA_DIRECT"] / comp["total"].replace(0, np.nan) * 100).round(1)
    comp["refurbished_marketplace"] = [int(df[(df["category"] == c) & (df["seller_type"] == "MARKETPLACE_SELLER")]["is_refurbished"].sum()) for c in cats]
    comp = comp.reset_index()
    comp.to_csv(data_dir / "vendedores_composicion_por_categoria.csv", index=False, encoding="utf-8")

    conc_rows = []
    for cat in cats:
        conteo = df.loc[df["category"] == cat, "seller"].value_counts()
        share = conteo / conteo.sum()
        conc_rows.append({
            "category": cat, "publicaciones": int(conteo.sum()), "vendedores_distintos": len(conteo),
            "vendedores_con_1_publicacion": int((conteo == 1).sum()), "vendedor_lider": conteo.index[0],
            "pct_lider": round(float(share.iloc[0] * 100), 1), "pct_top5": round(float(share.head(5).sum() * 100), 1),
            "hhi": int(round(float((share ** 2).sum() * 10000))),
        })
    conteo_tot = df["seller"].value_counts()
    share_tot = conteo_tot / conteo_tot.sum()
    conc_rows.append({
        "category": "TOTAL", "publicaciones": int(conteo_tot.sum()), "vendedores_distintos": len(conteo_tot),
        "vendedores_con_1_publicacion": int((conteo_tot == 1).sum()), "vendedor_lider": conteo_tot.index[0],
        "pct_lider": round(float(share_tot.iloc[0] * 100), 1), "pct_top5": round(float(share_tot.head(5).sum() * 100), 1),
        "hhi": int(round(float((share_tot ** 2).sum() * 10000))),
    })
    pd.DataFrame(conc_rows).to_csv(data_dir / "vendedores_concentracion_por_categoria.csv", index=False, encoding="utf-8")

    mix_gamas = pd.crosstab([df_nuevos["category"], df_nuevos["seller_type"]], df_nuevos["prices_category"], normalize="index").mul(100).round(1).reindex(columns=TIERS).fillna(0)
    mix_gamas.reset_index().to_csv(data_dir / "vendedores_mix_gamas_equipos_nuevos.csv", index=False, encoding="utf-8")

    # ana_05: composicion vendedores
    fig, axes = plt.subplots(1, 2, figsize=(14, 5.2), gridspec_kw={"width_ratios": [1, 1.25]})
    ax = axes[0]
    pct = comp.set_index("category")[SELLER_TYPES].div(comp.set_index("category")["total"].replace(0, np.nan), axis=0) * 100
    left = np.zeros(len(cats))
    for st in SELLER_TYPES:
        ax.barh(cats, pct[st], left=left, color=PAL_SELLER[st], edgecolor="white", linewidth=2, label=st, height=0.55)
        for i, v in enumerate(pct[st]):
            if v >= 15:
                ax.text(left[i] + v / 2, i, f"{v:.1f} %", ha="center", va="center", color="white", fontsize=10, fontweight="bold")
            elif v > 0:
                ax.text(left[i] + v / 2, i - 0.36, f"{v:.1f} %", ha="center", va="bottom", color="#333333", fontsize=9.5, fontweight="bold")
        left += pct[st].values
    for i in range(len(cats)):
        ax.text(102, i, f"n = {int(comp.loc[i, 'total'])}", va="center", fontsize=9, color="#555555")
    ax.set_xlim(0, 118)
    ax.set_ylim(len(cats) - 0.5, -0.8)
    ax.set_xlabel("% de publicaciones")
    ax.set_title("Participacion por tipo de vendedor")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.14), ncol=2, frameon=False)

    ax = axes[1]
    top = df["seller"].value_counts().head(12)
    tipo = df.drop_duplicates("seller").set_index("seller")["seller_type"]
    ax.barh(top.index, top.values, color=[PAL_SELLER[tipo[s]] for s in top.index], height=0.6)
    for i, v in enumerate(top.values):
        ax.text(v + max(0.5, top.max() * 0.015), i, f"{v} ({v / len(df) * 100:.1f} %)", va="center", fontsize=9)
    ax.invert_yaxis()
    ax.set_xlim(0, top.max() * 1.28)
    ax.set_xlabel("Publicaciones")
    ax.set_title(f"Top 12 vendedores (de {df['seller'].nunique()} totales)")
    plt.tight_layout()
    _save(fig, img_dir / "ana_05_composicion_vendedores.png")

    mw_precio = _comparar_vendedores(df_nuevos, cats, "internet_price")
    mw_desc = _comparar_vendedores(df_nuevos, cats, "discount_pct")
    mw_lista = _comparar_vendedores(df_nuevos, cats, "list_price")
    mw_precio.to_csv(data_dir / "mannwhitney_precio_por_vendedor_gama.csv", index=False, encoding="utf-8")
    mw_desc.to_csv(data_dir / "mannwhitney_descuento_por_vendedor_gama.csv", index=False, encoding="utf-8")
    mw_lista.to_csv(data_dir / "mannwhitney_precio_lista_por_vendedor_gama.csv", index=False, encoding="utf-8")

    ag_rows = []
    for cat in cats:
        sub = df_nuevos[df_nuevos["category"] == cat]
        a = sub.loc[sub["seller_type"] == "FALABELLA_DIRECT", "internet_price"]
        b = sub.loc[sub["seller_type"] == "MARKETPLACE_SELLER", "internet_price"]
        _, p, r_rb = _mann_whitney(a, b)
        ag_rows.append({
            "category": cat, "n_falabella": len(a), "n_marketplace": len(b),
            "mediana_falabella": round(float(a.median()), 2) if len(a) else np.nan,
            "mediana_marketplace": round(float(b.median()), 2) if len(b) else np.nan,
            "p_value": round(p, 4) if not np.isnan(p) else np.nan,
            "r_rank_biserial": round(r_rb, 3) if not np.isnan(r_rb) else np.nan,
        })
    pd.DataFrame(ag_rows).to_csv(data_dir / "mannwhitney_precio_por_vendedor_categoria.csv", index=False, encoding="utf-8")

    desc_altos = (
        df_nuevos.assign(desc_mayor_50=df_nuevos["discount_pct"] >= 50)
        .groupby(["category", "seller_type"], observed=True)
        .agg(publicaciones=("product", "size"), con_desc_mayor_50=("desc_mayor_50", "sum"))
        .reset_index()
    )
    desc_altos["pct_con_desc_mayor_50"] = (desc_altos["con_desc_mayor_50"] / desc_altos["publicaciones"] * 100).round(1)
    desc_altos.to_csv(data_dir / "descuentos_mayores_50_por_vendedor.csv", index=False, encoding="utf-8")

    rob_tablas = []
    for nombre, data in {
        "A_base_nuevos": df_nuevos,
        "B_con_reacondicionados": df,
        "C_nuevos_sin_atipicos": df_nuevos[df_nuevos["is_price_outlier"] == 0],
    }.items():
        for var in ["internet_price", "discount_pct"]:
            t = _comparar_vendedores(data, cats, var)
            t.insert(0, "variable", var)
            t.insert(0, "escenario", nombre)
            rob_tablas.append(t)
    pd.concat(rob_tablas, ignore_index=True).to_csv(data_dir / "mannwhitney_robustez_escenarios.csv", index=False, encoding="utf-8")

    def _box_gama(variable, tabla_mw, ylabel, titulo, out_name, log=False):
        fig, axes = plt.subplots(1, len(cats), figsize=(5.0 * len(cats), 5.4))
        if len(cats) == 1:
            axes = [axes]
        for ax, cat in zip(axes, cats):
            sub = df_nuevos[df_nuevos["category"] == cat]
            sns.boxplot(data=sub, x="prices_category", y=variable, hue="seller_type", order=TIERS, hue_order=SELLER_TYPES, palette=PAL_SELLER, width=0.65, fliersize=2.5, linewidth=1.1, ax=ax)
            vmin, vmax = sub[variable].min(), sub[variable].max()
            if log and vmin > 0:
                ax.set_yscale("log")
                ax.set_ylim(vmin * 0.75, vmax * 4.5)
            else:
                ax.set_ylim(min(0, vmin) - 3, vmax * 1.28)
            for i, tier in enumerate(TIERS):
                fila = tabla_mw[(tabla_mw["category"] == cat) & (tabla_mw["prices_category"] == tier)].iloc[0]
                p_txt = f"{fila['p_holm']:.3f}" if not pd.isna(fila["p_holm"]) else "NA"
                marca = " *" if fila["significativo_holm"] else ""
                ax.text(i, 0.975, f"p_holm = {p_txt}{marca}\nn = {fila['n_falabella']} vs {fila['n_marketplace']}", ha="center", va="top", fontsize=8.5, color="#333333", transform=ax.get_xaxis_transform())
            ax.set_title(cat, fontweight="bold")
            ax.set_xlabel("Gama")
            ax.set_ylabel(ylabel if ax is axes[0] else "")
            if ax.get_legend():
                ax.get_legend().remove()
        handles, labels = axes[0].get_legend_handles_labels()
        fig.legend(handles, labels, loc="lower center", ncol=2, frameon=False, bbox_to_anchor=(0.5, -0.04))
        fig.suptitle(titulo, fontsize=12.5)
        plt.tight_layout(rect=(0, 0.04, 1, 1))
        _save(fig, img_dir / out_name)

    _box_gama("internet_price", mw_precio, "Precio internet en S/ (escala log)", "Precio internet por tipo de vendedor y gama (equipos nuevos)", "ana_06_precio_vendedor_por_gama.png", log=True)
    _box_gama("discount_pct", mw_desc, "Descuento declarado (%)", "Descuento declarado por tipo de vendedor y gama (equipos nuevos)", "ana_07_descuento_vendedor_por_gama.png", log=False)


def _generate_obj3_stage(df, cats, data_dir, img_dir):
    marcas_base = df[df["brand"] != "GENERICO"]
    nuevos_marca = marcas_base[marcas_base["is_refurbished"] == 0]

    filas, kruskal_rows = [], []
    for cat in cats:
        sub = nuevos_marca[nuevos_marca["category"] == cat]
        conteo = sub["brand"].value_counts()
        top = conteo[conteo >= 10].index.tolist()
        if not top:
            top = conteo.head(5).index.tolist()
        for marca in top:
            s = sub[sub["brand"] == marca]
            q1, med, q3 = s["internet_price"].quantile([0.25, 0.5, 0.75])
            filas.append({
                "category": cat, "brand": marca, "n_nuevos": len(s),
                "n_reacondicionados": int(marcas_base[(marcas_base["category"] == cat) & (marcas_base["brand"] == marca)]["is_refurbished"].sum()),
                "pct_falabella_direct": round(float((s["seller_type"] == "FALABELLA_DIRECT").mean() * 100), 1),
                "min_soles": round(float(s["internet_price"].min()), 2), "q1_soles": round(float(q1), 2),
                "mediana_soles": round(float(med), 2), "q3_soles": round(float(q3), 2),
                "max_soles": round(float(s["internet_price"].max()), 2), "iqr_soles": round(float(q3 - q1), 2),
                "iqr_relativo_pct": round(float((q3 - q1) / med * 100), 1) if med else 0.0,
                "mediana_desc_pct": round(float(s["discount_pct"].median()), 2),
            })
        groups = [sub.loc[sub["brand"] == m, "internet_price"] for m in top if len(sub[sub["brand"] == m]) > 0]
        if len(groups) >= 2:
            h, p = stats.kruskal(*groups)
        else:
            h, p = np.nan, np.nan
        kruskal_rows.append({
            "category": cat, "marcas_comparadas": len(top),
            "H": round(float(h), 2) if not np.isnan(h) else np.nan,
            "p_value": float(p) if not np.isnan(p) else np.nan,
            "cobertura_publicaciones_pct": round(float(sub["brand"].isin(top).mean() * 100), 1),
        })

    ranking_marcas = pd.DataFrame(filas).sort_values(["category", "mediana_soles"], ascending=[True, False]).reset_index(drop=True)
    kruskal_df = pd.DataFrame(kruskal_rows)
    ranking_marcas.to_csv(data_dir / "marcas_ranking_por_categoria.csv", index=False, encoding="utf-8")
    kruskal_df.to_csv(data_dir / "marcas_kruskal_por_categoria.csv", index=False, encoding="utf-8")

    fig, axes = plt.subplots(1, len(cats), figsize=(5.3 * len(cats), 5.6))
    if len(cats) == 1:
        axes = [axes]
    for ax, cat in zip(axes, cats):
        orden = ranking_marcas.loc[ranking_marcas["category"] == cat, "brand"].tolist()
        sub = nuevos_marca[(nuevos_marca["category"] == cat) & (nuevos_marca["brand"].isin(orden))]
        sns.boxplot(data=sub, y="brand", x="internet_price", order=orden, color="#2a78d6", width=0.6, fliersize=2.5, linewidth=1.1, ax=ax)
        ax.set_xscale("log")
        xmax = sub["internet_price"].max()
        ax.set_xlim(sub["internet_price"].min() * 0.7, xmax * 3.2)
        for i, marca in enumerate(orden):
            fila = ranking_marcas[(ranking_marcas["category"] == cat) & (ranking_marcas["brand"] == marca)].iloc[0]
            ax.text(xmax * 1.35, i, f"n={fila['n_nuevos']}\nIQR rel. {fila['iqr_relativo_pct']:.0f} %", va="center", fontsize=8, color="#333333")
        k = kruskal_df[kruskal_df["category"] == cat].iloc[0]
        p_str = f"{k['p_value']:.2g}" if not pd.isna(k["p_value"]) else "NA"
        ax.set_title(f"{cat} (Kruskal-Wallis p = {p_str})", fontweight="bold")
        ax.set_xlabel("Precio internet S/ (escala log)")
        ax.set_ylabel("")
    fig.suptitle("Precio internet por marca (equipos nuevos)", fontsize=13)
    plt.tight_layout()
    _save(fig, img_dir / "ana_08_ranking_precio_marcas.png")

    g_rows = []
    for cat in cats:
        orden = ranking_marcas.loc[ranking_marcas["category"] == cat, "brand"].tolist()
        sub = nuevos_marca[(nuevos_marca["category"] == cat) & (nuevos_marca["brand"].isin(orden))]
        ct = pd.crosstab(sub["brand"], sub["prices_category"]).reindex(index=orden, columns=TIERS, fill_value=0)
        pct = ct.div(ct.sum(axis=1).replace(0, np.nan), axis=0) * 100
        for marca in orden:
            g_rows.append({
                "category": cat, "brand": marca, "n_nuevos": int(ct.loc[marca].sum()),
                "pct_low": round(float(pct.loc[marca, "low"]), 1),
                "pct_mid": round(float(pct.loc[marca, "mid"]), 1),
                "pct_high": round(float(pct.loc[marca, "high"]), 1),
                "gama_dominante": pct.loc[marca].idxmax(),
            })
    marcas_gama = pd.DataFrame(g_rows)
    marcas_gama.to_csv(data_dir / "marcas_distribucion_por_gama.csv", index=False, encoding="utf-8")

    phones_ref = marcas_base[(marcas_base["category"] == "phones") & (marcas_base["is_refurbished"] == 1)]["brand"].value_counts().head(2).index.tolist()
    ref_rows = []
    for marca in phones_ref:
        s = marcas_base[(marcas_base["category"] == "phones") & (marcas_base["brand"] == marca)]
        for etiq, dat in [("solo nuevos", s[s["is_refurbished"] == 0]), ("nuevos + reacondicionados", s)]:
            dist = dat["prices_category"].value_counts(normalize=True).reindex(TIERS, fill_value=0) * 100
            ref_rows.append({
                "brand": marca, "conjunto": etiq, "n": len(dat),
                "mediana_soles": round(float(dat["internet_price"].median()), 2) if len(dat) else np.nan,
                "pct_low": round(float(dist["low"]), 1), "pct_mid": round(float(dist["mid"]), 1), "pct_high": round(float(dist["high"]), 1),
            })
    pd.DataFrame(ref_rows).to_csv(data_dir / "marcas_efecto_reacondicionados_celulares.csv", index=False, encoding="utf-8")

    fig, axes = plt.subplots(1, len(cats), figsize=(5.0 * len(cats), 5.2))
    if len(cats) == 1:
        axes = [axes]
    for ax, cat in zip(axes, cats):
        sub = marcas_gama[marcas_gama["category"] == cat].set_index("brand")
        matriz = sub[["pct_low", "pct_mid", "pct_high"]]
        matriz.columns = TIERS
        sns.heatmap(matriz, annot=True, fmt=".0f", cmap="Blues", vmin=0, vmax=100, cbar=False, linewidths=2, linecolor="white", annot_kws={"fontsize": 10}, ax=ax)
        ax.set_yticklabels([f"{m} (n={n})" for m, n in zip(sub.index, sub["n_nuevos"])], rotation=0)
        ax.set_title(cat, fontweight="bold")
        ax.set_xlabel("Gama")
        ax.set_ylabel("")
    fig.suptitle("Distribucion del portafolio por gama (% en equipos nuevos)", fontsize=13)
    plt.tight_layout()
    _save(fig, img_dir / "ana_09_marcas_por_gama.png")

    tvs = df[(df["category"] == "tvs") & (df["inches"] > 0)].copy()
    if not tvs.empty:
        tvs["precio_por_pulgada"] = tvs["internet_price"] / tvs["inches"]
        rho, p_rho = stats.spearmanr(tvs["inches"], tvs["internet_price"])
        cnt = tvs["inches"].value_counts()
        tamanos = sorted(cnt[cnt >= 5].index) or sorted(cnt.index)
        tabla_pulg = (
            tvs[tvs["inches"].isin(tamanos)].groupby("inches")
            .agg(
                n=("product", "size"),
                q1_soles=("internet_price", lambda s: s.quantile(0.25)),
                mediana_soles=("internet_price", "median"),
                q3_soles=("internet_price", lambda s: s.quantile(0.75)),
                mediana_soles_por_pulgada=("precio_por_pulgada", "median"),
                mediana_desc_pct=("discount_pct", "median"),
                pct_falabella_direct=("seller_type", lambda s: (s == "FALABELLA_DIRECT").mean() * 100),
            )
            .round(1).reset_index()
        )
        groups_tv = [tvs.loc[tvs["inches"] == t, "internet_price"] for t in tamanos]
        h_tv, p_kw_tv = stats.kruskal(*groups_tv) if len(groups_tv) >= 2 else (np.nan, np.nan)
        pd.DataFrame([{"n": len(tvs), "spearman_rho": round(float(rho), 3), "spearman_p": float(p_rho), "kruskal_H": round(float(h_tv), 2) if not np.isnan(h_tv) else np.nan, "kruskal_p": float(p_kw_tv) if not np.isnan(p_kw_tv) else np.nan}]).to_csv(data_dir / "tvs_correlacion_pulgadas_precio.csv", index=False, encoding="utf-8")
        tabla_pulg.to_csv(data_dir / "tvs_precio_por_pulgadas.csv", index=False, encoding="utf-8")

        top_sizes = cnt.head(2).index.tolist()
        top_brands = tvs["brand"].value_counts().head(3).index.tolist()
        tvs[tvs["inches"].isin(top_sizes) & tvs["brand"].isin(top_brands)].groupby(["inches", "brand"])["internet_price"].agg(n="size", mediana_soles="median").reset_index().to_csv(data_dir / "tvs_precio_marca_top_pulgadas.csv", index=False, encoding="utf-8")

        palette_list = ["#2a78d6", "#eb6834", "#1baf7a"]
        pal_tv = {b: palette_list[i] for i, b in enumerate(top_brands)}
        pal_tv["Otras marcas"] = "#9a9a9a"
        tvs["marca_grafico"] = np.where(tvs["brand"].isin(top_brands), tvs["brand"], "Otras marcas")

        fig, axes = plt.subplots(1, 2, figsize=(14.5, 5.3), gridspec_kw={"width_ratios": [1.35, 1]})
        jitter = np.random.default_rng(42).uniform(-0.8, 0.8, len(tvs))
        for marca, color in pal_tv.items():
            s = tvs[tvs["marca_grafico"] == marca]
            if not s.empty:
                axes[0].scatter(s["inches"] + jitter[tvs["marca_grafico"].values == marca], s["internet_price"], s=28, alpha=0.75, color=color, edgecolor="white", linewidth=0.6, label=f"{marca} (n={len(s)})")
        axes[0].plot(tabla_pulg["inches"], tabla_pulg["mediana_soles"], color="#222222", linewidth=2, marker="o", markersize=6, label="Mediana por tamano")
        axes[0].set_yscale("log")
        axes[0].set_xlabel("Tamano de pantalla (pulgadas)")
        axes[0].set_ylabel("Precio internet S/ (escala log)")
        axes[0].set_title(f"TVs: Precio vs. pulgadas (Spearman rho = {rho:.2f})", fontweight="bold")
        axes[0].legend(fontsize=9, frameon=True, loc="upper left")

        axes[1].bar([f'{int(t)}"' for t in tabla_pulg["inches"]], tabla_pulg["mediana_soles_por_pulgada"], color="#2a78d6", width=0.6)
        for i, (v, n) in enumerate(zip(tabla_pulg["mediana_soles_por_pulgada"], tabla_pulg["n"])):
            axes[1].text(i, v + max(0.5, tabla_pulg["mediana_soles_por_pulgada"].max() * 0.02), f"S/ {v:.1f}\nn={int(n)}", ha="center", va="bottom", fontsize=8.5)
        axes[1].set_ylim(0, tabla_pulg["mediana_soles_por_pulgada"].max() * 1.3)
        axes[1].set_xlabel("Tamano de pantalla")
        axes[1].set_ylabel("Mediana S/ por pulgada")
        axes[1].set_title("Costo mediano por pulgada", fontweight="bold")
        plt.tight_layout()
        _save(fig, img_dir / "ana_10_precio_pulgadas_tvs.png")


def run(
    raw_path=DEFAULT_RAW,
    clean_path=None,
    removed_path=None,
    log_path=None,
    processed_path=None,
    output_dir=DEFAULT_OUTPUT_DIR,
):
    """Genera todas las tablas CSV analiticas y los 15 graficos PNG en <output_dir>."""
    output_dir = Path(output_dir).resolve()
    data_dir = output_dir / "data"
    img_dir = output_dir / "img"
    data_dir.mkdir(parents=True, exist_ok=True)
    img_dir.mkdir(parents=True, exist_ok=True)

    processed_path = Path(processed_path) if processed_path else (data_dir / "falabella_processed.csv")
    clean_path = Path(clean_path) if clean_path else (data_dir / "falabella_cleaned.csv")
    removed_path = Path(removed_path) if removed_path else (data_dir / "falabella_removed_rows.csv")
    log_path = Path(log_path) if log_path else (data_dir / "cleaning_log.csv")

    df = pd.read_csv(processed_path, encoding="utf-8")
    df["prices_category"] = pd.Categorical(df["prices_category"], categories=TIERS, ordered=True)
    if int(df.isna().sum().sum()) > 0:
        raise ValueError("El dataset procesado contiene valores nulos.")

    raw = pd.read_csv(raw_path, encoding="utf-8") if raw_path and Path(raw_path).exists() else None
    clean = pd.read_csv(clean_path, encoding="utf-8") if clean_path.exists() else df
    removed = pd.read_csv(removed_path, encoding="utf-8") if removed_path.exists() else pd.DataFrame()
    log_df = pd.read_csv(log_path, encoding="utf-8") if log_path.exists() else pd.DataFrame()

    sns.set_theme(style="whitegrid", context="notebook")
    cats = _ordered_cats(df)

    _generate_preprocessing_stage(raw, clean, removed, log_df, df, cats, data_dir, img_dir)
    _generate_fe_stage(df, cats, data_dir, img_dir)
    _generate_obj1_stage(df, cats, data_dir, img_dir)
    _generate_obj2_stage(df, cats, data_dir, img_dir)
    _generate_obj3_stage(df, cats, data_dir, img_dir)

    print(f"[analysis] Tablas y 15 graficos generados en {output_dir}")
    return {
        "n_rows": len(df),
        "n_cols": df.shape[1],
        "n_nulls": int(df.isna().sum().sum()),
        "data_dir": data_dir,
        "img_dir": img_dir,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Genera tablas CSV y 15 graficos PNG en <output-dir>")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--raw-path", type=Path, default=DEFAULT_RAW)
    args = parser.parse_args()
    run(raw_path=args.raw_path, output_dir=args.output_dir)