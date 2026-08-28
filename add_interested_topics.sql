-- ============================================
-- MIGRATION: Menambahkan kolom interested_topics ke tabel profiles
-- Jalankan script ini di SQL Editor Supabase Anda
-- ============================================

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS interested_topics TEXT[] DEFAULT '{}'::TEXT[];

-- Catatan:
-- Pastikan Row Level Security (RLS) policy UPDATE untuk tabel profiles 
-- memungkinkan user mengupdate datanya sendiri. (Berdasarkan blueprint, ini harusnya sudah tercover 
-- jika ada policy UPDATE USING (auth.uid() = id)).
