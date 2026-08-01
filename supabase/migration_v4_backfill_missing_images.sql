-- =========================================================
-- GrowIn — Isi otomatis gambar untuk SEMUA lowongan yang BELUM
-- punya foto sampul (company_logo_url) dan/atau galeri foto (gallery_urls).
--
-- Jalankan di Supabase Dashboard > SQL Editor, SETELAH schema.sql &
-- migration_v2_features.sql (kolom gallery_urls sudah harus ada).
--
-- Aman dijalankan berkali-kali (idempotent) — hanya menimpa baris yang
-- gambarnya masih kosong/null, lowongan yang sudah punya foto sendiri
-- (mis. diunggah lewat halaman "Pasang Lowongan") TIDAK akan diubah.
--
-- Sumber gambar: picsum.photos (placeholder gratis, tanpa API key),
-- seed dipetakan dari id lowongan supaya tiap lowongan dapat foto yang
-- berbeda-beda & konsisten (tidak berubah tiap refresh). Ganti kapan saja
-- dengan foto asli lewat halaman "Pasang Lowongan" di app, atau edit
-- manual lewat UPDATE ... WHERE id = '...' di bawah.
-- =========================================================

-- 1. Isi foto sampul / logo perusahaan yang masih kosong.
UPDATE jobs
SET company_logo_url = 'https://picsum.photos/seed/' || id::text || '-logo/200/200'
WHERE company_logo_url IS NULL OR company_logo_url = '';

-- 2. Isi galeri foto (3 foto suasana kerja) untuk lowongan yang belum
--    punya galeri sama sekali.
UPDATE jobs
SET gallery_urls = ARRAY[
  'https://picsum.photos/seed/' || id::text || '-1/800/600',
  'https://picsum.photos/seed/' || id::text || '-2/800/600',
  'https://picsum.photos/seed/' || id::text || '-3/800/600'
]
WHERE gallery_urls IS NULL OR array_length(gallery_urls, 1) IS NULL;

-- =========================================================
-- CONTOH: ganti foto satu lowongan tertentu dengan foto asli perusahaan
-- (ganti '<judul-lowongan>' & URL sesuai kebutuhan):
--
--   UPDATE jobs SET
--     company_logo_url = 'https://url-logo-asli-kamu.jpg',
--     gallery_urls = ARRAY[
--       'https://url-foto-1-kamu.jpg',
--       'https://url-foto-2-kamu.jpg',
--       'https://url-foto-3-kamu.jpg'
--     ]
--   WHERE title = '<judul-lowongan>';
-- =========================================================

NOTIFY pgrst, 'reload schema';
