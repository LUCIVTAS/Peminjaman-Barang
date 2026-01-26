# Lab-Track: Sistem Manajemen Peminjaman Barang Laboratorium
 Nama Anggota :
 Muhammad Al Fatih (230311005)
 Mahpujah (230311013)
 Diah (230311036)
Aplikasi manajemen peminjaman barang laboratorium berbasis **Flutter** dan **Firebase** yang dirancang untuk memudahkan administrasi inventaris secara digital dan real-time. Proyek ini dikembangkan sebagai tugas besar UAS Pemrograman Mobile.

---

## Fitur Utama
- **Autentikasi Firebase**: Sistem login aman untuk Admin dan Mahasiswa menggunakan Firebase Auth.
- **Notifikasi Push Real-time (FCM V1)**: Pemberitahuan instan ke perangkat mahasiswa saat status peminjaman disetujui atau diperbarui menggunakan protokol Google API terbaru.
- **Manajemen Inventaris (CRUD)**: Admin memiliki kendali penuh untuk mengelola data barang (Tambah, Edit, Hapus) secara langsung.
- **Sistem Peminjaman Akurat**: Pencatatan riwayat peminjaman dengan validasi waktu presisi (Jam & Menit).
- **Ekspor Laporan PDF**: Fitur cetak riwayat peminjaman ke format PDF untuk keperluan arsip fisik laboratorium.
- **Status Barang Otomatis**: Sinkronisasi status barang (Tersedia/Dipinjam) secara real-time di semua perangkat.
- **Custom Branding**: Antarmuka yang intuitif dengan ikon kustom "LabTrack".

## Teknologi & Library
- **Framework**: Flutter (Dart)
- **Database**: Cloud Firestore
- **Cloud Messaging**: Firebase Cloud Messaging (FCM V1 API)
- **Auth**: Firebase Authentication
- **Library Utama**:
  - `firebase_messaging`: Komunikasi notifikasi cloud.
  - `googleapis_auth`: Autentikasi server-to-server untuk pengiriman notifikasi.
  - `pdf` & `printing`: Pembuatan dokumen laporan.
  - `intl`: Lokalisasi format waktu Indonesia.



## Download Aplikasi (APK)
Anda dapat mengunduh file instalasi aplikasi yang sudah siap pakai (APK) melalui halaman **Releases** di repository ini:

**[Download LabTrack APK Terbaru](https://github.com/LUCIVTAS/Peminjaman-Barang/releases)**

---

## Cara Menjalankan dari Source Code

### 1. Persiapan Awal
Pastikan Flutter SDK sudah terpasang, lalu clone repository ini:
```bash
git clone [https://github.com/LUCIVTAS/Peminjaman-Barang.git](https://github.com/LUCIVTAS/Peminjaman-Barang.git)
cd Peminjaman-Barang
Pastikan file service-account.json telah didaftarkan pada file pubspec.yaml agar fitur notifikasi dapat berjalan dengan normal.

Maksud saya adalah semua bagian itu (dari judul sampai akhir) digabung menjadi satu di dalam satu file bernama README.md.

File README.md adalah satu-satunya file dokumentasi yang akan dibaca otomatis oleh GitHub untuk menampilkan halaman depan repository Anda. Jadi, Anda tidak perlu memisahnya ke banyak file.

Berikut adalah isi seluruh file README.md yang sudah saya satukan. Anda tinggal menghapus semua isi file README.md yang lama di VS Code, lalu tempel (paste) kode di bawah ini:

Markdown
# Lab-Track: Sistem Manajemen Peminjaman Barang Laboratorium

Aplikasi manajemen peminjaman barang laboratorium berbasis **Flutter** dan **Firebase** yang dirancang untuk memudahkan administrasi inventaris secara digital dan real-time. Proyek ini dikembangkan sebagai tugas besar UAS Pemrograman Mobile.

---

## 🚀 Fitur Utama
- **Autentikasi Firebase**: Sistem login aman untuk Admin dan Mahasiswa menggunakan Firebase Auth.
- **Notifikasi Push Real-time (FCM V1)**: Pemberitahuan instan ke perangkat mahasiswa saat status peminjaman disetujui atau diperbarui menggunakan protokol Google API terbaru.
- **Manajemen Inventaris (CRUD)**: Admin memiliki kendali penuh untuk mengelola data barang (Tambah, Edit, Hapus) secara langsung.
- **Sistem Peminjaman Akurat**: Pencatatan riwayat peminjaman dengan validasi waktu presisi (Jam & Menit).
- **Ekspor Laporan PDF**: Fitur cetak riwayat peminjaman ke format PDF untuk keperluan arsip fisik laboratorium.
- **Status Barang Otomatis**: Sinkronisasi status barang (Tersedia/Dipinjam) secara real-time di semua perangkat.
- **Custom Branding**: Antarmuka yang intuitif dengan ikon kustom "LabTrack".

## 🛠️ Teknologi & Library
- **Framework**: Flutter (Dart)
- **Database**: Cloud Firestore
- **Cloud Messaging**: Firebase Cloud Messaging (FCM V1 API)
- **Auth**: Firebase Authentication
- **Library Utama**:
  - `firebase_messaging`: Komunikasi notifikasi cloud.
  - `googleapis_auth`: Autentikasi server-to-server untuk pengiriman notifikasi.
  - `pdf` & `printing`: Pembuatan dokumen laporan.
  - `intl`: Lokalisasi format waktu Indonesia.



## 📱 Download Aplikasi (APK)
Anda dapat mengunduh file instalasi aplikasi yang sudah siap pakai (APK) melalui halaman **Releases** di repository ini:

**[👉 Download LabTrack APK Terbaru](https://github.com/LUCIVTAS/Peminjaman-Barang/releases)**

---

## 💻 Cara Menjalankan dari Source Code

### 1. Persiapan Awal
Pastikan Flutter SDK sudah terpasang, lalu clone repository ini:
```bash
git clone [https://github.com/LUCIVTAS/Peminjaman-Barang.git](https://github.com/LUCIVTAS/Peminjaman-Barang.git)
cd Peminjaman-Barang

### 2. Konfigurasi Firebase & Notifikasi
Buat proyek di Firebase Console.

Unduh google-services.json dan letakkan di android/app/.

Konfigurasi Service Account (FCM V1):

Masuk ke Project Settings > Service Accounts.

Klik Generate New Private Key, unduh filenya.

Simpan di: lib/assets/service-account.json.

PENTING: Jangan unggah file ini ke GitHub. Tambahkan path tersebut ke .gitignore.

### 3. Konfigurasi Manifest (Android)
Agar notifikasi muncul dengan prioritas tinggi, pastikan AndroidManifest.xml memiliki channel ID berikut di dalam tag <activity>:

XML
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />

### 4. Pengaturan Payload Notifikasi
Aplikasi menggunakan pengiriman berbasis data payload untuk memastikan notifikasi instan:

Dart
'android': {
  'priority': 'high',
  'notification': {
    'notification_priority': 'PRIORITY_HIGH',
    'sound': 'default',
  },
}

### 5. Instalasi & Jalankan
Bash
flutter pub get
flutter run