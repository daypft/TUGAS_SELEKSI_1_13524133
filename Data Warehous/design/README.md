# Asumsi Desain Data Warehouse

1. Grain `fact_broadcast` adalah satu penayangan program pada satu channel, satu tanggal, dan satu waktu mulai.
2. Data warehouse berada pada schema PostgreSQL `warehouse`, terpisah dari database operasional pada schema `public`.
3. Dimension table memakai surrogate key, sedangkan `source_*_id` menyimpan ID asal dari database operasional.
4. `date_key` memakai format `YYYYMMDD` dan `time_key` memakai format `HHMMSS`.
5. Satu program dapat memiliki banyak genre. Relasi ini disimpan pada `bridge_program_genre` agar genre tidak menggandakan baris pada `fact_broadcast`.
6. `episode_key` pada fact boleh `NULL` untuk penayangan yang tidak memiliki episode.
7. `duration_minutes` menghitung jadwal lintas tengah malam dengan menambahkan satu hari bila `end_time` lebih kecil dari `start_time`.