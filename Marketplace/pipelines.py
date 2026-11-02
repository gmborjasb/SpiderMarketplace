# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
import os
import psycopg
from dotenv import load_dotenv

load_dotenv()


class CleaningPipeline:
    """
    Pipeline encargado de limpiar y castear los datos crudos extraídos por los spiders.

    Verifica si el spider actual tiene métodos de limpieza específicos (como `_clean_price`)
    y los aplica. Asegura que los precios se conviertan a tipos numéricos (float)
    y los textos queden estandarizados antes de llegar a la base de datos.
    """

    def process_item(self, item, spider):

        if hasattr(spider, "_clean_price"):
            list_price = spider._clean_price(item.list_price)
            internet_price = spider._clean_price(item.internet_price)
            cmr_price = spider._clean_price(item.cmr_price)

            item.list_price = float(list_price) if list_price else None
            item.internet_price = float(internet_price) if internet_price else None
            item.cmr_price = float(cmr_price) if cmr_price else None

        if hasattr(spider, "_clean_seller"):
            item.seller = spider._clean_seller(item.seller)

        if hasattr(spider, "_clean_product"):
            item.product = spider._clean_product(item.product)

        if hasattr(spider, "_clean_brand"):
            item.brand = spider._clean_brand(item.brand)

        return item


class SupabasePipeline:
    """
    Pipeline encargado de persistir los items limpios en una base de datos PostgreSQL (Supabase).

    Maneja la conexión a la base de datos de forma eficiente, creando la tabla
    necesaria al inicio y ejecutando los commits de forma masiva (bulk)
    al finalizar el spider para maximizar el rendimiento.
    """

    def open_spider(self, spider):
        db_url = os.getenv("SUPABASE_DB_URL")

        if not db_url:
            raise ValueError(
                "ValueError: La variable de entorno SUPABASE_DB_URL no está configurada."
            )

        self.conn = psycopg.connect(db_url)
        self.cursor = self.conn.cursor()

        self.cursor.execute(
            """
            CREATE TABLE IF not EXISTS marketplace (
                product TEXT,
                brand VARCHAR(50),
                category VARCHAR(50),
                seller VARCHAR(100),
                list_price DECIMAL,
                internet_price DECIMAL,
                cmr_price DECIMAL,
                scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        self.conn.commit()

    def process_item(self, item, spider):
        if not self.conn:
            return item

        self.cursor.execute(
            "INSERT INTO marketplace (product, brand, category, seller, list_price, internet_price, cmr_price) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (
                item.product,
                item.brand,
                item.category,
                item.seller,
                item.list_price,
                item.internet_price,
                item.cmr_price,
            ),
        )

        return item

    def close_spider(self, spider):
        if self.conn:
            self.conn.commit()
            self.cursor.close()
            self.conn.close()
