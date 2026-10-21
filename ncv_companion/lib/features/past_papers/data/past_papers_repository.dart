import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/core/utils/remote_first.dart';
import 'package:ncv_companion/features/past_papers/models/download_record.dart';
import 'package:ncv_companion/features/past_papers/models/past_paper.dart';

class PastPapersRepository {
  PastPapersRepository({
    required SupabaseClient client,
    required LocalStorage storage,
    required ConnectivityGate gate,
  })  : _client = client,
        _storage = storage,
        _gate = gate;

  final SupabaseClient _client;
  final LocalStorage _storage;
  final ConnectivityGate _gate;

  static const _catalogKey = 'past_papers';

  /// Catalogue metadata is small (no PDFs), so the whole list is cached for
  /// offline browsing. The PDFs themselves are downloaded separately.
  Future<List<PastPaper>> fetchCatalog() {
    return remoteFirst<List<PastPaper>>(
      gate: _gate,
      offlineMessage: 'Connect to the internet once to load the past-paper list.',
      remote: () async {
        final rows = await _client
            .from('past_papers')
            .select('id, subject_id, year, paper_number, file_url, is_memo')
            .order('year', ascending: false);
        await _storage.writeJson(_storage.catalog, _catalogKey, rows);
        return rows.map(PastPaper.fromJson).toList(growable: false);
      },
      local: () {
        final cached = _storage.readList(_storage.catalog, _catalogKey);
        return cached
            ?.map((row) => PastPaper.fromJson(row as Map<String, dynamic>))
            .toList(growable: false);
      },
    );
  }

  Map<String, DownloadRecord> readDownloads() {
    final records = <String, DownloadRecord>{};
    for (final key in _storage.downloads.keys) {
      if (key is! String) continue;
      final json = _storage.readMap(_storage.downloads, key);
      if (json == null) continue;
      final record = DownloadRecord.fromJson(json);
      records[record.paperId] = record;
    }
    return records;
  }

  Future<void> saveDownload(DownloadRecord record) {
    return _storage.writeJson(
      _storage.downloads,
      record.paperId,
      record.toJson(),
    );
  }

  Future<void> deleteDownload(String paperId) {
    return _storage.remove(_storage.downloads, paperId);
  }
}
