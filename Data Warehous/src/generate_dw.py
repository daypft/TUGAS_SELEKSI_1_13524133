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

with open("Data Warehous/src/schema_dw.sql", "r", encoding="utf-8") as f:
    cur.execute(f.read())

cur.execute("""
    INSERT INTO warehouse.dim_date
    (date_key, full_date, day_number, month_number, month_name, quarter_number, year_number, day_name)
    SELECT DISTINCT
        TO_CHAR(broadcast_date, 'YYYYMMDD')::INTEGER,
        broadcast_date,
        EXTRACT(DAY FROM broadcast_date)::INTEGER,
        EXTRACT(MONTH FROM broadcast_date)::INTEGER,
        TRIM(TO_CHAR(broadcast_date, 'Month')),
        EXTRACT(QUARTER FROM broadcast_date)::INTEGER,
        EXTRACT(YEAR FROM broadcast_date)::INTEGER,
        TRIM(TO_CHAR(broadcast_date, 'Day'))
    FROM public.broadcast_schedules
""")

cur.execute("""
    INSERT INTO warehouse.dim_time
    (time_key, full_time, hour_number, minute_number, second_number)
    SELECT DISTINCT
        (EXTRACT(HOUR FROM full_time)::INTEGER * 10000)
        + (EXTRACT(MINUTE FROM full_time)::INTEGER * 100)
        + EXTRACT(SECOND FROM full_time)::INTEGER,
        full_time,
        EXTRACT(HOUR FROM full_time)::INTEGER,
        EXTRACT(MINUTE FROM full_time)::INTEGER,
        EXTRACT(SECOND FROM full_time)::INTEGER
    FROM (
        SELECT start_time AS full_time FROM public.broadcast_schedules
        UNION
        SELECT end_time AS full_time FROM public.broadcast_schedules
    ) AS times
""")

cur.execute("""
    INSERT INTO warehouse.dim_channel (source_channel_id, call_sign)
    SELECT channel_id, call_sign
    FROM public.tv_channels
""")

cur.execute("""
    INSERT INTO warehouse.dim_program
    (source_program_id, title, program_type, parental_rating)
    SELECT p.program_id, p.title, pt.type_name, p.parental_rating
    FROM public.tv_programs p
    JOIN public.program_types pt ON pt.program_type_id = p.program_type_id
""")

cur.execute("""
    INSERT INTO warehouse.dim_episode
    (source_episode_id, season_number, episode_number, episode_title)
    SELECT episode_id, season_number, episode_number, episode_title
    FROM public.episodes
""")

cur.execute("""
    INSERT INTO warehouse.dim_genre (source_genre_id, genre_name)
    SELECT genre_id, genre_name
    FROM public.genres
""")

cur.execute("""
    INSERT INTO warehouse.bridge_program_genre (program_key, genre_key)
    SELECT dp.program_key, dg.genre_key
    FROM public.program_genres pg
    JOIN warehouse.dim_program dp ON dp.source_program_id = pg.program_id
    JOIN warehouse.dim_genre dg ON dg.source_genre_id = pg.genre_id
""")

cur.execute("""
    INSERT INTO warehouse.fact_broadcast
    (date_key, start_time_key, end_time_key, channel_key, program_key, episode_key,
     duration_minutes, broadcast_count, is_live, is_new)
    SELECT
        dd.date_key,
        dst.time_key,
        det.time_key,
        dc.channel_key,
        dp.program_key,
        de.episode_key,
        EXTRACT(EPOCH FROM (
            CASE
                WHEN s.end_time > s.start_time THEN s.end_time - s.start_time
                ELSE s.end_time - s.start_time + INTERVAL '1 day'
            END
        ))::INTEGER / 60,
        1,
        s.is_live,
        s.is_new
    FROM public.broadcast_schedules s
    JOIN warehouse.dim_date dd ON dd.full_date = s.broadcast_date
    JOIN warehouse.dim_time dst ON dst.full_time = s.start_time
    JOIN warehouse.dim_time det ON det.full_time = s.end_time
    JOIN warehouse.dim_channel dc ON dc.source_channel_id = s.channel_id
    JOIN warehouse.dim_program dp ON dp.source_program_id = s.program_id
    LEFT JOIN warehouse.dim_episode de ON de.source_episode_id = s.episode_id
""")

cur.execute("SELECT COUNT(*) FROM warehouse.dim_date")
print(f"dim_date: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.dim_time")
print(f"dim_time: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.dim_channel")
print(f"dim_channel: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.dim_program")
print(f"dim_program: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.dim_episode")
print(f"dim_episode: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.dim_genre")
print(f"dim_genre: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.bridge_program_genre")
print(f"bridge_program_genre: {cur.fetchone()[0]} rows")
cur.execute("SELECT COUNT(*) FROM warehouse.fact_broadcast")
print(f"fact_broadcast: {cur.fetchone()[0]} rows")

conn.commit()
cur.close()
conn.close()

print("Data warehouse TV Guide berhasil dibuat.")
