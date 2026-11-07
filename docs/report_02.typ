#import "@preview/merman:0.5.0": mermaid

#set par(justify: true)
#set text(size: 12pt, lang: "es", font: "New Computer Modern")
#set heading(numbering: "1.")
#show link: underline

#let neo-maroon = rgb("BF0140")

#show heading.where(level: 1): it => {
  if it.numbering == none {
    set text(size: 18pt, font: "New Computer Modern Sans", weight: "bold", fill: black)
    it.body
  } else {
    set text(size: 18pt, font: "New Computer Modern Sans")
    box[
      #text[#sym.section #counter(heading).display()]
      #h(5pt)
      #it.body
    ]
  }
}

#show heading.where(level: 2): it => {
  set text(size: 14pt, font: "New Computer Modern Sans")

  box[
    #text[#sym.section#counter(heading).display()]
    #h(5pt)
    #it.body
  ]
}

#show heading.where(level: 3): it => {
  set text(size: 12pt, font: "New Computer Modern Sans")

  box[
    #text(fill: neo-maroon)[#sym.section#counter(heading).display()]
    #h(5pt)
    #it.body
  ]
}

#show selector(<nonumber>): it => {
  pagebreak(weak: true)
  set text(30pt)
  it.body
  v(1cm)
}


#align(center)[
  *UNIVERSIDAD DE INGENIERÍA Y TECNOLOGÍA*

  #image("img/utec_logo.jpg", width: 45%)

  #v(0.2cm)
  *FACULTAD DE COMPUTACIÓN*

  #v(0.2cm)
  *CARRERA DE DATA SCIENCE*

  #v(0.5cm)
  *SEGUNDO AVANCE DEL PROYECTO FINAL:*

  #v(0.5cm)
  _Análisis de precios, descuentos y competitividad comercial en productos tecnológicos de Falabella Perú_

  #v(0.5cm)
  *INTEGRANTES:*

  Axel Roberth Portal Ruiz

  Alondra Solange Obregon Carhuavilca

  Danna Nickol Gala Vásquez

  Gerald Marcelo Fernando Borjas Bernaola


]
#v(1.5cm)
#align(center)[
  *ANÁLISIS COMPUTACIONAL DE DATOS*
  #v(1cm)
  LIMA - PERÚ

  2026
]

#pagebreak()

#outline(
  title: [Índice General #v(0.5cm)],
  depth: 3,
  indent: (
    nesting => (
      if (nesting == 0) { 0em } else if nesting == 1 { 1em } else if nesting == 2 { 2.5em } else if nesting == 3 {
        4.5em
      }
    )
  ),
)




= Identificación

Para el presente proyecto, se desarrolló la siguiente distribución de responsabilidades:

#align(center)[
  #figure(
    table(
      columns: 2,
      [*Integrante*], [*Responsabilidad*],
      [Alondra Obregón], [Análisis de vendedores y marcas, Insights y Conclusiones],
      [Axel Portal], [Feature engineering, análisis de precios y descuentos, armado del PPT],
      [Danna Gala], [Preprocesamiento, Dataset y diccionario final],
      [Gerald Borjas], [Contexto y objetivos actualizados, Propuesta de pipeline, Documentación en GitHub],
    ),
    caption: [Distribución de responsabilidades],
  )
]

= Contexto actualizado

El crecimiento del comercio electrónico ha incrementado la cantidad de productos y vendedores disponibles en plataformas de marketplace, generando así una mayor variedad de alternativas para los consumidores. En plataformas como Falabella Perú, un mismo tipo de producto puede encontrarse asociado a diferentes marcas, precios, descuentos y vendedores, esto incluyendo tanto la venta directa de la plataforma como ofertas realizadas por terceros.

Esta variedad dificulta poder realizar comparaciones directas entre productos y vendedores, especialmente en categorías tecnológicas con alto valor como lo podrían ser laptops, celulares y televisores. Un producto puede presentar al mismo tiempo un precio de lista y un precio de internet, esto mientras que otros productos de características similares pueden ser comercializados por distintos vendedores a precios diferentes. Por ello, observar únicamente el precio de un producto no permitiría identificar con claridad cómo se distribuyen los precios, qué magnitud tienen los descuentos o cómo varían estas características entre marcas y tipos de vendedores.

Después de obtener la data mediante web scraping, se observa que los datos no necesariamente presentan el comportamiento esperado:

- Existen productos con precios muy bajos ($< "S/." 100$); estos productos suelen ser accesorios (e.g. soportes de pared para televisores clasificados en la categoría de TV) de una misma categoría que son considerados por el marketplace.
- Duplicación de productos debido a la carga dinámica en el marketplace.
- Productos que no presentan `list_price`, es decir, solo tienen precio de venta en internet mas no un precio de lista tachado (4.4 % del dataset crudo, cumpliendo holgadamente el límite máximo de 10 % de valores nulos por columna).

= Objetivos actualizados

/ Objetivo General:

Analizar la estructura de precios, magnitud de descuentos y niveles de competencia entre las marcas de laptops, celulares y televisores en Falabella Perú, comparando las ventas directas con las de los vendedores del marketplace, considerando la heterogeneidad de gamas y marcas.

/ Objetivos Específicos:

- _Evaluar la magnitud, distribución y veracidad de los descuentos_:

  Cuantificar la brecha porcentual entre el precio de lista y precio por internet en las tres categorías tecnológicas, determinando qué líneas presentan rebajas más agresivas y cuáles mantienen precios de venta rígidos, contrastando con fuentes externas para observar la veracidad de dichos descuentos.

- _Contrastar la competitividad tarifaria entre tipos de vendedores_:

  Comparar las distribuciones de precios y la agresividad de ofertas por _Falabella_ (y sus filiales) frente a los vendedores externos (sellers), estratificando el análisis por categoría de producto y nivel de gama, para verificar si los terceros representan una alternativa más económica.

- _Examinar el posicionamiento y la dispersión de costos por marca_:

  Determinar la mediana y la dispersión de precios entre las principales marcas de cada categoría (ej. Apple, Samsung, Lenovo, LG), contrastando la rigidez de las gamas altas frente a la volatilidad en marcas con presencia en cada segmento de precio.


= Dataset y Diccionario de datos

== Dataset Scraping

El dataset preliminar obtenido después del web scraping es el siguiente:

#align(center)[
  #figure(
    table(
      columns: 2,
      [*Atributo*], [*Descripción*],
      [`product`], [Nombre completo del producto tal como aparece en el sitio.],
      [`brand`], [Marca del producto.],
      [`category`], [La categoría del producto es teléfono (`phones`), televisor (`tvs`) o laptop (`laptops`).],
      [`seller`], [Nombre del vendedor del producto.],
      [`list_price`], [Precio de lista sin descuento del producto, en soles.],
      [`internet_price`], [Precio de venta por internet con descuento, en soles.],
    ),
    caption: [Atributos del dataset preliminar],
  )
]

== Volumen y estructura

El dataset crudo obtenido por scraping de Falabella Perú (`data/raw/falabella_raw.csv`) tiene 1,680 filas y 6 columnas (`product`, `brand`, `category`, `seller`, `list_price` e `internet_price`), donde ninguna variable supera el 10 % de valores faltantes (solo `list_price` presenta 4.4 % de vacíos).

El dataset resultante del preprocesamiento (`data/clean/falabella_cleaned.csv`) tiene 1,037 registros y 8 variables, y tras la etapa de ingeniería de características (`data/processed/falabella_processed.csv`) alcanza 1,037 registros y 16 variables con *0 % de valores nulos en todas sus columnas*. Conserva el 61.7 % de las 1,680 filas del CSV crudo y se reparte en 437 celulares, 433 laptops y 167 televisores.

#align(center)[
  #figure(
    table(
      columns: 4,
      align: (left, center, center, center),
      [*Indicador*], [*Antes (CSV crudo)*], [*Limpio (`cleaned`)*], [*Final (`processed`)*],
      [Registros], [1,680], [1,037], [1,037],
      [Variables], [6], [8], [16],
      [Celulares / laptops / televisores], [560 / 560 / 560], [437 / 433 / 167], [437 / 433 / 167],
      [Filas duplicadas exactas], [256 (15.2 %)], [0], [0],
      [Duplicados tras normalizar texto], [1], [0], [0],
      [Accesorios y otros productos], [386 (entre filas únicas)], [0], [0],
      [`list_price` vacío], [74 (4.4 %)], [0 (imputado en 36)], [0],
      [Columnas con valores nulos (NA)], [1 (4.4 %, $< 10\\%$)], [0 (0.0 %)], [0 (0.0 %)],
    ),
    caption: [Volumen del dataset en cada etapa del pipeline],
  )
]

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: (auto, auto, 1fr),
        align: (left, left, left),
        [*Variable*], [*Tipo*], [*Rango o valores observados (1,037 registros, 0 % NA)*],
        [`product`], [Texto], [931 nombres distintos normalizados, hasta 131 caracteres],
        [`brand`], [Categórico], [40 marcas; más frecuentes: Lenovo (154), Samsung (134), Apple (122), Asus (109), HP (96); 11 filas `GENERICO`],
        [`category`], [Categórico], [`phones` (437), `laptops` (433), `tvs` (167)],
        [`seller`], [Categórico], [186 vendedores; 59 aparecen una sola vez; Falabella, Tottus y Sodimac suman 155 filas (14.9 %)],
        [`list_price`], [Numérico (S/)], [S/ 159.00 a S/ 79,999.00],
        [`internet_price`], [Numérico (S/)], [S/ 79.90 a S/ 27,345.56],
        [`list_price_imputed`], [Binario (0/1)], [0 = original (1,001), 1 = imputado con `internet_price` (36 filas, 3.5 %)],
        [`is_price_outlier`], [Binario (0/1)], [0 = no atípico (984), 1 = atípico según IQR 1.5 por categoría (53 filas, 5.1 %)],
        [`has_discount`], [Binario (0/1)], [1 = con descuento (1,001 filas, 96.5 %), 0 = sin descuento (36 filas, 3.5 %)],
        [`discount_amount`], [Numérico (S/)], [S/ 0.00 a S/ 74,300.00 (mediana global: S/ 640.00)],
        [`discount_pct`], [Numérico (%)], [0.00 % a 92.88 % (mediana global: 23.08 %)],
        [`prices_category`], [Categórico], [Gama por terciles intracategoría: `low` (358), `mid` (336), `high` (343)],
        [`seller_type`], [Categórico], [`FALABELLA_DIRECT` (155 filas, 14.9 %), `MARKETPLACE_SELLER` (882 filas, 85.1 %)],
        [`is_refurbished`], [Binario (0/1)], [1 = reacondicionado / open box (93 filas, 9.0 %), 0 = nuevo (944 filas, 91.0 %)],
        [`is_bundle`], [Binario (0/1)], [1 = combo / pack con accesorio (97 filas, 9.4 %), 0 = individual (940 filas, 90.6 %)],
        [`inches`], [Numérico (pulg)], [En `tvs`: 15" a 100" (100 % extraído, mediana 65"); en `phones`/`laptops`: 0 = no aplica],
      )
    ],
    caption: [Variables del dataset final (`falabella_processed.csv`)],
  )
]

Los precios se expresan en soles. La mediana de `internet_price` es S/ 3,739 en laptops, S/ 1,729 en televisores y S/ 1,399 en celulares. Los rangos por categoría van de S/ 835 a S/ 27,345.56 en laptops, de S/ 79.90 a S/ 8,999 en celulares y de S/ 283.90 a S/ 9,999 en televisores.

El diccionario de datos final, con la descripción, el tipo, el rango, la unidad y las limitaciones de cada variable, se entrega en `docs/data_dictionary_final.pdf`.

== Limitaciones

+ Una sola captura y una sola tienda. El dataset es como una foto de Falabella Perú en un momento, no nos permite medir la evolución de precios ni comparar con otros retailers.
+ La muestra no es aleatoria. El scraper recorrió las primeras 20 páginas del listado de cada categoría en el orden que define la tienda.
+ Hay pocos televisores. Tras retirar accesorios quedan 167, por lo que segmentar finamente por marca o gama dentro de televisores dará celdas pequeñas.
+ El filtro de accesorios está basado en reglas. Se validó a mano sobre las filas de borde, pero no es infalible; las 386 filas retiradas se conservan aparte con su motivo.
+ Publicaciones con mismo producto y vendedor. 10 grupos (22 filas) con precio distinto se conservaron ya que pueden ser variantes o errores de captura y el CSV no permite distinguirlos.
+ `list_price` imputado en 36 filas con el supuesto de que "sin precio tachado" significa "sin descuento", tomado del código del spider y no de una verificación en la tienda.
+ Errores de digitación en el precio de lista. Una laptop tiene `list_price` de S/ 79,999 contra un precio internet de S/ 5,699; esto no se corrige en limpieza y se audita en el análisis de descuentos.
+ `GENERICO` y vendedores. 11 filas quedan como `GENERICO` (o sea, sin marca declarada) y se conservaron sin imputar la marca; tampoco se verificó si razones sociales distintas pertenecen al mismo dueño.

= Propuesta de Pipeline

El pipeline es la conclusión de todas las etapas del proyecto, por lo tanto consta de la ejecución de cada una de dichas partes.

El pipeline propuesto está dividido en 5 partes:

/ Scraper:
  Se ejecuta el scraper `falabella`, el cual obtiene la data cruda `falabella_raw.csv`, almacenada en la carpeta `data/raw/`.

/ Almacenamiento:
  El scraper `scrapy` guarda los datos en una base de datos PostgreSQL mediante la plataforma Supabase.

/ Limpieza:
  Se ejecutan las funciones de limpieza (`pipeline/cleaning.py`), y la data `falabella_cleaned.csv` es almacenada en la carpeta `data/clean/`.

/ Preprocesamiento e ingeniería de características:
  Se ejecutan las funciones de ingeniería de características (`pipeline/processing_data.py`), y la data `falabella_processed.csv` es almacenada en `data/processed/`.

/ Creación de reporte:
  El informe y las tablas de resultados se generan mediante la data final `falabella_processed.csv`.

= Preprocesamiento de Datos

El punto de partida es el CSV que produjo el spider (`data/raw/falabella_raw.csv`): 1,680 filas y 6 columnas (`product`, `brand`, `category`, `seller`, `list_price`, `internet_price`). El archivo crudo no se modifica; el tratamiento se ejecuta en `pipeline/cleaning.py`, se documenta paso a paso en el notebook `02_limpieza_preprocesamiento.ipynb` y deja dos salidas: `falabella_cleaned.csv` (1,037 filas y 8 columnas) y `falabella_removed_rows.csv` (las filas retiradas con su motivo, para auditoría).

En cuanto a valores faltantes, únicamente `list_price` está vacío en 74 filas del crudo (4.4 %, cumpliendo el límite máximo del 10 % exigido): falta cuando el producto no tiene precio tachado, es decir, no tiene descuento. Las otras 5 columnas tienen 0 % de nulos. El resto de los problemas son inconsistencias: filas repetidas, texto sin normalizar y productos que no son el equipo de su categoría.

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: (2.4fr, 3fr, 4.2fr, 2fr),
        align: (left, left, left, left),
        [*Problema*], [*Decisión*], [*Justificación*], [*Filas afectadas*],
        [Filas idénticas en las 6 columnas], [Eliminar duplicados exactos y conservar la primera aparición], [El CSV no guarda URL ni fecha; una repetición equivale a la misma publicación leída dos veces y sesga conteos y promedios.], [256 (15.2 % de 1,680)],
        [Texto con espacios duros, comillas y guiones tipográficos, puntos finales y espacios repetidos], [Normalizar `product`, `brand` y `seller` a mayúsculas ASCII, sin espacios repetidos ni punto final], [Evita que `OH SHOP` y `OH SHOP.` cuenten como dos vendedores y permite deduplicar de nuevo (apareció 1 duplicado oculto).], [286 cambian de texto; 1 duplicado nuevo],
        [Accesorios, repuestos y otros equipos en las secciones de televisores, celulares y laptops], [Retirar lo que no es el equipo, con reglas por categoría sobre el inicio del nombre; guardar las filas retiradas con su motivo], [Sin el filtro, la mediana de precio de televisores es S/ 99 (cables y controles). Mirar el inicio del nombre evita falsos positivos como "TELEVISOR … CON CONTROL DE VOZ".], [386 (27.1 % de 1,423)],
        [Etiqueta `GENERICO` en `brand`], [Conservar `GENERICO` como categoría explícita (la marca ya viene en mayúsculas)], [Asignar una marca a un producto sin marca sería inventar un dato; borrarlos quitaría productos válidos. Quien analice marcas decide si excluye `GENERICO`.], [`GENERICO` baja de 238 a 11 al retirar accesorios],
        [`list_price` vacío], [Imputar con `internet_price` y marcar con `list_price_imputed`], [El spider deja el campo vacío cuando no hay precio tachado, es decir, sin descuento. En las 1,001 filas con precio de lista el precio internet es siempre menor.], [36 (3.5 % de 1,037)],
        [Precios extremos], [Marcar con `is_price_outlier` (IQR 1.5 sobre `internet_price`, dentro de cada categoría y después de retirar accesorios); no eliminar], [Son productos reales de gama alta (laptops de hasta S/ 27,346) y el grupo acordó no borrar datos por precio o descuento alto sin una fuente externa.], [53 marcadas (5.1 %)],
      )
    ],
    caption: [Problemas encontrados, decisiones y filas afectadas en el preprocesamiento],
  )
]

== Limpieza

*Duplicados:* Se eliminaron 256 filas idénticas (15.2 %), de forma desigual entre categorías, siendo 22.3 % en laptops, 16.8 % en celulares y 6.6 % en televisores. Tras normalizar el texto apareció una fila repetida más (pasando de 1,424 a 1,423 filas únicas). Además, existen 10 grupos (22 filas) con el mismo producto, vendedor y categoría pero con precio distinto (en 9 grupos cambia el precio internet y en 1 solo el precio de lista), los cuales se conservaron porque pueden ser variantes de una misma publicación (por ejemplo, colores) y las columnas disponibles no permiten distinguirlas de un error de captura.

*Accesorios:* Tiene un efecto muy grande: en televisores se retiraron 356 de 523 filas únicas (68.1 %), siendo controles remotos y fundas (132), cables y adaptadores (81), soportes y racks (65), antenas y decodificadores (25), reproductores y dispositivos de streaming (21), proyectores (18) y otros productos (14). En celulares salieron 29 filas (6.2 %), casi todas repuestos de cámara (25), y en laptops un monitor portátil. La cifra de televisores supera la estimación inicial del grupo (44 %) porque aquí también salen proyectores y dispositivos que no son televisores. La regla se validó revisando a mano los productos más baratos que se conservan y los productos caros que se retiran. Estos últimos son 4 proyectores y una pizarra digital interactiva, ninguno siendo un televisor de consumo.

#align(center)[
  #figure(
    image("img/pre_01_accesorios_antes_despues.png", width: 100%),
    caption: [Filas por categoría en cada etapa (izquierda) y precio internet antes y después de retirar accesorios (derecha, en escala logarítmica)],
  )
]

La mediana de precio de televisores pasa de S/ 99 a S/ 1,729, mientras que en celulares (S/ 1,330 a S/ 1,399) y laptops (S/ 3,719 a S/ 3,739) casi no cambia. Sin este filtro, cualquier comparación de precios entre categorías habría sido engañosa.

*Valores faltantes:* La variable `list_price` está vacía en 36 de las 1,037 filas que quedan (3.5 %), siendo 16 en laptops, 15 en celulares y 5 en televisores. Según el código del spider, el campo proviene del precio tachado de la tarjeta, de modo que un vacío significa ausencia de rebaja. Los datos lo respaldan ya que en las 1,001 filas con precio de lista, el precio internet nunca iguala ni supera al de lista. Por eso se imputó con `internet_price`, que mantiene coherente el cálculo de descuento (cero para esos productos) y se dejó la bandera `list_price_imputed` para poder revertir el supuesto. Tras esta imputación, el dataset limpio queda con *0 % de valores nulos* en todas sus variables.

*Marcas:* La marca ya viene en mayúsculas desde el scraper, igualmente se normaliza. `GENERICO`, la etiqueta que usa la tienda cuando el vendedor no declara marca, tenía 238 filas en el crudo; la mayoría eran accesorios y al retirarlos quedan 11 (8 en celulares y 3 en televisores). Se conservó como categoría explícita en lugar de imputar una marca o borrar esas filas.

*Valores atípicos:* Se aplicó la regla del IQR (factor 1.5) sobre `internet_price`, dentro de cada categoría y después de retirar los accesorios; antes de ese paso los cables de S/ 10 habrían deformado los cuartiles de televisores. Un precio es atípico si queda fuera de $[\text{Q1} - 1.5\cdot\text{IQR}, \text{Q3} + 1.5\cdot\text{IQR}]$; el límite superior es S/ 9,959 en laptops, S/ 5,899 en celulares y S/ 4,050 en televisores. Quedaron 53 filas marcadas (15, 20 y 18 respectivamente), todas de precio alto. Como la distribución tiene cola a la derecha, el IQR marca la gama más alta de cada categoría y no los precios bajos. Son productos reales (por ejemplo, una laptop de S/ 27,346) y no errores de captura, por lo que se conservaron marcadas y, en caso de querer o necesitar excluirlas, se filtra con `is_price_outlier == 0`.

#align(center)[
  #figure(
    image("img/pre_02_outliers_precio.png", width: 100%),
    caption: [Precios atípicos marcados dentro de cada categoría (puntos rojos). El eje vertical es logarítmico solo para poder ver todos los precios; la regla del IQR se calculó sobre soles.],
  )
]

*Descuentos inflados:* Al revisar `list_price` contra `internet_price` apareció una fila con un descuento implícito mayor a 70 %, una laptop con precio de lista de S/ 79,999 y precio internet de S/ 5,699, probablemente un error de digitación del vendedor. No se corrige en esta etapa y se audita en el análisis de descuentos.

== Integración

El proyecto trabaja con una sola fuente, el CSV del spider de Falabella, de modo que no hay tablas que unir ni claves que cruzar. La integración se limitó a verificar el esquema (6 columnas esperadas, tres categorías y precios positivos) mediante aserciones en el notebook. No se integró la base de Supabase del scraper diario ni una segunda tienda (el spider de Ripley se eliminó en la Parte I); por eso el dataset es una captura en un solo momento y no permite analizar evolución de precios.

== Reducción

La reducción fue de filas: se pasó de 1,680 a 1,037 (61.7 % conservado), con cada fila retirada justificada y auditada. No se eliminaron columnas del CSV crudo: las seis originales son necesarias para los objetivos y con solo dos variables numéricas de precio no hay base para una reducción de dimensionalidad como PCA. Tampoco se aplicó muestreo porque el dataset ya es pequeño.

== Transformación

Se fijaron los tipos de dato (`category` como categórica, los dos precios como decimales `float64` y las banderas como enteros 0/1) y se normalizó el texto. No se escaló ni codificó ninguna variable porque esas operaciones corresponden al modelado, que esta parte no incluye. Los precios se conservan en soles sin transformar. Las variables derivadas (descuento, gama de precio, tipo de vendedor, banderas del nombre y pulgadas) se construyen en la etapa de feature engineering.

#align(center)[
  #figure(
    image("img/pre_03_filas_afectadas_por_paso.png", width: 90%),
    caption: [Filas afectadas por cada paso del preprocesamiento],
  )
]

= Feature Engineering

La etapa de ingeniería de características se implementa en `pipeline/processing_data.py` y se documenta en el notebook `03_feature_engineering.ipynb`. Recibe como entrada el dataset limpio (`data/clean/falabella_cleaned.csv`, 1,037 registros y 8 columnas) y genera el dataset procesado (`data/processed/falabella_processed.csv`, 1,037 registros y 16 columnas), creando *8 nuevas variables* sin introducir ningún valor nulo (0 % de NA en las 16 columnas).

#align(center)[
  #figure(
    text(size: 9pt)[
      #table(
        columns: (2.1fr, 2.8fr, 3.8fr, 1.5fr),
        align: (left, left, left, center),
        [*Variable creada*], [*Fórmula o regla de construcción*], [*Justificación analítica*], [*Objetivo que responde*],
        [`has_discount` \ _(Binario 0/1)_], [$1$ si `list_price` $>$ `internet_price`; $0$ si son iguales.], [Separa las publicaciones con oferta activa (96.5 %) de aquellas sin rebaja (3.5 %).], [Objetivo 1],
        [`discount_amount` \ _(Numérico, S/)_], [`list_price` $-$ `internet_price`], [Mide el ahorro nominal en soles para comparar el beneficio monetario real entre gamas.], [Objetivo 1],
        [`discount_pct` \ _(Numérico, %)_], [$(\text{list\_price} - \text{internet\_price}) / \text{list\_price} \times 100$], [Estandariza la magnitud de la rebaja en porcentaje (0 % a 92.88 %) para comparar categorías de distinto valor.], [Objetivos 1 y 2],
        [`prices_category` \ _(`low`, `mid`, `high`)_], [Terciles empíricos ($P_{33.3}$ y $P_{66.7}$) de `internet_price` calculados dentro de cada `category`.], [Evita mezclar escalas de precios entre categorías y permite estratificar la competencia por nivel de gama.], [Objetivos 1, 2 y 3],
        [`seller_type` \ _(Categórico)_], [`FALABELLA_DIRECT` si `seller` $\in$ {`FALABELLA`, `TOTTUS`, `SODIMAC`}; si no, `MARKETPLACE_SELLER`.], [Agrupa las ventas directas del grupo retail (14.9 %) frente a los 183 vendedores externos (85.1 %).], [Objetivo 2],
        [`is_refurbished` \ _(Binario 0/1)_], [Regex en `product`: `REACONDICIONADO`, `OPEN BOX`, `REFURBISHED`, `SEMI NUEVO`.], [Aísla equipos de segunda selección (17.4 % en celulares, sobre todo iPhones) que distorsionarían el piso de precios.], [Objetivos 1 y 3],
        [`is_bundle` \ _(Binario 0/1)_], [Regex en `product`: `COMBO`, `PACK`, `KIT`, `REGALO` o `+ ACCESORIO` (excluyendo `8+256GB`, `FHD+`, `SIM+ESIM`).], [Distingue paquetes promocionales con accesorios incluidos (9.4 % del total) de los equipos individuales.], [Objetivos 1 y 3],
        [`inches` \ _(Numérico, pulg)_], [Regex de diagonal de pantalla en `tvs` (15" a 100"); $0$ = no aplica en `phones` y `laptops`.], [Alcanza 100 % de extracción en los 167 televisores para evaluar el tamaño de panel como driver de precio sin generar NAs.], [Objetivo 3],
      )
    ],
    caption: [Variables construidas en la etapa de Feature Engineering],
  )
]

== Segmentación de Gamas por Terciles Intracategoría (`prices_category`)

Dado que la distribución de precios difiere drásticamente entre laptops, celulares y televisores, los puntos de corte de los terciles empíricos ($P_{33.3}$ y $P_{66.7}$) se calcularon de forma independiente dentro de cada categoría limpia y se contrastaron con los rangos comerciales del mercado retail peruano:

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: (auto, center, center, center, center, 1fr),
        align: (left, center, center, center, center, left),
        [*Categoría*], [*Corte `low` ($\le P_{33.3}$)*], [*Corte `mid` ($P_{33.3} - P_{66.7}$)*], [*Corte `high` ($> P_{66.7}$)*], [*Registros (`low`/`mid`/`high`)*], [*Correspondencia comercial en el retail tecnológico*],
        [`laptops`], [$\le$ S/ 3,199], [S/ 3,200 – S/ 4,699], [$>$ S/ 4,699], [155 / 136 / 142], [Entrada: ofimática Core i3/i5 y Ryzen 3/5; Media: corporativas y gamer RTX 3050/4050; Alta: gamer RTX 4060/5060+ y MacBooks.],
        [`phones`], [$\le$ S/ 892], [S/ 893 – S/ 2,126], [$>$ S/ 2,126], [146 / 145 / 146], [Entrada: gama básica 4G; Media: gama media 5G y reacondicionados de entrada; Alta: flagships Apple, Galaxy S y Xiaomi Ultra.],
        [`tvs`], [$\le$ S/ 1,489], [S/ 1,490 – S/ 1,999], [$>$ S/ 1,999], [57 / 55 / 55], [Entrada: LED/QLED de 32" a 50"; Media: paneles 4K UHD/QLED de 55" a 65"; Alta: OLED, MiniLED y formatos de 75" a 100".],
      )
    ],
    caption: [Umbrales de terciles empíricos por categoría y validación con segmentos comerciales],
  )
]

#align(center)[
  #figure(
    image("img/fe_01_gamas_terciles.png", width: 100%),
    caption: [Segmentación de gamas de precio (`low`, `mid`, `high`) por terciles empíricos dentro de cada categoría],
  )
]

== Clasificación de Vendedores y Extracción de Banderas por Expresiones Regulares

En la variable `seller_type`, las ventas directas del grupo (`FALABELLA_DIRECT`: Falabella con 113 publicaciones, Tottus con 32 y Sodimac con 10) suman 155 registros (14.9 %), con una participación mucho mayor en televisores (35.3 %) que en celulares (13.0 %) y laptops (9.0 %).

Por su parte, las expresiones regulares aplicadas sobre `product` identificaron 93 equipos reacondicionados (`is_refurbished == 1`), concentrados en celulares (76 filas, 17.4 %) y laptops corporativas ThinkPad (17 filas, 3.9 %), sin presencia en televisores. Asimismo, se detectaron 97 paquetes promocionales (`is_bundle == 1`: 52 en celulares, 25 en televisores y 20 en laptops), evitando falsos positivos en nomenclaturas técnicas como `8+256GB` o `FHD+`. Finalmente, en `tvs` se extrajo el tamaño en pulgadas (`inches`) en los 167 televisores (100 % de efectividad), predominando los formatos de 65" (53 unidades), 55" (30 unidades), 75" (19 unidades), 43" (16 unidades) y 32" (15 unidades).

#align(center)[
  #figure(
    image("img/fe_02_banderas_y_vendedores.png", width: 100%),
    caption: [Proporción de tipos de vendedor, banderas comerciales (`is_refurbished`, `is_bundle`) y distribución de pulgadas en televisores],
  )
]

= Análisis y Visualización de datos

== Concentración de Precios y Dispersión Relativa por Categoría (Objetivo 1)

El análisis exploratorio de precios y descuentos se desarrolla en el notebook `04_analisis_descuentos_categorias.ipynb`. Debido a la asimetría positiva de los precios, la dispersión dentro de cada categoría se cuantifica mediante el Rango Intercuartílico ($\text{IQR} = Q_3 - Q_1$) y el *IQR Relativo* ($\text{IQR} / \text{Mediana} \times 100$):

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: 8,
        align: (left, center, center, center, center, center, center, center),
        [*Categoría*], [*N*], [*Q1 (S/)*], [*Mediana (S/)*], [*Q3 (S/)*], [*IQR (S/)*], [*IQR Relativo (%)*], [*Mediana Desc. (%)*],
        [`laptops`], [433], [2,859.00], [3,739.00], [5,699.00], [2,840.00], [76.0 %], [19.12 %],
        [`phones`], [437], [699.00], [1,399.00], [2,779.00], [2,080.00], [*148.7 %*], [24.75 %],
        [`tvs`], [167], [1,299.00], [1,729.00], [2,399.45], [1,100.45], [*63.6 %*], [*34.80 %*],
      )
    ],
    caption: [Estadísticos robustos de precio internet y dispersión relativa por categoría],
  )
]

Los resultados revelan un contraste estructural entre las tres líneas tecnológicas:
- *Los celulares más que duplican en dispersión relativa a los televisores ($2.34\times$):* la categoría `phones` alcanza un IQR Relativo de *148.7 %* frente al *63.6 %* de `tvs` y el *76.0 %* de `laptops`.
- Como muestra el gráfico de violín, el catálogo de *televisores* presenta una silueta sumamente concentrada entre S/ 1,299 y S/ 2,399 debido a la estandarización de costos de los paneles LED/QLED de 43" a 65". En cambio, los *celulares* exhiben una distribución alargada y multimodal que abarca desde teléfonos básicos de S/ 80 hasta flagships de S/ 8,999.

#align(center)[
  #figure(
    image("img/ana_01_violin_precios_categoria.png", width: 100%),
    caption: [Gráficos de violín del precio internet (izquierda, escala logarítmica) y del porcentaje de descuento (derecha) por categoría],
  )
]

== Magnitud de Descuentos según Nivel de Gama y Relación Precio–Descuento

Al cruzar las variables de descuento (`discount_pct` y `discount_amount`) con los tres niveles de gama (`low`, `mid`, `high`), se identifica un patrón sistemático en las tres categorías:

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: 7,
        align: (left, center, center, center, center, center, center),
        [*Categoría*], [*Gama*], [*N*], [*% con Desc.*], [*Mediana Precio (S/)*], [*Mediana Desc. (%)*], [*Mediana Ahorro (S/)*],
        [`laptops`], [`low`], [155], [95.5 %], [2,499.00], [*23.33 %*], [620.00],
        [`laptops`], [`mid`], [136], [99.3 %], [3,799.00], [18.74 %], [977.45],
        [`laptops`], [`high`], [142], [94.4 %], [6,599.00], [17.24 %], [*1,388.50*],
        [`phones`], [`low`], [146], [97.3 %], [519.50], [*29.39 %*], [200.00],
        [`phones`], [`mid`], [145], [97.9 %], [1,399.00], [24.22 %], [420.00],
        [`phones`], [`high`], [146], [94.5 %], [3,379.00], [23.58 %], [*965.00*],
        [`tvs`], [`low`], [57], [100.0 %], [1,099.00], [*37.02 %*], [580.00],
        [`tvs`], [`mid`], [55], [90.9 %], [1,729.00], [34.80 %], [900.00],
        [`tvs`], [`high`], [55], [100.0 %], [3,299.00], [31.25 %], [*1,700.00*],
      )
    ],
    caption: [Comparación del porcentaje de descuento y ahorro en soles por categoría y gama],
  )
]

#align(center)[
  #figure(
    image("img/ana_02_boxplots_descuento_gama.png", width: 100%),
    caption: [Boxplots del porcentaje de descuento (izquierda) y del ahorro en soles (derecha) por categoría y gama de precio],
  )
]

En las tres categorías, la *rebaja porcentual mediana es mayor en la gama baja (`low`)* y disminuye hacia la gama alta (`high`): en televisores baja de 37.02 % a 31.25 %, en celulares de 29.39 % a 23.58 % y en laptops de 23.33 % a 17.24 %. Esta relación inversa se confirma mediante las pruebas de correlación entre `internet_price` y `discount_pct`:
- En *celulares (`phones`)* existe una correlación negativa estadísticamente significativa ($r = -0.274$, $\rho = -0.258$, $p < 0.0001$): a mayor precio del smartphone, menor es el porcentaje de descuento otorgado. Las marcas cuidan el valor percibido de sus equipos *flagship*, mientras que la gama de entrada y media compite con descuentos porcentuales agresivos.
- En *televisores* ($r = -0.176$, $\rho = -0.185$, $p = 0.023$) y *laptops* ($r = -0.129$, $\rho = -0.157$, $p = 0.007$) la tendencia también es negativa aunque más moderada.

#align(center)[
  #figure(
    image("img/ana_03_scatter_precio_descuento.png", width: 100%),
    caption: [Diagramas de dispersión entre precio internet y porcentaje de descuento con rectas de regresión por categoría],
  )
]

== Veracidad de Descuentos, Reacondicionados y Combos Promocionales

El cruce con las banderas extraídas en Feature Engineering permite explicar las anomalías del catálogo:
1. *Descuentos inflados o artificiales ($\ge 60\\%$):* Se identificaron 16 publicaciones con descuentos declarados de 60 % o más, de las cuales 15 pertenecen a vendedores externos (`MARKETPLACE_SELLER`). El caso más extremo supera el 70 %: la laptop `LENOVO LOQ 15AHP10 RYZEN 7 RTX 5050` publicada por `IVANCE ELECTRONIC ONLINE` declara un `list_price` de *S/ 79,999* frente a un `internet_price` de *S/ 5,699* (*92.88 %* de descuento), evidente error de digitación del vendedor (S/ 79,999 en vez de S/ 7,999, con lo que el descuento real sería 28.8 %). En televisores y celulares básicos, sellers externos como `ELECTROHOGAR` y `VICTORIA ILIMITADA` fijan precios de lista muy por encima del mercado para generar un efecto de anclaje publicitario.
2. *Efecto de equipos reacondicionados (`is_refurbished`):* De los 76 celulares reacondicionados del dataset, *69 son iPhones de Apple* (el 58.5 % de todas las publicaciones de Apple en celulares). Mientras que un iPhone nuevo tiene un precio mediano de *S/ 4,499*, un iPhone reacondicionado tiene una mediana de *S/ 1,739* ($-61.3\\%$). Aislar esta variable evita confundir equipos usados/reacondicionados por terceros con descuentos sobre equipos nuevos.
3. *Combos promocionales (`is_bundle`):* Los 97 combos identificados presentan descuentos porcentuales medianos ligeramente menores que los productos individuales (20.05 % vs. 25.01 % en celulares; 16.88 % vs. 19.30 % en laptops), dado que el incentivo comercial se traslada al accesorio incluido (`+ AUDÍFONOS`, `+ WATCH`, `+ MOCHILA` o `+ BARRA DE SONIDO`).

#align(center)[
  #figure(
    image("img/ana_04_anomalias_reacondicionados_combos.png", width: 100%),
    caption: [Impacto de la condición reacondicionada en celulares Apple vs. otras marcas (izquierda) y comparación de descuentos entre equipos individuales y combos (derecha)],
  )
]

= Insights encontrados

+ *Concentración vs. dispersión relativa entre categorías:* Los celulares presentan una dispersión relativa ($\text{IQR}/\text{Mediana} = 148.7\\%$) que más que duplica la de los televisores ($63.6\\%$), reflejando la estandarización de paneles en TVs frente a la fuerte polarización entre gama básica y flagships en smartphones.
+ *Rigidez porcentual en gama alta vs. agresividad en gama de entrada:* En las tres categorías el porcentaje mediano de descuento cae conforme sube la gama (`low` $>$ `mid` $>$ `high`), destacando la correlación negativa en celulares ($r = -0.27$, $p < 0.0001$). Sin embargo, para el comprador de gama alta el ahorro nominal mediano sigue siendo elevado (S/ 1,700 en TVs y S/ 1,388.50 en laptops).
+ *Anclaje publicitario y reacondicionados en el Marketplace:* Los descuentos superiores al 60 % (y el caso extremo de 92.88 % por error de digitación en `list_price` = S/ 79,999) provienen casi exclusivamente de sellers externos, mientras que el 58.5 % de la oferta de iPhones en la plataforma corresponde a equipos reacondicionados con un precio mediano 61.3 % inferior al de las unidades nuevas.

= Documentación y Reproducibilidad en Github

El repositorio del proyecto está ubicado en el enlace:

#align(center)[
  #link("https://github.com/gmborjasb/SpiderMarketplace")
]

La estructura del proyecto es la siguiente:

#text(size: 9pt)[
  ```md
   SpiderMarketplace/
      ├── Marketplace/   # Ingestión: Código del web scraper desarrollado con Scrapy.
      ├── pipeline/      # Automatización: Scripts de ejecución del scraper, limpieza, features y reporte.
      ├── data/          # Almacenamiento: Datasets divididos por etapas (raw, clean, processed, analysis).
      ├── notebooks/     # Analítica: Jupyter Notebooks con validación, limpieza, features y análisis.
      ├── docs/          # Documentación: Diccionarios de datos, recursos gráficos, PPT e informes en Typst.
      ├── pyproject.toml # Configuración del entorno y gestión de dependencias con uv.
      └── README.md      # Descripción general e instrucciones de uso del repositorio.
  ```
]

Para reproducir todo el proyecto es necesario:

1. Instalar las dependencias:
  #align(center)[`uv sync`]

2. Ejecutar el pipeline:
  #align(center)[`uv run python pipeline/main.py`]
