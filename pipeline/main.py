import argparse
from pathlib import Path

import analysis
import cleaning
import processing_data
import report
import scraper

ROOT = Path(__file__).resolve().parent.parent
RAW_SNAPSHOT = ROOT / "data" / "raw" / "falabella_raw.csv"
DEFAULT_OUTPUT_DIR = ROOT / "data" / "pipeline"


def pipeline(output_dir=DEFAULT_OUTPUT_DIR, run_scraper=False, compile_pdf=True):
    output_dir = Path(output_dir).resolve()
    data_dir = output_dir / "data"
    img_dir = output_dir / "img"
    data_dir.mkdir(parents=True, exist_ok=True)
    img_dir.mkdir(parents=True, exist_ok=True)

    if run_scraper:
        raw_path = data_dir / "falabella_raw.csv"
        scraper.run(output_path=raw_path)
    else:
        raw_path = RAW_SNAPSHOT

    clean_path = data_dir / "falabella_cleaned.csv"
    removed_path = data_dir / "falabella_removed_rows.csv"
    log_path = data_dir / "cleaning_log.csv"
    processed_path = data_dir / "falabella_processed.csv"

    _, _, log_df = cleaning.run(raw_path=raw_path, clean_path=clean_path, removed_path=removed_path)
    log_df.to_csv(log_path, index=False, encoding="utf-8")

    processing_data.run(clean_path=clean_path, processed_path=processed_path)
    analysis.run(
        raw_path=raw_path,
        clean_path=clean_path,
        removed_path=removed_path,
        log_path=log_path,
        processed_path=processed_path,
        output_dir=output_dir,
    )
    report.run(
        processed_path=processed_path,
        output_dir=output_dir,
        compile_pdf=compile_pdf,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Pipeline reproducible de SpiderMarketplace")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Carpeta base de salida donde se crearán data/, img/ y el reporte (default: data/pipeline).",
    )
    parser.add_argument(
        "--scrape",
        action="store_true",
        help="Ejecuta el scraper antes de limpiar/procesar (guarda el raw en <output-dir>/data/).",
    )
    parser.add_argument(
        "--no-pdf",
        action="store_true",
        help="Omite la compilación del reporte analítico a PDF con Typst.",
    )
    args = parser.parse_args()
    pipeline(
        output_dir=args.output_dir,
        run_scraper=args.scrape,
        compile_pdf=not args.no_pdf,
    )