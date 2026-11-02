import scraper
import cleaning
import processing_data
import report


def pipeline():

    scraper.run()

    cleaning.run()

    processing_data.run()

    report.run()


if __name__ == "__main__":
    pipeline()
