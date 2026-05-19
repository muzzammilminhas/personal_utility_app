-- ============================================================
--  supabase_setup.sql  –  Database Tables & Security Policies
--  Personal Utility App | Run this in Supabase SQL Editor
-- ============================================================
--
--  HOW TO USE:
--  1. Go to your Supabase project dashboard
--  2. Click "SQL Editor" in the left sidebar
--  3. Paste this entire file and click "Run"
--  4. All tables will be created with proper security
--
--  ROW LEVEL SECURITY (RLS):
--  Each table has RLS enabled, meaning users can ONLY
--  see and modify their own data. This is enforced at
--  the database level — not just in the app code.
--
-- ============================================================


-- ── 1. BUSINESS CARD PROFILES ────────────────────────────────
--  Stores user-created digital business card data

CREATE TABLE IF NOT EXISTS business_cards (
  id          UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID    REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT    NOT NULL,
  email       TEXT,
  phone       TEXT,
  company     TEXT,
  job_title   TEXT,
  website     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE business_cards ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only SELECT their own cards
CREATE POLICY "Users can view own cards"
  ON business_cards FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can only INSERT cards for themselves
CREATE POLICY "Users can insert own cards"
  ON business_cards FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only UPDATE their own cards
CREATE POLICY "Users can update own cards"
  ON business_cards FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can only DELETE their own cards
CREATE POLICY "Users can delete own cards"
  ON business_cards FOR DELETE
  USING (auth.uid() = user_id);


-- ── 2. QR SCAN HISTORY ───────────────────────────────────────
--  Stores the text content of QR codes that were scanned

CREATE TABLE IF NOT EXISTS scan_history (
  id           UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      UUID    REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  scanned_text TEXT    NOT NULL,
  scanned_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scan history"
  ON scan_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scan history"
  ON scan_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own scan history"
  ON scan_history FOR DELETE
  USING (auth.uid() = user_id);


-- ── 3. AUDIO RECORDINGS ──────────────────────────────────────
--  Stores metadata about audio recordings
--  The actual audio files are stored in Supabase Storage

CREATE TABLE IF NOT EXISTS recordings (
  id           UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      UUID    REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title        TEXT    NOT NULL DEFAULT 'Untitled Recording',
  notes        TEXT    DEFAULT '',
  file_path    TEXT    NOT NULL,   -- Path in Supabase Storage bucket
  duration_ms  INTEGER DEFAULT 0,  -- Duration in milliseconds
  created_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own recordings"
  ON recordings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recordings"
  ON recordings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recordings"
  ON recordings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own recordings"
  ON recordings FOR DELETE
  USING (auth.uid() = user_id);


-- ── 4. STORAGE BUCKET FOR AUDIO FILES ────────────────────────
--  Run this separately in SQL Editor OR use the Supabase UI:
--  Storage → Create Bucket → Name: "recordings" → Private

INSERT INTO storage.buckets (id, name, public)
VALUES ('recordings', 'recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload own recordings"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'recordings' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow authenticated users to read their own files
CREATE POLICY "Users can read own recordings"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'recordings' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow authenticated users to delete their own files
CREATE POLICY "Users can delete own recordings"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'recordings' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );


-- ── 5. ADMIN PANEL READ ACCESS ─────────────────────────────
--  The Flutter app checks the admin email in:
--  lib/config/admin_config.dart
--
--  For Supabase RLS to also allow admin dashboard reads:
--  1. Create/sign up your admin account first
--  2. Run this SQL in Supabase

CREATE TABLE IF NOT EXISTS app_admins (
  user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT UNIQUE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE app_admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view own admin row" ON app_admins;
CREATE POLICY "Admins can view own admin row"
  ON app_admins FOR SELECT
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.is_app_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_admins
    WHERE user_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "Admins can view all business cards" ON business_cards;
CREATE POLICY "Admins can view all business cards"
  ON business_cards FOR SELECT
  USING (public.is_app_admin());

DROP POLICY IF EXISTS "Admins can view all scan history" ON scan_history;
CREATE POLICY "Admins can view all scan history"
  ON scan_history FOR SELECT
  USING (public.is_app_admin());

DROP POLICY IF EXISTS "Admins can view all recordings" ON recordings;
CREATE POLICY "Admins can view all recordings"
  ON recordings FOR SELECT
  USING (public.is_app_admin());

INSERT INTO public.app_admins (user_id, email)
SELECT id, email
FROM auth.users
WHERE email = 'muzzammilminhas5@gmail.com'
ON CONFLICT (user_id) DO UPDATE
SET email = EXCLUDED.email;


-- ── HELPER: Auto-update updated_at timestamp ─────────────────
--  This function automatically sets updated_at = NOW()
--  whenever a row is updated (used by business_cards table)

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON business_cards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


-- ── DONE ─────────────────────────────────────────────────────
-- Tables created:
--   ✅ business_cards  (with RLS)
--   ✅ scan_history    (with RLS)
--   ✅ recordings      (with RLS)
--   ✅ Storage bucket: recordings
