import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ProfileModel?> fetchProfile(String userId) async {
    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return ProfileModel.fromJson(row);
  }
}
