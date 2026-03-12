-- Simplified Supabase Storage Setup (No RLS modifications)
-- Run this in your Supabase SQL Editor

-- Create storage bucket for images (this should work)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fieldfresh-images',
  'fieldfresh-images', 
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Verify bucket creation
SELECT * FROM storage.buckets WHERE id = 'fieldfresh-images';