# Asumsi Desain Database Relasional

1. `call_sign` dianggap unik untuk mengidentifikasi setiap channel televisi.
2. Program diidentifikasi oleh kombinasi `program_type` dan `title`; judul yang sama pada tipe berbeda dapat menjadi program berbeda.
3. Program dapat memiliki lebih dari satu genre dan satu genre dapat dimiliki banyak program, sehingga digunakan tabel penghubung `program_genres`.
4. Episode bersifat opsional pada jadwal karena film, berita, dan program non-episodik tidak selalu memiliki nomor episode.
5. Bila episode diisi pada jadwal, episode tersebut harus milik program yang sama.
6. Satu channel tidak boleh memiliki dua jadwal dengan waktu tayang yang saling tumpang tindih pada tanggal yang sama.
8. Kolom deskripsi, rating, genre, dan informasi episode yang tidak tersedia disimpan sebagai `NULL`.
9. Database operasional memakai full refresh pada setiap run.
