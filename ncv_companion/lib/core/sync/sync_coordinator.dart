import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/providers/catalog_providers.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';
import 'package:ncv_companion/features/icass/providers/icass_providers.dart';
import 'package:ncv_companion/features/past_papers/providers/downloads_providers.dart';
import 'package:ncv_companion/features/past_papers/providers/past_paper_providers.dart';

part 'sync_coordinator.g.dart';

class SyncState {
  const SyncState({this.syncing = false, this.lastSyncedAt, this.lastError});

  final bool syncing;
  final DateTime? lastSyncedAt;
  final String? lastError;
}

/// Offline sync orchestrator. Local writes are always applied first. This class
/// flushes them to Supabase when the device is online.
///
/// Triggers:
///  * app start / sign-in (auth state emits a session)
///  * connectivity changes from offline to online
///  * a debounced delay after each ICASS edit
///  * pull-to-refresh on the dashboard
@Riverpod(keepAlive: true)
class SyncCoordinator extends _$SyncCoordinator {
  Timer? _debounce;

  @override
  SyncState build() {
    ref.onDispose(() => _debounce?.cancel());

    ref.listen(connectivityResultsProvider, (previous, next) {
      final before = previous?.value;
      final now = next.value;
      if (now == null) return;
      final wasOnline = before != null && hasNetwork(before);
      if (!wasOnline && hasNetwork(now)) {
        unawaited(syncNow());
      }
    });

    ref.listen(authStateProvider, (previous, next) {
      if (next.value?.session != null) {
        unawaited(syncNow());
      }
    });

    return const SyncState();
  }

  void scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.syncDebounce, () => unawaited(syncNow()));
  }

  Future<void> syncNow() async {
    if (state.syncing) return;

    final session = ref.read(supabaseProvider).auth.currentSession;
    if (session == null) return;
    if (!await ref.read(connectivityGateProvider).isOnline) return;

    state = SyncState(syncing: true, lastSyncedAt: state.lastSyncedAt);
    try {
      await ref.read(icassRecordsControllerProvider.notifier).sync();
      await ref.read(downloadsProvider.notifier).processQueue();

      ref.invalidate(subjectsProvider);
      ref.invalidate(pastPaperCatalogProvider);
      ref.invalidate(profileProvider);

      state = SyncState(lastSyncedAt: DateTime.now());
    } catch (error) {
      state = SyncState(
        lastSyncedAt: state.lastSyncedAt,
        lastError: friendlyError(error),
      );
    }
  }
}
