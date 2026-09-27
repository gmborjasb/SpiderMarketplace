# SpiderMarketplace

Un proyecto de Web Scraping construido con Python y [Scrapy](https://scrapy.org/), diseñado para extraer datos detallados de productos y precios desde sitios retail de comercio electrónico (Falabella).

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

Para ejecutar los spiders, simplemente usa los comandos estándar de la CLI de Scrapy desde el directorio raíz.

Ejecutar el spider de **Falabella**:
```bash
scrapy crawl falabella
```
 o 
```bash
uv run scrapy crawl falabella
```
 o
```bash
uv run scrapy crawl falabella -o data/falabella.csv
```
para exportar los datos a un archivo `.csv`, `-o` para incrementar el dataset 

o 
 ```bash
uv run scrapy crawl falabella -O data/falabella.csv
```
para exportar los datos a un archivo `.csv`, `-O` para iniciar un dataset nuevo

## Estructura del Proyecto

El proyecto se divide en cuatro partes principales: extracción (Scrapy), almacenamiento de datos, análisis de datos y documentación.

```text
SpiderMarketplace/
│── docs/                 # Documentación del proyecto e informes (Typst, PDF)
│
├── Marketplace/         # Código fuente de Scrapy (spiders, pipelines, items, settings)
│
├── data/                # Datasets (Ej. data/falabella.csv)
│
├── notebooks/           # Jupyter Notebooks (.ipynb) con el Análisis de Datos(solo implementado la validacion)
│
├── README.md
└── pyproject.toml
```


## Arquitectura de Datos

### Diccionario de Datos

| Columna | Tipo | Descripcion |
|---|---|---|
| `product` | `str` | Nombre completo del producto tal como aparece en la tarjeta de Falabella. |
| `brand` | `str` | Marca del producto (ej. APPLE, SAMSUNG, XIAOMI). |
| `category` | `str` | Categoria de la URL fuente: `phones`, `laptops` o `tvs`. |
| `seller` | `str` | Nombre del vendedor en el marketplace (ej. "FALABELLA", "MARKETCELLPERU"). Se elimina el prefijo "Por" automaticamente. |
| `regular_price` | `float` | **Precio de lista / referencial** -- el precio mas alto, mostrado tachado en la tarjeta. Corresponde al atributo HTML `data-normal-price`. |
| `special_price` | `float` | **Precio con descuento general** -- precio intermedio disponible para todos los compradores. Se muestra en texto gris/negro. Corresponde al atributo HTML `data-internet-price` o `data-event-price`. |
| `has_cmr_discount`| `int` | **Indicador de Descuento CMR** -- valor booleano/entero (`1` o `0`). Indica si el producto cuenta con un precio de descuento exclusivo con tarjeta CMR / Banco Falabella. |

### Jerarquia de Precios de Falabella

Falabella muestra multiples niveles de precio en cada tarjeta de producto. Nosotros extraemos los 2 principales e indicamos si existe un tercer descuento:

```
+---------------------------------------------------------+
|  S/ 5,999   <- regular_price     (tachado, gris claro)  |
|  S/ 5,699   <- special_price     (texto normal, negro)  |
|  S/ 5,499   <- has_cmr_discount  (es 1 si existe)       |
+---------------------------------------------------------+
```

### Pipelines
Los datos fluyen a través de dos pipelines principales antes de finalizar:
1. **CleaningPipeline**: Limpia las cadenas de texto en bruto, elimina comas/espacios y convierte los textos a representaciones numéricas (`float`).
2. **SupabasePipeline**: Abre una conexión a Postgres y realiza operaciones `INSERT` al finalizar la ejecución del spider.

Para habilitar o deshabilitar los pipelines, usa el archivo `settings.py`.
