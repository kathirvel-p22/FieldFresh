-- Fix Supabase Storage RLS Policies for Image Upload
-- This will allow public uploads to the fieldfresh-images bucket

-- First, check if policies exist and drop them if they do
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete" ON storage.objects;

-- Create new policies that allow public access
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'fieldfresh-images' );

CREATE POLICY "Public Upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'fieldfresh-images' );

CREATE POLICY "Public Update"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'fieldfresh-images' );

CREATE POLICY "Public Delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'fieldfresh-images' );

-- Ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Verify the bucket exists and is public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'fieldfresh-images';

-- Check results
SELECT id, name, public FROM storage.buckets WHERE id = 'fieldfresh-images';
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%Public%';