# Lab-Track: Sistem Manajemen Peminjaman Barang Laboratorium

Aplikasi manajemen peminjaman barang laboratorium berbasis **Flutter** dan **Firebase** yang dirancang untuk memudahkan administrasi inventaris secara digital dan real-time. Proyek ini dikembangkan sebagai tugas besar UAS Pemrograman Mobile.

---

## Fitur Utama
- **Autentikasi Firebase**: Login aman untuk Admin dan Mahasiswa.
- **Manajemen Inventaris (CRUD)**: Admin dapat mengelola data barang (Tambah, Edit, Hapus) secara real-time.
- **Sistem Peminjaman Akurat**: Pencatatan peminjaman dengan validasi waktu (Jam & Menit).
- **Ekspor Laporan PDF**: Fitur cetak riwayat peminjaman ke dalam format PDF yang rapi untuk arsip.
- **Status Peminjaman**: Pelacakan status barang (Dipinjam/Tersedia) secara otomatis.
- **Custom Branding**: Aplikasi sudah dilengkapi dengan ikon kustom "LabTrack".

## Teknologi & Library
- **Framework**: Flutter
- **Database**: Cloud Firestore (NoSQL)
- **Auth**: Firebase Authentication
- **Library Penting**:
  - `pdf` & `printing`: Untuk generate laporan PDF.
  - `intl`: Untuk format tanggal dan waktu Indonesia.
  - `flutter_launcher_icons`: Untuk manajemen ikon aplikasi.

## Download Aplikasi (APK)
Anda dapat mengunduh file instalasi aplikasi yang sudah siap pakai (APK) melalui halaman **Releases** di repository ini:

**[Download LabTrack APK Terbaru](https://github.com/LUCIVTAS/Peminjaman-Barang/releases)**

## Cara Menjalankan dari Source Code
1. Clone repository ini:
   ```bash
   git clone [https://github.com/LUCIVTAS/Peminjaman-Barang.git](https://github.com/LUCIVTAS/Peminjaman-Barang.git)
