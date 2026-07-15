import json
from pathlib import Path
import re

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


SOURCE_URL = "https://www.tvguide.com/listings/"
DATA_DIR = Path("Data Scraping/data/raw")
BUTTON_SELECTOR = ".c-tvListingsSettingsChannels button"
ROW_SELECTOR = ".c-tvListingsSchedule_row"
PROGRAM_SELECTOR = ".c-tvListingsProgram"
TIME_PATTERN = re.compile(r"(\d{1,2}:\d{2}\s*[AP]M)\s*-\s*(\d{1,2}:\d{2}\s*[AP]M)")


driver = webdriver.Chrome()
driver.get(SOURCE_URL)

WebDriverWait(driver, 20).until(
    EC.presence_of_all_elements_located((By.CSS_SELECTOR, BUTTON_SELECTOR))
)

buttons = driver.find_elements(By.CSS_SELECTOR, BUTTON_SELECTOR)
for button in buttons:
    if button.text.strip() == "News":
        driver.execute_script("arguments[0].click();", button)

WebDriverWait(driver, 20).until(
    EC.presence_of_element_located((
        By.XPATH,
        "//button[contains(@class, 'c-tvlistingsButton-isActive') and .//span[normalize-space()='News']]",
    ))
)
rows = WebDriverWait(driver, 20).until(
    EC.presence_of_all_elements_located((By.CSS_SELECTOR, ROW_SELECTOR))
)

news_schedules = []
for channel_order, row in enumerate(rows, start=1):
    channel_name = row.find_element(
        By.CSS_SELECTOR, ".c-tvListingsChannel_name"
    ).text.strip()
    programs = row.find_elements(By.CSS_SELECTOR, PROGRAM_SELECTOR)

    for program_order, program in enumerate(programs, start=1):
        program_title = program.find_element(
            By.CSS_SELECTOR, ".c-tvListingsProgram_title"
        ).text.strip()
        program_duration = program.find_element(
            By.CSS_SELECTOR, ".c-tvListingsProgram_duration"
        ).text
        time_match = TIME_PATTERN.search(program_duration)

        news_schedules.append(
            {
                "channel_order": channel_order,
                "channel_name": channel_name,
                "program_order": program_order,
                "program_title": program_title,
                "start_time_raw": time_match.group(1) if time_match else None,
                "end_time_raw": time_match.group(2) if time_match else None,
                "is_new": "NEW" in program_duration.upper(),
                "is_live": "LIVE" in program_duration.upper(),
            }
        )

output_path = DATA_DIR / "news_schedules_raw.json"
with output_path.open("w", encoding="utf-8") as file:
    json.dump(news_schedules, file, indent=2, ensure_ascii=False)

print(f"Jadwal News berhasil disimpan: {len(news_schedules)}")
print(f"Lokasi file: {output_path}")

driver.quit()
