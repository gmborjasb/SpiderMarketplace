#set par(justify: true)
#set text(size: 12pt, lang: "es", font: "New Computer Modern")
#set heading(numbering: "1.")
#show link: underline

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
    #text(fill: neo-maroon)[#sym.section#counter(heading).display()]
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

  #v(1cm)
  *FACULTAD DE COMPUTACIÓN*

  #v(0.2cm)
  *CARRERA DE DATA SCIENCE*

  #v(0.5cm)
  *PRIMER AVANCE DEL PROYECTO FINAL:*

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
*CURSO:*
#align(center)[
  *ANÁLISIS COMPUTACIONAL DE DATOS*
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
      [Alondra Obregón], [Objetivos, Dataset Preliminar, Viabilidad, Apoyo en Web Scraping],
      [Axel Portal], [Identificación, Fuente de Datos, Estrategia, Apoyo en Web Scraping],
      [Danna Gala], [Contexto, Alcance, Diccionario de Datos],
      [Gerald], [Web Scraping de la página seleccionada],
    ),
    caption: [Distribución de responsabilidades],
  )
]

= Contexto

El crecimiento del comercio electrónico ha incrementado la cantidad de productos y vendedores disponibles en plataformas de marketplace, generando así una mayor variedad de alternativas para los consumidores. En plataformas como Falabella Perú, un mismo tipo de producto puede encontrarse asociado a diferentes marcas, precios, descuentos y vendedores, esto incluyendo tanto la venta directa de la plataforma como ofertas realizadas por terceros.

Esta variedad dificulta poder realizar comparaciones directas entre productos y vendedores, especialmente en categorías tecnológicas con alto valor como lo podrían ser laptops, celulares y televisores. Un producto puede presentar al mismo tiempo un precio normal y un precio de oferta, esto mientras que otros productos de características similares pueden ser comercializados por distintos vendedores a precios diferentes. Por ello, observar únicamente el precio de un producto nos permitiría identificar con claridad cómo se distribuyen los precios, qué magnitud tienen los descuentos o cómo varían estas características entre marcas y tipos de vendedores.

Bajo este contexto, nuestro proyecto propone utilizar técnicas de web scraping y análisis exploratorio de datos para poder construir un dataset a partir de productos publicados en la plataforma de _Falabella Perú_. Este análisis nos permitirá caracterizar los precios normales y de oferta, calcular los porcentajes de descuento y comparar estas variables según categoría, marca y vendedor. De esta manera, se busca obtener una descripción cuantitativa de la oferta tecnológica disponible en la plataforma y de las diferencias observables entre sus distintos tipos de vendedores.

= Objetivos

/ Objetivo General:

Analizar los precios, descuentos y niveles de competencia entre las marcas de laptops, celulares y televisores en Falabella Perú, comparando las ventas directas con las de los vendedores del marketplace.

/ Objetivos Específicos:

- _Evaluar la magnitud y distribución de los descuentos_:

  Cuantificar la brecha porcentual entre el precio normal y el precio de oferta en las tres categorías tecnológicas, determinando qué líneas presentan rebajas más agresivas y cuáles mantienen precios de venta rígidos.

- _Contrastar la competitividad tarifaria entre tipos de vendedores_:

  Comparar las distribuciones de precios ofertados por Falabella y sus filiales directas frente a los vendedores externos (sellers), identificando si los terceros constituyen una opción más económica o si replican las tarifas oficiales en los mismos modelos.

- _Examinar el posicionamiento y la dispersión de costos por marca_:

  Determinar las diferencias de precios promedio y rangos de dispersión entre las principales marcas de cada categoría (ej. Apple, Samsung, Lenovo, LG), clasificando su presencia en segmentos de gama de entrada, media y alta dentro de la plataforma.

= Dataset Preliminar

El resultado de la extracción es un archivo `.csv`  con *1680 filas y 7 columnas*, repartidas en siete secciones relacionadas con el servicio de retail (producto, marca, categoría, vendedor, precio regular, precio especial y hay descuento con cmr).
Cada fila representa un producto y cada columna es un atributo respecto a dicho producto:

#align(center)[
  #figure(
    table(
      columns: 2,
      [*Atributo*], [*Descripción*],
      [`product`], [Nombre completo del producto tal como aparece en el sitio.],
      [`brand`], [Marca del producto.],
      [`category`], [El producto es teléfono, televisor o laptop.],
      [`seller`], [Nombre del vendedor del producto.],
      [`regular_price`], [Precio regular sin descuento del producto, en soles.],
      [`special_price`], [Precio con descuento, en soles.],
      [`has_cmr_discount`], [Si el producto cuenta con algún descuento extra por pagar con tarjeta cmr.],
    ),
    caption: [Atributos del dataset preliminar],
  )
]

#align(center)[

  #show table: set text(size: 7pt)
  #figure(
    table(
      columns: 7,
      [*`product`*],
      [*`brand`*],
      [*`category`*],
      [*`seller`*],
      [*`regular_price`*],
      [*`special_price`*],
      [*`has_cmr_discount`*],

      [Celular Galaxy S26 512GB], [SAMSUNG], [phones], [FALABELLA], [5399.0], [4199.0], [0],
      [MacBook Neo 512GB - Índigo], [APPLE], [laptops], [TECHNOLOGY SUPPLIER PE], [4539.0], [3699.0], [1],
      [Televisor 32 QLED Full HD Smart TV 32S5K], [TCL], [tvs], [CITY TEC PERU], [899.0], [479.0], [0],
    ),
    caption: [Muestra de 3 registros del dataset preliminar],
  )
]

= Alcance

El proyecto se centrará en la recopilación y análisis de información pública disponible en Falabella Perú para productos pertenecientes a las categorías de laptops, celulares y televisores. La información será obtenida mediante técnicas de web scraping y posteriormente será organizada en un dataset estructurado para su análisis.

/ Dentro del alcance:

- La recopilación de información de productos publicados en las tres categorías seleccionadas.

- La identificación de atributos como nombre del producto, marca, categoría, vendedor, precio normal, precio de oferta y calificación, cuando estos se encuentren disponibles.
- El cálculo del porcentaje de descuento a partir de los precios normal y de oferta. \

- El análisis exploratorio de la distribución de precios y descuentos.

- La comparación de precios y descuentos entre las categorías estudiadas.

- El análisis de las diferencias de precios según marca.

- La comparación entre productos comercializados directamente por Falabella y productos ofrecidos por vendedores externos del marketplace, cuando dicha información pueda ser identificada en los datos recopilados.

- La identificación y análisis de valores atípicos, datos faltantes y posibles duplicados presentes en el dataset.

- La utilización de tablas y visualizaciones para facilitar la interpretación de los resultados.

/ Fuera del alcance:

- El seguimiento de la evolución de los precios a lo largo del tiempo, debido a que el análisis se realizará sobre los datos recopilados durante el periodo definido para el proyecto.

- La determinación de las ventas reales, ingresos o rentabilidad de Falabella o de los vendedores externos, debido a que estas variables no forman parte de la información recopilada.

- La evaluación de la calidad, desempeño o autenticidad de los productos.

- El análisis del comportamiento individual de los consumidores o de sus decisiones de compra.

- La evaluación de costos logísticos, tiempos de entrega, garantías u otros factores que no formen parte del dataset obtenido.

- La realización de inferencias causales sobre las razones por las cuales un vendedor establece determinado precio o descuento.

- La comparación con otras plataformas de comercio electrónico que no formen parte de la fuente de datos definida para el proyecto.

= Fuentes de Datos

La información para el proyecto se extrajo de la web oficial de Falabella Perú: \

#align(center)[
  #link("https://www.falabella.com.pe/falabella-pe")
]

Específicamente, se obtuvo la información de las categorías:

- Laptops: #link("https://www.falabella.com.pe/falabella-pe/category/cat40712/Laptops")[https://www.falabella.com.pe/falabella-pe/category/cat40712/Laptops]

- Televisores: #link("https://www.falabella.com.pe/falabella-pe/category/cat6370551/Televisores-Smart-TV")[https://www.falabella.com.pe/falabella-pe/category/cat6370551/Televisores-Smart-TV]

- Celulares: #link("https://www.falabella.com.pe/falabella-pe/category/cat760706/Celulares-y-Telefonos")[https://www.falabella.com.pe/falabella-pe/category/cat760706/Celulares-y-Telefonos]

La selección de _Falabella Perú_ como fuente principal se justifica por ser una plataforma de comercio electrónico líder en el mercado peruano, lo que garantiza un alto nivel de representación e interés local para un análisis de datos. Al ser un sitio de acceso libre y público, permite la extracción ética y continua de datos sin barreras de autenticación. Asimismo, la estructura HTML de la plataforma presenta plantillas consistentes y paginación organizada, aspectos esenciales para asegurar la factibilidad técnica y la reproducibilidad del web scraping. Finalmente, la plataforma ofrece una amplia variedad y densidad de atributos organizados por producto (como precio normal, precio de oferta, tarjetas de descuento, vendedor o seller, marca y calificación), lo cual brinda el detalle necesario para construir un dataset sólido, diverso y superior a los registros requeridos para el análisis y cumplimiento de los objetivos.

= Estrategia

Para la obtención de datos se utilizó Python y Scrapy, debido a su eficiencia, velocidad y capacidad para extraer de forma estructurada los datos. El proceso del web scraping fue el siguiente:

/ Navegación automatizada:
  Se definieron las URLs estáticas de tres categorías principales de Falabella Perú (Celulares, Laptops y Televisores). Para lograr el volumen de datos requerido, se aplicó un método de paginación inyectando el parámetro `?page={}` en un bucle que _iteró hasta 20 páginas por categoría_.

/ Parseo y Extracción:
  Al descargar el código fuente, la extracción se realizó mediante Selectores CSS, identificando los contenedores principales de las tarjetas de productos (`div.grid-pod`). Dentro de estas, se aislaron atributos específicos para cruzar los distintos niveles de precios (`data-normal-price`, `data-internet-price`, `data-cmr-price`).

/ Transformación y limpieza:
  Para asegurar la calidad de los datos, el script incluye funciones de limpieza durante el mismo proceso de extracción. Los textos extraídos (como el prefijo `Por ` en los vendedores) son depurados, los precios son convertidos directamente a valores numéricos (`float`), y los descuentos especiales (CMR) se transforman en variables categóricas binarias (1/0).

/ Almacenamiento Continuo:
  Los datos estructurados fluyen hacia un archivo .csv mediante un proceso de escritura incremental, garantizando la integridad de la información en tiempo real.

Por otro lado, dado que las plataformas e-commerce suelen implementar medidas contra la extracción automatizada, se desarrollaron medidas de contingencia.

Inicialmente, se revisó el archivos `robots.txt` de Falabella Perú:

#figure(
  image("img/robots.png"),
  caption: [Archivo `robots.txt` de Falabella Perú],
)

Se observa que Falabella permite y facilita la obtención de toda la información pública de productos, categorías y marcas. No obstante, está prohibido extraer datos de:

- El carrito de compras (`/falabella-pe/basket*`)

- Páginas de cuentas de usuario (`/falabella-pe/myaccount*`) \

- El proceso de pago o caja (`/falabella-pe/checkout*`) \

- El historial de pedidos (`/falabella-pe/orders*`) \

- Directorios del servidor (`/cgi-bin/`)

Por lo tanto, la obtención de estos datos queda totalmente fuera del alcance del proyecto.

Adicionalmente, se implementaron los siguientes mecanismos de contingencia:

/ Evasión de Bloqueos por Saturación (AutoThrottle):
  En lugar de hacer múltiples peticiones por segundo, se activó la extensión AutoThrottle de Scrapy. Esta herramienta analiza la latencia del servidor de Falabella y ajusta dinámicamente los tiempos de espera entre peticiones (entre 1 y 5 segundos), simulando un comportamiento humano e impidiendo que nuestra IP sature el sitio web o active los firewalls por límite de peticiones.

/ Headers:
  Se configuró una cabecera `HTTP USER_AGENT` realista que emula un sistema operativo y navegador de un usuario común, mitigando el rechazo por parte de los filtros básicos de seguridad del servidor.

/ Manejo de Caídas de Red (Try-Except y Errbacks):

  Ante la posibilidad de rechazos de conexión, cuelgues del servidor o errores DNS, se implementó una función `errback_handler` en las peticiones. Esta función utiliza bloques `try-except` para atrapar las excepciones, registrar el fallo en un archivo log sin detener la ejecución del script, y trabajar en conjunto con el RetryMiddleware de Scrapy para reintentar la conexión de manera automática.

/ Prevención de Pérdida de Datos:

  Gracias al almacenamiento en flujo de Scrapy y la pipeline orientada a bases de datos (Supabase), un eventual baneo definitivo de IP a mitad del proceso no provocaría la pérdida del dataset; todos los registros raspados hasta el segundo previo a la desconexión quedarían guardados y utilizables.

= Viabilidad

Justificación técnica de la factibilidad del proyecto considerando tiempo, recursos y herramientas.


