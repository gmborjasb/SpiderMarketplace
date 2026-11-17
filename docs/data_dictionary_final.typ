#set par(justify: true)
#set page(
  flipped: true,
  margin: (x: 1.2cm, top: 1.35cm, bottom: 1.1cm),
  header: align(left)[
    #text(size: 9.5pt)[_DS3021 Análisis Computacional de Datos · Semestre 2026-2_]
  ],
)

#set text(size: 10pt, lang: "es", font: "New Computer Modern")
#show link: underline

#align(center)[
  #v(1cm)
  #text(size: 14.5pt)[
    *Diccionario de Datos Final (`falabella_processed.csv`)*
  ]
]

#v(0.15cm)

#show table.cell: set text(size: 7.7pt)
#set table(inset: (x: 5pt, y: 3.5pt))
#figure(
  table(
    columns: (1.7fr, 3.1fr, 1.3fr, 1.1fr, 3.6fr, 1.0fr),
    align: (
      left + horizon,
      left + horizon,
      center + horizon,
      center + horizon,
      left + horizon,
      center + horizon,
    ),
    table.header(
      [*Variable*], [*Descripción*], [*Tipo*], [*Tamaño máx.*], [*Valores observados y rango*], [*Unidad*],
    ),

    [`product`],
    [Nombre de publicación normalizado en mayúsculas ASCII, sin espacios repetidos ni punto final.],
    [Texto \ (`object`)],
    [131 caract.],
    [931 valores distintos (0 % NA).],
    [-],

    [`brand`],
    [Marca comercial declarada en mayúsculas. `GENERICO` identifica publicaciones sin marca.],
    [Categórico \ (`object`)],
    [12 caract.],
    [40 marcas: `LENOVO` (154), `SAMSUNG` (134), `APPLE` (122), `ASUS` (109), `HP` (96); 11 `GENERICO`.],
    [-],

    [`category`],
    [Categoría tecnológica del equipo tras retirar accesorios y repuestos.],
    [Categórico \ (`object`)],
    [7 caract.],
    [`phones` (437), `laptops` (433), `tvs` (167).],
    [-],

    [`seller`],
    [Nombre normalizado del vendedor (venta directa Falabella/filiales o tercero externo).],
    [Categórico \ (`object`)],
    [36 caract.],
    [186 vendedores: `FALABELLA` (113), `JA INNOVATION` (37), `NORTICO PE` (36), `TOTTUS` (32)…],
    [-],

    [`list_price`],
    [Precio de lista (tachado). Si venía vacío en el crudo, se imputó con `internet_price`.],
    [Numérico \ (`float64`)],
    [7 dígitos],
    [S/ 159.00 a S/ 79,999.00 (mediana S/ 3,499.00; 0 % NA).],
    [Soles (S/)],

    [`internet_price`],
    [Precio vigente de venta en línea mostrado en la publicación.],
    [Numérico \ (`float64`)],
    [7 dígitos],
    [S/ 79.90 a S/ 27,345.56 (mediana S/ 2,489.00; 0 % NA).],
    [Soles (S/)],

    [`list_price_imputed`],
    [Bandera que indica si `list_price` estaba vacío y fue imputado con `internet_price`.],
    [Binario \ (`int64`)],
    [1 dígito],
    [`0` = original (1,001; 96.5 %), `1` = imputado (36; 3.5 %).],
    [-],

    [`is_price_outlier`],
    [Marca precios atípicos superiores según regla IQR $1.5$ sobre `internet_price` dentro de cada categoría.],
    [Binario \ (`int64`)],
    [1 dígito],
    [`0` = no atípico (984; 94.9 %), `1` = atípico (53; 5.1 %; no eliminados).],
    [-],

    [`has_discount`],
    [Indica si la publicación presenta rebaja declarada (`list_price` $>$ `internet_price`).],
    [Binario \ (`int64`)],
    [1 dígito],
    [`1` = con descuento (1,001; 96.5 %), `0` = sin descuento (36; 3.5 %).],
    [-],

    [`discount_amount`],
    [Ahorro nominal en soles (`list_price` $-$ `internet_price`).],
    [Numérico \ (`float64`)],
    [7 dígitos],
    [S/ 0.00 a S/ 74,300.00 (mediana S/ 696.00).],
    [Soles (S/)],

    [`discount_pct`],
    [Descuento porcentual declarado respecto al precio de lista.],
    [Numérico \ (`float64`)],
    [5 dígitos],
    [0.00 % a 92.88 % (mediana 24.13 %).],
    [Porcentaje (%)],

    [`prices_category`],
    [Segmento de gama por terciles empíricos ($P_(33.3)$, $P_(66.7)$) de `internet_price` por categoría.],
    [Categórico \ (`object`)],
    [4 caract.],
    [`low` (358), `mid` (336), `high` (343).],
    [-],

    [`seller_type`],
    [Clasificación operativa del vendedor: retail directo del grupo vs. marketplace tercero.],
    [Categórico \ (`object`)],
    [18 caract.],
    [`MARKETPLACE_SELLER` (882; 85.1 %), `FALABELLA_DIRECT` (155; 14.9 %: Falabella, Tottus, Sodimac).],
    [-],

    [`is_refurbished`],
    [Bandera extraída por regex en `product` (`REACONDICIONADO`, `OPEN BOX`, `REFURBISHED`, `SEMI NUEVO`).],
    [Binario \ (`int64`)],
    [1 dígito],
    [`0` = nuevo (944; 91.0 %), `1` = reacondicionado (93; 9.0 %).],
    [-],

    [`is_bundle`],
    [Bandera extraída por regex en `product` (`COMBO`, `PACK`, `KIT`, `REGALO` o `+ ACCESORIO`).],
    [Binario \ (`int64`)],
    [1 dígito],
    [`0` = individual (940; 90.6 %), `1` = combo (97; 9.4 %).],
    [-],

    [`inches`],
    [Tamaño diagonal de pantalla extraído por regex en `tvs`; `0` = no aplica en `phones`/`laptops`.],
    [Numérico \ (`int64`)],
    [3 dígitos],
    [En `tvs`: 15 a 100 (100 % extraído, mediana 65); `0` en `phones`/`laptops`.],
    [Pulgadas (`"`)],
  ),
  caption: [Diccionario de datos final (`data/pipeline/data/falabella_processed.csv`)],
)