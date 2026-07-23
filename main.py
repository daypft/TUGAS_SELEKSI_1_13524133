from datetime import datetime
import json
import os
import shutil
import subprocess
import sys
from zoneinfo import ZoneInfo


os.makedirs("Data Scraping/data/raw", exist_ok=True)
os.makedirs("Data Scraping/data/csv", exist_ok=True)
os.makedirs("Data Scraping/data/cleaned", exist_ok=True)

skip_scraping = "--skip-scraping" in sys.argv
skip_storing = "--skip-storing" in sys.argv
batch_id = None
ready_file = "Data Scraping/data/raw/pipeline_ready.json"

if not skip_scraping:
    if os.path.exists(ready_file):
        os.remove(ready_file)

    scrape_time = datetime.now(ZoneInfo("Asia/Jakarta"))
    batch_id = scrape_time.strftime("%Y-%m-%d_%H-%M-%S")

    # Urutan scraper
    print("Menjalankan scrape_channel.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_channel.py"], check=True)

    print("Menjalankan scrape_schedule.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_schedule.py"], check=True)

    print("Menjalankan scrape_program.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_program.py"], check=True)

    print("Menjalankan scrape_sports.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_sports.py"], check=True)

    print("Menjalankan scrape_movies.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_movies.py"], check=True)

    print("Menjalankan scrape_family.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_family.py"], check=True)

    print("Menjalankan scrape_news.py")
    subprocess.run([sys.executable, "Data Scraping/src/scrape_news.py"], check=True)

    print("Menjalankan json_to_csv.py")
    subprocess.run([sys.executable, "Data Scraping/src/json_to_csv.py"], check=True)

    metadata = {
        "broadcast_date": scrape_time.date().isoformat(),
        "scraped_at": scrape_time.isoformat(),
        "batch_id": batch_id,
    }

    with open("Data Scraping/data/raw/scrape_metadata.json", "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    with open(ready_file, "w", encoding="utf-8") as f:
        json.dump({"batch_id": batch_id, "scraped_at": scrape_time.isoformat()}, f, indent=2)

if skip_scraping and not os.path.exists(ready_file):
    raise RuntimeError(
        "Raw data belum lengkap. Jalankan main.py tanpa --skip-scraping terlebih dahulu."
    )

print("Menjalankan clean_data.py")
subprocess.run([sys.executable, "Data Scraping/src/clean_data.py"], check=True)

if batch_id is not None:
    shutil.copytree(
        "Data Scraping/data/raw",
        f"Data Scraping/data/batches/{batch_id}/raw",
    )
    shutil.copytree(
        "Data Scraping/data/csv",
        f"Data Scraping/data/batches/{batch_id}/csv",
    )
    shutil.copytree(
        "Data Scraping/data/cleaned",
        f"Data Scraping/data/batches/{batch_id}/cleaned",
    )
    print(f"Batch tersimpan: Data Scraping/data/batches/{batch_id}")

if not skip_storing:
    print("Menjalankan storing.py")
    subprocess.run([sys.executable, "Data Storing/src/storing.py"], check=True)

    print("Menjalankan generate_dw.py")
    subprocess.run([sys.executable, "Data Warehous/src/generate_dw.py"], check=True)

print("Pipeline TV Guide selesai.")
