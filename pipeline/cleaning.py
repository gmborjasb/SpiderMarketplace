"""Limpieza del dataset de Falabella (Parte II).

Cada funcion hace un paso y run() las junta. pipeline/main.py llama a run().
Tambien se puede correr solo, desde la raiz del repo:

    python pipeline/cleaning.py
"""

import re
import unicodedata
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW_PATH = ROOT / "data" / "raw" / "falabella_raw.csv"
CLEAN_PATH = ROOT / "data" / "clean" / "falabella_cleaned.csv"
REMOVED_PATH = ROOT / "data" / "clean" / "falabella_removed_rows.csv"

TEXT_COLUMNS = ("product", "brand", "seller")
IQR_FACTOR = 1.5

# caracteres raros que aparecen en los nombres: comillas, guiones y espacio duro
_CHAR_MAP = str.maketrans(
    {
        chr(0x2033): '"', chr(0x201D): '"', chr(0x201C): '"',
        chr(0x2019): "'", chr(0x2018): "'",
        chr(0x2011): "-", chr(0x2013): "-", chr(0x2014): "-",
        chr(0x00A0): " ",
    }
)

# un televisor de verdad empieza con su tipo o con el tamano de pantalla
_TV_CORE = re.compile(
    r"^(?:NUEVO\s+(?:MODELO\s+)?)?(?:TELEVISOR|SMART\s+TV|TV(?!\s+(?:BOX|BACKLIGHT))"
    r"|(?:LED|QLED|OLED|QNED)\b|\d{2,3}\s*(?:\"|''|AI\b|NANO\b|QNED\b|OLED\b|MINI\b|PULG))"
)

# motivo de retiro y palabras que lo detectan (gana el primero que coincida)
_TV_NON_CORE_REASONS = (
    ("proyector", r"PROYECTOR"),
    ("cable, adaptador o conversor", r"CABLE|ADAPTADOR|CONVERTIDOR|DISPLAYPORT|HDMI|SPLIT|SWITCH|HUB\b|EXTENDER|RECEPTOR|CAPTUR|WECAST|LECTOR|ROLLO"),
    ("control remoto o funda", r"CONTROL|MAGIC|FUNDA|PROTECTOR"),
    ("soporte, rack o pantalla de proyeccion", r"SOPORTE|RACK|BRAZO|ECRAN"),
    ("antena o decodificador", r"ANTENA|DECODIFICADOR|SINTONIZADOR|ISDB|SATELITAL"),
    ("streaming, reproductor u otro dispositivo", r"FIRE TV|TV BOX|STREAMING|REPRODUCTOR|MULTIGRABADOR|CONSOLA|SOUNDBAR|DVR|CAMARA|WATCH"),
)
_ACCESSORY_LEAD = re.compile(
    r"^(?P<lead>CABLE|REPUESTO|CARGADOR|FUNDA|CASE|PROTECTOR|MICA|LAMINA|AUDIFONOS?|BATERIA|"
    r"POWER BANK|ADAPTADOR|SOPORTE|ESTUCHE|CARCASA|MOCHILA|MALETIN|MOUSE|TECLADO|COOLER|BASE|"
    r"MONITOR|PULSERA)\b"
)


def strip_accents(text):
    return "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")


def load_raw(path=RAW_PATH):
    return pd.read_csv(path, encoding="utf-8")


def drop_exact_duplicates(df):
    # filas iguales en todas las columnas, se queda la primera
    mask = df.duplicated(keep="first")
    return df[~mask].copy(), df[mask].assign(removal_reason="duplicado exacto")


def normalize_text(df):
    # todo en mayusculas, sin espacios repetidos y sin el punto final suelto
    # que deja la tienda en cosas como "COMPUVISION."
    out = df.copy()
    for col in TEXT_COLUMNS:
        s = out[col].astype("string").str.translate(_CHAR_MAP)
        s = s.str.replace(r"\s+", " ", regex=True).str.strip().str.upper()
        if col in ("seller", "product"):
            s = s.str.replace(r"\s*\.+$", "", regex=True).str.strip()
        out[col] = s
    return out


def unify_seller_spelling(df):
    # junta vendedores que solo cambian en la puntuacion, con la grafia mas usada
    out = df.copy()
    key = out["seller"].str.replace(r"[^A-Z0-9 ]", " ", regex=True).str.split().str.join(" ")
    canonical = out.groupby(key)["seller"].agg(lambda s: s.value_counts().index[0])
    out["seller"] = key.map(canonical)
    return out


def classify_non_target(df):
    # devuelve el motivo si la fila no es el equipo de su categoria (NA si si lo es).
    # Se mira como empieza el nombre: "CABLE HDMI...", "CONTROL REMOTO..."
    # Los combos "CELULAR ... + CARGADOR" empiezan por el equipo y se quedan.
    names = df["product"].map(strip_accents)
    reasons = pd.Series(pd.NA, index=df.index, dtype="string")

    is_tv = df["category"].eq("tvs")
    not_core_tv = is_tv & ~names.str.match(_TV_CORE)
    for label, pattern in _TV_NON_CORE_REASONS:
        hit = not_core_tv & reasons.isna() & names.str.contains(pattern, regex=True)
        reasons[hit] = label
    reasons[not_core_tv & reasons.isna()] = "otro producto que no es televisor"

    lead = names.str.extract(_ACCESSORY_LEAD)["lead"]
    other = ~is_tv & lead.notna()
    reasons[other] = "accesorio u otro producto (" + lead[other].str.lower() + ")"
    return reasons


def drop_non_target(df):
    reasons = classify_non_target(df)
    mask = reasons.notna()
    return df[~mask].copy(), df[mask].assign(removal_reason=reasons[mask])


def impute_list_price(df):
    # si no hay precio de lista es porque el producto no tiene descuento,
    # asi que se completa con el precio internet y se deja una marca.
    # cmr_price vacio significa que no hay precio CMR, ese no se toca.
    out = df.copy()
    missing = out["list_price"].isna()
    out["list_price_imputed"] = missing.astype("int8")
    out.loc[missing, "list_price"] = out.loc[missing, "internet_price"]
    return out


def flag_price_outliers(df, factor=IQR_FACTOR):
    # regla del IQR sobre internet_price, dentro de cada categoria.
    # Solo se marcan, no se borran.
    out = df.copy()
    grouped = out.groupby("category")["internet_price"]
    q1 = grouped.transform(lambda s: s.quantile(0.25))
    q3 = grouped.transform(lambda s: s.quantile(0.75))
    iqr = q3 - q1
    price = out["internet_price"]
    out["is_price_outlier"] = ((price < q1 - factor * iqr) | (price > q3 + factor * iqr)).astype("int8")
    return out


def cast_types(df):
    out = df.copy()
    for col in TEXT_COLUMNS:
        out[col] = out[col].astype(str)
    out["category"] = out["category"].astype("category")
    for col in ("list_price", "internet_price", "cmr_price"):
        out[col] = out[col].astype("float64")
    return out


def run(raw_path=RAW_PATH, clean_path=CLEAN_PATH, removed_path=REMOVED_PATH):
    # corre todos los pasos, guarda los dos csv y devuelve (limpio, retirados, resumen por paso)
    df = load_raw(raw_path)
    removed_parts = []
    log = []

    def record(step, before, after, affected=None):
        log.append({"paso": step, "filas_antes": before, "filas_despues": after,
                    "filas_afectadas": before - after if affected is None else affected})

    n = len(df)
    df, gone = drop_exact_duplicates(df)
    removed_parts.append(gone)
    record("duplicados exactos", n, len(df))

    df = normalize_text(df)
    df = unify_seller_spelling(df)
    n = len(df)
    df, gone = drop_exact_duplicates(df)
    removed_parts.append(gone)
    record("duplicados tras normalizar texto", n, len(df))

    n = len(df)
    df, gone = drop_non_target(df)
    removed_parts.append(gone)
    record("accesorios y productos que no son el equipo", n, len(df))

    n_missing = int(df["list_price"].isna().sum())
    df = impute_list_price(df)
    record("list_price vacio imputado con internet_price", len(df), len(df), n_missing)

    df = flag_price_outliers(df)
    record("precios atipicos marcados (no eliminados)", len(df), len(df), int(df["is_price_outlier"].sum()))

    df = cast_types(df).reset_index(drop=True)
    removed = pd.concat(removed_parts)

    clean_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(clean_path, index=False, encoding="utf-8")
    removed.to_csv(removed_path, index=False, encoding="utf-8")
    return df, removed, pd.DataFrame(log)


if __name__ == "__main__":
    clean, removed, log = run()
    print(log.to_string(index=False))
    print(f"\nfalabella_cleaned.csv: {clean.shape[0]} filas x {clean.shape[1]} columnas")
