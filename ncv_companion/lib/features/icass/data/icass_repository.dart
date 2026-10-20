import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/features/icass/models/icass_record.dart';

/// Local-first ICASS storage.
///
/// Writes go to Hive first and are marked dirty. [pushPending] uploads them
/// later. [pullRemote] merges server rows, and it never overwrites a dirty
/// local record. Conflicts resolve by last-write-wins on updated_at.
class IcassRepository {
  IcassRepository({
    required SupabaseClient client,
    required LocalStorage storage,
  })  : _client = client,
        _storage = storage;

  final SupabaseClient _client;
  final LocalStorage _storage;

  String? get userId => _client.auth.currentUser?.id;

  String _key(String uid, String subjectId) => '$uid::$subjectId';

  IcassRecord? readLocal(String subjectId) {
    final uid = userId;
    if (uid == null) return null;
    final json = _storage.readMap(_storage.icass, _key(uid, subjectId));
    return json == null ? null : IcassRecord.fromJson(json);
  }

  Map<String, IcassRecord> readAllLocal() {
    final uid = userId;
    if (uid == null) return {};

    final prefix = '$uid::';
    final records = <String, IcassRecord>{};
    for (final key in _storage.icass.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final json = _storage.readMap(_storage.icass, key);
      if (json == null) continue;
      final record = IcassRecord.fromJson(json);
      records[record.subjectId] = record;
    }
    return records;
  }

  /// Saves locally and marks dirty. Works offline.
  Future<void> saveLocal(IcassRecord record) async {
    final uid = userId;
    if (uid == null) throw StateError('Sign in to save ICASS marks.');
    await _storage.writeJson(
      _storage.icass,
      _key(uid, record.subjectId),
      record.copyWith(dirty: true).toLocalJson(),
    );
  }

  /// Uploads dirty records. Returns how many were pushed.
  Future<int> pushPending() async {
    final uid = userId;
    if (uid == null) return 0;

    final pending = readAllLocal().values.where((r) => r.dirty).toList();
    for (final record in pending) {
      await _client.from('student_icass').upsert(
            record.toRemoteJson(uid),
            onConflict: 'user_id,subject_id',
          );

      // Mark clean only if the record was not edited while the upload ran.
      final latest = readLocal(record.subjectId);
      if (latest != null && latest.updatedAt == record.updatedAt) {
        await _storage.writeJson(
          _storage.icass,
          _key(uid, record.subjectId),
          latest.copyWith(dirty: false).toLocalJson(),
        );
      }
    }
    return pending.length;
  }

  /// Pulls the learner's rows from Supabase and merges them into Hive.
  Future<void> pullRemote() async {
    final uid = userId;
    if (uid == null) return;

    final rows = await _client.from('student_icass').select().eq('user_id', uid);
    for (final row in rows) {
      final remote = IcassRecord.fromJson(row);
      final local = readLocal(remote.subjectId);
      final localWins = local != null &&
          (local.dirty || !remote.updatedAt.isAfter(local.updatedAt));
      if (localWins) continue;

      await _storage.writeJson(
        _storage.icass,
        _key(uid, remote.subjectId),
        remote.toLocalJson(),
      );
    }
  }
}
