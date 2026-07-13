from datetime import datetime, timezone
import json
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


SOURCE_URL = "https://www.tvguide.com/listings/"
DATA_DIR = Path("Data Scraping/data/raw")
SCREENSHOT_DIR = Path("Data Scraping/screenshot")
ROW_SELECTOR = ".c-tvListingsSchedule_row"
PROGRAM_SELECTOR = ".c-tvListingsProgram"
MAX_SCROLLS = 5


chrome_options = webdriver.ChromeOptions()
# chrome_options.add_argument("--window-size=1366,768")
driver = webdriver.Chrome(options=chrome_options)


driver.get(SOURCE_URL)


listing_rows = WebDriverWait(driver, 20).until(
    EC.presence_of_all_elements_located((By.CSS_SELECTOR, ROW_SELECTOR))
)


for i in range(MAX_SCROLLS):
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")

driver.execute_script("window.scrollTo(0, 0);")
listing_rows = driver.find_elements(By.CSS_SELECTOR, ROW_SELECTOR)


channels_raw = []
schedules_raw = []
program_details_raw = []
scraped_at_utc = datetime.now(timezone.utc).isoformat()


total_channels = len(listing_rows)

for channel_index in range(total_channels):
    listing_rows = driver.find_elements(By.CSS_SELECTOR, ROW_SELECTOR)
    row = listing_rows[channel_index]

    channel_name = row.find_element(
        By.CSS_SELECTOR,
        ".c-tvListingsChannel_name",
    ).text

    logo_elements = row.find_elements(By.CSS_SELECTOR, ".c-tvListingsChannel img")
    channel_logo_url = logo_elements[0].get_attribute("src") if logo_elements else None

    channels_raw.append(
        {
            "channel_order": channel_index + 1,
            "channel_name": channel_name,
            "channel_logo_url": channel_logo_url,
            "scraped_at_utc": scraped_at_utc,
        }
    )

    program_elements = row.find_elements(By.CSS_SELECTOR, PROGRAM_SELECTOR)
    total_programs = len(program_elements)
    print(f"\nChannel {channel_index + 1}: {channel_name} ({total_programs} program)")

    for program_index in range(total_programs):
        listing_rows = driver.find_elements(By.CSS_SELECTOR, ROW_SELECTOR)
        row = listing_rows[channel_index]
        program_elements = row.find_elements(By.CSS_SELECTOR, PROGRAM_SELECTOR)
        program_element = program_elements[program_index]

        program_text_before_click = program_element.text
        program_html_before_click = program_element.get_attribute("outerHTML")
        row_text_before_click = row.text

        link_elements = program_element.find_elements(By.CSS_SELECTOR, "a[href]")
        detail_url = link_elements[0].get_attribute("href") if link_elements else None

        schedules_raw.append(
            {
                "channel_order": channel_index + 1,
                "channel_name": channel_name,
                "program_order": program_index + 1,
                "program_text": program_text_before_click,
                "detail_url": detail_url,
                "scraped_at_utc": scraped_at_utc,
            }
        )

        driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", program_element)
        driver.execute_script("arguments[0].click();", program_element)

        program_details_raw.append(
            {
                "channel_order": channel_index + 1,
                "channel_name": channel_name,
                "program_order": program_index + 1,
                "program_text_before_click": program_text_before_click,
                "program_html_before_click": program_html_before_click,
                "expanded_row_text": row.text,
                "expanded_row_html": row.get_attribute("outerHTML"),
                "row_text_changed_after_click": row.text != row_text_before_click,
                "scraped_at_utc": scraped_at_utc,
            }
        )

        print(f"- Program {program_index + 1}: {program_text_before_click}")


with (DATA_DIR / "channels_raw.json").open("w", encoding="utf-8") as file:
    json.dump(channels_raw, file, indent=2, ensure_ascii=False)

with (DATA_DIR / "schedules_raw.json").open("w", encoding="utf-8") as file:
    json.dump(schedules_raw, file, indent=2, ensure_ascii=False)

with (DATA_DIR / "program_details_raw.json").open("w", encoding="utf-8") as file:
    json.dump(program_details_raw, file, indent=2, ensure_ascii=False)

print(f"\nChannel raw: {len(channels_raw)}")
print(f"Schedule raw: {len(schedules_raw)}")
print(f"Program detail raw: {len(program_details_raw)}")


driver.quit()
