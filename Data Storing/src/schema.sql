DROP TABLE IF EXISTS broadcast_schedules;
DROP TABLE IF EXISTS episodes;
DROP TABLE IF EXISTS program_genres;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS tv_programs;
DROP TABLE IF EXISTS tv_channels;
DROP TABLE IF EXISTS program_types;

CREATE TABLE IF NOT EXISTS program_types (
    program_type_id INTEGER PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT chk_program_type_name
        CHECK (type_name IN ('movie', 'sports', 'family', 'news', 'other'))
);

CREATE TABLE IF NOT EXISTS tv_channels (
    channel_id INTEGER PRIMARY KEY,
    call_sign VARCHAR(255) NOT NULL UNIQUE,
    CONSTRAINT chk_channel_call_sign_not_blank CHECK (btrim(call_sign) <> '')
);

CREATE TABLE IF NOT EXISTS tv_programs (
    program_id INTEGER PRIMARY KEY,
    program_type_id INTEGER NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    parental_rating VARCHAR(30),
    CONSTRAINT fk_program_type
        FOREIGN KEY (program_type_id) REFERENCES program_types(program_type_id),
    CONSTRAINT uq_program_type_title UNIQUE (program_type_id, title),
    CONSTRAINT chk_program_title_not_blank CHECK (btrim(title) <> '')
);

CREATE TABLE IF NOT EXISTS genres (
    genre_id INTEGER PRIMARY KEY,
    genre_name VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT chk_genre_name_not_blank CHECK (btrim(genre_name) <> '')
);

CREATE TABLE IF NOT EXISTS program_genres (
    program_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (program_id, genre_id),
    CONSTRAINT fk_program_genres_program
        FOREIGN KEY (program_id) REFERENCES tv_programs(program_id) ON DELETE CASCADE,
    CONSTRAINT fk_program_genres_genre
        FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS episodes (
    episode_id INTEGER PRIMARY KEY,
    program_id INTEGER NOT NULL,
    season_number INTEGER NOT NULL,
    episode_number INTEGER NOT NULL,
    episode_title VARCHAR(500),
    episode_synopsis TEXT,
    CONSTRAINT fk_episode_program
        FOREIGN KEY (program_id) REFERENCES tv_programs(program_id) ON DELETE CASCADE,
    CONSTRAINT uq_episode_program_season_episode
        UNIQUE (program_id, season_number, episode_number),
    CONSTRAINT chk_episode_numbers_positive
        CHECK (season_number > 0 AND episode_number > 0)
);

CREATE TABLE IF NOT EXISTS broadcast_schedules (
    schedule_id INTEGER PRIMARY KEY,
    channel_id INTEGER NOT NULL,
    program_id INTEGER NOT NULL,
    episode_id INTEGER,
    broadcast_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_live BOOLEAN NOT NULL DEFAULT FALSE,
    is_new BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_schedule_channel
        FOREIGN KEY (channel_id) REFERENCES tv_channels(channel_id),
    CONSTRAINT fk_schedule_program
        FOREIGN KEY (program_id) REFERENCES tv_programs(program_id),
    CONSTRAINT fk_schedule_episode
        FOREIGN KEY (episode_id) REFERENCES episodes(episode_id),
    CONSTRAINT uq_schedule_channel_date_start
        UNIQUE (channel_id, broadcast_date, start_time),
    CONSTRAINT chk_schedule_nonzero_duration
        CHECK (end_time <> start_time)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_schedule_nonzero_duration'
          AND conrelid = 'broadcast_schedules'::regclass
    ) THEN
        ALTER TABLE broadcast_schedules
            ADD CONSTRAINT chk_schedule_nonzero_duration
            CHECK (end_time <> start_time);
    END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_tv_programs_type
    ON tv_programs(program_type_id);
CREATE INDEX IF NOT EXISTS idx_episodes_program
    ON episodes(program_id);
CREATE INDEX IF NOT EXISTS idx_schedules_program
    ON broadcast_schedules(program_id);
CREATE INDEX IF NOT EXISTS idx_schedules_date
    ON broadcast_schedules(broadcast_date);
