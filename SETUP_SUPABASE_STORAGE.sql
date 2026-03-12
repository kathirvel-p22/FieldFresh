-- Setup Supabase Storage for FieldFresh Images
-- Run this in your Supabase SQL Editor

-- Create storage bucket for images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fieldfresh-images',
  'fieldfresh-images', 
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Create RLS policy to allow public uploads
CREATE POLICY "Allow public uploads" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'fieldfresh-images');

-- Create RLS policy to allow public access
CREATE POLICY "Allow public access" ON storage.objects
FOR SELECT USING (bucket_id = 'fieldfresh-images');

-- Create RLS policy to allow users to update their own files
CREATE POLICY "Allow authenticated users to update" ON storage.objects
FOR UPDATE USING (bucket_id = 'fieldfresh-images' AND auth.role() = 'authenticated');

-- Create RLS policy to allow users to delete their own files
CREATE POLICY "Allow authenticated users to delete" ON storage.objects
FOR DELETE USING (bucket_id = 'fieldfresh-images' AND auth.role() = 'authenticated');

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Verify bucket creation
SELECT * FROM storage.buckets WHERE id = 'fieldfresh-images';