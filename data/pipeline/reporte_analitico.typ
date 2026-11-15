#set par(justify: true)
#set text(size: 10pt, lang: "es", font: "New Computer Modern")
#set heading(numbering: "1.")
#set page(margin: 1.6cm)
#show figure.where(kind: table): set block(breakable: true)
#show table.cell.where(y: 0): set text(weight: "bold")

#align(center)[
  #text(size: 18pt, weight: "bold")[Reporte Automatizado]
  \ 
  _Dataset procesado: 1,037 registros, 16 variables, 0 valores nulos_
]

= Resumen de Volumen y Preprocesamiento
Resultados objetivos de la depuracion, remocion de registros e imputacion ejecutadas por `cleaning.py`.
#align(center)[
  #figure(
    text(size: 8pt)[
      #table(
        columns: (auto, auto, auto, auto),
        inset: (x: 5pt, y: 4pt),
        align: (left, center, center, center),
        [*Etapa*], [*Registros*], [*Cols.*], [*Nulos*],
      [Crudo (raw)], [1,680], [6], [74],
      [Limpio (cleaned)], [1,037], [8], [0],
      [Procesado (processed)], [1,037], [16], [0],
      )
    ],
    caption: [Volumen del dataset por etapa del pipeline],
  )
]

#align(center)[
  #figure(
    text(size: 8pt)[
      #table(
        columns: (2.4fr, auto, auto, auto),
        inset: (x: 5pt, y: 4pt),
        align: (left, center, center, center),
        [*Paso de preprocesamiento*], [*Antes*], [*Despues*], [*Afectadas*],
      [duplicados exactos], [1,680], [1,424], [256],
      [duplicados tras normalizar texto], [1,424], [1,423], [1],
      [accesorios y productos que no son el equipo], [1,423], [1,037], [386],
      [list\_price vacio imputado con internet\_price], [1,037], [1,037], [36],
      [precios atipicos marcados (no eliminados)], [1,037], [1,037], [53],
      )
    ],
    caption: [Registro de filas afectadas por paso de limpieza],
  )
]

#align(center)[
  #figure(
    text(size: 8pt)[
      #table(
        columns: (2.2fr, auto, auto, auto),
        inset: (x: 5pt, y: 4pt),
        align: (left, center, center, center),
        [*Motivo de remocion*], [*Registros*], [*% Remov.*], [*% Crudo*],
      [duplicado exacto], [257], [40], [15.3],
      [control remoto o funda], [132], [20.5], [7.9],
      [cable, adaptador o conversor], [81], [12.6], [4.8],
      [soporte, rack o pantalla de proyeccion], [65], [10.1], [3.9],
      [accesorio u otro producto (repuesto)], [25], [3.9], [1.5],
      [antena o decodificador], [25], [3.9], [1.5],
      [streaming, reproductor u otro dispositivo], [21], [3.3], [1.2],
      [proyector], [18], [2.8], [1.1],
      [otro producto que no es televisor], [14], [2.2], [0.8],
      [accesorio u otro producto (cargador)], [1], [0.2], [0.1],
      [accesorio u otro producto (cable)], [1], [0.2], [0.1],
      [accesorio u otro producto (adaptador)], [1], [0.2], [0.1],
      [accesorio u otro producto (pulsera)], [1], [0.2], [0.1],
      [accesorio u otro producto (monitor)], [1], [0.2], [0.1],
      )
    ],
    caption: [Desglose de registros removidos por motivo],
  )
]

#figure(image("img/pre_01_accesorios_antes_despues.png", width: 92%), caption: [Comparacion antes y despues de filtrar accesorios])
#figure(image("img/pre_02_outliers_precio.png", width: 92%), caption: [Precios atipicos marcados por IQR 1.5])
#figure(image("img/pre_03_filas_afectadas_por_paso.png", width: 92%), caption: [Filas afectadas por paso de limpieza])

= Feature Engineering
Umbrales empiricos por terciles y distribucion de banderas generadas por `processing_data.py`.
#align(center)[
  #figure(
    text(size: 7.2pt)[
      #table(
        columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*Min (S/)*], [*P33 (S/)*], [*Mediana (S/)*], [*P66 (S/)*], [*Max (S/)*], [*Low*], [*Mid*], [*High*],
      [laptops], [835.00], [3,199.0], [3,739.0], [4,699.0], [27,345.6], [155], [136], [142],
      [phones], [79.90], [892.33], [1,399.0], [2,125.7], [8,999.0], [146], [145], [146],
      [tvs], [283.90], [1,489.0], [1,729.0], [1,999.0], [9,999.0], [57], [55], [55],
      )
    ],
    caption: [Cortes de terciles por categoria],
  )
]

#align(center)[
  #figure(
    text(size: 7.2pt)[
      #table(
        columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*n*], [*% Directo*], [*% c/ Desc.*], [*Reac.*], [*% Reac.*], [*Combos*], [*% Combos*], [*Outliers*],
      [laptops], [433], [9], [96.3], [17], [3.9], [20], [4.6], [15],
      [phones], [437], [13], [96.6], [76], [17.4], [52], [11.9], [20],
      [tvs], [167], [35.3], [97], [0], [0], [25], [15], [18],
      )
    ],
    caption: [Distribucion de vendedores y banderas derivadas por categoria],
  )
]

#figure(image("img/fe_01_gamas_terciles.png", width: 92%), caption: [Segmentacion de gamas por terciles empiricos])
#figure(image("img/fe_02_banderas_y_vendedores.png", width: 92%), caption: [Tipo de vendedor, banderas y pulgadas en TVs])

= Analisis de Precios, Dispersion y Descuentos (Objetivo 1)
#page(flipped: true, margin: 1.2cm)[
#align(center)[
  #figure(
    text(size: 7pt)[
      #table(
        columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*n*], [*Min (S/)*], [*Q1 (S/)*], [*Mediana (S/)*], [*Q3 (S/)*], [*Max (S/)*], [*IQR (S/)*], [*IQR rel. (%)*], [*Media (S/)*], [*DE (S/)*],
      [laptops], [433], [835.00], [2,859.0], [3,739.0], [5,699.0], [27,345.6], [2,840.0], [76], [4,562.7], [3,073.6],
      [phones], [437], [79.90], [699.00], [1,399.0], [2,779.0], [8,999.0], [2,080.0], [148.7], [1,945.5], [1,680.2],
      [tvs], [167], [283.90], [1,299.0], [1,729.0], [2,399.4], [9,999.0], [1,100.5], [63.6], [2,219.6], [1,770.6],
      )
    ],
    caption: [Dispersion relativa de precios por categoria],
  )
]

#align(center)[
  #figure(
    text(size: 7pt)[
      #table(
        columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*Gama*], [*n*], [*% c/ Desc.*], [*Med. Precio*], [*Med. Desc. (%)*], [*IQR Desc.*], [*Med. Ahorro*], [*IQR Ahorro*],
      [laptops], [low], [155], [95.5], [2,499.0], [23.33], [20.27], [620.00], [804.04],
      [laptops], [mid], [136], [99.3], [3,799.0], [18.74], [20.70], [977.45], [1,267.8],
      [laptops], [high], [142], [94.4], [6,599.0], [17.24], [13.93], [1,388.5], [1,469.5],
      [phones], [low], [146], [97.3], [519.50], [29.39], [22.05], [200.00], [222.00],
      [phones], [mid], [145], [97.9], [1,399.0], [24.22], [16.18], [420.00], [400.00],
      [phones], [high], [146], [94.5], [3,379.0], [23.58], [20.97], [965.00], [1,206.2],
      [tvs], [low], [57], [100], [1,099.0], [37.02], [20.32], [580.00], [451.00],
      [tvs], [mid], [55], [90.9], [1,729.0], [34.80], [16.95], [900.00], [675.00],
      [tvs], [high], [55], [100], [3,299.0], [31.25], [24.57], [1,700.0], [2,030.0],
      )
    ],
    caption: [Descuentos por categoria y gama],
  )
]

]

#align(center)[
  #figure(
    text(size: 8pt)[
      #table(
        columns: (auto, auto, auto, auto, auto, auto),
        inset: (x: 5pt, y: 4pt),
        align: (center, center, center, center, center, center),
        [*Cat.*], [*n*], [*Pearson r*], [*p (Pearson)*], [*Spearman rho*], [*p (Spearman)*],
      [laptops], [433], [-0.129], [0.0074], [-0.157], [0.0011],
      [phones], [437], [-0.274], [0.0000], [-0.258], [0.0000],
      [tvs], [167], [-0.176], [0.0231], [-0.185], [0.0168],
      )
    ],
    caption: [Correlacion entre precio internet y descuento (%)],
  )
]

#page(flipped: true, margin: 1.2cm)[
#align(center)[
  #figure(
    text(size: 6.8pt)[
      #table(
        columns: (0.7fr, 0.9fr, 1.3fr, 0.9fr, 0.7fr, 0.7fr, 0.6fr, 2.5fr),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, left, center, center, center, center, left),
        [*Cat.*], [*Marca*], [*Vendedor*], [*Tipo vend.*], [*Lista (S/)*], [*Internet (S/)*], [*Desc. (%)*], [*Producto*],
      [laptops], [LENOVO], [IVANCE ELECTRONIC ONLINE], [Marketplace], [79,999.0], [5,699.0], [92.88], [LAPTOP LOQ 15AHP10 AMD RYZEN 7 250 16GB DDR5 512GB RTX...],
      [tvs], [LG], [ELECTROHOGAR], [Marketplace], [4,999.0], [1,599.0], [68.01], [TELEVISOR 65" NANO 4K UHD AI SMART TV 65NU800BPSB - 2026],
      [phones], [LOGIC], [D'TEEC CORPORACION. CJ...], [Marketplace], [299.00], [99.00], [66.89], [CELULAR BASICO C10L 4G DUAL SIM - NEGRO],
      [phones], [LOGIC], [TEC DTEEC], [Marketplace], [299.00], [99.00], [66.89], [CELULAR BASICO C10L 4G DUAL SIM - NEGRO],
      [tvs], [TCL], [IMPORT ELECTRO JB], [Marketplace], [5,999.0], [2,049.0], [65.84], [TELEVISOR QLED 75 UHD 4K SMART TV GOOGLE 75T6C],
      [tvs], [LG], [IVANCE ELECTRONIC ONLINE], [Marketplace], [1,699.0], [589.00], [65.33], [TELEVISOR 32 SMART TV LED 32LQ600BPSA],
      [tvs], [LG], [SEVEN SHOP], [Marketplace], [1,699.0], [589.00], [65.33], [TELEVISOR 32 SMART TV LED 32LQ600BPSA],
      [tvs], [GENERICO], [VICTORIA ILIMITADA], [Marketplace], [2,999.0], [1,069.0], [64.35], [TELEVISOR JVC 50 UHD 4K GOOGLE TV LT-50KB538],
      [tvs], [CAIXUN], [CAIXUN TIENDA OFICIAL], [Marketplace], [989.00], [369.00], [62.69], [SMART TV LED 32 HD ROKU TV C32V1HR],
      [tvs], [JVC], [SODIMAC], [Falabella], [4,999.9], [1,899.9], [62.00], [TELEVISOR 75" QD MINILED 4K GOOGLE TV LT-75KM958],
      [tvs], [SAMSUNG], [ELECTROHOGAR], [Marketplace], [3,999.0], [1,549.0], [61.27], [TELEVISOR QLED 65" SMART TV 4K QN65Q6FAAGXPE - NUEVO 2025],
      [tvs], [SAMSUNG], [ELECTROHOGAR], [Marketplace], [3,999.0], [1,549.0], [61.27], [TELEVISOR QLED 65" SMART TV 4K QN65Q6F - NUEVO 2025],
      [tvs], [LG], [CORPORACION M & P], [Marketplace], [1,499.0], [585.00], [60.97], [TELEVISOR 32" SMART TV HD LED CON THINQ AI MODELO 32LQ6...],
      [phones], [UNNECTO], [MIA PHONE], [Marketplace], [240.00], [95.00], [60.42], [CELULAR BOLT F1 DUAL SIM CON MEMORIA EXPANDIBLE HASTA 1...],
      [phones], [UNNECTO], [MIA PHONE], [Marketplace], [240.00], [95.00], [60.42], [CELULAR BOLT F1 DUAL SIM CON MEMORIA EXPANDIBLE HASTA 1...],
      )
    ],
    caption: [Publicaciones con descuento \>= 60 % (top 15)],
  )
]

]

#figure(image("img/ana_01_violin_precios_categoria.png", width: 92%), caption: [Violines de precio internet y descuento por categoria])
#figure(image("img/ana_02_boxplots_descuento_gama.png", width: 92%), caption: [Descuentos (%) y ahorro nominal por gama])
#figure(image("img/ana_03_scatter_precio_descuento.png", width: 92%), caption: [Dispersion entre precio internet y descuento (%)])
#figure(image("img/ana_04_anomalias_reacondicionados_combos.png", width: 92%), caption: [Efecto de reacondicionados y combos promocionales])

= Competitividad entre Tipos de Vendedor (Objetivo 2)
#align(center)[
  #figure(
    text(size: 7.5pt)[
      #table(
        columns: (auto, auto, auto, auto, auto, auto),
        inset: (x: 5pt, y: 4pt),
        align: (center, center, center, center, center, center),
        [*Cat.*], [*Falabella Direct*], [*Marketplace*], [*Total*], [*% Directo*], [*Reac. Mkt.*],
      [laptops], [39], [394], [433], [9], [17],
      [phones], [57], [380], [437], [13], [76],
      [tvs], [59], [108], [167], [35.3], [0],
      )
    ],
    caption: [Composicion de vendedores por categoria],
  )
]

#align(center)[
  #figure(
    text(size: 7.2pt)[
      #table(
        columns: (auto, auto, auto, auto, 1.4fr, auto, auto, auto),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, left, center, center, center),
        [*Cat.*], [*Pub.*], [*Vend. dist.*], [*Vend. 1 pub.*], [*Vendedor lider*], [*% Lider*], [*% Top 5*], [*HHI*],
      [laptops], [433], [83], [28], [NORTICO PE], [8.3], [33.3], [362],
      [phones], [437], [100], [26], [FALABELLA], [8.7], [25.2], [247],
      [tvs], [167], [41], [17], [FALABELLA], [25.1], [47.9], [882],
      [TOTAL], [1,037], [186], [59], [FALABELLA], [10.9], [24], [240],
      )
    ],
    caption: [Concentracion e indice HHI por categoria],
  )
]

#page(flipped: true, margin: 1.2cm)[
#align(center)[
  #figure(
    text(size: 6.8pt)[
      #table(
        columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*Gama*], [*n Fal.*], [*n Mkt.*], [*Med. Fal.*], [*Med. Mkt.*], [*Dif. (F-M)*], [*U*], [*p-valor*], [*r RB*], [*p Holm*], [*Sig. p\<0.05*], [*Sig. Holm*],
      [laptops], [low], [11], [129], [2,449.0], [2,599.0], [-150.00], [634.50], [0.5635], [-0.106], [1.0000], [No], [No],
      [laptops], [mid], [17], [118], [3,899.0], [3,789.0], [110.00], [1,237.5], [0.1205], [0.234], [0.9638], [No], [No],
      [laptops], [high], [11], [130], [6,599.0], [6,624.0], [-25.00], [771.50], [0.6667], [0.079], [1.0000], [No], [No],
      [phones], [low], [10], [125], [534.00], [499.00], [35.00], [756.50], [0.2709], [0.210], [1.0000], [No], [No],
      [phones], [mid], [21], [81], [1,399.0], [1,399.0], [0.00], [862.50], [0.9241], [0.014], [1.0000], [No], [No],
      [phones], [high], [26], [98], [3,849.0], [3,414.0], [435.00], [1,517.5], [0.1357], [0.191], [0.9638], [No], [No],
      [tvs], [low], [15], [42], [1,199.0], [1,074.0], [125.00], [350.50], [0.5257], [0.113], [1.0000], [No], [No],
      [tvs], [mid], [16], [39], [1,799.0], [1,729.0], [70.00], [324.50], [0.8235], [0.040], [1.0000], [No], [No],
      [tvs], [high], [28], [27], [3,699.0], [2,999.0], [700.00], [485.00], [0.0728], [0.283], [0.6552], [No], [No],
      )
    ],
    caption: [Prueba Mann-Whitney de precio por gama (equipos nuevos)],
  )
]

#align(center)[
  #figure(
    text(size: 6.8pt)[
      #table(
        columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*Gama*], [*n Fal.*], [*n Mkt.*], [*Med. Fal.*], [*Med. Mkt.*], [*Dif. (F-M)*], [*U*], [*p-valor*], [*r RB*], [*p Holm*], [*Sig. p\<0.05*], [*Sig. Holm*],
      [laptops], [low], [11], [129], [37.19], [22.51], [14.68], [1,133.5], [0.0010], [0.598], [0.0072], [Si], [Si],
      [laptops], [mid], [17], [118], [34.33], [17.12], [17.21], [1,525.0], [0.0005], [0.520], [0.0043], [Si], [Si],
      [laptops], [high], [11], [130], [33.97], [16.67], [17.30], [1,068.0], [0.0067], [0.494], [0.0403], [Si], [Si],
      [phones], [low], [10], [125], [20.95], [30.06], [-9.11], [402.50], [0.0621], [-0.356], [0.2486], [No], [No],
      [phones], [mid], [21], [81], [21.06], [24.72], [-3.66], [708.50], [0.2415], [-0.167], [0.5367], [No], [No],
      [phones], [high], [26], [98], [11.52], [25.89], [-14.37], [688.00], [0.0003], [-0.460], [0.0029], [Si], [Si],
      [tvs], [low], [15], [42], [33.35], [37.25], [-3.90], [261.00], [0.3323], [-0.171], [0.5367], [No], [No],
      [tvs], [mid], [16], [39], [30.73], [35.40], [-4.67], [239.00], [0.1789], [-0.234], [0.5367], [No], [No],
      [tvs], [high], [28], [27], [25.90], [38.58], [-12.68], [242.00], [0.0225], [-0.360], [0.1126], [Si], [No],
      )
    ],
    caption: [Prueba Mann-Whitney de descuento por gama (equipos nuevos)],
  )
]

]

#figure(image("img/ana_05_composicion_vendedores.png", width: 92%), caption: [Participacion y top vendedores del catalogo])
#figure(image("img/ana_06_precio_vendedor_por_gama.png", width: 92%), caption: [Precio internet por tipo de vendedor y gama])
#figure(image("img/ana_07_descuento_vendedor_por_gama.png", width: 92%), caption: [Descuento declarado por tipo de vendedor y gama])

= Posicionamiento por Marca y Tamano en TVs (Objetivo 3)
#page(flipped: true, margin: 1.2cm)[
#align(center)[
  #figure(
    text(size: 6.8pt)[
      #table(
        columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center, center, center, center, center, center),
        [*Cat.*], [*Marca*], [*n Nuevos*], [*Reac.*], [*% Directo*], [*Min (S/)*], [*Q1 (S/)*], [*Mediana (S/)*], [*Q3 (S/)*], [*Max (S/)*], [*IQR (S/)*], [*IQR rel. (%)*], [*Med. Desc. (%)*],
      [laptops], [MSI], [12], [0], [0], [5,549.0], [6,424.0], [6,599.0], [6,799.0], [9,299.0], [375.00], [5.7], [20.00],
      [laptops], [APPLE], [28], [4], [7.1], [2,450.0], [3,959.0], [5,699.0], [6,499.0], [9,749.0], [2,540.0], [44.6], [11.83],
      [laptops], [ASUS], [109], [0], [14.7], [1,038.0], [3,199.0], [4,050.0], [7,499.0], [27,345.6], [4,300.0], [106.2], [25.33],
      [laptops], [ACER], [17], [0], [17.6], [1,699.0], [2,489.0], [3,899.0], [5,499.0], [6,999.0], [3,010.0], [77.2], [20.29],
      [laptops], [LENOVO], [147], [7], [8.2], [1,599.9], [2,974.5], [3,599.0], [4,699.0], [22,890.0], [1,724.5], [47.9], [17.77],
      [laptops], [HP], [93], [3], [6.5], [1,147.0], [2,399.0], [3,399.0], [4,469.0], [8,709.0], [2,070.0], [60.9], [20.00],
      [phones], [APPLE], [46], [44], [21.7], [2,699.0], [3,274.0], [5,069.0], [6,199.0], [8,999.0], [2,925.0], [57.7], [25.16],
      [phones], [SAMSUNG], [64], [22], [23.4], [429.00], [956.50], [2,199.0], [3,801.5], [6,990.0], [2,845.0], [129.4], [27.38],
      [phones], [OPPO], [12], [0], [16.7], [849.00], [1,199.0], [1,599.0], [1,599.0], [1,599.0], [400.00], [25], [36.01],
      [phones], [XIAOMI], [79], [0], [12.7], [375.00], [764.00], [1,419.0], [2,624.4], [5,299.0], [1,860.5], [131.1], [19.89],
      [phones], [HONOR], [59], [4], [11.9], [375.00], [793.50], [1,099.0], [1,799.0], [3,599.0], [1,005.5], [91.5], [20.10],
      [phones], [MOTOROLA], [25], [0], [36], [379.00], [549.00], [1,049.0], [1,399.0], [6,999.0], [850.00], [81], [27.70],
      [phones], [INFINIX], [12], [0], [0], [449.00], [652.17], [821.00], [1,169.0], [2,159.0], [516.83], [63], [15.16],
      [phones], [ZTE], [15], [0], [13.3], [319.00], [377.45], [459.00], [649.00], [1,399.0], [271.55], [59.2], [22.89],
      [tvs], [SAMSUNG], [48], [0], [29.2], [619.00], [1,549.0], [1,972.0], [3,386.5], [8,999.0], [1,837.5], [93.2], [30.96],
      [tvs], [JVC], [13], [0], [100], [399.00], [799.00], [1,899.9], [2,799.9], [5,299.0], [2,000.9], [105.3], [45.85],
      [tvs], [TCL], [25], [0], [44], [469.00], [1,499.0], [1,849.0], [2,199.0], [9,999.0], [700.00], [37.9], [31.68],
      [tvs], [LG], [59], [0], [27.1], [585.00], [1,324.0], [1,659.0], [1,964.0], [9,999.0], [640.00], [38.6], [35.40],
      )
    ],
    caption: [Ranking de precios por marca (equipos nuevos)],
  )
]

]

#align(center)[
  #figure(
    text(size: 8pt)[
      #table(
        columns: (auto, auto, auto, auto, auto),
        inset: (x: 5pt, y: 4pt),
        align: (center, center, center, center, center),
        [*Cat.*], [*Marcas*], [*H*], [*p-valor*], [*Cobertura (%)*],
      [laptops], [6], [39.19], [2.17e-07], [97.6],
      [phones], [8], [123.21], [1.65e-23], [88.4],
      [tvs], [4], [5.34], [0.1486], [88.4],
      )
    ],
    caption: [Prueba Kruskal-Wallis entre marcas por categoria],
  )
]

#align(center)[
  #figure(
    text(size: 7.5pt)[
      #table(
        columns: (auto, auto, auto, auto, auto, auto, auto, auto),
        inset: (x: 3pt, y: 3pt),
        align: (center, center, center, center, center, center, center, center),
        [*Pulg.*], [*n*], [*Q1 (S/)*], [*Mediana (S/)*], [*Q3 (S/)*], [*S/ / pulg.*], [*Med. Desc. (%)*], [*% Directo*],
      [32], [15], [449.00], [585.00], [604.00], [18.3], [50.10], [6.7],
      [43], [16], [996.50], [1,114.4], [1,424.0], [25.9], [26.60], [18.8],
      [50], [8], [1,091.5], [1,224.4], [1,259.0], [24.5], [35.20], [50],
      [55], [30], [1,359.0], [1,674.0], [1,899.7], [30.4], [28.80], [50],
      [65], [53], [1,559.0], [1,749.0], [2,096.0], [26.9], [34.80], [30.2],
      [75], [19], [2,049.0], [2,299.0], [2,749.0], [30.7], [36.40], [36.8],
      [85], [9], [2,899.0], [3,299.0], [3,499.0], [38.8], [38.60], [66.7],
      )
    ],
    caption: [Precio de televisores segun tamano de pantalla],
  )
]

#figure(image("img/ana_08_ranking_precio_marcas.png", width: 92%), caption: [Distribucion de precios por marca (equipos nuevos)])
#figure(image("img/ana_09_marcas_por_gama.png", width: 92%), caption: [Porcentaje del portafolio de cada marca por gama])
#figure(image("img/ana_10_precio_pulgadas_tvs.png", width: 92%), caption: [Precio frente a tamano de pantalla en televisores])