-- =========================================================
-- GrowIn — Supabase Schema (Flutter version)
-- Jalankan di Supabase Dashboard > SQL Editor
-- Schema ini adalah lanjutan dari schema.sql prototype awal,
-- ditambah beberapa kolom & storage bucket yang dibutuhkan
-- oleh versi Flutter (foto profil, upload CV, lampiran chat).
-- =========================================================

-- 1. Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL CHECK (role IN ('jobseeker', 'recruiter')),
  avatar_url TEXT DEFAULT '',
  headline TEXT DEFAULT '',
  location TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  summary TEXT DEFAULT '',
  skills TEXT[] DEFAULT '{}',
  company_name TEXT DEFAULT '',        -- dipakai bila role = recruiter
  company_logo_url TEXT DEFAULT '',    -- dipakai bila role = recruiter
  is_verified BOOLEAN DEFAULT FALSE,
  completeness INT DEFAULT 20,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Jobs table (diposting oleh recruiter)
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recruiter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  company TEXT NOT NULL,
  company_logo_url TEXT DEFAULT '',
  location TEXT NOT NULL,
  city TEXT DEFAULT 'Yogyakarta',
  lat DECIMAL DEFAULT -7.79,
  lng DECIMAL DEFAULT 110.38,
  salary_min DECIMAL,
  salary_max DECIMAL,
  salary_display TEXT DEFAULT 'Negotiable',
  experience_level TEXT DEFAULT 'Mid',
  job_type TEXT DEFAULT 'Full-time',
  industry TEXT DEFAULT '',
  description TEXT DEFAULT '',
  qualifications TEXT DEFAULT '',
  about_company TEXT DEFAULT '',
  applicants_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Applications table
CREATE TABLE IF NOT EXISTS applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  cv_id UUID,
  status TEXT DEFAULT 'Terkirim' CHECK (status IN ('Terkirim', 'Dilihat', 'Interview', 'Diterima', 'Ditolak')),
  cover_letter TEXT DEFAULT '',
  expected_salary TEXT DEFAULT '',
  notice_period TEXT DEFAULT 'Segera',
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(job_id, user_id)
);

-- 4. CVs table (tersimpan, dibuat lewat Template CV Builder / upload foto sendiri)
CREATE TABLE IF NOT EXISTS cvs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  fullname TEXT DEFAULT '',
  title TEXT DEFAULT '',              -- tagline, contoh: "Lulusan Baru"
  summary TEXT DEFAULT '',
  photo_url TEXT DEFAULT '',
  -- Data Pribadi
  birth_place TEXT DEFAULT '',
  birth_date TEXT DEFAULT '',
  location TEXT DEFAULT '',           -- alamat
  phone TEXT DEFAULT '',
  gender TEXT DEFAULT '',
  religion TEXT DEFAULT '',
  nationality TEXT DEFAULT 'Indonesia',
  email TEXT DEFAULT '',
  marital_status TEXT DEFAULT '',
  -- Kontak (sidebar CV, bisa berbeda dari data pribadi)
  contact_phone TEXT DEFAULT '',
  contact_address TEXT DEFAULT '',
  contact_website TEXT DEFAULT '',
  -- Pendidikan & Pengalaman
  educations JSONB DEFAULT '[]',
  experiences JSONB DEFAULT '[]',
  -- Keahlian & Hobi
  skills_tech TEXT[] DEFAULT '{}',
  skills_soft TEXT[] DEFAULT '{}',
  file_url TEXT DEFAULT '',           -- untuk CV hasil upload PDF (opsional)
  is_ai_generated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4b. Cover Letters table (Template Surat Lamaran Builder)
CREATE TABLE IF NOT EXISTS cover_letters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  place TEXT DEFAULT '',
  letter_date TEXT DEFAULT '',
  company_name TEXT DEFAULT '',
  recipient_title TEXT DEFAULT '',
  company_address TEXT DEFAULT '',
  source_site TEXT DEFAULT '',
  source_date TEXT DEFAULT '',
  position TEXT DEFAULT '',
  fullname TEXT DEFAULT '',
  birth_place TEXT DEFAULT '',
  birth_date TEXT DEFAULT '',
  gender TEXT DEFAULT '',
  address TEXT DEFAULT '',
  last_education TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  attachments JSONB DEFAULT '[]',
  signature_name TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  attachment_url TEXT DEFAULT '',
  read_status BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT DEFAULT 'job' CHECK (category IN ('job','status','message','tips')),
  title TEXT NOT NULL,
  body TEXT DEFAULT '',
  action_url TEXT DEFAULT '',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Interview sessions table (AI Interview Simulator - voice)
CREATE TABLE IF NOT EXISTS interview_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  company TEXT NOT NULL,
  score_tone INT DEFAULT 0,
  score_filler INT DEFAULT 0,
  score_structure INT DEFAULT 0,
  score_overall INT DEFAULT 0,
  history JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Saved jobs (bookmark) — dipisah dari applications
CREATE TABLE IF NOT EXISTS saved_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, job_id)
);

-- =========================================================
-- Row Level Security
-- =========================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE cvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cover_letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Anyone can view public profile fields" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Anyone can view jobs" ON jobs FOR SELECT USING (true);
CREATE POLICY "Recruiters can insert jobs" ON jobs FOR INSERT WITH CHECK (auth.uid() = recruiter_id);
CREATE POLICY "Recruiters can update own jobs" ON jobs FOR UPDATE USING (auth.uid() = recruiter_id);
CREATE POLICY "Recruiters can delete own jobs" ON jobs FOR DELETE USING (auth.uid() = recruiter_id);

CREATE POLICY "Users can view own applications" ON applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Recruiters can view applications to their jobs" ON applications FOR SELECT
  USING (EXISTS (SELECT 1 FROM jobs WHERE jobs.id = applications.job_id AND jobs.recruiter_id = auth.uid()));
CREATE POLICY "Users can insert own applications" ON applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Recruiters can update status of applications to their jobs" ON applications FOR UPDATE
  USING (EXISTS (SELECT 1 FROM jobs WHERE jobs.id = applications.job_id AND jobs.recruiter_id = auth.uid()));

CREATE POLICY "Users can view own CVs" ON cvs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own CVs" ON cvs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own CVs" ON cvs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own CVs" ON cvs FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own cover letters" ON cover_letters FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own cover letters" ON cover_letters FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own cover letters" ON cover_letters FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own cover letters" ON cover_letters FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own messages" ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can send messages" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update read status of received messages" ON messages FOR UPDATE
  USING (auth.uid() = receiver_id);

CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can manage own interview sessions" ON interview_sessions FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own saved jobs" ON saved_jobs FOR ALL USING (auth.uid() = user_id);

-- Auto-create profile on signup (role dikirim dari Flutter saat signUp via metadata)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'jobseeker')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =========================================================
-- Storage buckets (jalankan lewat Supabase Dashboard > Storage,
-- atau via SQL berikut bila "storage" extension aktif)
-- =========================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('cvs', 'cvs', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('chat-attachments', 'chat-attachments', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('company-logos', 'company-logos', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Anyone can view avatar files" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view CV files" ON storage.objects FOR SELECT USING (bucket_id = 'cvs');
CREATE POLICY "Users can upload own CV" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'cvs' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view chat attachments" ON storage.objects FOR SELECT USING (bucket_id = 'chat-attachments');
CREATE POLICY "Users can upload chat attachments" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'chat-attachments' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view company logos" ON storage.objects FOR SELECT USING (bucket_id = 'company-logos');
CREATE POLICY "Recruiters can upload company logo" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'company-logos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Enable realtime for chat & notifications
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE applications;

-- =========================================================
-- MIGRASI (jalankan blok ini SAJA bila kamu sudah pernah membuat
-- tabel `cvs` versi lama sebelum fitur Template CV Builder ini ada).
-- Aman dijalankan berkali-kali karena pakai IF NOT EXISTS.
-- =========================================================
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS birth_place TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS birth_date TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS religion TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS nationality TEXT DEFAULT 'Indonesia';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS marital_status TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS contact_phone TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS contact_address TEXT DEFAULT '';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS contact_website TEXT DEFAULT '';
-- Jika kolom skills_tech / skills_soft lama bertipe TEXT (bukan TEXT[]),
-- jalankan ini untuk mengubah tipenya:
-- ALTER TABLE cvs ALTER COLUMN skills_tech TYPE TEXT[] USING string_to_array(skills_tech, ',');
-- ALTER TABLE cvs ALTER COLUMN skills_soft TYPE TEXT[] USING string_to_array(skills_soft, ',');

-- =========================================================
-- MIGRASI: tabel `cover_letters` (Template Surat Lamaran Builder).
-- Jalankan blok ini bila kamu sudah pernah menjalankan schema versi
-- sebelum fitur Surat Lamaran (Template) ini ada. Aman dijalankan
-- berkali-kali.
-- =========================================================
CREATE TABLE IF NOT EXISTS cover_letters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  place TEXT DEFAULT '',
  letter_date TEXT DEFAULT '',
  company_name TEXT DEFAULT '',
  recipient_title TEXT DEFAULT '',
  company_address TEXT DEFAULT '',
  source_site TEXT DEFAULT '',
  source_date TEXT DEFAULT '',
  position TEXT DEFAULT '',
  fullname TEXT DEFAULT '',
  birth_place TEXT DEFAULT '',
  birth_date TEXT DEFAULT '',
  gender TEXT DEFAULT '',
  address TEXT DEFAULT '',
  last_education TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  attachments JSONB DEFAULT '[]',
  signature_name TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE cover_letters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own cover letters" ON cover_letters;
CREATE POLICY "Users can view own cover letters" ON cover_letters FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own cover letters" ON cover_letters;
CREATE POLICY "Users can insert own cover letters" ON cover_letters FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own cover letters" ON cover_letters;
CREATE POLICY "Users can update own cover letters" ON cover_letters FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own cover letters" ON cover_letters;
CREATE POLICY "Users can delete own cover letters" ON cover_letters FOR DELETE USING (auth.uid() = user_id);

NOTIFY pgrst, 'reload schema';
