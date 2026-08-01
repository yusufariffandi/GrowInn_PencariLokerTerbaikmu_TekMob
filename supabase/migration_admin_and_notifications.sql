-- =========================================================
-- GrowIn — Migrasi tambahan: Akun Admin (kelola gambar) & hapus
-- tabel AI Interview yang sudah tidak dipakai lagi.
-- Jalankan SETELAH schema.sql utama, di Supabase Dashboard > SQL Editor.
-- Aman dijalankan berkali-kali.
-- =========================================================

-- 1. Izinkan role 'admin' di tabel profiles
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('jobseeker', 'recruiter', 'admin'));

-- 2. Tabel app_images — menyimpan gambar apa saja yang tampil di app
--    (hero landing, kartu fitur, dll), supaya bisa diganti admin tanpa
--    perlu update aplikasi.
CREATE TABLE IF NOT EXISTS app_images (
  key TEXT PRIMARY KEY,          -- contoh: 'landing_hero', 'feature_card_1'
  url TEXT NOT NULL DEFAULT '',
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view app images" ON app_images;
CREATE POLICY "Anyone can view app images" ON app_images FOR SELECT USING (true);

DROP POLICY IF EXISTS "Only admin can manage app images" ON app_images;
CREATE POLICY "Only admin can manage app images" ON app_images FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

-- 3. Storage bucket khusus gambar tampilan app, publik untuk dibaca,
--    hanya admin yang boleh upload/ubah/hapus.
INSERT INTO storage.buckets (id, name, public) VALUES ('app-images', 'app-images', true)
  ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "Anyone can view app-images bucket" ON storage.objects;
CREATE POLICY "Anyone can view app-images bucket" ON storage.objects FOR SELECT
  USING (bucket_id = 'app-images');

DROP POLICY IF EXISTS "Only admin can upload app-images" ON storage.objects;
CREATE POLICY "Only admin can upload app-images" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'app-images' AND EXISTS (
    SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  ));

DROP POLICY IF EXISTS "Only admin can update app-images" ON storage.objects;
CREATE POLICY "Only admin can update app-images" ON storage.objects FOR UPDATE
  USING (bucket_id = 'app-images' AND EXISTS (
    SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  ));

-- 4. (Opsional, boleh dilewati) bersih-bersih tabel AI Interview yang
--    fiturnya sudah dihapus dari aplikasi:
-- DROP TABLE IF EXISTS interview_sessions;

-- 5. Cara bikin 1 akun admin (karena signup admin sengaja TIDAK dibuka
--    publik lewat aplikasi, harus dibuat manual lewat dashboard):
--    a) Buka Supabase Dashboard > Authentication > Users > "Add user"
--       isi email & password untuk admin.
--    b) Jalankan SQL ini (ganti EMAIL_ADMIN dengan email yang barusan dibuat):
--
--    UPDATE profiles SET role = 'admin', name = 'Admin GrowIn'
--    WHERE email = 'EMAIL_ADMIN';
--
--    Setelah itu login di app lewat layar tersembunyi /login/admin
--    menggunakan email & password tsb.

NOTIFY pgrst, 'reload schema';
