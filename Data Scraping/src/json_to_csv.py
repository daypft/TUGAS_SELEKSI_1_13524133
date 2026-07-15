import csv
import json

with open("Data Scraping/data/raw/channels_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/channels_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(file, fieldnames=["channel_order", "channel_name"])
    writer.writeheader()
    writer.writerows(data)


with open("Data Scraping/data/raw/schedules_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/schedules_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "channel_order",
            "channel_name",
            "program_order",
            "program_title",
            "start_time_raw",
            "end_time_raw",
            "is_new",
            "is_live",
        ],
    )
    writer.writeheader()
    writer.writerows(data)


with open("Data Scraping/data/raw/program_details_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/program_details_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "channel_order",
            "channel_name",
            "program_order",
            "program_title",
            "duration_raw",
            "release_year",
            "rating",
            "genres_raw",
            "season_number",
            "episode_number",
            "episode_title",
            "synopsis",
        ],
    )
    writer.writeheader()
    writer.writerows(data)


with open("Data Scraping/data/raw/sports_schedules_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/sports_schedules_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "channel_order",
            "channel_name",
            "program_order",
            "program_title",
            "start_time_raw",
            "end_time_raw",
            "is_new",
            "is_live",
        ],
    )
    writer.writeheader()
    writer.writerows(data)


with open("Data Scraping/data/raw/movies_schedules_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/movies_schedules_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "channel_order",
            "channel_name",
            "program_order",
            "program_title",
            "start_time_raw",
            "end_time_raw",
            "is_new",
            "is_live",
        ],
    )
    writer.writeheader()
    writer.writerows(data)


with open("Data Scraping/data/raw/family_schedules_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/family_schedules_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "channel_order",
            "channel_name",
            "program_order",
            "program_title",
            "start_time_raw",
            "end_time_raw",
            "is_new",
            "is_live",
        ],
    )
    writer.writeheader()
    writer.writerows(data)


with open("Data Scraping/data/raw/news_schedules_raw.json", encoding="utf-8") as file:
    data = json.load(file)

with open("Data Scraping/data/csv/news_schedules_raw.csv", mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "channel_order",
            "channel_name",
            "program_order",
            "program_title",
            "start_time_raw",
            "end_time_raw",
            "is_new",
            "is_live",
        ],
    )
    writer.writeheader()
    writer.writerows(data)
