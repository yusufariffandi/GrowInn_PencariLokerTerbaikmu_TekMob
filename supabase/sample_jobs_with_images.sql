-- =========================================================
-- GrowIn — Contoh data lowongan pekerjaan LENGKAP DENGAN FOTO
-- (foto sampul & galeri 3 foto), untuk testing tampilan Job Detail /
-- Job Card di aplikasi. Jalankan di Supabase Dashboard > SQL Editor,
-- SETELAH schema.sql & migration_v2_features.sql (kolom gallery_urls).
--
-- Foto di bawah pakai layanan placeholder gratis (picsum.photos) —
-- ganti dengan URL foto asli perusahaan kamu kapan saja lewat halaman
-- "Pasang Lowongan" di app, atau edit langsung UPDATE di bagian bawah.
-- =========================================================

-- 1. Lowongan ini akan dikaitkan ke akun RECRUITER pertama yang ada di
--    tabel profiles. Kalau kamu mau pilih recruiter tertentu, ganti baris
--    SELECT id FROM profiles ... di bawah dengan:
--    SELECT id FROM profiles WHERE email = 'email_recruiter_kamu@contoh.com'

INSERT INTO jobs (
  recruiter_id, title, company, company_logo_url, location, city, lat, lng,
  salary_min, salary_max, salary_display, experience_level, job_type,
  industry, description, qualifications, about_company, gallery_urls,
  is_active
)
SELECT
  p.id,
  'Frontend Developer (React)',
  COALESCE(NULLIF(p.company_name, ''), 'GrowIn Digital'),
  'https://picsum.photos/seed/growin-logo/200/200',
  'Yogyakarta',
  'Yogyakarta',
  -7.797068,
  110.370529,
  6000000,
  9000000,
  'Rp6.000.000 - Rp9.000.000',
  'Mid',
  'Full-time',
  'Teknologi Informasi',
  'Kami mencari Frontend Developer berpengalaman untuk membangun antarmuka aplikasi web yang cepat dan mudah digunakan, bekerja sama dengan tim produk & desain.',
  'Menguasai React/Flutter, familiar dengan REST API, minimal 1 tahun pengalaman.',
  'GrowIn Digital adalah perusahaan rintisan yang fokus mengembangkan produk teknologi untuk membantu pencari kerja di Indonesia.',
  ARRAY[
    'https://picsum.photos/seed/growin-office-1/800/600',
    'https://picsum.photos/seed/growin-office-2/800/600',
    'https://picsum.photos/seed/growin-office-3/800/600'
  ],
  true
FROM profiles p
WHERE p.role = 'recruiter'
ORDER BY p.created_at ASC
LIMIT 1;

-- 2. Contoh lowongan kedua (opsional) — hapus blok ini kalau tidak perlu.
INSERT INTO jobs (
  recruiter_id, title, company, company_logo_url, location, city, lat, lng,
  salary_min, salary_max, salary_display, experience_level, job_type,
  industry, description, qualifications, about_company, gallery_urls,
  is_active
)
SELECT
  p.id,
  'Staff Admin & Keuangan',
  COALESCE(NULLIF(p.company_name, ''), 'GrowIn Digital'),
  'https://picsum.photos/seed/growin-logo/200/200',
  'Sleman, Yogyakarta',
  'Yogyakarta',
  -7.716851,
  110.404114,
  4000000,
  5500000,
  'Rp4.000.000 - Rp5.500.000',
  'Entry',
  'Full-time',
  'Administrasi',
  'Bertanggung jawab mengelola pencatatan keuangan harian, arsip dokumen, dan koordinasi administrasi kantor.',
  'Lulusan minimal D3 Akuntansi/Manajemen, teliti, menguasai Excel dasar.',
  'GrowIn Digital adalah perusahaan rintisan yang fokus mengembangkan produk teknologi untuk membantu pencari kerja di Indonesia.',
  ARRAY[
    'https://picsum.photos/seed/growin-team-1/800/600',
    'https://picsum.photos/seed/growin-team-2/800/600',
    'https://picsum.photos/seed/growin-team-3/800/600'
  ],
  true
FROM profiles p
WHERE p.role = 'recruiter'
ORDER BY p.created_at ASC
LIMIT 1;

-- =========================================================
-- CATATAN:
-- - Kalau query di atas tidak menghasilkan baris (0 rows inserted), artinya
--   belum ada akun dengan role = 'recruiter' di project Supabase kamu.
--   Daftar dulu 1 akun recruiter lewat aplikasi, baru jalankan ulang SQL ini.
-- - Untuk mengganti foto lowongan yang sudah ada, jalankan contoh berikut
--   (ganti 'Frontend Developer (React)' dengan judul lowongan yang mau diedit):
--
--   UPDATE jobs SET gallery_urls = ARRAY[
--     'https://url-foto-1-kamu.jpg',
--     'https://url-foto-2-kamu.jpg',
--     'https://url-foto-3-kamu.jpg'
--   ] WHERE title = 'Frontend Developer (React)';
-- =========================================================

NOTIFY pgrst, 'reload schema';
