# Supabase Setup Instructions

## 1. Create Supabase Project
1. Go to https://supabase.com and create a new project
2. Note down your project URL and anon key from Settings > API

## 2. Create Storage Bucket
1. In your Supabase dashboard, go to Storage
2. Create a new bucket named `complaint-images`
3. Set the bucket to public (for easy access to images)

## 3. Update Configuration
1. Open `lib/supabase_config.dart`
2. Replace `YOUR_SUPABASE_URL` with your project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your anon key

## 4. Install Dependencies
Run: `flutter pub get`

## 5. Storage Policies (Optional)
For better security, you can set up Row Level Security policies in Supabase:
- Allow authenticated users to upload images
- Allow public read access to images

Your complaint registration now stores images in Supabase and saves the public URL in Firestore.