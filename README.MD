# TUGAS SELEKSI 1 - 13524133

## Author

- Nama: Muhammad Daffa Arrizki Yanma
- NIM: 13524133

---

## Deskripsi Singkat Data dan DBMS

Proyek ini membangun pipeline ETL untuk data jadwal tayangan televisi dari [TV Guide](https://www.tvguide.com/listings/). Data yang dikumpulkan meliputi channel, jadwal tayang, detail program, genre, dan episode. Data disimpan pada PostgreSQL dengan schema relasional `public`, lalu ditransformasikan kembali ke schema data warehouse `warehouse` untuk kebutuhan analitik.

Topik televisi dipilih karena sejak kecil saya suka menonton film dan acara televisi dari Amerika Serikat. Karena itu, saya ingin mendesain database yang dapat menyimpan jadwal tayang beserta informasi programnya secara terstruktur.

---

## Struktur Project

```text
Data Scraping/
  src/                 # scraper, JSON ke CSV, dan cleaning
  data/raw/            # JSON aktif hasil scraping terbaru
  data/csv/            # hasil konversi JSON ke CSV
  data/cleaned/        # CSV siap dimuat ke PostgreSQL
  data/batches/        # arsip batch scraping berhasil

Data Storing/
  src/                 # schema.sql, trigger.sql, dan storing.py
  design/              # ERD dan diagram relasional
  export/              # hasil export PostgreSQL (.sql)
  screenshot/          # bukti data tersimpan di DBMS

Data Warehous/
  src/                 # schema warehouse dan generate_dw.py
  design/              # star schema
  export/              # hasil export schema warehouse (.sql)
  screenshot/          # bukti tabel warehouse

Query Optimasi/        # query pembanding, query optimal, dan screenshot hasil
main.py                # orkestrator seluruh pipeline
run_pipeline.bat       # runner pipeline untuk Windows Task Scheduler
setup_scheduler.ps1    # pembuat task scheduler portabel untuk Windows
```

---

## Cara Menjalankan Project

### 1. Buat virtual environment dan install dependency

Jalankan perintah berikut dari root repository.

```powershell
py -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Konfigurasi PostgreSQL

Salin `.env.example` menjadi `.env`, lalu isi kredensial PostgreSQL lokal.

```env
PGDATABASE=tvguide_db
PGUSER=postgres
PGPASSWORD=your_password
PGHOST=localhost
PGPORT=5432
```

### 3. Jalankan pipeline penuh

```powershell
.venv\Scripts\python.exe main.py
```

Pipeline akan menjalankan scraping, konversi JSON ke CSV, cleaning, penyimpanan ke PostgreSQL, dan pembentukan data warehouse.

Opsi yang tersedia:

```powershell
# Gunakan raw data lengkap yang sudah ada, tanpa scraping ulang
.venv\Scripts\python.exe main.py --skip-scraping

# Jalankan sampai cleaning saja, tanpa PostgreSQL dan warehouse
.venv\Scripts\python.exe main.py --skip-storing
```

> `--skip-scraping` hanya dapat digunakan apabila file `pipeline_ready.json` tersedia. File tersebut mencegah raw data parsial diproses setelah scraper gagal di tengah pipeline.

---

## Alur ETL

```text
TV Guide
  → Raw JSON
  → CSV
  → Cleaned CSV
  → PostgreSQL schema public
  → PostgreSQL schema warehouse
```

1. Scraper Selenium mengambil data dari halaman TV Guide dan menyimpannya sebagai JSON.
2. `json_to_csv.py` mengubah JSON menjadi CSV.
3. `clean_data.py` menormalisasi string, menangani missing value, memvalidasi waktu, membuat ID/FK, dan menghasilkan CSV per tabel.
4. `storing.py` membuat ulang schema dan trigger, lalu memuat cleaned CSV memakai PostgreSQL `COPY`.
5. `generate_dw.py` membuat star schema dan mengisi dimension, bridge, serta fact table dari schema `public`.

Database operasional dan warehouse memakai full refresh, sehingga hanya menyimpan snapshot terbaru dan tidak memiliki redundansi antar-run. Arsip histori raw/CSV/cleaned disimpan pada `Data Scraping/data/batches/<timestamp>/`.

---

## Struktur File JSON

Seluruh JSON aktif berada pada `Data Scraping/data/raw/`. Setiap file jadwal berbentuk array JSON; setiap elemen array mewakili satu channel, satu program, atau satu jadwal sesuai nama filenya.

### 1. `channels_raw.json`

Berisi daftar channel yang tampil pada halaman listings.

| Field | Tipe | Penjelasan |
|---|---|---|
| `channel_order` | integer | Urutan channel pada halaman TV Guide. |
| `channel_name` | string | Call sign atau nama channel, misalnya `ABC`. |

```json
[
  {
    "channel_order": 1,
    "channel_name": "ABC"
  }
]
```

### 2. `schedules_raw.json`

Berisi seluruh jadwal tayangan dari halaman listings utama. Satu objek merepresentasikan satu slot tayang.

| Field | Tipe | Penjelasan |
|---|---|---|
| `channel_order` | integer | Urutan channel pada halaman. |
| `channel_name` | string | Nama/call sign channel. |
| `program_order` | integer | Urutan kartu program dalam channel tersebut. |
| `program_title` | string | Judul program yang tampil pada kartu jadwal. |
| `start_time_raw` | string/null | Waktu mulai dalam format TV Guide, misalnya `1:00 PM`. |
| `end_time_raw` | string/null | Waktu selesai dalam format TV Guide. |
| `is_new` | boolean | Bernilai `true` bila kartu jadwal memiliki penanda `NEW`. |
| `is_live` | boolean | Bernilai `true` bila kartu jadwal memiliki penanda `LIVE`. |

```json
[
  {
    "channel_order": 1,
    "channel_name": "ABC",
    "program_order": 1,
    "program_title": "ABC World News Now",
    "start_time_raw": "1:00 PM",
    "end_time_raw": "2:00 PM",
    "is_new": false,
    "is_live": false
  }
]
```

### 3. `program_details_raw.json`

Berisi detail program yang diperoleh setelah kartu program pada jadwal dibuka. Waktu dan identitas kartu disimpan kembali agar detail dapat dicocokkan dengan jadwal pada tahap cleaning.

| Field | Tipe | Penjelasan |
|---|---|---|
| `channel_order`, `channel_name` | integer, string | Identitas channel asal detail program. |
| `program_order`, `program_title` | integer, string | Identitas kartu jadwal dan judul program. |
| `start_time_raw`, `end_time_raw` | string/null | Waktu slot tayang untuk pencocokan dengan `schedules_raw.json`. |
| `duration_raw` | string/null | Durasi/metadata mentah yang ditampilkan panel detail. |
| `release_year` | string/null | Tahun rilis bila tersedia. |
| `rating` | string/null | Rating usia, misalnya `TV-PG` atau `PG`. |
| `genres_raw` | string/null | Genre mentah; dapat memuat lebih dari satu genre. |
| `season_number`, `episode_number` | integer/null | Nomor season dan episode bila program bersifat episodik. |
| `episode_title` | string/null | Judul episode bila tersedia. |
| `synopsis` | string/null | Deskripsi atau synopsis tayangan. |

```json
[
  {
    "channel_order": 1,
    "channel_name": "ABC",
    "program_order": 1,
    "program_title": "ABC World News Now",
    "start_time_raw": "1:00 PM",
    "end_time_raw": "2:00 PM",
    "duration_raw": "1 hr",
    "release_year": null,
    "rating": "TV-PG",
    "genres_raw": "News",
    "season_number": null,
    "episode_number": null,
    "episode_title": null,
    "synopsis": "Overnight news, weather, and political coverage."
  }
]
```

### 4. `sports_schedules_raw.json`

Berisi jadwal setelah filter **Sports** dipilih. Struktur objeknya sama persis dengan `schedules_raw.json`; perbedaannya hanya seluruh record berasal dari filter Sports.

```json
[
  {
    "channel_order": 1,
    "channel_name": "ESPN",
    "program_order": 1,
    "program_title": "SportsCenter",
    "start_time_raw": "2:00 PM",
    "end_time_raw": "3:00 PM",
    "is_new": false,
    "is_live": true
  }
]
```

### 5. `movies_schedules_raw.json`

Berisi jadwal setelah filter **Movies** dipilih. Struktur objek sama dengan `schedules_raw.json` dan digunakan untuk memberi tipe `movie` pada program yang cocok.

```json
[
  {
    "channel_order": 1,
    "channel_name": "ENCORE",
    "program_order": 1,
    "program_title": "School of Rock",
    "start_time_raw": "2:00 PM",
    "end_time_raw": "4:00 PM",
    "is_new": false,
    "is_live": false
  }
]
```

### 6. `family_schedules_raw.json`

Berisi jadwal setelah filter **Family** dipilih. Struktur objek sama dengan `schedules_raw.json` dan digunakan untuk memberi tipe `family` pada program yang cocok.

```json
[
  {
    "channel_order": 1,
    "channel_name": "DISNEYXD",
    "program_order": 1,
    "program_title": "Big Hero 6",
    "start_time_raw": "2:00 PM",
    "end_time_raw": "2:30 PM",
    "is_new": false,
    "is_live": false
  }
]
```

### 7. `news_schedules_raw.json`

Berisi jadwal setelah filter **News** dipilih. Struktur objek sama dengan `schedules_raw.json` dan digunakan untuk memberi tipe `news` pada program yang cocok.

```json
[
  {
    "channel_order": 1,
    "channel_name": "BBCNW",
    "program_order": 1,
    "program_title": "BBC News",
    "start_time_raw": "2:00 PM",
    "end_time_raw": "3:00 PM",
    "is_new": false,
    "is_live": true
  }
]
```

### 8. `scrape_metadata.json`

Berisi metadata satu batch scraping. `broadcast_date` dipakai saat cleaning agar tanggal siaran mengikuti batch scraping, bukan waktu script cleaning dijalankan.

| Field | Tipe | Penjelasan |
|---|---|---|
| `broadcast_date` | string | Tanggal batch dalam format `YYYY-MM-DD`. |
| `scraped_at` | string | Timestamp scraping dengan timezone. |
| `batch_id` | string | ID folder arsip batch. |

```json
{
  "broadcast_date": "2026-07-23",
  "scraped_at": "2026-07-23T13:55:28+07:00",
  "batch_id": "2026-07-23_13-55-28"
}
```

### 9. `pipeline_ready.json`

File penanda bahwa seluruh scraper dan konversi JSON ke CSV telah selesai. File ini digunakan `main.py` untuk mengizinkan opsi `--skip-scraping`.

```json
{
  "batch_id": "2026-07-23_13-55-28",
  "scraped_at": "2026-07-23T13:55:28+07:00"
}
```

---

## Database Relasional

Schema operasional berada pada PostgreSQL schema `public` dan terdiri dari:

```text
program_types
tv_channels
tv_programs
genres
program_genres
episodes
broadcast_schedules
```

Constraint utama yang diterapkan:

- Primary key dan foreign key pada seluruh relasi.
- `UNIQUE (program_type_id, title)` pada `tv_programs`.
- Primary key gabungan `(program_id, genre_id)` pada `program_genres`.
- `UNIQUE (channel_id, broadcast_date, start_time)` pada `broadcast_schedules`.
- Trigger memastikan episode yang dijadwalkan adalah episode milik program yang sama.
- Trigger mencegah jadwal tumpang tindih pada channel yang sama.

### ERD dan Diagram Relasional

![ERD](<Data%20Storing/design/Diagram%20Basis%20Data-ERD.png>)

![Diagram Relasional](<Data%20Storing/design/Diagram%20Basis%20Data-Relational.png>)

### Translasi ERD ke Relasional

#### 1. Relasi `Dikelompokkan`: `tv_programs` dan `genres`

Terdapat relasi many-to-many antara `tv_programs` dan `genres`. Oleh karena itu, dibentuk tabel junction `program_genres`.

```text
tv_programs
genres
program_genres
```

**Primary key:**

- `tv_programs`: `program_id`
- `genres`: `genre_id`
- `program_genres`: `(program_id, genre_id)`

**Foreign key:**

- `program_genres.program_id` → `tv_programs.program_id`
- `program_genres.genre_id` → `genres.genre_id`

#### 2. Relasi jadwal tayang: `broadcast_schedules`

`broadcast_schedules` adalah tabel transaksi utama. Satu channel, program, atau episode dapat muncul pada banyak jadwal, sedangkan satu jadwal mengacu ke satu channel dan satu program. Episode bersifat opsional.

```text
broadcast_schedules
tv_channels
tv_programs
episodes
```

**Primary key:**

- `broadcast_schedules`: `schedule_id`
- `tv_channels`: `channel_id`
- `tv_programs`: `program_id`
- `episodes`: `episode_id`

**Foreign key:**

- `broadcast_schedules.channel_id` → `tv_channels.channel_id`
- `broadcast_schedules.program_id` → `tv_programs.program_id`
- `broadcast_schedules.episode_id` → `episodes.episode_id`

> Pada diagram relasional, atribut mungkin tertulis `progran_id`. Nama kolom implementasi PostgreSQL yang benar adalah `program_id`.

#### 3. Relasi `Bertipe`: `tv_programs` dan `program_types`

Satu `program_type` dapat dimiliki banyak program, sedangkan setiap program memiliki satu tipe. Foreign key ditarik ke tabel `tv_programs`.

```text
tv_programs
program_types
```

**Primary key:**

- `program_types`: `program_type_id`

**Foreign key:**

- `tv_programs.program_type_id` → `program_types.program_type_id`

#### 4. Relasi `Memiliki`: `tv_programs` dan `episodes`

Satu program dapat memiliki banyak episode. Oleh karena itu, foreign key berada pada tabel `episodes`, bukan pada `tv_programs`.

```text
tv_programs
episodes
```

**Primary key:**

- `episodes`: `episode_id`

**Foreign key:**

- `episodes.program_id` → `tv_programs.program_id`

### Screenshot Penyimpanan Data

| Program | Jadwal broadcast |
|---|---|
| ![TV Program](<Data%20Storing/screenshot/tv_program.png>) | ![Broadcast Schedule](<Data%20Storing/screenshot/broadcast_schedule.png>) |

| Genre dan relasinya | Episode |
|---|---|
| ![Program Genre](<Data%20Storing/screenshot/program_genres.png>) | ![Episode](<Data%20Storing/screenshot/episode.png>) |

---

## Bonus: Data Warehouse

Data warehouse berada pada schema PostgreSQL `warehouse` dengan grain:

> Satu baris `fact_broadcast` merepresentasikan satu penayangan program pada satu channel, satu tanggal, dan satu waktu mulai.

Tabel warehouse:

```text
dim_date
dim_time
dim_channel
dim_program
dim_episode
dim_genre
bridge_program_genre
fact_broadcast
```

`bridge_program_genre` digunakan agar relasi many-to-many program dan genre tidak menggandakan baris `fact_broadcast`.

### Star Schema

![Star Schema](<Data%20Warehous/design/Diagram%20Basis%20Data-Star%20Schema.png>)

### Screenshot Warehouse

| Fact broadcast | Program dimension |
|---|---|
| ![Fact Broadcast](<Data%20Warehous/screenshot/fact_boradcast.png>) | ![Dim Program](<Data%20Warehous/screenshot/dim_program.png>) |

| Program-genre bridge | Query analitik |
|---|---|
| ![Bridge Program Genre](<Data%20Warehous/screenshot/bridge_program_genre.png>) | ![Program dan Tipe Tayangan](<Data%20Warehous/screenshot/program_dan_tipe_tayangan.png>) |

---

## Bonus: Automated Scheduling

Otomasi dijalankan melalui Windows Task Scheduler dengan `run_pipeline.bat`. Runner menggunakan `.venv` relatif terhadap root project, sehingga tidak bergantung pada path username atau Anaconda tertentu.

Untuk membuat task pada komputer Windows lain:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_scheduler.ps1 -Time 12:45
```

Task menjalankan seluruh pipeline setiap hari. Batch sukses disimpan pada folder `Data Scraping/data/batches/` dan metadata menyimpan waktu ekstraksi untuk membandingkan batch yang berbeda.

---

## Bonus: Query Optimasi

Folder `Query Optimasi` berisi perbandingan query awal dan query optimal. Optimasi dilakukan dengan menyederhanakan pola join/filter.

---

## Penggunaan AI

### Bagian yang dibantu AI

- **Data scraping:** bagian yang paling banyak dibantu AI, terutama untuk memahami alur Selenium, menyusun selector, penggunaan `WebDriverWait`, ekstraksi detail program, serta menangani kegagalan selector atau perubahan tampilan halaman.
- **Otomasi pipeline:** diskusi mengenai urutan scraping, konversi JSON/CSV, cleaning, storing, pencatatan metadata batch, dan penjadwalan melalui Windows Task Scheduler.
- **Debugging:** membantu menelusuri masalah seperti data detail program yang tidak cocok dengan jadwal, nilai waktu yang tidak valid saat `COPY`, dan pembaruan data yang belum terlihat pada PostgreSQL/DBeaver.

### Bagian yang tetap dikerjakan sendiri

- Menentukan topik data TV Guide dan alasan pemilihan topik.
- Memahami kebutuhan tugas, menentukan data yang perlu diekstrak, dan memeriksa hasil scraping pada file JSON.
- Mendesain serta memperbaiki ERD, diagram relasional, dan star schema secara mandiri.
- Melakukan pengujian pipeline, menjalankan PostgreSQL/DBeaver, memeriksa isi tabel, dan mengambil screenshot hasil.
- Menentukan keputusan akhir terhadap struktur data, constraint, trigger, serta isi dokumentasi. Untuk bagian **data storing** dan **data warehouse**,

### Refleksi Penggunaan AI

AI mempercepat proses belajar ketika menghadapi library dan error yang belum familiar, khususnya pada Selenium dan integrasi PostgreSQL. Namun, AI tidak selalu mengetahui kondisi halaman web, data lokal, maupun konfigurasi database yang sedang digunakan. Karena itu, setiap saran perlu diverifikasi dengan menjalankan program, membaca log, memeriksa JSON/CSV, dan mengecek tabel. Proses tersebut membantu saya memahami alasan di balik solusi yang dipakai.

---

## Referensi

- [TV Guide Listings](https://www.tvguide.com/listings/)
- [Selenium Documentation](https://www.selenium.dev/documentation/)
- [ScraperAPI: How to Use Selenium for Web Scraping](https://www.scraperapi.com/web-scraping/selenium/)
- [Beautiful Soup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Psycopg Documentation](https://www.psycopg.org/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [python-dotenv](https://pypi.org/project/python-dotenv/)
