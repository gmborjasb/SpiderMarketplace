# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
import psycopg
import os
from itemadapter import ItemAdapter


class SupabasePipeline:
    def open_spider(self, spider):
        db_url = os.getenv("SUPABASE_DB_URL")

        self.conn = psycopg.connect(db_url)
        self.cursor = self.conn.cursor()

        self.cursor.execute(
            """
            CREATE TABLE IF not EXISTS marketplace (
                marketplace VARCHAR(50),
                brand VARCHAR(50),
                seller VARCHAR(50),
                title TEXT,
                old_price VARCHAR(10),
                regular_price VARCHAR(10),
                special_price VARCHAR(10), 
                scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        self.conn.commit()

    def process_item(self, item, spider):
        if not self.conn:
            return item

        self.cursor.execute(
            "INSERT INTO marketplace (marketplace, brand, seller, title, old_price, regular_price, special_price) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (
                spider.name,
                item.brand,
                item.seller,
                item.title,
                item.old_price,
                item.regular_price,
                item.special_price,
            ),
        )
        self.conn.commit()

        return item

    def close_spider(self, spider):
        self.cursor.close()
        self.conn.close()
