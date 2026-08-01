-- =========================================================
-- FIX: trigger handle_new_user() menyebabkan "Database error
-- saving new user" saat signup, sehingga akun auth.users pun
-- ikut batal dibuat (karena trigger jalan dalam transaksi yang
-- sama dengan INSERT ke auth.users).
--
-- Penyebab paling umum: fungsi SECURITY DEFINER tanpa
-- `SET search_path` eksplisit bisa gagal menemukan tabel
-- `profiles` tergantung konteks pemanggilnya.
--
-- Jalankan file ini di Supabase Dashboard > SQL Editor.
-- Aman dijalankan berkali-kali.
-- =========================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
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
  -- Jangan sampai kegagalan insert profil membatalkan pembuatan
  -- akun auth itu sendiri. Errornya tetap tercatat di Logs > Postgres
  -- di dashboard Supabase (cari "handle_new_user failed").
  RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Pastikan grant dasar tersedia untuk role yang dipakai Auth.
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, service_role;
