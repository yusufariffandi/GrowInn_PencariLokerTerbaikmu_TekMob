# GrowIn — Aplikasi Pencari Kerja & Pengembangan Karier Berbasis AI

## 📖 Deskripsi

**GrowIn** adalah aplikasi mobile berbasis **Flutter** yang membantu proses pencarian kerja dan pengembangan karier bagi dua jenis pengguna: **Karyawan (pencari kerja)** dan **Rekruter (perusahaan)** di Yogyakarta. Proyek ini dibangun sebagai kontribusi mendukung **SDGs 8 — Pekerjaan Layak dan Pertumbuhan Ekonomi**, dan merupakan hasil konversi dari prototype **HTML/Express** menjadi aplikasi mobile Flutter dengan tema hitam-putih glassmorphic ("**Mono Glass**").

Tujuan utama GrowIn adalah menjadi platform pencarian kerja yang menyeluruh — bukan sekadar menampilkan lowongan, tetapi juga membantu pengguna menyiapkan CV, membuat surat lamaran, melacak status lamaran, dan mendapat insight gaji, semuanya ditenagai **Google Gemini AI** dan backend **Supabase**.

Proyek ini dikembangkan sebagai tugas mata kuliah Teknologi Mobile di Universitas Ahmad Dahlan, di bawah **OpenCode Agency**.

---

## ✨ Fitur Utama

- 🔐 Alur login/signup **terpisah total** untuk Karyawan (jobseeker) & Rekruter
- 🏠 Home feed lowongan kerja, pencarian & filter berdasarkan kota
- 🗺️ Peta lowongan interaktif (OpenStreetMap, tanpa API key berbayar)
- 📝 Apply flow 3 langkah — pilih CV → detail lowongan → konfirmasi
- 📄 **Template CV Builder** — form terstruktur (Data Pribadi, Pendidikan, Pengalaman, Keahlian, Kontak, Hobi) + upload foto dari galeri/kamera, hasil tampil sebagai preview CV profesional
- ✉️ **Surat Lamaran (Template)** — form terstruktur yang otomatis tersusun jadi surat lamaran formal, siap **preview, print, atau export PDF** langsung dari HP
- 💰 **Kalkulator Gaji** dengan insight AI (Gemini)
- 📊 Application Tracker per status & daftar Lowongan Tersimpan
- 💬 Chat real-time (Supabase Realtime) & Notifikasi
- 🧑‍💼 Dashboard Rekruter — pasang lowongan & kelola kandidat per status

---

## ⚙️ Cara Instalasi

### Persyaratan

- Flutter SDK `>=3.3.0 <4.0.0`
- Akun [Supabase](https://supabase.com) (gratis)
- Akun Google + API key dari [Google AI Studio](https://aistudio.google.com) (gratis)

### Langkah-langkah

**1. Clone repository**

```bash
git clone https://github.com/yusufariffandi/GrowInn_PencariLokerTerbaikmu_TekMob.git
cd GrowInn_PencariLokerTerbaikmu_TekMob
```

**2. Install dependency & buat folder platform**

Proyek ini dikirim **tanpa folder `android/`, `ios/`, dll** (dibuat ulang otomatis agar tidak konflik versi Flutter/Gradle di komputer kamu):

```bash
flutter create .
flutter pub get
```

> `flutter create .` tidak akan menimpa `lib/` atau `pubspec.yaml` yang sudah ada.

**3. Tambahkan permission (wajib untuk fitur suara & peta)**

Edit `android/app/src/main/AndroidManifest.xml`, tambahkan sebelum tag `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

Untuk iOS, tambahkan di `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>GrowIn butuh akses mikrofon untuk simulasi wawancara suara.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>GrowIn butuh akses pengenalan suara untuk simulasi wawancara.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>GrowIn butuh lokasi untuk menampilkan peta lowongan terdekat.</string>
<key>NSCameraUsageDescription</key>
<string>GrowIn butuh akses kamera untuk mengambil foto profil & CV.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>GrowIn butuh akses galeri untuk memilih foto profil & CV.</string>
```

Set juga `minSdkVersion 21` di `android/app/build.gradle` (dibutuhkan oleh `speech_to_text`).

**4. Setup Supabase**

1. Buat project baru di [supabase.com](https://supabase.com).
2. Buka **SQL Editor**, jalankan seluruh isi `supabase/schema.sql`.
3. Jalankan juga `supabase/migration_admin_and_notifications.sql`.
4. Buka **Project Settings > API**, salin `Project URL` dan `anon public key`.
5. Buat akun Admin lewat **Authentication > Users > Add user**, lalu jalankan di SQL Editor:
   ```sql
   UPDATE profiles SET role = 'admin' WHERE email = 'EMAIL_ADMIN';
   ```

**5. Setup Google Gemini AI**

1. Buka [aistudio.google.com](https://aistudio.google.com) (bukan `console.cloud.google.com`).
2. Login, klik **"Get API key"** → **"Create API key"** → **"Create API key in new project"**.
3. Key langsung muncul (diawali `AIza...`), tanpa perlu kartu kredit atau NPWP.

**6. Isi file environment**

```bash
cp .env.example .env
```

Isi `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `GEMINI_API_KEY` di file `.env`.

**7. Jalankan aplikasi**

```bash
flutter run
```

---

## ▶️ Cara Penggunaan

1. **Pilih peran** saat pertama membuka aplikasi: **Karyawan** (pencari kerja) atau **Rekruter** (perusahaan), lalu buat akun (signup) sesuai peran.
2. **Sebagai Karyawan:**
   - Jelajahi lowongan di halaman *Home*, gunakan pencarian/filter kota, atau lihat lewat *Peta Lowongan*.
   - Buka menu **AI Tools** untuk membuat **CV** lewat Template CV Builder — isi form Data Pribadi, Pendidikan, Pengalaman, dsb., lalu unggah foto profil.
   - Buat **Surat Lamaran** lewat form terstruktur, lalu langsung *preview*, *print*, atau *export PDF*.
   - Lamar lowongan lewat *Apply flow* (pilih CV → detail → konfirmasi), lalu pantau statusnya di **Application Tracker**.
   - Gunakan **Kalkulator Gaji** untuk mendapat insight gaji berbasis AI.
   - Chat langsung dengan rekruter dan pantau **Notifikasi**.
3. **Sebagai Rekruter:**
   - Pasang lowongan baru lewat Dashboard Rekruter.
   - Kelola kandidat yang melamar berdasarkan status (baru, diproses, diterima, ditolak).
4. **Sebagai Admin** *(opsional)*: login lewat layar tersembunyi `/login/admin` untuk mengelola tampilan aplikasi (`app_images`).

Contoh menjalankan aplikasi di perangkat/emulator yang sudah terhubung:

```bash
flutter run
```

---

## 🤝 Kontribusi

Kontribusi terbuka bagi siapa pun yang ingin membantu pengembangan GrowIn. Untuk berkontribusi:

1. **Fork** repository ini.
2. Buat branch baru untuk fitur/perbaikan yang dikerjakan:
   ```bash
   git checkout -b fitur/nama-fitur
   ```
3. Lakukan perubahan dan commit dengan pesan yang jelas:
   ```bash
   git commit -m "feat: menambahkan fitur X"
   ```
4. Push ke branch tersebut:
   ```bash
   git push origin fitur/nama-fitur
   ```
5. Buka **Pull Request** ke branch `main`, jelaskan perubahan yang dilakukan secara singkat.

**Panduan tambahan:**
- Ikuti struktur folder yang sudah ada di `lib/features/` untuk fitur baru.
- Pastikan `flutter analyze` tidak menghasilkan error sebelum membuat PR.
- Gunakan `GeminiService` untuk pemanggilan AI, jangan panggil API Gemini langsung dari widget.
- Laporkan bug atau ide fitur lewat tab **Issues**.

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan akademik (tugas mata kuliah Teknologi Mobile, Universitas Ahmad Dahlan) di bawah **OpenCode Agency**. Belum ada lisensi open-source resmi yang diterapkan — silakan hubungi pemilik repository (**yusufariffandi**) untuk izin penggunaan, distribusi, atau modifikasi di luar konteks akademik ini.

---

<p align="center">Dibuat dengan 🖤 untuk mendukung SDGs 8 — Pekerjaan Layak dan Pertumbuhan Ekonomi</p>
