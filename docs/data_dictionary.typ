#set par(justify: true)
#set page(
  header: align(left)[
    _DS3021 Análisis Computacional de Datos_ \
    _Semestre 2026-2_
  ],
)

#set text(size: 12pt, lang: "es", font: "New Computer Modern")
#set heading(numbering: "1.")
#show link: underline

#align(center)[
  #text(font: "New Computer Modern Sans", size: 20pt)[
    *Diccionario de Datos*

    *DS3021 Análisis Computacional de Datos*
  ]

  #v(1cm)

  #show table.cell: set text(size: 9pt)
  #figure(
    table(
      columns: 6,
      align: (
        center + horizon,
        center + horizon,
        center + horizon,
        center + horizon,
        center + horizon,
        center + horizon,
      ),
      [*Variable*], [*Descripción*], [*Tipo*], [*Tamaño máximo*], [*Valores*], [*Unidad*],

      [`product`],
      [Identificador / nombre del producto],
      [Cadena de Caracteres],
      [*147* : encontrado \ \ `TEXT` sin límites por SQL],
      [Texto en mayúsculas (ej. "`CELULAR GALAXY S26 512GB`")],
      [-],

      [`brand`],
      [Fabricante o marca comercial asociada a un producto],
      [Categórico],
      [*15* : encontrado \ \ Delimitado por SQL `VARCHAR(50)`],
      [88 marcas distintas: `GENERICO, LENOVO, APPLE, ASUS, HP, SAMSUNG, XIAOMI, LG…`],
      [-],

      [`category`],
      [Clasificación de producto en base a su tipo],
      [Categórico],
      [*7* : encontrado \ \ Delimitado por SQL `VARCHAR(50)`],
      [phones, laptops, tvs],
      [-],

      [`seller`],
      [Comercio que ofrece el producto],
      [Categórico],
      [*36* : encontrado \ \ Delimitado por SQL `VARCHAR(100)`],
      [275 vendedores, en MAYÚSCULAS: `FALABELLA, NORTICO PE, JA INNOVATION, TOTTUS…`],
      [-],

      [`list_price`],
      [Precio de lista o referencial de un producto sin aplicar reducción],
      [Numérico \ (decimal)],
      [*7* (5 enteros + 2 decimales)],
      [19.90 a 79,999.00 \ \ Variación $0 - 10^6$],
      [Soles (S/)],

      [`internet_price`],
      [Precio de venta online de un producto con oferta o promoción general],
      [Numérico \ (decimal)],
      [*7* (5 enteros + 2 decimales)],
      [9.90 a 27,345.56 \ \ Variación $0 - 10^6$],
      [Soles (S/)],
    ),
    caption: [Diccionario de datos],
  )
]
