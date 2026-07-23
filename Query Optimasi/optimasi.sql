-- kode `pembanding`
-- 1. Query untuk melihat total broadcast program dengan genre Drama atau Comedy.
SELECT COUNT(DISTINCT s.schedule_id) AS total_broadcast
FROM public.broadcast_schedules s
JOIN public.program_genres pg ON pg.program_id = s.program_id
JOIN public.genres g ON g.genre_id = pg.genre_id
WHERE g.genre_name IN ('Drama', 'Comedy');

-- 2. Query untuk melihat jumlah broadcast pada setiap channel tanggal 23 Juli 2026.
SELECT
    c.call_sign,
    (
        SELECT COUNT(*)
        FROM public.broadcast_schedules s
        WHERE s.channel_id = c.channel_id
           AND s.broadcast_date = DATE '2026-07-23'
    ) AS total_broadcast
FROM public.tv_channels c;

-- 3. Query untuk melihat total broadcast dan total durasi tayang per channel pada 23 Juli 2026.
SELECT
    c.call_sign,
    COUNT(*) AS total_broadcast,
    SUM(f.duration_minutes) AS total_minutes
FROM warehouse.fact_broadcast f
JOIN warehouse.dim_date d ON d.date_key = f.date_key
JOIN warehouse.dim_channel c ON c.channel_key = f.channel_key
WHERE EXTRACT(YEAR FROM d.full_date) = 2026
  AND EXTRACT(MONTH FROM d.full_date) = 7
  AND EXTRACT(DAY FROM d.full_date) = 23
GROUP BY c.call_sign;


-- kode optimasi
-- 1. Query untuk melihat total broadcast program dengan genre Drama atau Comedy.
SELECT COUNT(*) AS total_broadcast
FROM public.broadcast_schedules s
WHERE EXISTS (
    SELECT 1
    FROM public.program_genres pg
    JOIN public.genres g ON g.genre_id = pg.genre_id
    WHERE pg.program_id = s.program_id
      AND g.genre_name IN ('Drama', 'Comedy')
);

-- 2. Query untuk melihat jumlah broadcast pada setiap channel tanggal 23 Juli 2026.
SELECT
    c.call_sign,
    COUNT(s.schedule_id) AS total_broadcast
FROM public.tv_channels c
LEFT JOIN public.broadcast_schedules s
    ON s.channel_id = c.channel_id
    AND s.broadcast_date = DATE '2026-07-23'
GROUP BY c.channel_id, c.call_sign;

-- 3. Query untuk melihat total broadcast dan total durasi tayang per channel pada 23 Juli 2026.
SELECT
    c.call_sign,
    COUNT(*) AS total_broadcast,
    SUM(f.duration_minutes) AS total_duration_minutes
FROM warehouse.fact_broadcast f
JOIN warehouse.dim_channel c ON c.channel_key = f.channel_key
WHERE f.date_key = 20260723
GROUP BY c.call_sign
ORDER BY c.call_sign;


-- Penjelasan
-- 1. EXISTS menggunakan Semi-Join. database akan mengecek tabel referensi dan langsung berhenti begitu menemukan satu kecocokan pertama. 
-- Sebaliknya, JOIN akan mencari dan menggabungkan seluruh kecocokan yang ada.

-- 2. penggunaan LEFT JOIN jauh lebih efisien daripada Subquery karena database memproses data secara massal sekaligus

-- 3.penggunaan key (20260723) langsung pada fact table mengeliminasi kebutuhan JOIN yang berat ke tabel dimensi waktu.