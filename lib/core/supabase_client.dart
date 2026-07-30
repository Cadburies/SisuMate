import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static final instance = Supabase.instance.client;

  // Init is handled in main.dart via Supabase.initialize
}
