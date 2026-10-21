import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/features/past_papers/models/download_record.dart';
import 'package:ncv_companion/features/past_papers/models/past_paper.dart';
import 'package:ncv_companion/features/past_papers/providers/past_paper_providers.dart';

part 'downloads_providers.g.dart';

/// Data-saver preference. On by default, so PDFs only download over Wi-Fi or Ethernet.
@Riverpod(keepAlive: true)
class WifiOnlyDownloads extends _$WifiOnlyDownloads {
  static const _key = 'wifi_only_downloads';

  @override
  bool build() {
    return ref.read(localStorageProvider).meta.get(_key) != 'false';
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(localStorageProvider).meta.put(_key, value.toString());
  }
}

/// Offline download queue.
///
/// Enqueue works offline. The queue drains when the device is online, and on
/// Wi-Fi if the data saver is enabled. Downloads run one at a time to protect
/// the device and mobile data.
@Riverpod(keepAlive: true)
class Downloads extends _$Downloads {
  bool _processing = false;

  @override
  Map<String, DownloadRecord> build() {
    return ref.watch(pastPapersRepositoryProvider).readDownloads();
  }

  Future<void> enqueue(PastPaper paper, {required String title}) async {
    final existing = state[paper.id];
    if (existing != null && existing.isActive) return;
    if (existing != null && existing.isComplete &&
        File(existing.localPath!).existsSync()) {
      return;
    }

    await _persist(
      DownloadRecord(
        paperId: paper.id,
        title: title,
        sourcePath: paper.filePath,
        status: DownloadStatus.queued,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    unawaited(processQueue());
  }

  Future<void> retry(String paperId) async {
    final record = state[paperId];
    if (record == null) return;
    await _persist(record.copyWith(status: DownloadStatus.queued, clearError: true));
    unawaited(processQueue());
  }

  Future<void> remove(String paperId) async {
    final record = state[paperId];
    if (record != null) {
      await ref.read(paperDownloadServiceProvider).deleteLocal(record.localPath);
    }
    await ref.read(pastPapersRepositoryProvider).deleteDownload(paperId);
    state = Map.of(state)..remove(paperId);
  }

  /// Drains queued downloads. Safe to call repeatedly: only one run at a time.
  Future<void> processQueue() async {
    if (_processing) return;

    final gate = ref.read(connectivityGateProvider);
    if (!await gate.isOnline) return;
    if (ref.read(wifiOnlyDownloadsProvider) && !await gate.isUnmetered) return;
    if (ref.read(supabaseProvider).auth.currentSession == null) return;

    _processing = true;
    try {
      final queue = state.values
          .where((r) => r.status == DownloadStatus.queued)
          .toList()
        ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

      for (final record in queue) {
        // Re-check between files. The learner may have walked out of Wi-Fi range.
        if (!await gate.isOnline) break;
        if (ref.read(wifiOnlyDownloadsProvider) && !await gate.isUnmetered) break;
        await _downloadOne(record);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _downloadOne(DownloadRecord record) async {
    await _persist(record.copyWith(
      status: DownloadStatus.downloading,
      progress: 0,
      clearError: true,
    ));

    try {
      final localPath =
          await ref.read(paperDownloadServiceProvider).download(
                paperId: record.paperId,
                storagePath: record.sourcePath,
                onProgress: (progress) {
                  final current = state[record.paperId];
                  if (current == null ||
                      current.status != DownloadStatus.downloading) {
                    return;
                  }
                  // Throttle state updates to about 2% steps.
                  if (progress - current.progress < 0.02 && progress < 1) return;
                  state = {
                    ...state,
                    record.paperId: current.copyWith(progress: progress),
                  };
                },
              );

      await _persist(record.copyWith(
        status: DownloadStatus.completed,
        progress: 1,
        localPath: localPath,
        clearError: true,
      ));
    } catch (error) {
      await _persist(record.copyWith(
        status: DownloadStatus.failed,
        error: friendlyError(error),
      ));
    }
  }

  Future<void> _persist(DownloadRecord record) async {
    state = {...state, record.paperId: record};
    await ref.read(pastPapersRepositoryProvider).saveDownload(record);
  }
}
