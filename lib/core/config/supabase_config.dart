import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://igffhhpdmtkhajksekom.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlnZmZoaHBkbXRraGFqa3Nla29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2NDc3NTQsImV4cCI6MjA4OTIyMzc1NH0.WXApBrSjUNT25_hg_hRvUAww-OtxfJP1ueLkgNgEBqg';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}