-- =========================================================
-- GrowIn — Migrasi v2: Galeri Foto Lowongan (3 slide) & slot
-- gambar Hero untuk halaman utama pelamar.
-- Jalankan SETELAH schema.sql dan migration_admin_and_notifications.sql,
-- di Supabase Dashboard > SQL Editor. Aman dijalankan berkali-kali.
-- =========================================================

-- 1. Kolom galeri foto pekerjaan (maks 3 URL) di tabel jobs.
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS gallery_urls TEXT[] DEFAULT '{}';

-- 2. Storage bucket khusus galeri foto lowongan, publik untuk dibaca,
--    hanya recruiter pemilik folder (uid) yang boleh upload.
INSERT INTO storage.buckets (id, name, public) VALUES ('job-gallery', 'job-gallery', true)
  ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "Anyone can view job gallery" ON storage.objects;
CREATE POLICY "Anyone can view job gallery" ON storage.objects FOR SELECT
  USING (bucket_id = 'job-gallery');

DROP POLICY IF EXISTS "Recruiters can upload job gallery" ON storage.objects;
CREATE POLICY "Recruiters can upload job gallery" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'job-gallery' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Recruiters can update own job gallery" ON storage.objects;
CREATE POLICY "Recruiters can update own job gallery" ON storage.objects FOR UPDATE
  USING (bucket_id = 'job-gallery' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 3. Slot gambar Hero untuk Beranda Pelamar (dikelola Admin lewat
--    app_images, key 'jobseeker_hero'). Tidak perlu SQL tambahan karena
--    tabel app_images sudah generik (key/url) — cukup tambahkan slot ini
--    di daftar _kImageSlots pada admin_home_screen.dart (sudah dilakukan).

NOTIFY pgrst, 'reload schema';
