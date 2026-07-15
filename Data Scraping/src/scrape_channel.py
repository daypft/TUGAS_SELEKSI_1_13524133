import json
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


SOURCE_URL = "https://www.tvguide.com/listings/"
DATA_DIR = Path("Data Scraping/data/raw")
ROW_SELECTOR = ".c-tvListingsSchedule_row"


driver = webdriver.Chrome()

driver.get(SOURCE_URL)

rows = WebDriverWait(driver, 20).until(
    EC.presence_of_all_elements_located((By.CSS_SELECTOR, ROW_SELECTOR))
)

channels = []

for channel_order, row in enumerate(rows, start=1):
    channel_name = row.find_element(
        By.CSS_SELECTOR, ".c-tvListingsChannel_name"
    ).text.strip()

    if channel_name:
        channels.append(
            {
                "channel_order": channel_order,
                "channel_name": channel_name,
            }
        )

output_path = DATA_DIR / "channels_raw.json"
with output_path.open("w", encoding="utf-8") as file:
    json.dump(channels, file, indent=2, ensure_ascii=False)

print(f"Channel berhasil disimpan: {len(channels)}")
print(f"Lokasi file: {output_path}")

driver.quit()
