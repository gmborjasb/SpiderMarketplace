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
      [Identificador /nombre del producto],
      [Cadena de Caracteres],
      [*147* :  encontrado \ \ `TEXT` sin límites por SQL],
      [Texto en mayúsculas (ej. "`CELULAR GALAXY S26 512GB`")],
      [-],

      [`brand`],
      [Fabricante o marca comercial asociada a un producto],
      [Categórico],
      [*15* : encontrado \ \ Delimitado por SQL `VARCHAR(50)`],
      [95 marcas distintas: `GENERICO, LENOVO, APPLE, ASUS, HP, SAMSUNG, XIAOMI, LG…`],
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
      [*36* : encontrado \ \ Delimitado por SQL `VARCHAR(50)`],
      [296 vendedores, en MAYÚSCULAS: `FALABELLA, NORTICO PE, JA INNOVATION, TOTTUS…`],
      [-],

      [`regular_price`],
      [Precio regular de un producto sin aplicar alguna reducción],
      [Numérico \ (decimal)],
      [*7* (5 enteros + 2 decimales) ],
      [19.90 a 49,999.00 \ \ Variación $0 - 10^6$],
      [Soles (S/)],

      [`special_price`],
      [Precio de un producto con una oferta o promoción],
      [Numérico \ (decimal)],
      [*7* (5 enteros + 2 decimales)],
      [9.89 a 47,999.00 \ \ Variación $0 - 10^6$],
      [Soles (S/)],

      [`has_cmr_discount`],
      [Indica si un producto cuenta con descuento de tarjeta],
      [Categórico \ Binario],
      [1],
      [0 = No, 1 = Sí],
      [-],
    ),
    caption: [Diccionario de datos],
  )
]
