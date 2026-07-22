DROP SCHEMA IF EXISTS warehouse CASCADE;
CREATE SCHEMA warehouse;

CREATE TABLE warehouse.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_number INTEGER NOT NULL,
    month_number INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter_number INTEGER NOT NULL,
    year_number INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL
);

CREATE TABLE warehouse.dim_time (
    time_key INTEGER PRIMARY KEY,
    full_time TIME NOT NULL UNIQUE,
    hour_number INTEGER NOT NULL,
    minute_number INTEGER NOT NULL,
    second_number INTEGER NOT NULL
);

CREATE TABLE warehouse.dim_channel (
    channel_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_channel_id INTEGER NOT NULL UNIQUE,
    call_sign VARCHAR(255) NOT NULL
);

CREATE TABLE warehouse.dim_program (
    program_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_program_id INTEGER NOT NULL UNIQUE,
    title VARCHAR(500) NOT NULL,
    program_type VARCHAR(20) NOT NULL,
    parental_rating VARCHAR(30)
);

CREATE TABLE warehouse.dim_episode (
    episode_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_episode_id INTEGER NOT NULL UNIQUE,
    season_number INTEGER NOT NULL,
    episode_number INTEGER NOT NULL,
    episode_title VARCHAR(500)
);

CREATE TABLE warehouse.dim_genre (
    genre_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_genre_id INTEGER NOT NULL UNIQUE,
    genre_name VARCHAR(100) NOT NULL
);

CREATE TABLE warehouse.bridge_program_genre (
    program_key INTEGER NOT NULL REFERENCES warehouse.dim_program(program_key),
    genre_key INTEGER NOT NULL REFERENCES warehouse.dim_genre(genre_key),
    PRIMARY KEY (program_key, genre_key)
);

CREATE TABLE warehouse.fact_broadcast (
    broadcast_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key INTEGER NOT NULL REFERENCES warehouse.dim_date(date_key),
    start_time_key INTEGER NOT NULL REFERENCES warehouse.dim_time(time_key),
    end_time_key INTEGER NOT NULL REFERENCES warehouse.dim_time(time_key),
    channel_key INTEGER NOT NULL REFERENCES warehouse.dim_channel(channel_key),
    program_key INTEGER NOT NULL REFERENCES warehouse.dim_program(program_key),
    episode_key INTEGER REFERENCES warehouse.dim_episode(episode_key),
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    broadcast_count INTEGER NOT NULL DEFAULT 1 CHECK (broadcast_count = 1),
    is_live BOOLEAN NOT NULL,
    is_new BOOLEAN NOT NULL,
    CONSTRAINT uq_fact_broadcast UNIQUE (channel_key, date_key, start_time_key)
);

CREATE INDEX idx_fact_broadcast_date ON warehouse.fact_broadcast(date_key);
CREATE INDEX idx_fact_broadcast_channel ON warehouse.fact_broadcast(channel_key);
CREATE INDEX idx_fact_broadcast_program ON warehouse.fact_broadcast(program_key);
