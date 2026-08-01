-- =========================================================
-- GrowIn — Migrasi v3: perbaikan upload foto profil & foto CV.
-- Jalankan SETELAH schema.sql, migration_admin_and_notifications.sql,
-- dan migration_v2_features.sql, di Supabase Dashboard > SQL Editor.
-- Aman dijalankan berkali-kali.
--
-- Kenapa migrasi ini diperlukan:
-- schema.sql hanya membuat policy SELECT (lihat) dan INSERT (unggah baru)
-- untuk bucket 'avatars', 'cvs', dan 'company-logos'. Tidak ada policy
-- UPDATE / DELETE. Kode Flutter memanggil uploadBinary(..., upsert: true),
-- yang di baliknya butuh izin UPDATE bila file dengan path yang sama sudah
-- ada. Tanpa policy ini, sebagian upload foto gagal diam-diam (foto tidak
-- pernah benar-benar tersimpan / tidak muncul lagi setelah upload ulang).
-- =========================================================

-- ---- Bucket 'avatars' (foto profil pelamar) ----
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar" ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- Bucket 'cvs' (foto yang dipakai di CV Builder) ----
DROP POLICY IF EXISTS "Users can update own CV files" ON storage.objects;
CREATE POLICY "Users can update own CV files" ON storage.objects FOR UPDATE
  USING (bucket_id = 'cvs' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete own CV files" ON storage.objects;
CREATE POLICY "Users can delete own CV files" ON storage.objects FOR DELETE
  USING (bucket_id = 'cvs' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- Bucket 'company-logos' (foto profil recruiter) ----
DROP POLICY IF EXISTS "Recruiters can update own company logo" ON storage.objects;
CREATE POLICY "Recruiters can update own company logo" ON storage.objects FOR UPDATE
  USING (bucket_id = 'company-logos' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Recruiters can delete own company logo" ON storage.objects;
CREATE POLICY "Recruiters can delete own company logo" ON storage.objects FOR DELETE
  USING (bucket_id = 'company-logos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- Catatan tentang hapus CV / Surat Lamaran ----
-- Tabel `cvs` dan `cover_letters` SUDAH punya policy DELETE
-- ("Users can delete own CVs" / "Users can delete own cover letters") sejak
-- schema.sql awal, jadi tidak perlu SQL tambahan untuk itu — tombol Hapus
-- yang baru ditambahkan di aplikasi Flutter akan langsung berfungsi.
-- Jalankan blok di bawah ini HANYA jika query berikut mengembalikan 0 baris
-- (artinya policy delete belum ada di project kamu):
--
--   SELECT policyname FROM pg_policies
--   WHERE tablename IN ('cvs','cover_letters') AND cmd = 'DELETE';
--
DROP POLICY IF EXISTS "Users can delete own CVs" ON cvs;
CREATE POLICY "Users can delete own CVs" ON cvs FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own cover letters" ON cover_letters;
CREATE POLICY "Users can delete own cover letters" ON cover_letters FOR DELETE USING (auth.uid() = user_id);

-- Pastikan juga policy UPDATE ada (dipakai fitur edit CV/Surat Lamaran yang
-- sekarang benar-benar meng-update baris lama, bukan selalu insert baru).
DROP POLICY IF EXISTS "Users can update own CVs" ON cvs;
CREATE POLICY "Users can update own CVs" ON cvs FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own cover letters" ON cover_letters;
CREATE POLICY "Users can update own cover letters" ON cover_letters FOR UPDATE USING (auth.uid() = user_id);

NOTIFY pgrst, 'reload schema';
