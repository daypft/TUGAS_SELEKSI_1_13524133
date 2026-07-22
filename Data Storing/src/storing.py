from dotenv import load_dotenv
import os
import psycopg2


load_dotenv()

conn = psycopg2.connect(
    dbname=os.getenv("PGDATABASE"),
    user=os.getenv("PGUSER"),
    password=os.getenv("PGPASSWORD"),
    host=os.getenv("PGHOST"),
    port=os.getenv("PGPORT"),
)

cur = conn.cursor()

with open("Data Storing/src/schema.sql", "r", encoding="utf-8") as f:
    cur.execute(f.read())

with open("Data Storing/src/trigger.sql", "r", encoding="utf-8") as f:
    cur.execute(f.read())

with open("Data Scraping/data/cleaned/program_types.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.program_types (program_type_id, type_name) FROM STDIN WITH CSV",
        f,
    )

with open("Data Scraping/data/cleaned/tv_channels.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.tv_channels (channel_id, call_sign) FROM STDIN WITH CSV",
        f,
    )

with open("Data Scraping/data/cleaned/tv_programs.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.tv_programs "
        "(program_id, program_type_id, title, description, parental_rating) "
        "FROM STDIN WITH CSV NULL ''",
        f,
    )

with open("Data Scraping/data/cleaned/genres.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.genres (genre_id, genre_name) FROM STDIN WITH CSV",
        f,
    )

with open("Data Scraping/data/cleaned/program_genres.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.program_genres (program_id, genre_id) FROM STDIN WITH CSV",
        f,
    )

with open("Data Scraping/data/cleaned/episodes.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.episodes "
        "(episode_id, program_id, season_number, episode_number, "
        "episode_title, episode_synopsis) "
        "FROM STDIN WITH CSV NULL ''",
        f,
    )

with open("Data Scraping/data/cleaned/broadcast_schedules.csv", "r", encoding="utf-8") as f:
    next(f)
    cur.copy_expert(
        "COPY public.broadcast_schedules "
        "(schedule_id, channel_id, program_id, episode_id, broadcast_date, "
        "start_time, end_time, is_live, is_new) "
        "FROM STDIN WITH CSV NULL ''",
        f,
    )

conn.commit()
cur.close()
conn.close()

print("Data TV Guide berhasil dimuat ke PostgreSQL.")
