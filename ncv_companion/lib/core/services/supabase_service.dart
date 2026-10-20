import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/config/env.dart';

part 'supabase_service.g.dart';

/// Call once from main() before runApp. Restores any persisted session.
Future<void> initializeSupabase() {
  return Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}

@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) => Supabase.instance.client;
