# GrowIn — Flutter App

Aplikasi pencarian kerja & pengembangan karier berbasis AI untuk pencari kerja
(Karyawan) dan perusahaan (Rekruter) di Yogyakarta. Konversi dari prototype
HTML/Express ke Flutter, dengan tema **hitam-putih glassmorphic ("Mono Glass")**,
backend **Supabase**, dan semua fitur AI ditenagai **Google Gemini**.

## ✨ Fitur

- Alur login/signup **terpisah total** untuk Karyawan (jobseeker) & Rekruter
- Home feed lowongan, pencarian & filter kota, peta lowongan (OpenStreetMap)
- Apply flow 3 langkah (pilih CV → detail → konfirmasi)
- **Template CV Builder** — form terstruktur (Data Pribadi, Pendidikan, Pengalaman,
  Keahlian, Kontak, Hobi) + upload foto dari galeri/kamera perangkat, dengan opsi
  langsung dipakai sebagai foto profil akun; hasilnya tampil di preview bergaya
  CV profesional (sidebar gelap + foto, konten kanan)
- **Surat Lamaran (Template)** — form terstruktur (tujuan surat, info lowongan, data
  pribadi, daftar lampiran berkas) yang otomatis tersusun jadi surat lamaran formal
  siap **preview, print, atau export PDF** langsung dari HP
- **Kalkulator Gaji** dengan insight AI
- Application Tracker (per status), Lowongan Tersimpan
- Chat real-time (Supabase Realtime), Notifikasi
- Dashboard Rekruter: pasang lowongan, kelola kandidat per status

## 🧱 Struktur Proyek

```
lib/
  core/           # theme (warna, tipografi), router (go_router)
  models/         # data class (Job, Profile, Application, CV, dst.)
  services/       # SupabaseService, GeminiService, VoiceService
  providers/      # Riverpod providers (auth, job, application, message, notification)
  shared/widgets/ # GlassPane, JobCard, PrimaryPillButton, dst. (reusable)
  features/
    auth/         # splash, role-select, login/signup (jobseeker & recruiter terpisah)
    home/         # main shell (bottom nav role-aware), home jobseeker & recruiter
    job/          # search, detail, peta, apply flow
    ai/           # AI tools hub (CV, surat lamaran, peta lowongan)
    cv/           # Template CV Builder (form + upload foto) & preview
    cover_letter/ # Template Surat Lamaran Builder, PDF generator & preview/print
    profile/      # profile, saved jobs
    tracker/      # application tracker
    messages/     # list chat & chat detail
    career_tools/ # kalkulator gaji
    recruiter/    # daftar lowongan, post job, kandidat
supabase/
  schema.sql      # schema lengkap + RLS + storage buckets, siap dijalankan di Supabase
```

## 🚀 Cara Menjalankan

### 1. Install dependency & buat folder platform

Project ini dikirim **tanpa folder `android/`, `ios/`, dll** (dibuat ulang otomatis
supaya tidak konflik versi Flutter/Gradle di komputer kamu). Jalankan di root project:

```bash
flutter create .
flutter pub get
```

Perintah `flutter create .` tidak akan menimpa `lib/` atau `pubspec.yaml` yang sudah ada.

### 2. Tambahkan permission (WAJIB untuk fitur suara & peta)

Setelah `flutter create .`, edit `android/app/src/main/AndroidManifest.xml`,
tambahkan sebelum tag `<application>`:

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

### 3. Setup Supabase

1. Buat project baru di [supabase.com](https://supabase.com) (gratis).
2. Buka **SQL Editor**, jalankan seluruh isi `supabase/schema.sql`.
3. Jalankan juga `supabase/migration_admin_and_notifications.sql` (menambah role
   `admin`, tabel `app_images`, dan storage bucket `app-images` untuk fitur
   "Kelola Tampilan").
4. Buka **Project Settings > API**, salin `Project URL` dan `anon public key`.
5. Buat 1 akun Admin: **Authentication > Users > Add user** (isi email & password),
   lalu jalankan `UPDATE profiles SET role = 'admin' WHERE email = 'EMAIL_ADMIN';`
   di SQL Editor. Login lewat layar tersembunyi `/login/admin` di app (tidak
   ditautkan dari halaman pilih peran publik).

### 4. Setup Google Gemini AI

1. Buka **[aistudio.google.com](https://aistudio.google.com)** — BUKAN `console.cloud.google.com`.
   Google AI Studio adalah platform gratis permanen untuk Gemini API, terpisah dari
   Google Cloud Console (yang minta info pembayaran untuk trial $300 produk cloud lain).
2. Login dengan akun Google biasa, klik **"Get API key"** di sidebar kiri.
3. Klik **"Create API key"** → **"Create API key in new project"**.
4. Key langsung muncul (diawali `AIza...`), **tanpa perlu kartu kredit atau NPWP**.
5. Jangan klik banner "Try Google Cloud for free" — itu untuk fitur cloud lain yang
   memang mewajibkan info pembayaran, tidak dibutuhkan untuk Gemini API.

Free tier: ±10 request/menit & beberapa ratus request/hari untuk model Flash — cukup
untuk testing/skripsi. Model default project ini adalah `gemini-3.5-flash` (bisa
diganti lewat `GEMINI_MODEL` di `.env`). Google terus merilis model baru dan mem-pensiunkan
yang lama secara berkala — kalau suatu saat muncul error "model no longer available" atau
404, cukup ganti nilai `GEMINI_MODEL` di `.env` ke model Flash terbaru yang direkomendasikan
di [ai.google.dev/gemini-api/docs/models](https://ai.google.dev/gemini-api/docs/models),
tidak perlu ubah kode.

### 5. Isi file `.env`

```bash
cp .env.example .env
```

Lalu isi `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `GEMINI_API_KEY` di file `.env`.

### 6. Jalankan aplikasi

```bash
flutter run
```

## 🎨 Desain — "Mono Glass"

Redesign dari tema asli "Spatial Glass" (coklat/cream) menjadi **hitam-putih
glassmorphic**: panel kaca blur di atas mesh gradient monokrom, tombol pil hitam
solid, dan aksen warna dijaga netral (lihat `lib/core/theme/app_colors.dart`).

## 🔑 Catatan Penting

- Semua panggilan AI (salary insight, dll) lewat satu
  `GeminiService` (`lib/services/gemini_service.dart`) — kalau `GEMINI_API_KEY`
  kosong, fitur akan menampilkan pesan error yang jelas, bukan crash.
- **CV dan Surat Lamaran dibuat lewat form/template** (`lib/features/cv/` &
  `lib/features/cover_letter/`), bukan generatif-AI — isian mengikuti pertanyaan
  standar masing-masing dokumen. Surat lamaran dirender jadi PDF asli lewat
  package `pdf` + `printing`, bisa langsung di-print, di-share, atau disimpan
  sebagai file dari layar preview.
- Role `jobseeker`/`recruiter` disimpan di tabel `profiles` dan otomatis dibuat
  lewat trigger `handle_new_user()` saat signup (dikirim dari Flutter via
  `data: {name, role}` pada `Supabase.auth.signUp`).
- Chat & notifikasi pakai Supabase Realtime (`.stream()`), tidak perlu server
  Socket.io terpisah seperti prototype awal.
