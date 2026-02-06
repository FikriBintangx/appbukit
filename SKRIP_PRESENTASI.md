# Skrip Presentasi Aplikasi Tiara Finance
Sistem Manajemen Keuangan & Administrasi RT/RW Modern

---

## 1. Pembukaan (Intro)
"Assalamualaikum wr. wb. / Selamat Pagi semuanya.
Pada kesempatan kali ini, saya akan mendemokan aplikasi Tiara Finance, sebuah solusi digital untuk modernisasi manajemen keuangan dan administrasi di lingkungan RT/RW kita.
Aplikasi ini dibuat untuk menggantikan pencatatan manual (buku kas) yang rawan hilang dan tidak transparan, menjadi sistem berbasis cloud yang real-time dan mudah diakses warga."

---

## 2. Teknologi yang Digunakan
"Aplikasi ini dibangun menggunakan teknologi mutakhir:"
- Frontend: Flutter (Dart) - untuk tampilan yang mulus (smooth) di Android & iOS.
- Backend: Firebase (Auth, Firestore, Messaging) & Supabase (Storage).
- Fitur Spesial:
    - Push Notification (Firebase Cloud Messaging).
    - Desain UI Modern (Glassmorphism & Wavy Headers).
    - Keamanan data (Enkripsi Password SHA-256).

---

## 3. Demo Fitur Utama (Alur Aplikasi)

### A. Keamanan & Autentikasi
"Pertama, kita masuk ke halaman Login. Keamanan adalah prioritas.
- Password pengguna di-enkripsi menggunakan SHA-256, jadi admin pun tidak bisa melihat password asli user.
- Sistem membedakan akses antara Warga dan Admin/Ketua RT."

---

### B. Tampilan Warga (User Experience)
"Masuk sebagai Warga, kita disambut dengan Dashboard Modern:
- Header Bergelombang (Wavy): Memberikan kesan estetis dan tidak kaku.
- Kartu Saldo & Tagihan: Warga langsung tahu status iuran mereka (Lunas/Belum).
- Fitur SOS: Tombol darurat yang langsung menghubungkan ke Satpam, Ambulans, atau Pemadam Kebakaran.
- Pembayaran Digital: Warga bisa memilih bulan iuran, upload bukti transfer, dan status akan berubah menjadi 'Menunggu Verifikasi'."

---

### C. Tampilan Admin/Ketua RT (Manajemen)
"Sekarang kita beralih ke sisi Admin:
- Verifikasi Cepat: Di dashboard, admin melihat notifikasi iuran masuk. Tinggal klik 'Terima' atau 'Tolak'.
- Laporan Otomatis: Tidak perlu rekap manual. Statistik pemasukan & pengeluaran tampil dalam bentuk grafik yang mudah dibaca.
- Kelola Warga: Admin bisa mendata warga baru dan memantau siapa yang rajin bayar dan yang nunggak.
- Cetak Kwitansi: Sistem bisa mencetak kwitansi digital (PDF) secara otomatis dan valid."

---

### D. Fitur Sosial & Komunitas
"Tidak hanya soal uang, Tiara Finance juga punya fitur sosial:
- Forum Diskusi: Warga bisa usul kegiatan (misal: Kerja Bakti), dan perlu approval Ketua RT sebelum tayang.
- Pengaduan (Wadul): Lapor lampu jalan mati atau sampah numpuk, update status pengaduan bisa dipantau real-time.
- Pengumuman: Ketua RT bisa kirim info penting yang langsung masuk notifikasi HP warga."

---

## 4. Kesimpulan & Penutup
"Jadi, Tiara Finance bukan sekadar aplikasi pencatat iuran, tapi sebuah Ekosistem Digital untuk lingkungan.
- Transparan: Semua mutasi uang tercatat.
- Efisien: Memangkas waktu admin/Ketua RT.
- Interaktif: Meningkatkan partisipasi warga lewat Forum & Laporan.

Sekian presentasi dari saya. Terima kasih."

---

Catatan Teknis:
- Kode bersih dan sudah menggunakan bahasa Indonesia yang santai pada komentar kodingan.
- Struktur folder rapi (MVC Pattern).
