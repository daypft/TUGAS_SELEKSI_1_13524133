import json
from pathlib import Path
import re

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


SOURCE_URL = "https://www.tvguide.com/listings/"
DATA_DIR = Path("Data Scraping/data/raw")
ROW_SELECTOR = ".c-tvListingsSchedule_row"
PROGRAM_SELECTOR = ".c-tvListingsProgram"
DETAIL_SELECTOR = ".c-tvListingsProgramDetailed"
DETAIL_WAIT_TIME = 1


driver = webdriver.Chrome()
driver.implicitly_wait(DETAIL_WAIT_TIME)

driver.get(SOURCE_URL)

WebDriverWait(driver, 20).until(
    EC.presence_of_all_elements_located((By.CSS_SELECTOR, ROW_SELECTOR))
)

program_details = []
total_channels = len(driver.find_elements(By.CSS_SELECTOR, ROW_SELECTOR))

for channel_index in range(total_channels):
    rows = driver.find_elements(By.CSS_SELECTOR, ROW_SELECTOR)
    row = rows[channel_index]
    channel_name = row.find_element(
        By.CSS_SELECTOR, ".c-tvListingsChannel_name"
    ).text.strip()
    total_programs = len(row.find_elements(By.CSS_SELECTOR, PROGRAM_SELECTOR))

    for program_index in range(total_programs):
        # Elemen diambil ulang karena halaman berubah setelah kartu diklik
        rows = driver.find_elements(By.CSS_SELECTOR, ROW_SELECTOR)
        row = rows[channel_index]
        program = row.find_elements(By.CSS_SELECTOR, PROGRAM_SELECTOR)[program_index]
        program_title = program.find_element(
            By.CSS_SELECTOR, ".c-tvListingsProgram_title"
        ).text.strip()

        driver.execute_script(
            "arguments[0].scrollIntoView({block: 'center'});", program
        )
        driver.execute_script("arguments[0].click();", program)

        detail_elements = driver.find_elements(By.CSS_SELECTOR, DETAIL_SELECTOR)

        if not detail_elements:
            print(f"Detail tidak tersedia: {channel_name} - {program_title}")
            continue

        soup = BeautifulSoup(driver.page_source, "html.parser")
        soup_rows = soup.select(ROW_SELECTOR)
        detail = soup_rows[channel_index].select_one(DETAIL_SELECTOR)

        if not detail:
            print(f"Detail tidak tersedia: {channel_name} - {program_title}")
            continue

        detail_title_element = detail.select_one(".c-tvListingsProgramDetailed-title")
        detail_title = detail_title_element.get_text(strip=True) if detail_title_element else None
        metadata_lists = detail.select(".c-tvListingsProgramDetailed-metadata")
        basic_metadata = metadata_lists[0].select("li") if metadata_lists else []
        episode_metadata = metadata_lists[1].select("li") if len(metadata_lists) > 1 else []
        metadata = [item.get_text(strip=True) for item in basic_metadata]
        episode_text = episode_metadata[0].get_text(strip=True) if episode_metadata else None
        episode_match = re.search(r"S(\d+)\s*E(\d+)", episode_text or "")

        genre_element = detail.select_one(".c-tvListingsProgramDetailed-genres")
        synopsis_element = detail.select_one(".c-tvListingsProgramDetailed-description")

        program_details.append(
            {
                "channel_order": channel_index + 1,
                "channel_name": channel_name,
                "program_order": program_index + 1,
                "program_title": detail_title or program_title,
                "duration_raw": metadata[0] if metadata else None,
                "release_year": next(
                    (item for item in metadata if re.fullmatch(r"(?:19|20)\d{2}", item)),
                    None,
                ),
                "rating": next(
                    (item for item in metadata if re.fullmatch(r"TV-[A-Z0-9-]+|G|PG|PG-13|R", item)),
                    None,
                ),
                "genres_raw": genre_element.get_text(strip=True) if genre_element else None,
                "season_number": int(episode_match.group(1)) if episode_match else None,
                "episode_number": int(episode_match.group(2)) if episode_match else None,
                "episode_title": episode_metadata[1].get_text(strip=True) if len(episode_metadata) > 1 else None,
                "synopsis": synopsis_element.get_text(" ", strip=True).replace("Read More", "").strip() if synopsis_element else None,
            }
        )
        print(f"Detail berhasil: {channel_name} - {program_title}")

output_path = DATA_DIR / "program_details_raw.json"
with output_path.open("w", encoding="utf-8") as file:
    json.dump(program_details, file, indent=2, ensure_ascii=False)

print(f"Detail program berhasil disimpan: {len(program_details)}")
print(f"Lokasi file: {output_path}")

driver.quit()
