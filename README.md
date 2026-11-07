# SpiderMarketplace

Un proyecto de Web Scraping y Análisis Computacional de Datos construido con Python y [Scrapy](https://scrapy.org/), diseñado para extraer, limpiar y analizar datos detallados de productos tecnológicos y precios desde Falabella Perú.

## Integrantes

- Alondra Solange Obregon Carhuavilca
- Axel Roberth Portal Ruiz
- Danna Nickol Gala Vasquez
- Gerald Marcelo Fernando Borjas Bernaola

## Requisitos Previos

- Python 3.10 o superior.
- `uv`

## Instalación

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/gmborjasb/SpiderMarketplace.git
   cd SpiderMarketplace
   ```

2. Instalar las dependencias y sincronizar el entorno:
   ```bash
   uv sync
   ```

## Configuración del Entorno

Este proyecto requiere (de manera opcional) una conexión a una base de datos remota para operar.

1. Crea un archivo `.env` en el directorio raíz del proyecto.
2. Agrega tu URL de la base de datos Supabase al archivo:

```env
SUPABASE_DB_URL=postgresql://postgres:[TU-CONTRASEÑA]@db.[TU-REFERENCIA-SUPABASE].supabase.co:5432/postgres
```

Para habilitar o deshabilitar la base de datos, usa el archivo `settings.py`.

## Uso

Para ejecutar el spider desde el directorio raíz:

```bash
uv run scrapy crawl falabella -O data/raw/falabella_raw.csv
```

Para ejecutar el pipeline completo de limpieza, feature engineering y procesamiento:

```bash
uv run python pipeline/main.py
```

## Estructura del Proyecto

El proyecto se divide en extracción (Scrapy), pipeline reproducible (limpieza y feature engineering), almacenamiento de datos por etapas, notebooks analíticos y documentación.

```text
SpiderMarketplace/
├── docs/                 # Documentación del proyecto, diccionarios de datos e informes (Typst, PDF, PPT)
├── Marketplace/          # Código fuente de Scrapy (spiders, pipelines, items, settings)
├── pipeline/             # Scripts modulares del pipeline (cleaning.py, processing_data.py, main.py)
├── data/                 # Datasets organizados por etapa (raw/, clean/, processed/, analysis/)
├── notebooks/            # Jupyter Notebooks (.ipynb) de validación, limpieza, feature engineering y análisis
├── README.md
└── pyproject.toml
```

## Arquitectura de Datos

### Diccionario de Datos (Dataset Crudo)

| Columna | Tipo | Descripción |
|---|---|---|
| `product` | `str` | Nombre completo del producto tal como aparece en la tarjeta de Falabella. |
| `brand` | `str` | Marca del producto en mayúsculas (ej. APPLE, SAMSUNG, XIAOMI). |
| `category` | `str` | Categoría de la URL fuente: `phones`, `laptops` o `tvs`. |
| `seller` | `str` | Nombre del vendedor en el marketplace (ej. "FALABELLA", "TOTTUS"). Se elimina el prefijo "Por" automáticamente. |
| `list_price` | `float` | **Precio de lista / referencial** -- el precio sin descuento mostrado tachado en la tarjeta. Corresponde al atributo HTML `data-normal-price`. |
| `internet_price` | `float` | **Precio de venta online** -- precio vigente con descuento general o de evento disponible para todos los compradores. Corresponde al atributo HTML `data-internet-price` o `data-event-price`. |

### Jerarquía de Precios Extraída en Falabella

Falabella muestra niveles de precio en cada tarjeta de producto; extraemos los dos precios de alcance general que cumplen el umbral de completitud (< 10% de valores nulos):

```
+---------------------------------------------------------+
|  S/ 5,999   <- list_price        (tachado, gris claro)  |
|  S/ 5,699   <- internet_price    (texto normal, negro)  |
+---------------------------------------------------------+
```

### Pipelines de Extracción
Los datos fluyen a través de dos pipelines en Scrapy antes de finalizar:
1. **CleaningPipeline**: Limpia las cadenas de texto en bruto, estandariza a mayúsculas, elimina comas/espacios y convierte los precios a representaciones numéricas (`float`).
2. **SupabasePipeline**: Abre una conexión a Postgres y realiza operaciones `INSERT` al finalizar la ejecución del spider.

Para habilitar o deshabilitar los pipelines, usa el archivo `settings.py`.
