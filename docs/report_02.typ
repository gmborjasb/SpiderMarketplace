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


