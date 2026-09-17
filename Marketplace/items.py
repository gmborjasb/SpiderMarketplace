# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

from dataclasses import dataclass
from typing import Optional

import scrapy


@dataclass
class MarketplaceItem:
    brand: Optional[str] = None
    seller: Optional[str] = None
    title: Optional[str] = None
    old_price: Optional[str] = None
    regular_price: Optional[str] = None
    special_price: Optional[str] = None
