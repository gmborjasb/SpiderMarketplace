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
      [Alondra Obregón], [Objetivos, Dataset Preliminar, Viabilida],
      [Axel Portal], [Feature engineering, análisis y visualización, PPT],
      [Danna Gala], [Preprocesamiento, Dataset y diccionario final],
      [Gerald], [Contexto y objetivos actualizados, Propuesta de pipeline, Documentación en GitHub],
    ),
    caption: [Distribución de responsabilidades],
  )
]

= Contexto actualizado

El crecimiento del comercio electrónico ha incrementado la cantidad de productos y vendedores disponibles en plataformas de marketplace, generando así una mayor variedad de alternativas para los consumidores. En plataformas como Falabella Perú, un mismo tipo de producto puede encontrarse asociado a diferentes marcas, precios, descuentos y vendedores, esto incluyendo tanto la venta directa de la plataforma como ofertas realizadas por terceros.

Esta variedad dificulta poder realizar comparaciones directas entre productos y vendedores, especialmente en categorías tecnológicas con alto valor como lo podrían ser laptops, celulares y televisores. Un producto puede presentar al mismo tiempo un precio de lista y un precio de internet, esto mientras que otros productos de características similares pueden ser comercializados por distintos vendedores a precios diferentes. Por ello, observar únicamente el precio de un producto nos permitiría identificar con claridad cómo se distribuyen los precios, qué magnitud tienen los descuentos o cómo varían estas características entre marcas y tipos de vendedores.

Después de obtener la data mediante web scraping, se observa que los datos no necesariamente presentan el comportamiento esperado:

- Existen productos con precios muy bajos($<"S/."100$), estos productos suelen ser accesorios(e.g. soportes de pared para televisores clasificados en la categoría de tv) de una misma categoría que son considerados por el marketplace.
- Duplicación de productos debido a la carga dinámica en el marketplace.
- Productos que no presentan (`list_price`), es decir solo tienen precio de venta en internet mas no un precio de lista.

= Objetivos actualizados

/ Objetivo General:

Analizar la estructura de precios, magnitud de descuentos y niveles de competencia entre las marcas de laptops, celulares y televisores en Falabella Perú, comparando las ventas directas con las de los vendedores del marketplace, considerando la heterogeneidad de gamas y marcas.

/ Objetivos Específicos:

- _Evaluar la magnitud, distribución y veracidad de los descuentos_:

  Cuantificar la brecha porcentual entre el precio de lista y precio por internet en las tres categorías tecnológicas, determinando qué líneas presentan rebajas más agresivas y cuáles mantienen precios de venta rígidos, contrastando con fuentes externas para observar la veracidad de dichos descuentos.

- _Contrastar la competitividad tarifaria entre tipos de vendedores_:

  Comparar las distribuciones de precios y la agresividad de ofertas por _Falabella_(y sus filiales) frente a los vendedores externos (sellers), estratificando al análisis por categoría de producto y nivel de gama, para verificar si los terceros representan una alternativa mas económica.

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
      [`category`], [La categoría del producto es teléfono, televisor o laptop.],
      [`seller`], [Nombre del vendedor del producto.],
      [`list_price`], [Precio regular sin descuento del producto, en soles.],
      [`internet_price`], [Precio con descuento, en soles.],
    ),
    caption: [Atributos del dataset preliminar],
  )
]

== Volumen y estructura

El dataset crudo obtenido por scraping de Falabella Perú, tiene 1,680 filas y 7 columnas (`product`, `brand`, `category`, `seller`, `list_price`, `internet_price` y `cmr_price`).

El dataset resultante del preprocesamiento (`falabella_cleaned.csv`, 113 KB) tiene 1,039 registros y 9 variables. Cada registro es una publicación de Falabella Perú. Conserva el 61.8 % de las 1,680 filas del CSV crudo y se reparte en 439 celulares, 433 laptops y 167 televisores. No tiene valores nulos, salvo `cmr_price` que queda vacío en 857 filas (82.5 %) porque la publicación no ofrece precio con tarjeta CMR.

#align(center)[
  #figure(
    table(
      columns: 3,
      align: (left, center, center),
      [*Indicador*], [*Antes (CSV crudo)*], [*Después (dataset final)*],
      [Registros], [1,680], [1,039],
      [Variables], [7], [9],
      [Celulares / laptops / televisores], [560 / 560 / 560], [439 / 433 / 167],
      [Filas duplicadas exactas], [254], [0],
      [Accesorios y otros productos], [386 (entre las filas únicas)], [0],
      [`list_price` vacío], [74 (4.4 %)], [0],
      [`cmr_price` vacío (sin precio CMR)], [1,453 (86.5 %)], [857 (82.5 %)],
    ),
    caption: [Volumen del dataset antes y después del preprocesamiento],
  )
]

#align(center)[
  #figure(
    text(size: 10pt)[
      #table(
        columns: (auto, auto, 1fr),
        align: (left, left, left),
        [*Variable*], [*Tipo*], [*Rango o valores observados*],
        [`product`], [Texto], [931 nombres distintos, hasta 131 caracteres],
        [`brand`], [Categórico], [40 marcas; más frecuentes: Lenovo (154), Samsung (134), Apple (122), Asus (109), HP (96); 11 filas `GENERICO`],
        [`category`], [Categórico], [`laptops` (433), `phones` (439), `tvs` (167)],
        [`seller`], [Categórico], [186 vendedores; 59 aparecen una sola vez; Falabella, Tottus y Sodimac suman 155 filas (14.9 %)],
        [`list_price`], [Numérico (S/)], [S/ 159 a S/ 79,999],
        [`internet_price`], [Numérico (S/)], [S/ 79.90 a S/ 27,345.56],
        [`cmr_price`], [Numérico (S/)], [S/ 299 a S/ 13,499; vacío en 857 filas (82.5 %)],
        [`list_price_imputed`], [Categórico (binario)], [0 = original, 1 = imputado (36 filas, 3.5 %)],
        [`is_price_outlier`], [Categórico (binario)], [0 = no atípico, 1 = atípico (53 filas, 5.1 %)],
      )
    ],
    caption: [Variables del dataset final],
  )
]

Los precios se expresan en soles. La mediana de `internet_price` es S/ 3,739 en laptops, S/ 1,729 en televisores y S/ 1,399 en celulares. Los rangos por categoría van de S/ 835 a S/ 27,346 en laptops, de S/ 80 a S/ 8,999 en celulares y de S/ 284 a S/ 9,999 en televisores. El precio CMR existe en el 13.9 % de las laptops, el 18.9 % de los celulares y el 23.4 % de los televisores.

El diccionario de datos final, con la descripción, el tipo, el rango, la unidad y las limitaciones de cada variable, se entrega en `docs/data_dictionary_final.pdf`.

== Limitaciones

+ Una sola captura y una sola tienda. El dataset es como una foto de Falabella Perú en un momento, no nos permite medir la evolución de precios ni comparar con otros retailers.
+ La muestra no es aleatoria. El scraper recorrió las primeras 20 páginas del listado de cada categoría en el orden que define la tienda.
+ Hay pocos televisores. Tras retirar accesorios quedan 167, por lo que segmentar finamente por marca o gama dentro de televisores dará celdas pequeñas.
+ El filtro de accesorios está basado en reglas. Se validó a mano sobre las filas de borde, pero no es infalible; las 386 filas retiradas se conservan aparte con su motivo.
+ Publicaciones con mismo producto y vendedor. 12 grupos (26 filas) con precio distinto se conservaron ya que pueden ser variantes o errores de captura y el CSV no permite distinguirlos.
+ `list_price` imputado en 36 filas con el supuesto de que "sin precio tachado" significa "sin descuento", tomado del código del spider y no de una verificación en la tienda.
+ `cmr_price` vacío en 857 filas porque no hay precio CMR, no se imputa. El ahorro con tarjeta solo puede calcularse con las filas que sí lo tienen.
+ Errores de digitación en el precio de lista. Una laptop tiene `list_price` de S/ 79,999 contra un precio internet de S/ 5,699, esto no se corrige y se reporta para el análisis de descuentos.
+ `GENERICO` y vendedores. 11 filas quedan como `GENERICO` (o sea, sin marca declarada) y se conservaron sin imputar la marca; tampoco se verificó si razones sociales distintas pertenecen al mismo dueño.

= Propuesta de Pipeline

El pipeline es la conclusión de todas las etapas del proyecto, por lo tanto consta de la ejecucion de cada una de dichas partes.

El pipeline propuesto está dividido en 5 partes:

/ Scraper:
  Se ejecuta el scraper `falabella`, el cual obtiene la data cruda `falabella_raw.csv`, este es almacenado en la carpeta `data/pipeline/`

/ Almacenamiento:
  El scraper `scrapy`, guarda los datos en una base de datos postgresSQL mediante la plataforma Supabase.

/ Limpieza:
  Se ejecutan las funciones de limpieza, la data `falabella_cleaned.csv` es almacenada en la carpeta `data/pipeline`.

/ Preprocesamiento e ingeniería de características:
  Se ejecutan las funciones de preprocesamiento e ingeniería de características, la data `falabella_processed.csv` es almacenada en `data/pipeline`.

/ Creación de reporte:

  El informe es creado mediante la data final `falabella_processed.csv`, dicho reporte contiene los hallazgos del informe.
// Formato de infomre aun por definir:
// 1. Estatico: pdf
// 2. Dinamico: html - web

= Preprocesamiento de Datos

El punto de partida es el CSV que produjo el spider, entregado tal como salió del scraping (`falabella_raw.csv`): 1,680 filas y 7 columnas (`product`, `brand`, `category`, `seller`, `list_price`, `internet_price`, `cmr_price`). El archivo crudo no se modifica, el tratamiento se ejecuta en `pipeline/cleaning.py`, se documenta paso a paso en el notebook `02_limpieza_preprocesamiento.ipynb` y deja dos salidas: `falabella_cleaned.csv` (1,039 filas) y `falabella_removed_rows.csv` (las filas retiradas con su motivo, para auditoría).

Hay dos columnas con valores vacíos y significan cosas distintas. `list_price` está vacío en 74 filas (4.4 %): falta cuando el producto no tiene precio tachado, o sea, no tiene descuento. También `cmr_price` está vacío en 1,453 filas (86.5 %): el spider solo lo guarda cuando la publicación ofrece precio con tarjeta CMR, así que un vacío no es un dato perdido. El resto de los problemas son inconsistencias, por ejemplo, filas repetidas, texto sin normalizar y productos que no son el equipo de su categoría.

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: (2.4fr, 3fr, 4.2fr, 2fr),
        align: (left, left, left, left),
        [*Problema*], [*Decisión*], [*Justificación*], [*Filas afectadas*],
        [Filas idénticas en las 7 columnas], [Eliminar duplicados exactos y conservar la primera aparición], [El CSV no guarda URL ni fecha; una repetición equivale a la misma publicación leída dos veces y sesga conteos y promedios.], [254 (15.1 % de 1,680)],
        [Texto con espacios duros, comillas y guiones tipográficos, puntos finales y espacios repetidos], [Normalizar `product`, `brand` y `seller` a mayúsculas ASCII, sin espacios repetidos ni punto final], [Evita que `OH SHOP` y `OH SHOP.` cuenten como dos vendedores y permite deduplicar de nuevo (apareció 1 duplicado oculto).], [287 cambian de texto; 1 duplicado nuevo],
        [Accesorios, repuestos y otros equipos en las secciones de televisores, celulares y laptops], [Retirar lo que no es el equipo, con reglas por categoría sobre el inicio del nombre; guardar las filas retiradas con su motivo], [Sin el filtro, la mediana de precio de televisores es S/ 99 (cables y controles). Mirar el inicio del nombre evita falsos positivos como "TELEVISOR … CON CONTROL DE VOZ".], [386 (27.1 % de 1,425)],
        [Etiqueta `GENERICO` en `brand`], [Conservar `GENERICO` como categoría explícita (la marca ya viene en mayúsculas)], [Asignar una marca a un producto sin marca sería inventar un dato; borrarlos quitaría productos válidos. Quien analice marcas decide si excluye `GENERICO`.], [`GENERICO` baja de 238 a 11 al retirar accesorios],
        [`list_price` vacío], [Imputar con `internet_price` y marcar con `list_price_imputed`], [El spider deja el campo vacío cuando no hay precio tachado, es decir, sin descuento. En las 1,003 filas con precio de lista el precio internet es siempre menor.], [36 (3.5 % de 1,039)],
        [`cmr_price` vacío], [No imputar: el vacío significa que no hay precio CMR], [Rellenarlo inventaría un descuento con tarjeta que no existe. Cuando existe, siempre es menor al precio internet.], [857 vacíos (82.5 %) se mantienen],
        [Precios extremos], [Marcar con `is_price_outlier` (IQR 1.5 sobre `internet_price`, dentro de cada categoría y después de retirar accesorios); no eliminar], [Son productos reales de gama alta (laptops de hasta S/ 27,346) y el grupo acordó no borrar datos por precio o descuento alto sin una fuente externa.], [53 marcadas (5.1 %)],
      )
    ],
    caption: [Problemas encontrados, decisiones y filas afectadas en el preprocesamiento],
  )
]

== Limpieza

*Duplicados:* Se eliminaron 254 filas idénticas (15.1 %), de forma desigual entre categorías, siendo 22.3 % en laptops, 16.4 % en celulares y 6.6 % en televisores. Tras normalizar el texto apareció una fila repetida más. Además, existen 12 grupos (26 filas) con el mismo producto, vendedor y categoría pero con precio distinto (en 9 grupos cambia el precio internet y en 3 solo el precio de lista o el precio CMR), por lo cual se conservaron porque pueden ser variantes de una misma publicación (por ejemplo, colores) y las columnas disponibles no permiten distinguirlas de un error de captura.

*Accesorios:* Tiene un efecto muy grande: en televisores se retiraron 356 de 523 filas únicas (68.1 %), siendo controles remotos y fundas (132), cables y adaptadores (81), soportes y racks (65), antenas y decodificadores (25), reproductores y dispositivos de streaming (21), proyectores (18) y otros productos (14). En celulares salieron 29 filas (6.2 %), casi todas repuestos de cámara (25), y en laptops un monitor portátil. La cifra de televisores supera la estimación inicial del grupo (44 %) porque aquí también salen proyectores y dispositivos que no son televisores. La regla se validó revisando a mano los productos más baratos que se conservan y los productos caros que se retiran. Estos últimos son 4 proyectores y una pizarra digital interactiva, ninguno siendo un televisor de consumo.

#align(center)[
  #figure(
    image("img/pre_01_accesorios_antes_despues.png", width: 100%),
    caption: [Filas por categoría en cada etapa (izquierda) y precio internet antes y después de retirar accesorios (derecha, en escala logarítmica)],
  )
]

La mediana de precio de televisores pasa de S/ 99 a S/ 1,729, mientras que en celulares (S/ 1,339 a S/ 1,399) y laptops (S/ 3,719 a S/ 3,739) casi no cambia. Sin este filtro, cualquier comparación de precios entre categorías habría sido engañosa.

*Valores faltantes:* En la variable `list_price` está vacío en 36 de las 1,039 filas que quedan (3.5 %), siendo 16 en laptops, 15 en celulares y 5 en televisores. Según el código del spider, el campo proviene del precio tachado de la tarjeta, de modo que un vacío significa ausencia de rebaja. Los datos lo respaldan ya que en las 1,003 filas con precio de lista, el precio internet nunca iguala ni supera al de lista. Por eso se imputó con `internet_price`, que mantiene coherente el cálculo de descuento (cero para esos productos) y se dejó la bandera `list_price_imputed` para poder revertir el supuesto. Imputar con la media o la mediana habría inventado descuentos inexistentes. `cmr_price`, en cambio, no se imputa ya que su vacío (857 filas, 82.5 %) quiere decir que la publicación no tiene precio con tarjeta CMR, y cuando existe es siempre menor al precio internet. Lo tienen el 13.9 % de las laptops, el 18.9 % de los celulares y el 23.4 % de los televisores.

*Marcas:* La marca ya viene en mayúsculas desde el scraper, igualmente se normaliza. `GENERICO`, la etiqueta que usa la tienda cuando el vendedor no declara marca, tenía 238 filas en el crudo, la mayoría eran accesorios y al retirarlos quedan 11 (8 en celulares y 3 en televisores). Se conservó como categoría explícita en lugar de imputar una marca o borrar esas filas.

*Valores atípicos:* Se aplicó la regla del IQR (factor 1.5) sobre `internet_price`, dentro de cada categoría y después de retirar los accesorios, antes de ese paso los cables de S/ 10 habrían deformado los cuartiles de televisores. Un precio es atípico si queda fuera de [Q1 − 1.5·IQR, Q3 + 1.5·IQR]; el límite superior es S/ 9,959 en laptops, S/ 5,899 en celulares y S/ 4,050 en televisores. Quedaron 53 filas marcadas (15, 20 y 18 respectivamente), todas de precio alto. Como la distribución tiene cola a la derecha, el IQR marca la gama más alta de cada categoría y no los precios bajos. Son productos reales (por ejemplo, una laptop de S/ 27,346) y no errores de captura, por lo que se conservaron marcadas y, en caso de querer o necesitar excluirlas, se filtra con `is_price_outlier == 0`.

#align(center)[
  #figure(
    image("img/pre_02_outliers_precio.png", width: 100%),
    caption: [Precios atípicos marcados dentro de cada categoría (puntos rojos). El eje vertical es logarítmico solo para poder ver todos los precios; la regla del IQR se calculó sobre soles.],
  )
]

*Descuentos inflados:* Al revisar `list_price` contra `internet_price` apareció una fila con un descuento implícito mayor a 70 %, una laptop con precio de lista de S/ 79,999 y precio internet de S/ 5,699, probablemente un error de digitación del vendedor. No se corrige en esta etapa y solo se reporta para el análisis de descuentos.

== Integración

El proyecto trabaja con una sola fuente, el CSV del spider de Falabella, de modo que no hay tablas que unir ni claves que cruzar. La integración se limitó a verificar el esquema (columnas esperadas, tres categorías, precios positivos y precio CMR menor al precio internet) mediante aserciones en el notebook. No se integró la base de Supabase del scraper diario ni una segunda tienda (el spider de Ripley se eliminó en la Parte I); por eso el dataset es una captura en un solo momento y no permite analizar evolución de precios.

== Reducción

La reducción fue de filas: se pasó de 1,680 a 1,039 (61.8 % conservado), con cada fila retirada justificada y auditada. No se eliminaron columnas, las siete originales son necesarias para los objetivos y con solo tres variables numéricas no hay base para una reducción de dimensionalidad como PCA. Tampoco se aplicó muestreo porque el dataset ya es pequeño.

== Transformación

Se fijaron los tipos de dato (`category` como categórica, los tres precios como decimales y las banderas como enteros 0/1) y se normalizó el texto. No se escaló ni codificó ninguna variable porque esas operaciones corresponden al modelado, que esta parte no incluye. Los precios se conservan en soles sin transformar. Las variables derivadas (descuento, gama de precio, tipo de vendedor, banderas del nombre) se construyen en la etapa de feature engineering.

#align(center)[
  #figure(
    image("img/pre_03_filas_afectadas_por_paso.png", width: 90%),
    caption: [Filas afectadas por cada paso del preprocesamiento],
  )
]

= Feature Engineering

= Análisis y Visualización de datos

= Insights encontrados

+
+
+

= Documentación y Reproducibilidad en Github

El repositorio del proyecto, está ubicado en en enlace:

#align(center)[
  #link("https://github.com/gmborjasb/SpiderMarketplace")
]

La estructura del proyecto es la siguiente:

#text(size: 9pt)[
  ```md
   SpiderMarketplace/
      ├── Marketplace/   # Ingestión: Código del web scraper desarrollado con Scrapy.
      ├── pipeline/      # Automatización: Scripts de ejecución del scraper, limpieza, features y reporte.
      ├── data/          # Almacenamiento: Datasets divididos por etapas (raw, clean, final, pipeline).
      ├── notebooks/     # Analítica: Jupyter Notebooks con la limpieza, exploración, gráficos e insights.
      ├── docs/          # Documentación: Diccionario de datos, recursos gráficos e informes en Typst.
      ├── pyproject.toml # Configuración del entorno y gestión de dependencias con uv (reemplaza REQUIREMENTS.txt)
      └── README.md      # Descripción general e instrucciones de uso del repositorio.
  ```
]

Para reproducir todo el proyecto es necesario:

1. Instalar las dependencias:
  #align(center)[`uv sync`]

2. Ejecutar el pipeline:
  #align(center)[`uv run pipeline/main.py`]


