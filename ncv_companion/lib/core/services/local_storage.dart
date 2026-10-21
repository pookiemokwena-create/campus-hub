import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_storage.g.dart';

/// Offline store built on Hive CE.
///
/// Every box holds JSON strings. This keeps the schema identical to the
/// Supabase row shape (snake_case), so one toJson/fromJson per model serves
/// both the network and the cache. It also avoids generated TypeAdapters.
class LocalStorage {
  LocalStorage._({
    required this.profiles,
    required this.catalog,
    required this.icass,
    required this.downloads,
    required this.chat,
    required this.meta,
  });

  /// userId -> profile JSON.
  final Box<String> profiles;

  /// Shared, non-user catalogue cache: 'subjects', 'past_papers'.
  final Box<String> catalog;

  /// '<userId>::<subjectId>' -> IcassRecord JSON (includes the `dirty` flag).
  final Box<String> icass;

  /// paperId -> DownloadRecord JSON. The PDF bytes live on the file system.
  final Box<String> downloads;

  /// userId -> AI chat history JSON.
  final Box<String> chat;

  /// Preferences and small markers.
  final Box<String> meta;

  static Future<LocalStorage> open() async {
    await Hive.initFlutter();
    return LocalStorage._(
      profiles: await Hive.openBox<String>('profiles'),
      catalog: await Hive.openBox<String>('catalog'),
      icass: await Hive.openBox<String>('icass'),
      downloads: await Hive.openBox<String>('downloads'),
      chat: await Hive.openBox<String>('chat'),
      meta: await Hive.openBox<String>('meta'),
    );
  }

  Map<String, dynamic>? readMap(Box<String> box, String key) {
    final raw = box.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  List<dynamic>? readList(Box<String> box, String key) {
    final raw = box.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> writeJson(Box<String> box, String key, Object value) {
    return box.put(key, jsonEncode(value));
  }

  Future<void> remove(Box<String> box, String key) => box.delete(key);
}

/// Overridden in main() with the opened instance. Reading it without the
/// override is a programming error, so fail loudly.
@Riverpod(keepAlive: true)
LocalStorage localStorage(Ref ref) {
  throw StateError('LocalStorage must be overridden in main() before use.');
}
