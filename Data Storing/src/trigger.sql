CREATE OR REPLACE FUNCTION validate_schedule_episode()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.episode_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM episodes
           WHERE episode_id = NEW.episode_id
             AND program_id = NEW.program_id
       )
    THEN
        RAISE EXCEPTION 'episode_id % does not belong to program_id %',
            NEW.episode_id, NEW.program_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_schedule_episode ON broadcast_schedules;

CREATE TRIGGER trg_validate_schedule_episode
BEFORE INSERT OR UPDATE OF program_id, episode_id
ON broadcast_schedules
FOR EACH ROW
EXECUTE FUNCTION validate_schedule_episode();


-- Satu channel tidak boleh mempunyai dua tayangan pada waktu yang bertumpuk.
CREATE OR REPLACE FUNCTION prevent_schedule_overlap()
RETURNS TRIGGER AS $$
DECLARE
    new_start TIMESTAMP;
    new_end TIMESTAMP;
BEGIN
    new_start := NEW.broadcast_date + NEW.start_time;
    new_end := NEW.broadcast_date + NEW.end_time;

    IF NEW.end_time < NEW.start_time THEN
        new_end := new_end + INTERVAL '1 day';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM broadcast_schedules s
        WHERE s.channel_id = NEW.channel_id
          AND s.schedule_id IS DISTINCT FROM NEW.schedule_id
          AND new_start < s.broadcast_date + s.end_time
              + CASE WHEN s.end_time < s.start_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
          AND s.broadcast_date + s.start_time < new_end
    ) THEN
        RAISE EXCEPTION
            'schedule channel_id % overlaps an existing schedule', NEW.channel_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_schedule_overlap ON broadcast_schedules;

CREATE TRIGGER trg_prevent_schedule_overlap
BEFORE INSERT OR UPDATE OF channel_id, broadcast_date, start_time, end_time
ON broadcast_schedules
FOR EACH ROW
EXECUTE FUNCTION prevent_schedule_overlap();
