# SpiderMarketplace

Un proyecto de Web Scraping y Análisis Computacional de Datos construido con Python y [Scrapy](https://scrapy.org/), diseñado para extraer, limpiar y analizar datos detallados de productos tecnológicos y precios desde Falabella Perú.

## Integrantes

- Alondra Solange Obregon Carhuavilca
- Axel Roberth Portal Ruiz
- Danna Nickol Gala Vasquez
- Gerald Marcelo Fernando Borjas Bernaola

## Requisitos Previos

- Python 3.13 o superior (`requires-python = ">=3.13"`).
- `uv` (o `pip` con `Requirements.txt`).
- `Typst` (necesario solo para compilar `docs/*.typ` y el reporte PDF del pipeline).

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
   Alternativamente, sin `uv`:
   ```bash
   pip install -r Requirements.txt
   ```

## Configuración del Entorno

Este proyecto puede operar de forma 100 % local con CSV (configuración activa por defecto). La conexión a Supabase en `Marketplace/settings.py` permanece desactivada.

Si deseas habilitar la carga hacia PostgreSQL/Supabase:
1. Crea un archivo `.env` en el directorio raíz del proyecto.
2. Agrega tu cadena de conexión:
   ```env
   SUPABASE_DB_URL=postgresql://postgres:[TU-CONTRASEÑA]@db.[TU-REFERENCIA-SUPABASE].supabase.co:5432/postgres
   ```
3. Descomenta `Marketplace.pipelines.SupabasePipeline` en `Marketplace/settings.py`.

## Uso

Para ejecutar solo el spider desde el directorio raíz:
```bash
uv run scrapy crawl falabella -O data/raw/falabella_raw.csv
```

Para ejecutar el pipeline completo (limpieza, feature engineering, análisis estadístico/visual y reporte automático):
```bash
uv run python pipeline/main.py
```

Opciones disponibles en `pipeline/main.py`:
- `--output-dir <ruta>`: carpeta de salida (por defecto `data/pipeline/`).
- `--scrape`: ejecuta el spider `falabella` antes de iniciar la limpieza.
- `--no-pdf`: omite la compilación de `reporte_analitico.pdf`.

Para compilar la documentación y el informe principal en `docs/` (desde la raíz del repositorio):
```bash
typst compile --root . docs/report_02.typ
typst compile docs/data_dictionary.typ
typst compile docs/data_dictionary_final.typ
```

## Estructura del Proyecto

```text
SpiderMarketplace/
├── Marketplace/             # Código fuente de Scrapy (spiders, pipelines, items, settings)
├── pipeline/                # Módulos del pipeline: scraper.py, cleaning.py, processing_data.py, analysis.py, report.py, main.py
├── data/
│   ├── raw/                 # Captura cruda del spider (falabella_raw.csv)
│   ├── clean/               # Dataset limpio, filas removidas y log de limpieza
│   ├── processed/           # Dataset procesado con 16 variables y umbrales de terciles
│   ├── analysis/            # Tablas resumen de pruebas estadísticas y rankings
│   └── pipeline/            # Salida unificada de pipeline/main.py (data/, img/, reporte_analitico.pdf)
├── notebooks/               # Notebooks 01_Validation.ipynb al 05_analisis_vendedores_marcas.ipynb
├── docs/                    # Informes (report_01.typ, report_02.typ/.pdf), diccionarios de datos y recursos gráficos
├── pyproject.toml           # Configuración del proyecto y dependencias (uv)
├── Requirements.txt         # Dependencias equivalentes para pip
├── uv.lock                  # Lockfile de uv
├── scrapy.cfg               # Configuración del proyecto Scrapy
└── README.md
```

## Arquitectura de Datos

### Diccionario de Datos (Dataset Crudo)

| Columna | Tipo | Descripción |
|---|---|---|
| `product` | `str` | Nombre completo del producto tal como aparece en la tarjeta de Falabella. |
| `brand` | `str` | Marca del producto en mayúsculas (ej. `APPLE`, `SAMSUNG`, `XIAOMI`). |
| `category` | `str` | Categoría de la URL fuente: `phones`, `laptops` o `tvs`. |
| `seller` | `str` | Nombre del vendedor en el marketplace (ej. `FALABELLA`, `TOTTUS`). Se elimina el prefijo `"Por"` automáticamente. |
| `list_price` | `float` | **Precio de lista / referencial** — precio sin descuento mostrado tachado en la tarjeta (`data-normal-price`). |
| `internet_price` | `float` | **Precio de venta online** — precio vigente con descuento general disponible para todos los compradores (`data-internet-price` o `data-event-price`). |

Los diccionarios completos y el informe de análisis están disponibles en `docs/`:
- Diccionario crudo: [docs/data_dictionary.pdf](docs/data_dictionary.pdf)
- Diccionario final procesado: [docs/data_dictionary_final.pdf](docs/data_dictionary_final.pdf)
- Informe final (Parte II): [docs/report_02.pdf](docs/report_02.pdf)

### Jerarquía de Precios Extraída en Falabella

Falabella muestra niveles de precio en cada tarjeta de producto; extraemos los dos precios de alcance general que cumplen el umbral de completitud (< 10 % de valores nulos):

```text
+---------------------------------------------------------+
|  S/ 5,999   <- list_price        (tachado, gris claro)  |
|  S/ 5,699   <- internet_price    (texto normal, negro)  |
+---------------------------------------------------------+
```

### Pipelines de Extracción (Scrapy)
Los datos crudos pasan por los pipelines configurados en `Marketplace/settings.py`:
1. **CleaningPipeline** (activo): limpia cadenas de texto, estandariza a mayúsculas, elimina comas/espacios y convierte precios a `float`.
2. **SupabasePipeline** (opcional, desactivado por defecto): inserta registros en PostgreSQL al finalizar la ejecución del spider.