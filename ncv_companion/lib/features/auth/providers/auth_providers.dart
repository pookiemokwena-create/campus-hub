import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/models/profile.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/features/auth/data/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    client: ref.watch(supabaseProvider),
    storage: ref.watch(localStorageProvider),
    gate: ref.watch(connectivityGateProvider),
  );
}

/// Emits on sign-in, sign-out, token refresh and the initial restored session.
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
}

/// The learner's profile. Refreshes on auth change and when connectivity returns.
@riverpod
Future<Profile?> profile(Ref ref) {
  ref.watch(authStateProvider);
  ref.watch(isOnlineProvider);
  return ref.watch(authRepositoryProvider).loadProfile();
}

/// Drives the sign-in / sign-up form. AsyncValue carries loading and error state.
@riverpod
class AuthFormController extends _$AuthFormController {
  @override
  FutureOr<AuthOutcome?> build() => null;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue<AuthOutcome?>.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      return AuthOutcome.signedIn;
    });
  }

  Future<void> signUp(SignUpRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue<AuthOutcome?>.guard(() {
      return ref.read(authRepositoryProvider).signUp(request);
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
