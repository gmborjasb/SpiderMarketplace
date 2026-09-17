import scrapy
import re

from Marketplace.items import MarketplaceItem


class FalabellaSpider(scrapy.Spider):
    name = "falabella"
    allowed_domains = ["falabella.com.pe"]
    start_url = "https://www.falabella.com.pe/falabella-pe/category/cat760706/Celulares-y-Telefonos"

    last_page = 2

    async def start(self):
        base_url = self.start_url + "?page={}"

        urls = [base_url.format(idx) for idx in range(1, self.last_page + 1)]

        for url in urls:
            yield scrapy.Request(url=url, callback=self.parse)

    def parse(self, response):
        items = response.css("div.grid-pod")

        for item in items:
            marketplaceItem = MarketplaceItem()

            detail = item.css("div.pod-details")

            if not detail:
                continue

            brand = detail.css("b.pod-title::text").get()
            product = detail.css("b.pod-subTitle::text").get()
            seller = detail.css("b.pod-sellerText::text").get()

            marketplaceItem.brand = brand
            marketplaceItem.product = product
            marketplaceItem.seller = seller

            prices = item.css("ol.pod-prices")

            if not prices:
                yield marketplaceItem
                continue

            old_price = prices.css(
                "li[data-normal-price]::attr(data-normal-price)"
            ).get()
            regular_price = prices.css(
                "li[data-event-price]::attr(data-event-price)"
            ).get()
            special_price = prices.css("li[data-cmr-price]::attr(data-cmr-price)").get()

            marketplaceItem.old_price = old_price
            marketplaceItem.regular_price = regular_price
            marketplaceItem.special_price = special_price

            yield marketplaceItem

    # Cleaning methods
    def _clean_price(self, value):
        if not value:
            return None

        value = value.replace(",", "").strip()

        return value if value else None

    def _clean_seller(self, value):
        if not value:
            return None

        value = value.strip()

        if value.upper().startswith("POR "):
            value = value[4:].strip()

        value = value.upper()

        return value

    def _clean_product(self, value):
        if not value:
            return None

        value = value.upper()

        return value
