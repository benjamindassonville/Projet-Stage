import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientSingleton {
  SupabaseClientSingleton._();
  static SupabaseClient get client => Supabase.instance.client;
}
