#set par(justify: true)
#set page(
  margin: 1.8cm,
  header: align(left)[
    _DS3021 Análisis Computacional de Datos_ \
    _Semestre 2026-1_
  ],
)

#set text(size: 11pt, lang: "es", font: "New Computer Modern")
#set heading(numbering: "1.")
#show link: underline

#align(center)[
  #text(font: "New Computer Modern", size: 18pt)[
    *Diccionario de Datos Crudos (`falabella_raw.csv`)*
  ]

  #v(0.6cm)

  #show table.cell: set text(size: 8.8pt)
  #figure(
    table(
      columns: (1.4fr, 2.3fr, 1.3fr, 1.5fr, 3.0fr, 1.0fr),
      align: (
        left + horizon,
        left + horizon,
        center + horizon,
        center + horizon,
        left + horizon,
        center + horizon,
      ),
      [*Variable*], [*Descripción*], [*Tipo*], [*Tamaño máximo*], [*Valores observados*], [*Unidad*],

      [`product`],
      [Nombre completo de la publicación tal como aparece en Falabella Perú],
      [Texto \ (`object`)],
      [131 caracteres],
      [1,308 títulos distintos (0 % NA). Ej.: `"CELULAR REDMI A5 3GB + 64GB AZUL OCÉANO"`],
      [-],

      [`brand`],
      [Fabricante o marca comercial declarada en la publicación],
      [Categórico \ (`object`)],
      [21 caracteres],
      [95 marcas distintas (0 % NA); principales: `GENERICO` (238), `LENOVO` (193), `ASUS` (144), `SAMSUNG` (141), `APPLE` (133)],
      [-],

      [`category`],
      [Línea tecnológica consultada por el spider en Falabella],
      [Categórico \ (`object`)],
      [7 caracteres],
      [`phones` (560), `laptops` (560), `tvs` (560) — 0 % NA],
      [-],

      [`seller`],
      [Comercio o vendedor que publica el producto en el marketplace],
      [Categórico \ (`object`)],
      [36 caracteres],
      [305 vendedores distintos (0 % NA); principales: `FALABELLA` (133), `JA INNOVATION` (72), `COMPUVISION.` (58)],
      [-],

      [`list_price`],
      [Precio de lista o tachado sin descuento declarado en la tarjeta (vacío si no hay rebaja)],
      [Numérico \ (`float64`)],
      [7 dígitos \ (5 int + 2 dec)],
      [S/ 22.00 a S/ 79,999.00 (mediana S/ 2,499.00; 74 vacíos = 4.4 % NA)],
      [Soles (S/)],

      [`internet_price`],
      [Precio vigente de venta en línea mostrado en Falabella Perú],
      [Numérico \ (`float64`)],
      [7 dígitos \ (5 int + 2 dec)],
      [S/ 9.89 a S/ 27,345.56 (mediana S/ 1,599.70; 0 % NA)],
      [Soles (S/)],
    ),
    caption: [Diccionario de datos crudos (`data/raw/falabella_raw.csv`)],
  )
]