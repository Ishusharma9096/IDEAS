import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
  static bool get isInitialized =>
      isConfigured && Supabase.instance.isInitialized;

  /// Returns false in demo/offline mode rather than preventing app startup.
  static Future<bool> initializeIfConfigured() async {
    if (!isConfigured) return false;
    if (Supabase.instance.isInitialized) return true;
    await Supabase.initialize(url: url, publishableKey: anonKey);
    return true;
  }

  static SupabaseClient get client {
    if (!isInitialized) throw StateError('Supabase is not configured.');
    return Supabase.instance.client;
  }
}
