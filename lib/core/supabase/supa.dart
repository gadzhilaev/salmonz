import 'package:supabase_flutter/supabase_flutter.dart';

/// Single access point for the shared Supabase client.
///
/// Existing feature files may keep a local `final supa = Supabase.instance.client;`
/// alias; both resolve to the same initialized singleton.
SupabaseClient get supa => Supabase.instance.client;
