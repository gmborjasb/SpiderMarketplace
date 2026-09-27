import scrapy
import re

from Marketplace.items import MarketplaceItem
from twisted.internet.error import DNSLookupError
from twisted.internet.error import TimeoutError, TCPTimedOutError
from scrapy.spidermiddlewares.httperror import HttpError


class FalabellaSpider(scrapy.Spider):
    """
    Spider diseñado para extraer productos y precios de Falabella Perú.

    Navega dinámicamente a través de las categorías definidas en `custom_urls`,
    maneja la paginación y delega la extracción de datos de las tarjetas de
    productos al método `parse`.
    """

    name = "falabella"
    allowed_domains = ["falabella.com.pe"]
    custom_urls = [
        {
            "url": "https://www.falabella.com.pe/falabella-pe/category/cat760706/Celulares-y-Telefonos",
            "category": "phones",
            "last_page": 20,  # default : 170
        },
        {
            "url": "https://www.falabella.com.pe/falabella-pe/category/cat40712/Laptops",
            "category": "laptops",
            "last_page": 20,  # default : 200
        },
        {
            "url": "https://www.falabella.com.pe/falabella-pe/category/cat210477/TV-Televisores",
            "category": "tvs",
            "last_page": 20,  # default : 200
        },
    ]

    async def start(self):
        """
        Generador asíncrono inicial.

        Itera sobre las URLs base de las categorías, calcula la paginación
        hasta el límite establecido (`last_page`) y lanza peticiones HTTP.
        Inyecta la categoría del producto en el parámetro `meta` de la petición.
        """
        for url_dict in self.custom_urls:
            start_url = url_dict["url"]
            category = url_dict["category"]
            last_page = url_dict["last_page"]

            base_url = start_url + "?page={}"

            urls = [base_url.format(idx) for idx in range(1, last_page + 1)]

            for url in urls:
                yield scrapy.Request(
                    url=url,
                    callback=self.parse,
                    errback=self.errback_handler,
                    meta={"category": category},
                )

    def errback_handler(self, failure):
        """
        Manejo de errores explícito para conexiones fallidas y códigos HTTP de error.
        """
        request_url = failure.request.url
        self.logger.error(
            f"Se detectó un fallo intentando raspar la URL: {request_url}"
        )

        try:
            failure.raiseException()

        except HttpError as e:
            response = failure.value.response
            self.logger.error(
                f"HttpError: Falabella devolvió un estado {response.status}. Posible bloqueo o página inexistente."
            )

        except TimeoutError:
            self.logger.error("TimeoutError: El servidor tardó demasiado en responder.")
        except TCPTimedOutError:
            self.logger.error("TCPTimedOutError: Conexión fallida por Timeout en TCP.")
        except DNSLookupError:
            self.logger.error(
                "DNSLookupError: Fallo de red, no se pudo resolver el dominio."
            )
        except Exception as e:
            self.logger.error(f"Error general capturado: {repr(e)}")

    def parse(self, response):
        """
        Callback principal que procesa la respuesta HTML de cada página.

        Busca todas las tarjetas de producto (`div.grid-pod`) en el HTML,
        extrae los datos crudos (marca, nombre, vendedor) y delega la
        lógica de precios a `_extract_prices`. Finalmente, emite
        objetos `MarketplaceItem` listos para los pipelines.
        """
        items = response.css("div.grid-pod")

        for item in items:
            marketplace_item = MarketplaceItem()

            category = response.meta.get("category")
            marketplace_item.category = category

            detail = item.css("div.pod-details")

            if not detail:
                continue

            brand = detail.css("b.pod-title::text").get()
            product = detail.css("b.pod-subTitle::text").get()
            seller = detail.css("b.pod-sellerText::text").get()

            marketplace_item.brand = brand
            marketplace_item.product = product
            marketplace_item.seller = seller

            regular_price, special_price, has_cmr = self._extract_prices(item)
            marketplace_item.regular_price = regular_price
            marketplace_item.special_price = special_price
            marketplace_item.has_cmr_discount = has_cmr

            yield marketplace_item

    def _extract_prices(self, card):
        """Extrae el precio regular, precio especial y evalúa la presencia de CMR.

        Falabella utiliza cuatro posibles atributos de datos en los elementos ``<li>``
        dentro de ``ol.pod-prices``:

        * ``data-normal-price``   -- precio de lista / referencial (tachado)
        * ``data-internet-price`` -- precio con descuento online (texto gris/negro)
        * ``data-event-price``    -- precio promocional / evento (texto gris/negro)
        * ``data-cmr-price``      -- precio exclusivo con tarjeta CMR Falabella (texto rojo)

        Devuelve valores float sin comas separadoras de miles para los precios,
        y 1 o 0 para has_cmr_discount dependiendo si data-cmr-price está presente.
        """
        prices_ol = card.css("ol.pod-prices")

        if not prices_ol:
            return None, None, 0

        regular_price = prices_ol.css(
            "li[data-normal-price]::attr(data-normal-price)"
        ).get()

        special_price = prices_ol.css(
            "li[data-internet-price]::attr(data-internet-price)"
        ).get()
        if special_price is None:
            special_price = prices_ol.css(
                "li[data-event-price]::attr(data-event-price)"
            ).get()

        cmr_price_raw = prices_ol.css("li[data-cmr-price]::attr(data-cmr-price)").get()

        has_cmr_discount = 1 if cmr_price_raw else 0

        return (
            regular_price,
            special_price,
            has_cmr_discount,
        )

    # Cleaning methods
    def _clean_price(self, value):
        """Extrae el primer precio válido (mínimo) y elimina las comas separadoras."""
        if not value:
            return None

        # Busca todos los patrones de precio (ej. "999", "3,549", "10,999")
        # Esto separa correctamente rangos fusionados como "3,549,3,819" -> ["3,549", "3,819"]
        matches = re.findall(r'\d{1,3}(?:,\d{3})*(?:\.\d+)?', value)
        
        if matches:
            # Tomamos el primer precio del rango (el "Desde") y le quitamos las comas
            first_price = matches[0].replace(",", "")
            return first_price
            
        return None

    def _clean_seller(self, value):
        """Limpia el nombre del vendedor (ej. remueve el prefijo 'Por ')."""
        if not value:
            return None

        value = value.strip()

        if value.upper().startswith("POR "):
            value = value[4:].strip()

        value = value.upper()

        return value

    def _clean_product(self, value):
        """Convierte el nombre del producto a mayúsculas para mantener consistencia."""
        if not value:
            return None

        value = value.upper()

        return value
