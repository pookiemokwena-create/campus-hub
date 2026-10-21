import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/models/profile.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/core/utils/remote_first.dart';

enum AuthOutcome { signedIn, confirmEmail }

class SignUpRequest {
  const SignUpRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.collegeName,
    required this.nqfLevel,
    required this.vocationalStream,
  });

  final String email;
  final String password;
  final String fullName;
  final String collegeName;
  final int nqfLevel;
  final String vocationalStream;
}

class AuthRepository {
  AuthRepository({
    required SupabaseClient client,
    required LocalStorage storage,
    required ConnectivityGate gate,
  })  : _client = client,
        _storage = storage,
        _gate = gate;

  final SupabaseClient _client;
  final LocalStorage _storage;
  final ConnectivityGate _gate;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Profile fields go in user metadata. A database trigger (handle_new_user)
  /// copies them into public.profiles, so no client insert is needed and RLS
  /// is not an obstacle while the session is still being created.
  Future<AuthOutcome> signUp(SignUpRequest request) async {
    final response = await _client.auth.signUp(
      email: request.email,
      password: request.password,
      data: {
        'full_name': request.fullName,
        'college_name': request.collegeName,
        'nqf_level': request.nqfLevel,
        'vocational_stream': request.vocationalStream,
      },
    );
    return response.session == null
        ? AuthOutcome.confirmEmail
        : AuthOutcome.signedIn;
  }

  /// Local data is keyed by user id, so signing out does not expose another
  /// learner's marks on a shared device.
  Future<void> signOut() => _client.auth.signOut();

  Future<Profile?> loadProfile() {
    final uid = currentUserId;
    if (uid == null) return Future<Profile?>.value(null);

    return remoteFirst<Profile?>(
      gate: _gate,
      offlineMessage: 'Connect to the internet once to load your profile.',
      remote: () async {
        final row = await _client
            .from('profiles')
            .select()
            .eq('id', uid)
            .maybeSingle();
        if (row == null) return null;
        final profile = Profile.fromJson(row);
        await _storage.writeJson(_storage.profiles, uid, profile.toJson());
        return profile;
      },
      local: () {
        final cached = _storage.readMap(_storage.profiles, uid);
        return cached == null ? null : Profile.fromJson(cached);
      },
    );
  }
}
