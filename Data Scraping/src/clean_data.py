from datetime import datetime
import json
import os

import pandas as pd


channels = pd.read_csv("Data Scraping/data/csv/channels_raw.csv", dtype="string")
schedules = pd.read_csv("Data Scraping/data/csv/schedules_raw.csv", dtype="string")
details = pd.read_csv("Data Scraping/data/csv/program_details_raw.csv", dtype="string")
sports = pd.read_csv("Data Scraping/data/csv/sports_schedules_raw.csv", dtype="string")
movies = pd.read_csv("Data Scraping/data/csv/movies_schedules_raw.csv", dtype="string")
family = pd.read_csv("Data Scraping/data/csv/family_schedules_raw.csv", dtype="string")
news = pd.read_csv("Data Scraping/data/csv/news_schedules_raw.csv", dtype="string")

# Samakan spasi dan ubah placeholder kosong menjadi NULL
all_data = [channels, schedules, details, sports, movies, family, news]
empty_values = ["", "-", "N/A", "n/a", "NA", "na", "None", "none", "NULL", "null"]
raw_schedule_count = len(schedules)

for dataframe in all_data:
    for column in dataframe.columns:
        dataframe[column] = dataframe[column].str.strip().str.replace(r"\s+", " ", regex=True)
        dataframe[column] = dataframe[column].replace(empty_values, pd.NA)

# Catat data jadwal yang tidak dapat dikonversi ke format waktu PostgreSQL
invalid_time_count = (
    pd.to_datetime(schedules["start_time_raw"], format="%I:%M %p", errors="coerce").isna()
    | pd.to_datetime(schedules["end_time_raw"], format="%I:%M %p", errors="coerce").isna()
).sum()

channels["channel_key"] = channels["channel_name"].str.casefold()
schedules["channel_key"] = schedules["channel_name"].str.casefold()
unmatched_channel_count = (~schedules["channel_key"].isin(channels["channel_key"])).sum()

schedules = schedules.dropna(
    subset=["channel_name", "program_title", "start_time_raw", "end_time_raw"]
).copy()

# format waktu HH:MM:SS
schedule_data = [schedules, details, sports, movies, family, news]
for dataframe in schedule_data:
    dataframe["channel_key"] = dataframe["channel_name"].str.casefold()
    dataframe["title_key"] = dataframe["program_title"].str.casefold()
    dataframe["start_time"] = pd.to_datetime(
        dataframe["start_time_raw"], format="%I:%M %p", errors="coerce"
    ).dt.strftime("%H:%M:%S")
    dataframe["end_time"] = pd.to_datetime(
        dataframe["end_time_raw"], format="%I:%M %p", errors="coerce"
    ).dt.strftime("%H:%M:%S")

schedules = schedules.dropna(subset=["start_time", "end_time"]).copy()

if os.path.exists("Data Scraping/data/raw/scrape_metadata.json"):
    with open("Data Scraping/data/raw/scrape_metadata.json", "r", encoding="utf-8") as f:
        broadcast_date = json.load(f)["broadcast_date"]
else:
    broadcast_date = datetime.fromtimestamp(
        os.path.getmtime("Data Scraping/data/csv/schedules_raw.csv")
    ).date().isoformat()

schedules["broadcast_date"] = broadcast_date

schedules = schedules.drop_duplicates(
    subset=["channel_key", "broadcast_date", "start_time"]
).copy()

sports["program_type"] = "sports"
movies["program_type"] = "movie"
family["program_type"] = "family"
news["program_type"] = "news"

categories = pd.concat([sports, movies, family, news], ignore_index=True)
category_keys = ["channel_key", "title_key", "start_time", "end_time"]
categories = categories.drop_duplicates(subset=category_keys)[category_keys + ["program_type"]]
schedules = schedules.merge(categories, on=category_keys, how="left", validate="m:1")
schedules["program_type"] = schedules["program_type"].fillna("other")
schedules["program_key"] = schedules["title_key"] + "|" + schedules["program_type"]

details["channel_key"] = details["channel_name"].str.casefold()
details["title_key"] = details["program_title"].str.casefold()
detail_keys = ["channel_key", "title_key", "start_time", "end_time"]
details = details.drop_duplicates(subset=detail_keys)
details = details[
    detail_keys
    + ["rating", "genres_raw", "season_number", "episode_number", "episode_title", "synopsis"]
]
schedules = schedules.merge(details, on=detail_keys, how="left", validate="m:1")

program_types = pd.DataFrame(
    {
        "program_type_id": [1, 2, 3, 4, 5],
        "type_name": ["movie", "sports", "family", "news", "other"],
    }
)
type_ids = {"movie": 1, "sports": 2, "family": 3, "news": 4, "other": 5}

# Bentuk tabel dimensi/induk beserta primary key
channels = channels.dropna(subset=["channel_name"]).copy()
channels["channel_key"] = channels["channel_name"].str.casefold()
channels = channels.drop_duplicates(subset=["channel_key"]).reset_index(drop=True)
channels["channel_id"] = range(1, len(channels) + 1)

programs = schedules[
    ["program_key", "program_title", "program_type", "synopsis", "rating", "genres_raw"]
].copy()
programs["synopsis"] = programs.groupby("program_key")["synopsis"].transform("first")
programs["rating"] = programs.groupby("program_key")["rating"].transform("first")
programs["genres_raw"] = programs.groupby("program_key")["genres_raw"].transform("first")
programs = programs.drop_duplicates(subset=["program_key"]).reset_index(drop=True)
programs["program_id"] = range(1, len(programs) + 1)
programs["program_type_id"] = programs["program_type"].map(type_ids)

# Pecah genre multivalue menjadi tabel genres dan junction program_genres
genre_source = programs[["program_key", "genres_raw"]].dropna().copy()
genre_source["genre_name"] = genre_source["genres_raw"].str.split("/")
genre_source = genre_source.explode("genre_name")
genre_source["genre_name"] = genre_source["genre_name"].str.strip()
genre_source = genre_source[genre_source["genre_name"].notna() & (genre_source["genre_name"] != "")]
genre_source["genre_key"] = genre_source["genre_name"].str.casefold()

genres = genre_source[["genre_name", "genre_key"]].drop_duplicates("genre_key").reset_index(drop=True)
genres["genre_id"] = range(1, len(genres) + 1)
program_genres = genre_source[["program_key", "genre_key"]].drop_duplicates()
program_genres = program_genres.merge(programs[["program_key", "program_id"]], on="program_key")
program_genres = program_genres.merge(genres[["genre_key", "genre_id"]], on="genre_key")

episodes = schedules[
    ["program_key", "season_number", "episode_number", "episode_title", "synopsis"]
].copy()
episodes["season_number"] = pd.to_numeric(episodes["season_number"], errors="coerce").astype("Int64")
episodes["episode_number"] = pd.to_numeric(episodes["episode_number"], errors="coerce").astype("Int64")
episodes = episodes.dropna(subset=["season_number", "episode_number"])
episodes = episodes[(episodes["season_number"] > 0) & (episodes["episode_number"] > 0)]
episodes = episodes.drop_duplicates(["program_key", "season_number", "episode_number"])
episodes = episodes.merge(programs[["program_key", "program_id"]], on="program_key").reset_index(drop=True)
episodes["episode_id"] = range(1, len(episodes) + 1)

# natural key hasil scraping menjadi foreign key numerik
schedules = schedules.merge(channels[["channel_key", "channel_id"]], on="channel_key", validate="m:1")
schedules = schedules.merge(programs[["program_key", "program_id"]], on="program_key", validate="m:1")
schedules["season_number"] = pd.to_numeric(schedules["season_number"], errors="coerce").astype("Int64")
schedules["episode_number"] = pd.to_numeric(schedules["episode_number"], errors="coerce").astype("Int64")
schedules = schedules.merge(
    episodes[["program_id", "season_number", "episode_number", "episode_id"]],
    on=["program_id", "season_number", "episode_number"],
    how="left",
    validate="m:1",
)
schedules["episode_id"] = pd.to_numeric(schedules["episode_id"], errors="coerce").astype("Int64")
schedules["is_live"] = schedules["is_live"].str.casefold().map({"true": True, "false": False})
schedules["is_new"] = schedules["is_new"].str.casefold().map({"true": True, "false": False})
schedules["schedule_id"] = range(1, len(schedules) + 1)

os.makedirs("Data Scraping/data/cleaned", exist_ok=True)
program_types.to_csv("Data Scraping/data/cleaned/program_types.csv", index=False)
channels[["channel_id", "channel_name"]].rename(columns={"channel_name": "call_sign"}).to_csv(
    "Data Scraping/data/cleaned/tv_channels.csv", index=False, na_rep=""
)
programs[["program_id", "program_type_id", "program_title", "synopsis", "rating"]].rename(
    columns={"program_title": "title", "synopsis": "description", "rating": "parental_rating"}
).to_csv("Data Scraping/data/cleaned/tv_programs.csv", index=False, na_rep="")
genres[["genre_id", "genre_name"]].to_csv("Data Scraping/data/cleaned/genres.csv", index=False)
program_genres[["program_id", "genre_id"]].to_csv(
    "Data Scraping/data/cleaned/program_genres.csv", index=False
)
episodes[["episode_id", "program_id", "season_number", "episode_number", "episode_title", "synopsis"]].rename(
    columns={"synopsis": "episode_synopsis"}
).to_csv("Data Scraping/data/cleaned/episodes.csv", index=False, na_rep="")
schedules[
    [
        "schedule_id", "channel_id", "program_id", "episode_id", "broadcast_date",
        "start_time", "end_time", "is_live", "is_new",
    ]
].to_csv("Data Scraping/data/cleaned/broadcast_schedules.csv", index=False, na_rep="")

print(f"Raw schedules: {raw_schedule_count}")
print(f"Invalid time: {invalid_time_count}")
print(f"Unmatched channel: {unmatched_channel_count}")
print(f"Loaded schedules: {len(schedules)}")
print(f"Broadcast date: {broadcast_date}")
