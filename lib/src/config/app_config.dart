import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();
  static late final SupabaseClient supabase;

  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: 'https://YOUR-PROJECT.supabase.co');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: 'YOUR-ANON-KEY');

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    supabase = Supabase.instance.client;
  }
}
