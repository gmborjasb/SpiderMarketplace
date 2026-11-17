#import "@preview/merman:0.5.0": mermaid

#set par(justify: true)
#set text(size: 10pt, lang: "es", font: "New Computer Modern")
#set heading(numbering: "1.")
#show link: underline

#let neo-maroon = rgb("BF0140")

#show heading.where(level: 1): it => {
  if it.numbering == none {
    set text(size: 18pt, font: "New Computer Modern", weight: "bold", fill: black)
    it.body
  } else {
    set text(size: 18pt, font: "New Computer Modern")
    box[
      #text[#sym.section #counter(heading).display()]
      #h(5pt)
      #it.body
    ]
  }
}

#show heading.where(level: 2): it => {
  set text(size: 14pt, font: "New Computer Modern")

  box[
    #text[#sym.section#counter(heading).display()]
    #h(5pt)
    #it.body
  ]
}

#show heading.where(level: 3): it => {
  set text(size: 12pt, font: "New Computer Modern")

  box[
    #text[#sym.section#counter(heading).display()]
    #h(5pt)
    #it.body
  ]
}

// Helpers para leer CSVs del pipeline sin tipeo manual
#let csv-records(path) = {
  let raw = csv(path)
  let headers = raw.first()
  raw
    .slice(1)
    .map(row => {
      let d = (:)
      for (i, h) in headers.enumerate() {
        d.insert(h, row.at(i))
      }
      d
    })
}

#let fmt-int(val) = {
  let n = calc.round(float(val))
  let neg = n < 0
  let s = str(int(calc.abs(n)))
  let out = ""
  let len = s.len()
  for (i, ch) in s.clusters().enumerate() {
    if i > 0 and calc.rem(len - i, 3) == 0 { out += "," }
    out += ch
  }
  if neg { "-" + out } else { out }
}

#let fmt-dec(val, digits: 2) = {
  let factor = calc.pow(10, digits)
  let r = calc.round(float(val) * factor) / factor
  let neg = r < 0
  let abs-r = calc.abs(r)
  let int-part = int(calc.floor(abs-r + 1e-9))
  let frac-int = int(calc.round((abs-r - int-part) * factor))
  if frac-int >= factor {
    int-part += 1
    frac-int -= int(factor)
  }
  let int-str = fmt-int(int-part)
  let frac-str = str(frac-int)
  while frac-str.len() < digits { frac-str = "0" + frac-str }
  let res = if digits > 0 { int-str + "." + frac-str } else { int-str }
  if neg and (int-part > 0 or frac-int > 0) { "-" + res } else { res }
}

#let cat-median(rows, cat, col) = {
  let vals = rows.filter(r => r.category == cat).map(r => float(r.at(col))).sorted()
  let n = vals.len()
  if n == 0 { 0.0 } else if calc.rem(n, 2) == 1 { vals.at(int(calc.floor(n / 2))) } else {
    (vals.at(int(n / 2) - 1) + vals.at(int(n / 2))) / 2.0
  }
}

#let vol-rows = csv-records("/data/pipeline/data/resumen_volumen_etapas.csv")
#let log-rows = csv-records("/data/pipeline/data/cleaning_log.csv")
#let proc-rows = csv-records("/data/pipeline/data/falabella_processed.csv")
#let umb-rows = csv-records("/data/pipeline/data/umbrales_gamas_terciles.csv")
#let disp-rows = csv-records("/data/pipeline/data/dispersion_precios_por_categoria.csv")
#let gamas-rows = csv-records("/data/pipeline/data/descuentos_por_categoria_y_gama.csv")
#let conc-rows = csv-records("/data/pipeline/data/vendedores_concentracion_por_categoria.csv")
#let mw-p-rows = csv-records("/data/pipeline/data/mannwhitney_precio_por_vendedor_gama.csv")
#let mw-d-rows = csv-records("/data/pipeline/data/mannwhitney_descuento_por_vendedor_gama.csv")
#let m-rank-rows = csv-records("/data/pipeline/data/marcas_ranking_por_categoria.csv")
#let m-gama-rows = csv-records("/data/pipeline/data/marcas_distribucion_por_gama.csv")
#let tvs-rows = csv-records("/data/pipeline/data/tvs_precio_por_pulgadas.csv")

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

  Semestre 2026-2
  #v(0.8cm)
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

#pagebreak()


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

#pagebreak()

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
#pagebreak()
== Volumen y estructura

El dataset crudo obtenido por scraping de Falabella Perú (`data/raw/falabella_raw.csv`) tiene 1,680 filas y 6 columnas (`product`, `brand`, `category`, `seller`, `list_price` e `internet_price`), donde ninguna variable supera el 10 % de valores faltantes (solo `list_price` presenta 4.4 % de vacíos).

El dataset resultante del preprocesamiento (`data/clean/falabella_cleaned.csv`) tiene 1,037 registros y 8 variables, y tras la etapa de ingeniería de características (`data/processed/falabella_processed.csv`) alcanza 1,037 registros y 16 variables con *0 % de valores nulos en todas sus columnas*. Conserva el 61.7 % de las 1,680 filas del CSV crudo y se reparte en 437 celulares, 433 laptops y 167 televisores.

#let v-raw = vol-rows.at(0)
#let v-clean = vol-rows.at(1)
#let v-proc = vol-rows.at(2)
#let n-raw = float(v-raw.registros)
#let dup-exact = int(log-rows.at(0).filas_afectadas)
#let dup-norm = int(log-rows.at(1).filas_afectadas)
#let acc-rem = int(log-rows.at(2).filas_afectadas)
#let lp-imp = int(log-rows.at(3).filas_afectadas)
#let na-raw = int(v-raw.nulos_totales)
#let n-cel = proc-rows.filter(r => r.category == "phones").len()
#let n-lap = proc-rows.filter(r => r.category == "laptops").len()
#let n-tv = proc-rows.filter(r => r.category == "tvs").len()

#align(center)[
  #figure(
    table(
      columns: 4,
      align: (left, center, center, center),
      [*Indicador*], [*Antes (CSV crudo)*], [*Limpio (`cleaned`)*], [*Final (`processed`)*],
      [Registros], [#fmt-int(v-raw.registros)], [#fmt-int(v-clean.registros)], [#fmt-int(v-proc.registros)],
      [Variables], [#v-raw.columnas], [#v-clean.columnas], [#v-proc.columnas],
      [Celulares / laptops / televisores], [560 / 560 / 560], [#n-cel / #n-lap / #n-tv], [#n-cel / #n-lap / #n-tv],
      [Filas duplicadas exactas], [#fmt-int(dup-exact) (#fmt-dec(dup-exact / n-raw * 100, digits: 1) %)], [0], [0],
      [Duplicados tras normalizar texto], [#fmt-int(dup-norm)], [0], [0],
      [Accesorios y otros productos], [#fmt-int(acc-rem) (entre filas únicas)], [0], [0],
      [`list_price` vacío],
      [#fmt-int(na-raw) (#fmt-dec(na-raw / n-raw * 100, digits: 1) %)],
      [0 (imputado en #lp-imp)],
      [0],

      [Columnas con valores nulos (NA)],
      [1 (#fmt-dec(na-raw / n-raw * 100, digits: 1) %, $< 10$ %)],
      [0 (0.0 %)],
      [0 (0.0 %)],
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
        [`brand`],
        [Categórico],
        [40 marcas; más frecuentes: Lenovo (154), Samsung (134), Apple (122), Asus (109), HP (96); 11 filas `GENERICO`],

        [`category`], [Categórico], [`phones` (437), `laptops` (433), `tvs` (167)],
        [`seller`],
        [Categórico],
        [186 vendedores; 59 aparecen una sola vez; Falabella, Tottus y Sodimac suman 155 filas (14.9 %)],

        [`list_price`], [Numérico (S/)], [S/ 159.00 a S/ 79,999.00],
        [`internet_price`], [Numérico (S/)], [S/ 79.90 a S/ 27,345.56],
        [`list_price_imputed`],
        [Binario (0/1)],
        [0 = original (1,001), 1 = imputado con `internet_price` (36 filas, 3.5 %)],

        [`is_price_outlier`],
        [Binario (0/1)],
        [0 = no atípico (984), 1 = atípico según IQR 1.5 por categoría (53 filas, 5.1 %)],

        [`has_discount`],
        [Binario (0/1)],
        [1 = con descuento (1,001 filas, 96.5 %), 0 = sin descuento (36 filas, 3.5 %)],

        [`discount_amount`], [Numérico (S/)], [S/ 0.00 a S/ 74,300.00 (mediana global: S/ 696.00)],
        [`discount_pct`], [Numérico (%)], [0.00 % a 92.88 % (mediana global: 24.13 %)],
        [`prices_category`], [Categórico], [Gama por terciles intracategoría: `low` (358), `mid` (336), `high` (343)],
        [`seller_type`],
        [Categórico],
        [`FALABELLA_DIRECT` (155 filas, 14.9 %), `MARKETPLACE_SELLER` (882 filas, 85.1 %)],

        [`is_refurbished`],
        [Binario (0/1)],
        [1 = reacondicionado / open box (93 filas, 9.0 %), 0 = nuevo (944 filas, 91.0 %)],

        [`is_bundle`],
        [Binario (0/1)],
        [1 = combo / pack con accesorio (97 filas, 9.4 %), 0 = individual (940 filas, 90.6 %)],

        [`inches`],
        [Numérico (pulg)],
        [En `tvs`: 15" a 100" (100 % extraído, mediana 65"); en `phones`/`laptops`: 0 = no aplica],
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
+ Publicaciones con mismo producto y vendedor: 10 grupos (21 filas) con precio distinto se conservaron ya que pueden ser variantes o errores de captura y el CSV no permite distinguirlos.
+ `list_price` imputado en 36 filas con el supuesto de que "sin precio tachado" significa "sin descuento", tomado del código del spider y no de una verificación en la tienda.
+ Errores de digitación en el precio de lista. Una laptop tiene `list_price` de S/ 79,999 contra un precio internet de S/ 5,699; esto no se corrige en limpieza y se audita en el análisis de descuentos.
+ `GENERICO` y vendedores. 11 filas quedan como `GENERICO` (o sea, sin marca declarada) y se conservaron sin imputar la marca; tampoco se verificó si razones sociales distintas pertenecen al mismo dueño.

= Propuesta de Pipeline

El pipeline integra de extremo a extremo todas las etapas del proyecto bajo la orquestación de `pipeline/main.py` (con soporte de `--scrape`, `--no-pdf` y `--output-dir`).

El flujo modular está dividido en 5 etapas:

/ Scraper (`pipeline/scraper.py`):
  Ejecución opcional (`--scrape`) del spider `falabella`, que captura el catálogo y guarda `data/raw/falabella_raw.csv` (el almacenamiento en Supabase permanece desactivado en `Marketplace/settings.py`). Si se omite `--scrape`, el pipeline reutiliza el CSV crudo existente.

/ Limpieza (`pipeline/cleaning.py`):
  Normaliza texto, elimina duplicados exactos y tras normalización, filtra accesorios e imputa `list_price` faltante sin descartar atípicos, generando `falabella_cleaned.csv`, `falabella_removed_rows.csv` y `cleaning_log.csv`.

/ Ingeniería de características (`pipeline/processing_data.py`):
  Construye las 8 variables derivadas (descuento, terciles intracategoría en `prices_category`, clasificación `seller_type`, banderas de reacondicionado/combo y pulgadas), generando `falabella_processed.csv` y `umbrales_gamas_terciles.csv`.

/ Análisis estadístico y visual (`pipeline/analysis.py`):
  Calcula las métricas de dispersión, índices HHI, pruebas no paramétricas (Mann-Whitney U con corrección Holm-Bonferroni y Kruskal-Wallis) y exporta los 28 CSVs y 15 gráficos en `data/pipeline/data/` y `data/pipeline/img/`.

/ Creación de reporte (`pipeline/report.py`):
  Compila automáticamente el informe analítico (`reporte_analitico.typ` y `reporte_analitico.pdf`) a partir de los resultados del pipeline (opcionalmente omitible con `--no-pdf`).

#align(center)[
  #figure(
    mermaid(```mermaid
    flowchart LR
      A["1. Scraper\n(pipeline/scraper.py)\n--scrape opcional"] --> B["2. Limpieza\n(pipeline/cleaning.py)\nfalabella_cleaned.csv"]
      B --> C["3. Feature Engineering\n(pipeline/processing_data.py)\nfalabella_processed.csv"]
      C --> D["4. Análisis\n(pipeline/analysis.py)\n28 CSVs + 15 PNGs"]
      D --> E["5. Reporte\n(pipeline/report.py)\nreporte_analitico.pdf"]
    ```),
    caption: [Arquitectura modular del pipeline ejecutado mediante `pipeline/main.py`],
  )
]

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
        [Filas idénticas en las 6 columnas],
        [Eliminar duplicados exactos y conservar la primera aparición],
        [El CSV no guarda URL ni fecha; una repetición equivale a la misma publicación leída dos veces y sesga conteos y promedios.],
        [256 (15.2 % de 1,680)],

        [Texto con espacios duros, comillas y guiones tipográficos, puntos finales y espacios repetidos],
        [Normalizar `product`, `brand` y `seller` a mayúsculas ASCII, sin espacios repetidos ni punto final],
        [Evita que `OH SHOP` y `OH SHOP.` cuenten como dos vendedores y permite deduplicar de nuevo (apareció 1 duplicado oculto).],
        [286 cambian de texto; 1 duplicado nuevo],

        [Accesorios, repuestos y otros equipos en las secciones de televisores, celulares y laptops],
        [Retirar lo que no es el equipo, con reglas por categoría sobre el inicio del nombre; guardar las filas retiradas con su motivo],
        [Sin el filtro, la mediana de precio de televisores es S/ 99 (cables y controles). Mirar el inicio del nombre evita falsos positivos como "TELEVISOR … CON CONTROL DE VOZ".],
        [386 (27.1 % de 1,423)],

        [Etiqueta `GENERICO` en `brand`],
        [Conservar `GENERICO` como categoría explícita (la marca ya viene en mayúsculas)],
        [Asignar una marca a un producto sin marca sería inventar un dato; borrarlos quitaría productos válidos. Quien analice marcas decide si excluye `GENERICO`.],
        [`GENERICO` baja de 238 a 11 al retirar accesorios],

        [`list_price` vacío],
        [Imputar con `internet_price` y marcar con `list_price_imputed`],
        [El spider deja el campo vacío cuando no hay precio tachado, es decir, sin descuento. En las 1,001 filas con precio de lista el precio internet es siempre menor.],
        [36 (3.5 % de 1,037)],

        [Precios extremos],
        [Marcar con `is_price_outlier` (IQR 1.5 sobre `internet_price`, dentro de cada categoría y después de retirar accesorios); no eliminar],
        [Son productos reales de gama alta (laptops de hasta S/ 27,346) y el grupo acordó no borrar datos por precio o descuento alto sin una fuente externa.],
        [53 marcadas (5.1 %)],
      )
    ],
    caption: [Problemas encontrados, decisiones y filas afectadas en el preprocesamiento],
  )
]

== Limpieza

*Duplicados:* Se eliminaron 256 filas idénticas (15.2 %), de forma desigual entre categorías, siendo 22.3 % en laptops, 16.8 % en celulares y 6.6 % en televisores. Tras normalizar el texto apareció una fila repetida más (pasando de 1,424 a 1,423 filas únicas). Además, existen 10 grupos (21 filas) con el mismo producto, vendedor y categoría pero con precio distinto (en 8 grupos cambia el precio internet y en 2 solo el precio de lista), los cuales se conservaron porque pueden ser variantes de una misma publicación (por ejemplo, colores) y las columnas disponibles no permiten distinguirlas de un error de captura.

*Accesorios:* Tiene un efecto muy grande: en televisores se retiraron 356 de 523 filas únicas (68.1 %), siendo controles remotos y fundas (132), cables y adaptadores (81), soportes y racks (65), antenas y decodificadores (25), reproductores y dispositivos de streaming (21), proyectores (18) y otros productos (14). En celulares salieron 29 filas (6.2 %), casi todas repuestos de cámara (25), y en laptops un monitor portátil. La cifra de televisores supera la estimación inicial del grupo (44 %) porque aquí también salen proyectores y dispositivos que no son televisores. La regla se validó revisando a mano los productos más baratos que se conservan y los productos caros que se retiran. Estos últimos son 4 proyectores y una pizarra digital interactiva, ninguno siendo un televisor de consumo.

#align(center)[
  #figure(
    image("/data/pipeline/img/pre_01_accesorios_antes_despues.png", width: 100%),
    caption: [Filas por categoría en cada etapa (izquierda) y precio internet antes y después de retirar accesorios (derecha, en escala logarítmica)],
  )
]

La mediana de precio de televisores pasa de S/ 99 a S/ 1,729, mientras que en celulares (S/ 1,339 a S/ 1,399) y laptops (S/ 3,719 a S/ 3,739) casi no cambia. Sin este filtro, cualquier comparación de precios entre categorías habría sido engañosa.

*Valores faltantes:* La variable `list_price` está vacía en 36 de las 1,037 filas que quedan (3.5 %), siendo 16 en laptops, 15 en celulares y 5 en televisores. Según el código del spider, el campo proviene del precio tachado de la tarjeta, de modo que un vacío significa ausencia de rebaja. Los datos lo respaldan ya que en las 1,001 filas con precio de lista, el precio internet nunca iguala ni supera al de lista. Por eso se imputó con `internet_price`, que mantiene coherente el cálculo de descuento (cero para esos productos) y se dejó la bandera `list_price_imputed` para poder revertir el supuesto. Tras esta imputación, el dataset limpio queda con *0 % de valores nulos* en todas sus variables.

*Marcas:* La marca ya viene en mayúsculas desde el scraper, igualmente se normaliza. `GENERICO`, la etiqueta que usa la tienda cuando el vendedor no declara marca, tenía 238 filas en el crudo; la mayoría eran accesorios y al retirarlos quedan 11 (8 en celulares y 3 en televisores). Se conservó como categoría explícita en lugar de imputar una marca o borrar esas filas.

*Valores atípicos:* Se aplicó la regla del IQR (factor 1.5) sobre `internet_price`, dentro de cada categoría y después de retirar los accesorios; antes de ese paso los cables de S/ 10 habrían deformado los cuartiles de televisores. Un precio es atípico si queda fuera de $[Q_1 - 1.5 dot "IQR", Q_3 + 1.5 dot "IQR"]$; el límite superior es S/ 9,959 en laptops, S/ 5,899 en celulares y S/ 4,050 en televisores. Quedaron 53 filas marcadas (15, 20 y 18 respectivamente), todas de precio alto. Como la distribución tiene cola a la derecha, el IQR marca la gama más alta de cada categoría y no los precios bajos. Son productos reales (por ejemplo, una laptop de S/ 27,346) y no errores de captura, por lo que se conservaron marcadas y, en caso de querer o necesitar excluirlas, se filtra con `is_price_outlier == 0`.

#align(center)[
  #figure(
    image("/data/pipeline/img/pre_02_outliers_precio.png", width: 100%),
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
    image("/data/pipeline/img/pre_03_filas_afectadas_por_paso.png", width: 90%),
    caption: [Filas afectadas por cada paso del preprocesamiento],
  )
]

= Feature Engineering

La etapa de ingeniería de características se implementa en `pipeline/processing_data.py` y se documenta en el notebook `03_feature_engineering.ipynb`.

Recibe como entrada el dataset limpio (`data/clean/falabella_cleaned.csv`, 1,037 registros y 8 columnas) y genera el dataset procesado (`data/processed/falabella_processed.csv`, 1,037 registros y 16 columnas), creando *8 nuevas variables* sin introducir ningún valor nulo (0 % de NA en las 16 columnas).

#align(center)[
  #figure(
    text(size: 9pt)[
      #table(
        columns: (2.1fr, 2.8fr, 3.8fr, 1.5fr),
        align: (left, left, left, center),
        [*Variable creada*],
        [*Fórmula o regla de construcción*],
        [*Justificación analítica*],
        [*Objetivo que responde*],

        [`has_discount` \ _(Binario 0/1)_],
        [$1$ si `list_price` $>$ `internet_price`; $0$ si son iguales.],
        [Separa las publicaciones con oferta activa (96.5 %) de aquellas sin rebaja (3.5 %).],
        [Objetivo 1],

        [`discount_amount` \ _(Numérico, S/)_],
        [`list_price` $-$ `internet_price`],
        [Mide el ahorro nominal en soles para comparar el beneficio monetario real entre gamas.],
        [Objetivo 1],

        [`discount_pct` \ _(Numérico, %)_],
        [$("list_price" - "internet_price") / "list_price" times 100$],
        [Estandariza la magnitud de la rebaja en porcentaje (0 % a 92.88 %) para comparar categorías de distinto valor.],
        [Objetivos 1 y 2],

        [`prices_category` \ _(`low`, `mid`, `high`)_],
        [Terciles empíricos ($P_(33.3)$ y $P_(66.7)$) de `internet_price` calculados dentro de cada `category`.],
        [Evita mezclar escalas de precios entre categorías y permite estratificar la competencia por nivel de gama.],
        [Objetivos 1, 2 y 3],

        [`seller_type` \ _(Categórico)_],
        [`FALABELLA_DIRECT` si `seller` $in$ {`FALABELLA`, `TOTTUS`, `SODIMAC`}; si no, `MARKETPLACE_SELLER`.],
        [Agrupa las ventas directas del grupo retail (14.9 %) frente a los 183 vendedores externos (85.1 %).],
        [Objetivo 2],

        [`is_refurbished` \ _(Binario 0/1)_],
        [Regex en `product`: `REACONDICIONADO`, `OPEN BOX`, `REFURBISHED`, `SEMI NUEVO`.],
        [Aísla equipos de segunda selección (17.4 % en celulares, sobre todo iPhones) que distorsionarían el piso de precios.],
        [Objetivos 1 y 3],

        [`is_bundle` \ _(Binario 0/1)_],
        [Regex en `product`: `COMBO`, `PACK`, `KIT`, `REGALO` o `+ ACCESORIO` (excluyendo `8+256GB`, `FHD+`, `SIM+ESIM`).],
        [Distingue paquetes promocionales con accesorios incluidos (9.4 % del total) de los equipos individuales.],
        [Objetivos 1 y 3],

        [`inches` \ _(Numérico, pulg)_],
        [Regex de diagonal de pantalla en `tvs` (15" a 100"); $0$ = no aplica en `phones` y `laptops`.],
        [Alcanza 100 % de extracción en los 167 televisores para evaluar el tamaño de panel como driver de precio sin generar NAs.],
        [Objetivo 3],
      )
    ],
    caption: [Variables construidas en la etapa de Feature Engineering],
  )
]

== Segmentación de Gamas por Terciles Intracategoría (`prices_category`)

Dado que la distribución de precios difiere drásticamente entre laptops, celulares y televisores, los puntos de corte de los terciles empíricos ($P_(33.3)$ y $P_(66.7)$) se calcularon de forma independiente dentro de cada categoría limpia y se contrastaron con los rangos comerciales del mercado retail peruano:

#let gama-desc = (
  laptops: [Entrada: ofimática Core i3/i5 y Ryzen 3/5; Media: corporativas y gamer RTX 3050/4050; Alta: gamer RTX 4060/5060+ y MacBooks.],
  phones: [Entrada: gama básica 4G; Media: gama media 5G y reacondicionados de entrada; Alta: flagships Apple, Galaxy S y Xiaomi Ultra.],
  tvs: [Entrada: LED/QLED de 32" a 50"; Media: paneles 4K UHD/QLED de 55" a 65"; Alta: OLED, MiniLED y formatos de 75" a 100".],
)

#align(center)[
  #figure(
    text(size: 8.5pt)[
      #table(
        columns: (1fr, 1.1fr, 1.5fr, 1.1fr, 1.3fr, 3.6fr),
        align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, left + horizon),
        [*Categoría*],
        [*Corte `low`* \ ($<= P_(33.3)$)],
        [*Corte `mid`* \ ($P_(33.3) - P_(66.7)$)],
        [*Corte `high`* \ ($> P_(66.7)$)],
        [*Registros* \ (`low` / `mid` / `high`)],
        [*Correspondencia comercial en el retail tecnológico*],
        ..umb-rows.map(r => {
          let p33 = int(calc.round(float(r.p33_cutoff)))
          let p66 = int(calc.round(float(r.p66_cutoff)))
          (
            raw(r.category),
            [$<=$ S/ #fmt-int(p33)],
            [S/ #fmt-int(p33 + 1) – S/ #fmt-int(p66)],
            [$>$ S/ #fmt-int(p66)],
            [#r.low_count / #r.mid_count / #r.high_count],
            gama-desc.at(r.category),
          )
        }).flatten(),
      )
    ],
    caption: [Umbrales de terciles empíricos por categoría y validación con segmentos comerciales],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/fe_01_gamas_terciles.png", width: 100%),
    caption: [Segmentación de gamas de precio (`low`, `mid`, `high`) por terciles empíricos dentro de cada categoría],
  )
]

== Clasificación de Vendedores y Extracción de Banderas por Expresiones Regulares

En la variable `seller_type`, las ventas directas del grupo (`FALABELLA_DIRECT`: Falabella con 113 publicaciones, Tottus con 32 y Sodimac con 10) suman 155 registros (14.9 %), con una participación mucho mayor en televisores (35.3 %) que en celulares (13.0 %) y laptops (9.0 %).

Por su parte, las expresiones regulares aplicadas sobre `product` identificaron 93 equipos reacondicionados (`is_refurbished == 1`), concentrados en celulares (76 filas, 17.4 %) y laptops corporativas ThinkPad (17 filas, 3.9 %), sin presencia en televisores. Asimismo, se detectaron 97 paquetes promocionales (`is_bundle == 1`: 52 en celulares, 25 en televisores y 20 en laptops), evitando falsos positivos en nomenclaturas técnicas como `8+256GB` o `FHD+`.
Finalmente, en `tvs` se extrajo el tamaño en pulgadas (`inches`) en los 167 televisores (100 % de efectividad), predominando los formatos de 65" (53 unidades), 55" (30 unidades), 75" (19 unidades), 43" (16 unidades) y 32" (15 unidades).

#align(center)[
  #figure(
    image("/data/pipeline/img/fe_02_banderas_y_vendedores.png", width: 100%),
    caption: [Proporción de tipos de vendedor, banderas comerciales (`is_refurbished`, `is_bundle`) y distribución de pulgadas en televisores],
  )
]

= Análisis y Visualización de datos

== Concentración de Precios y Dispersión Relativa por Categoría (Objetivo 1)

El análisis exploratorio de precios y descuentos se desarrolla en el notebook `04_analisis_descuentos_categorias.ipynb`. Debido a la asimetría positiva de los precios, la dispersión dentro de cada categoría se cuantifica mediante el Rango Intercuartílico ($"IQR" = Q_3 - Q_1$) y el *IQR Relativo* ($"IQR" / "Mediana" times 100$):

#let iqr-rels = disp-rows.map(r => float(r.iqr_relativo_pct))
#let max-iqr-rel = calc.max(..iqr-rels)
#let min-iqr-rel = calc.min(..iqr-rels)
#let cat-meds = disp-rows.map(r => cat-median(proc-rows, r.category, "discount_pct"))
#let max-cat-med = calc.max(..cat-meds)

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: 8,
        align: (left, center, center, center, center, center, center, center),
        [*Categoría*], [*N*], [*Q1 (S/)*], [*Mediana (S/)*], [*Q3 (S/)*], [*IQR (S/)*], [*IQR Relativo (%)*], [*Mediana Desc. (%)*],
        ..disp-rows.map(r => {
          let iqr-rel = float(r.iqr_relativo_pct)
          let m-desc = cat-median(proc-rows, r.category, "discount_pct")
          let iqr-txt = [#fmt-dec(iqr-rel, digits: 1) %]
          let desc-txt = [#fmt-dec(m-desc, digits: 2) %]
          (
            raw(r.category),
            [#fmt-int(r.n)],
            [#fmt-dec(r.q1_soles)],
            [#fmt-dec(r.median_soles)],
            [#fmt-dec(r.q3_soles)],
            [#fmt-dec(r.iqr_soles)],
            if iqr-rel == max-iqr-rel or iqr-rel == min-iqr-rel { strong(iqr-txt) } else { iqr-txt },
            if m-desc == max-cat-med { strong(desc-txt) } else { desc-txt },
          )
        }).flatten(),
      )
    ],
    caption: [Estadísticos robustos de precio internet y dispersión relativa por categoría],
  )
]

Los resultados revelan un contraste estructural entre las tres líneas tecnológicas:
- *Los celulares más que duplican en dispersión relativa a los televisores ($2.34 times$):* la categoría `phones` alcanza un IQR Relativo de *148.7 %* frente al *63.6 %* de `tvs` y el *76.0 %* de `laptops`.
- Como muestra el gráfico de violín, el catálogo de *televisores* presenta una silueta sumamente concentrada entre S/ 1,299 y S/ 2,399 debido a la estandarización de costos de los paneles LED/QLED de 43" a 65". En cambio, los *celulares* exhiben una distribución alargada y multimodal que abarca desde teléfonos básicos de S/ 80 hasta flagships de S/ 8,999.

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_01_violin_precios_categoria.png", width: 100%),
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
        [*Categoría*], [*Gama*], [*N*], [*\% con Desc.*], [*Mediana Precio (S/)*], [*Mediana Desc. (%)*], [*Mediana Ahorro (S/)*],
        ..gamas-rows.map(r => {
          let d-txt = [#fmt-dec(r.mediana_desc_pct, digits: 2) %]
          let a-txt = [#fmt-dec(r.mediana_ahorro_soles, digits: 2)]
          (
            raw(r.category),
            raw(r.prices_category),
            [#fmt-int(r.n)],
            [#fmt-dec(r.pct_con_descuento, digits: 1) %],
            [#fmt-dec(r.mediana_precio_soles, digits: 2)],
            if r.prices_category == "low" { strong(d-txt) } else { d-txt },
            if r.prices_category == "high" { strong(a-txt) } else { a-txt },
          )
        }).flatten(),
      )
    ],
    caption: [Comparación del porcentaje de descuento y ahorro en soles por categoría y gama],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_02_boxplots_descuento_gama.png", width: 100%),
    caption: [Boxplots del porcentaje de descuento (izquierda) y del ahorro en soles (derecha) por categoría y gama de precio],
  )
]

En las tres categorías, la *rebaja porcentual mediana es mayor en la gama baja (`low`)* y disminuye hacia la gama alta (`high`): en televisores baja de 37.02 % a 31.25 %, en celulares de 29.39 % a 23.58 % y en laptops de 23.33 % a 17.24 %. Esta relación inversa se confirma mediante las pruebas de correlación entre `internet_price` y `discount_pct`:
- En *celulares (`phones`)* existe una correlación negativa estadísticamente significativa ($r = -0.274$, $rho = -0.258$, $p < 0.0001$): a mayor precio del smartphone, menor es el porcentaje de descuento otorgado. Las marcas cuidan el valor percibido de sus equipos *flagship*, mientras que la gama de entrada y media compite con descuentos porcentuales agresivos.
- En *televisores* ($r = -0.176$, $rho = -0.185$, $p = 0.023$) y *laptops* ($r = -0.129$, $rho = -0.157$, $p = 0.007$) la tendencia también es negativa aunque más moderada.

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_03_scatter_precio_descuento.png", width: 100%),
    caption: [Diagramas de dispersión entre precio internet y porcentaje de descuento con rectas de regresión por categoría],
  )
]

== Veracidad de Descuentos, Reacondicionados y Combos Promocionales

El cruce con las banderas extraídas en Feature Engineering permite explicar las anomalías del catálogo:
1. *Descuentos inflados o artificiales ($>= 60$ %):* Se identificaron 16 publicaciones con descuentos declarados de 60 % o más, de las cuales 15 pertenecen a vendedores externos (`MARKETPLACE_SELLER`). El caso más extremo supera el 70 %: la laptop `LENOVO LOQ 15AHP10 RYZEN 7 RTX 5050` publicada por `IVANCE ELECTRONIC ONLINE` declara un `list_price` de *S/ 79,999* frente a un `internet_price` de *S/ 5,699* (*92.88 %* de descuento), evidente error de digitación del vendedor (S/ 79,999 en vez de S/ 7,999, con lo que el descuento real sería 28.8 %). En televisores y celulares básicos, sellers externos como `ELECTROHOGAR` y `VICTORIA ILIMITADA` fijan precios de lista muy por encima del mercado para generar un efecto de anclaje publicitario.
2. *Efecto de equipos reacondicionados (`is_refurbished`):* De los 76 celulares reacondicionados del dataset, *44 son iPhones de Apple* (el 48.9 % de las 90 publicaciones de Apple en celulares). Mientras que un iPhone nuevo tiene un precio mediano de *S/ 5,069*, un iPhone reacondicionado tiene una mediana de *S/ 1,999* ($-60.6$ %). Aislar esta variable evita confundir equipos usados/reacondicionados por terceros con descuentos sobre equipos nuevos.
3. *Combos promocionales (`is_bundle`):* Los 97 combos identificados presentan descuentos porcentuales medianos ligeramente menores que los productos individuales (20.05 % vs. 25.01 % en celulares; 16.88 % vs. 19.30 % en laptops), dado que el incentivo comercial se traslada al accesorio incluido (`+ AUDÍFONOS`, `+ WATCH`, `+ MOCHILA` o `+ BARRA DE SONIDO`).

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_04_anomalias_reacondicionados_combos.png", width: 100%),
    caption: [Impacto de la condición reacondicionada en celulares Apple vs. otras marcas (izquierda) y comparación de descuentos entre equipos individuales y combos (derecha)],
  )
]

== Competitividad Tarifaria entre Tipos de Vendedor (Objetivo 2)

El análisis del segundo objetivo se desarrolla en el notebook `05_analisis_vendedores_marcas.ipynb` y compara las publicaciones de `FALABELLA_DIRECT` (Falabella, Tottus y Sodimac) con las de `MARKETPLACE_SELLER`. Se fijaron cuatro criterios metodológicos:

- *Solo equipos nuevos* (`is_refurbished == 0`, 944 publicaciones): los 93 equipos reacondicionados del catálogo pertenecen en su totalidad a vendedores externos, por lo que incluirlos haría parecer más baratos a los terceros por vender un producto distinto.
- *Comparación dentro de cada categoría y gama* (`prices_category`): así se separa "qué productos ofrece cada tipo de vendedor" de "a qué precio los ofrece".
- *Prueba U de Mann-Whitney* bilateral ($alpha = 0.05$), adecuada para precios asimétricos y grupos pequeños (Falabella tiene entre 10 y 28 productos por celda), con *corrección de Holm* por las 9 comparaciones simultáneas ($p_"Holm"$).
- *Tamaño del efecto* mediante la correlación biserial de rangos $r_"rb" = 2 U_F \/ (n_F n_M) - 1$: un valor positivo indica que Falabella tiende a valores mayores.

=== Composición del catálogo y concentración de vendedores

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: 6,
        align: (left, center, center, left, center, center),
        [*Categoría*], [*Publicaciones*], [*Vendedores distintos*], [*Vendedor líder*], [*Top 5*], [*HHI*],
        ..conc-rows.map(r => {
          let is-tot = r.category == "TOTAL"
          (
            if is-tot { [*Total*] } else { raw(r.category) },
            [#fmt-int(r.publicaciones)],
            [#fmt-int(r.vendedores_distintos)],
            [#r.vendedor_lider (#fmt-dec(r.pct_lider, digits: 1) %)],
            [#fmt-dec(r.pct_top5, digits: 1) %],
            [#fmt-int(r.hhi)],
          )
        }).flatten(),
      )
    ],
    caption: [Concentración de la oferta por vendedor (calculada sobre publicaciones, no sobre ventas)],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_05_composicion_vendedores.png", width: 100%),
    caption: [Participación de cada tipo de vendedor por categoría (izquierda) y 12 vendedores con más publicaciones (derecha)],
  )
]

El catálogo lo publican mayoritariamente terceros: el 85.1 % de las publicaciones corresponde a vendedores externos. La venta directa del grupo Falabella solo tiene un peso relevante en televisores (35.3 %), frente al 13.0 % en celulares y el 9.0 % en laptops. La oferta está muy atomizada: hay 186 vendedores, 59 de ellos con una sola publicación, y el líder (FALABELLA) apenas reúne el 10.9 % del catálogo. Los televisores son la categoría más concentrada (HHI = 882).

Además, cada tipo de vendedor ofrece una mezcla de gamas distinta. Entre los equipos nuevos, Falabella concentra su oferta en la gama alta (45.6 % de sus celulares y 47.5 % de sus televisores son `high`), mientras que los terceros tienen más peso en la gama baja (41.1 % de sus celulares y 38.9 % de sus televisores son `low`).

=== Precio internet dentro de cada gama

#align(center)[
  #figure(
    text(size: 8.5pt)[
      #table(
        columns: 9,
        align: (left, center, center, right, right, center, center, center, center),
        table.header(
          table.cell(rowspan: 2)[*Categoría*], table.cell(rowspan: 2)[*Gama*], table.cell(rowspan: 2)[*n (F / M)*],
          table.cell(colspan: 3)[*Precio internet (mediana)*], table.cell(colspan: 3)[*Descuento declarado (mediana)*],
          [*Falabella*], [*Marketplace*], [*$p_"Holm"$*], [*Falabella*], [*Marketplace*], [*$p_"Holm"$*],
        ),
        ..mw-p-rows.zip(mw-d-rows).map(((p, d)) => {
          let ph-p = [#fmt-dec(p.p_holm, digits: 3)]
          let ph-d = [#fmt-dec(d.p_holm, digits: 3)]
          (
            raw(p.category),
            raw(p.prices_category),
            [#p.n_falabella / #p.n_marketplace],
            [S/ #fmt-int(p.mediana_falabella)],
            [S/ #fmt-int(p.mediana_marketplace)],
            if p.significativo_holm == "True" { strong(ph-p) } else { ph-p },
            [#fmt-dec(d.mediana_falabella, digits: 1) %],
            [#fmt-dec(d.mediana_marketplace, digits: 1) %],
            if d.significativo_holm == "True" { strong(ph-d) } else { ph-d },
          )
        }).flatten(),
      )
    ],
    caption: [Prueba U de Mann-Whitney entre `FALABELLA_DIRECT` (F) y `MARKETPLACE_SELLER` (M) por categoría y gama, solo equipos nuevos. En negrita, las diferencias significativas tras la corrección de Holm],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_06_precio_vendedor_por_gama.png", width: 100%),
    caption: [Precio internet por tipo de vendedor dentro de cada gama (equipos nuevos, escala logarítmica)],
  )
]

*Dentro de una misma categoría y gama no existen diferencias de precio significativas entre Falabella y los vendedores externos.* Ninguna de las 9 comparaciones es significativa: el p-valor sin corregir más bajo es 0.073 (televisores `high`) y todos los $p_"Holm"$ son mayores o iguales a 0.655. Los tamaños de efecto son pequeños ($|r_"rb"| <= 0.28$). La hipótesis inicial de que los terceros son más económicos en la gama baja tampoco se confirma: en celulares `low` (S/ 534 frente a S/ 499) y televisores `low` (S/ 1,199 frente a S/ 1,074) las medianas de los terceros son algo menores, pero sin significancia ($p = 0.27$ y $p = 0.53$).

En cambio, si se compara la categoría completa sin estratificar por gama, Falabella aparece más caro en celulares (mediana S/ 1,899 frente a S/ 1,152; $p < 0.001$) y en televisores (S/ 1,999 frente a S/ 1,614; $p = 0.002$). Esa brecha es un *efecto de composición*: Falabella no cobra más por productos equivalentes, sino que publica proporcionalmente más productos de gama alta.

=== Agresividad de las ofertas: descuento declarado

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_07_descuento_vendedor_por_gama.png", width: 100%),
    caption: [Descuento declarado (`discount_pct`) por tipo de vendedor dentro de cada gama (equipos nuevos)],
  )
]

A diferencia del precio, el descuento declarado sí difiere entre tipos de vendedor, aunque en sentido opuesto según la categoría:

- *Laptops:* Falabella declara descuentos significativamente mayores en las tres gamas (medianas de 37.2 %, 34.3 % y 34.0 % frente a 22.5 %, 17.1 % y 16.7 %; $r_"rb"$ entre 0.49 y 0.60). Como el precio final no difiere, la diferencia proviene de un *precio de lista más alto*: en la gama `mid`, la mediana de `list_price` de Falabella es S/ 5,899 frente a S/ 4,799 de los terceros ($p_"Holm" < 0.001$).
- *Celulares de gama alta:* ocurre lo contrario; Falabella declara un descuento mediano de 11.5 % frente a 25.9 % de los terceros ($p_"Holm" = 0.003$).
- *Televisores:* los terceros concentran las rebajas extremas. El 24.1 % de sus televisores nuevos declara un descuento de al menos 50 %, frente al 8.5 % de Falabella. Las diferencias de mediana no son significativas tras la corrección.

En conjunto, dentro de una misma gama ambos tipos de vendedor cobran prácticamente lo mismo pero declaran descuentos distintos. Por lo tanto, *el porcentaje de descuento depende del precio de lista que declara cada vendedor y no indica un menor precio final*: funciona más como una herramienta de comunicación (efecto de anclaje) que como una medida del ahorro real.

*Robustez.* Las pruebas se repitieron incluyendo los reacondicionados y excluyendo los precios atípicos (`is_price_outlier == 1`). En ambos escenarios ninguna diferencia de precio resulta significativa, y el patrón de descuentos se mantiene. La única excepción es laptops `high`, que deja de ser significativa sin atípicos ($p_"Holm" = 0.092$) porque Falabella queda con solo 10 productos en esa celda.

== Posicionamiento y Dispersión de Precios por Marca (Objetivo 3)

Para cada categoría se analizaron las marcas con al menos 10 publicaciones de equipos nuevos, excluyendo `GENERICO` (etiqueta que la tienda asigna cuando no se declara la marca). Los reacondicionados se excluyen porque desplazan artificialmente hacia abajo el precio de algunas marcas; su efecto se analiza aparte. Las diferencias entre marcas se evaluaron con la prueba de Kruskal-Wallis.

=== Ranking de marcas y presencia por gama

#align(center)[
  #figure(
    text(size: 8.5pt)[
      #table(
        columns: 7,
        align: (left, left, center, right, center, center, center),
        [*Categoría*], [*Marca*], [*n*], [*Mediana*], [*IQR relativo*], [*% low / mid / high*], [*Desc. mediano*],
        ..m-rank-rows.zip(m-gama-rows).map(((rk, gm)) => (
          raw(rk.category),
          [#rk.brand],
          [#rk.n_nuevos],
          [S/ #fmt-int(rk.mediana_soles)],
          [#fmt-dec(rk.iqr_relativo_pct, digits: 1) %],
          [#int(calc.round(float(gm.pct_low))) / #int(calc.round(float(gm.pct_mid))) / #int(calc.round(float(gm.pct_high)))],
          [#fmt-dec(rk.mediana_desc_pct, digits: 1) %],
        )).flatten(),
      )
    ],
    caption: [Precio internet por marca (equipos nuevos), ordenado por mediana dentro de cada categoría],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_08_ranking_precio_marcas.png", width: 100%),
    caption: [Distribución del precio internet por marca (equipos nuevos, escala logarítmica)],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_09_marcas_por_gama.png", width: 100%),
    caption: [Porcentaje del portafolio de cada marca en cada gama (equipos nuevos)],
  )
]

- *Celulares: la marca define el precio* (Kruskal-Wallis $H = 123.2$, $p < 0.001$). Apple mantiene un posicionamiento premium rígido: el 100 % de sus celulares nuevos está en la gama alta y su equipo nuevo más barato (S/ 2,699) cuesta más que la mediana de Samsung (S/ 2,199). Samsung y Xiaomi, en cambio, tienen portafolios elásticos que cubren las tres gamas, con la mayor dispersión relativa (129.4 % y 131.1 %). OPPO (91.7 % en `mid`) y ZTE (80.0 % en `low`) se especializan en gamas menores.
- *Laptops:* también hay diferencias significativas entre marcas ($H = 39.2$, $p < 0.001$). MSI es la marca más rígida (100 % en `high`, IQR relativo de 5.7 %) y Apple concentra el 64.3 % de su oferta en la gama alta, con el descuento mediano más bajo de la categoría (11.8 %). Lenovo, HP, Acer y ASUS cubren las tres gamas; ASUS es la más dispersa (IQR relativo de 106.2 %).
- *Televisores:* las marcas *no* difieren significativamente en precio ($H = 5.3$, $p = 0.15$). Samsung, TCL y LG tienen medianas cercanas y presencia en las tres gamas.

*Efecto de los reacondicionados en el posicionamiento.* Si se incluyen los equipos reacondicionados, la proporción de celulares Apple en la gama alta baja de 100 % a 73.3 % y su mediana cae de S/ 5,069 a S/ 3,014. Esto significa que Apple solo aparece en la gama media a través de los 44 iPhones reacondicionados (48.9 % de sus 90 publicaciones), todos vendidos por terceros.

=== El tamaño de pantalla como determinante del precio en televisores

#align(center)[
  #figure(
    text(size: 9.5pt)[
      #table(
        columns: 6,
        align: (center, center, center, right, right, center),
        [*Tamaño*], [*n*], [*Rango intercuartílico*], [*Mediana*], [*Mediana S/ por pulgada*], [*% Falabella directo*],
        ..tvs-rows.map(r => (
          [#r.inches"],
          [#r.n],
          [S/ #fmt-int(r.q1_soles) – S/ #fmt-int(r.q3_soles)],
          [S/ #fmt-int(r.mediana_soles)],
          [S/ #fmt-dec(r.mediana_soles_por_pulgada, digits: 1)],
          [#fmt-dec(r.pct_falabella_direct, digits: 1) %],
        )).flatten(),
      )
    ],
    caption: [Precio internet de los televisores según el tamaño de pantalla (tamaños con al menos 5 publicaciones; 150 de 167 televisores)],
  )
]

#align(center)[
  #figure(
    image("/data/pipeline/img/ana_10_precio_pulgadas_tvs.png", width: 100%),
    caption: [Precio internet frente al tamaño de pantalla con la mediana por tamaño (izquierda) y costo mediano por pulgada (derecha)],
  )
]

El tamaño de pantalla (`inches`) es el principal determinante del precio de un televisor: la correlación de Spearman es $rho = 0.78$ ($p < 0.001$) y las diferencias entre tamaños son muy significativas (Kruskal-Wallis $H = 89.6$, $p < 0.001$). La mediana sube de S/ 585 en 32" a S/ 3,299 en 85". Sin embargo, el precio no crece de forma proporcional: el costo por pulgada pasa de S/ 18.3 a S/ 38.8, con una excepción en *65"*, que sale más barato por pulgada (S/ 26.9) que 55" (S/ 30.4) y cuya mediana está apenas S/ 75 por encima. Además, 65" es el tamaño con más publicaciones (53 de 167). A igual tamaño, la marca mueve el precio de forma moderada y sin un orden fijo: en 55" LG es la más barata (S/ 1,479 frente a S/ 1,849 de TCL), mientras que en 65" lo es TCL (S/ 1,599 frente a S/ 1,945 de Samsung).

= Insights encontrados

Cada hallazgo se acompaña de la evidencia que lo respalda y de una recomendación para un usuario concreto: el *comprador*, la *plataforma* (Falabella como operador del marketplace) o el *vendedor externo*.

+ *El porcentaje de descuento cae al subir de gama, pero el ahorro en soles crece.* En las tres categorías la rebaja porcentual mediana disminuye de `low` a `high` (en televisores, de 37.0 % a 31.3 %; en laptops, de 23.3 % a 17.2 %), y en celulares el precio y el descuento porcentual tienen una correlación negativa ($r = -0.27$, $p < 0.001$). Aun así, el ahorro nominal mediano es mayor en gama alta (S/ 1,700 en televisores y S/ 1,388.50 en laptops).

  _Recomendación para el comprador:_ en gama alta conviene evaluar el ahorro en soles y no el porcentaje, porque un descuento porcentual "bajo" puede representar un ahorro mayor que una rebaja llamativa en un equipo de entrada.

+ *Para equipos nuevos, comprar a un vendedor externo no es más barato que comprar a Falabella.* Dentro de la misma categoría y gama, ninguna de las 9 comparaciones de precio muestra diferencias significativas ($p_"Holm" >= 0.655$). La aparente ventaja de los terceros al comparar categorías completas se explica porque Falabella publica más productos de gama alta.

  _Recomendación para el comprador:_ como el precio es equivalente, la decisión entre un producto de Falabella y uno de un tercero debería basarse en la garantía, el despacho y la reputación del vendedor. _Para el vendedor externo:_ competir solo por precio no lo diferencia de la venta directa; sus ventajas deben estar en el servicio o en el surtido.

+ *El porcentaje de descuento no es una señal confiable de un mejor precio.* Con precios finales equivalentes, cada tipo de vendedor declara descuentos distintos según el precio de lista que publica: Falabella declara más descuento en laptops (alrededor de 35 % frente a 17–22 %), mientras que los terceros lo hacen en celulares de gama alta y concentran las rebajas de 50 % o más en televisores (24.1 % de sus televisores frente a 8.5 % de Falabella). De las 16 publicaciones con descuentos de 60 % o más, 15 son de terceros, incluido un error de digitación de S/ 79,999 en el precio de lista de una laptop.

  _Recomendación para el comprador:_ comparar el precio final (`internet_price`) entre publicaciones y no el porcentaje de rebaja. _Para la plataforma:_ validar automáticamente los precios de lista de los vendedores externos, por ejemplo alertando cuando el descuento declarado supera el 60 % o el precio de lista se aleja mucho del de productos de la misma gama.

+ *La oferta "barata" del marketplace en celulares proviene de los reacondicionados.* Los 93 equipos reacondicionados del catálogo son de vendedores externos. En Apple, 44 de sus 90 publicaciones de celulares (48.9 %) son reacondicionadas, con una mediana de S/ 1,999 frente a S/ 5,069 de los iPhones nuevos. Si no se separan, Apple aparenta tener presencia en la gama media.

  _Recomendación para el comprador:_ verificar la condición del equipo antes de comparar precios. _Para la plataforma:_ ofrecer un filtro visible de condición (nuevo o reacondicionado) para que los equipos reacondicionados no se comparen directamente con los nuevos.

+ *En celulares la marca define el rango de precio; Apple es rígida y Samsung y Xiaomi son elásticas.* Apple concentra el 100 % de sus celulares nuevos en la gama alta, con un piso de S/ 2,699. Samsung y Xiaomi cubren las tres gamas, con una dispersión relativa superior al 129 %.

  _Recomendación para el comprador con presupuesto acotado:_ Samsung y Xiaomi ofrecen alternativas en todos los rangos de precio. _Para el vendedor externo:_ en celulares, el surtido de marcas elásticas permite atender a más segmentos que un catálogo concentrado en una sola marca premium.

+ *En televisores importa más el tamaño que la marca, y 65" es el formato con mejor costo por pulgada.* El precio se asocia fuertemente con el tamaño ($rho = 0.78$), mientras que las marcas no difieren significativamente ($p = 0.15$). El televisor de 65" cuesta en mediana S/ 26.9 por pulgada, menos que uno de 55" (S/ 30.4), y su mediana está apenas S/ 75 por encima.

  _Recomendación para el comprador:_ quien evalúa un televisor de 55" puede considerar uno de 65" por una diferencia de precio pequeña, y a igual tamaño conviene comparar marcas, ya que en 55" la diferencia entre LG y TCL llega a S/ 370 en mediana.

= Conclusiones

El proyecto permitió transformar 1,680 registros extraídos por web scraping en un dataset de 1,037 equipos verificados y 16 variables sin valores nulos, sobre el que se respondieron los tres objetivos específicos:

- *Objetivo 1 (magnitud, distribución y veracidad de los descuentos).* El descuento es prácticamente universal en el catálogo: el 96.5 % de las publicaciones declara una rebaja. Los televisores tienen los descuentos más agresivos (mediana de #fmt-dec(cat-median(proc-rows, "tvs", "discount_pct")) %, frente a #fmt-dec(cat-median(proc-rows, "phones", "discount_pct")) % en celulares y #fmt-dec(cat-median(proc-rows, "laptops", "discount_pct")) % en laptops). Los celulares son la categoría más heterogénea en precio (IQR relativo de 148.7 %, 2.34 veces el de los televisores). En las tres categorías, la gama alta mantiene descuentos porcentuales más bajos. En cuanto a la veracidad, la evidencia interna (precios de lista que difieren entre vendedores con el mismo precio final, descuentos extremos casi exclusivos de terceros y un error de digitación de S/ 79,999) indica que el porcentaje de descuento refleja en buena parte el precio de lista declarado y no necesariamente un ahorro real.
- *Objetivo 2 (competitividad entre tipos de vendedor).* Los vendedores externos *no representan una alternativa más económica* para equipos nuevos: dentro de la misma categoría y gama los precios no difieren significativamente, resultado que se mantiene en los tres escenarios de robustez. Lo que sí difiere es la estrategia de comunicación del descuento y la composición de la oferta: Falabella se concentra en gama alta, y los terceros en gama baja y en equipos reacondicionados, que son su única fuente real de precios más bajos.
- *Objetivo 3 (posicionamiento y dispersión por marca).* En celulares y laptops la marca es un determinante significativo del precio. Hay marcas de posicionamiento rígido en la gama alta (Apple en celulares, MSI en laptops) y marcas con portafolios elásticos en las tres gamas (Samsung y Xiaomi en celulares; Lenovo, HP, Acer y ASUS en laptops). En televisores, en cambio, la marca no explica el precio y el tamaño de pantalla sí, con una relación creciente pero no proporcional.

*Reflexión crítica y limitaciones.* Los resultados deben leerse dentro de las condiciones del dataset:

- Los datos provienen de *una sola captura en el tiempo y de una sola tienda*. Por ello no se puede comprobar si los precios de lista se cobraron alguna vez (la verificación más directa de la veracidad de un descuento) ni comparar con otros retailers. El contraste con fuentes externas planteado en el Objetivo 1 queda como trabajo futuro.
- La muestra corresponde a las primeras páginas del listado de cada categoría, *no es aleatoria*, y se analizan publicaciones, no ventas: la concentración de vendedores mide oferta, no participación de mercado.
- La columna `cmr_price` se eliminó porque superaba el límite de 10 % de valores nulos por columna (más del 80 % de las publicaciones no tenía precio con tarjeta CMR). Por eso no se pudo evaluar el ahorro adicional con tarjeta.
- El filtro de accesorios es por reglas y, aunque se revisó manualmente en los casos límite, no es infalible. Tras aplicarlo, los televisores quedaron en 167 registros y varias celdas de la comparación entre vendedores tienen pocos productos de Falabella (10 a 28), lo que reduce la potencia de las pruebas: no detectar diferencias no equivale a demostrar que los precios son idénticos.
- Las gamas son terciles relativos a la muestra y no segmentos oficiales del mercado. Además, con las columnas disponibles no se pueden emparejar modelos idénticos entre vendedores, por lo que la comparación se hizo por categoría y gama.

Como trabajo futuro, programar capturas periódicas con el workflow del scraper permitiría seguir la evolución de los precios de lista y verificar directamente la veracidad de los descuentos. Por su parte, extraer especificaciones del nombre del producto (almacenamiento, RAM, procesador) haría posible comparar modelos equivalentes entre vendedores.

= Documentación y Reproducibilidad en Github

El repositorio del proyecto está ubicado en el enlace:

#align(center)[
  #link("https://github.com/gmborjasb/SpiderMarketplace")
]

La estructura del proyecto es la siguiente:

#text(size: 9pt)[
  ```md
   SpiderMarketplace/
      ├── Marketplace/     # Ingestión: Código del web scraper desarrollado con Scrapy.
      ├── pipeline/        # Automatización: scraper, cleaning, processing_data, analysis y report.
      ├── data/            # Almacenamiento: raw, clean, processed, analysis y salida unificada en pipeline/.
      ├── notebooks/       # Analítica: Notebooks 01 al 05 (auditoría, limpieza, features y análisis).
      ├── docs/            # Documentación: Diccionarios de datos, informes en Typst y recursos.
      ├── pyproject.toml   # Configuración del entorno y dependencias para uv.
      ├── Requirements.txt # Lista equivalente de dependencias para pip.
      └── README.md        # Descripción general e instrucciones de uso del repositorio.
  ```
]

Para reproducir el proyecto completo:

1. Instalar las dependencias (con `uv` o `pip`):
  #align(center)[`uv sync` #h(1em) o #h(1em) `pip install -r Requirements.txt`]

2. Ejecutar el pipeline completo de datos, análisis y reporte automático:
  #align(center)[`uv run python pipeline/main.py`]

3. Compilar este informe conectando los resultados generados en `data/pipeline/`:
  #align(center)[`typst compile --root . docs/report_02.typ`]
