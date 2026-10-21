import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/utils/remote_first.dart';

part 'subjects_repository.g.dart';

class SubjectsRepository {
  SubjectsRepository({
    required SupabaseClient client,
    required LocalStorage storage,
    required ConnectivityGate gate,
  })  : _client = client,
        _storage = storage,
        _gate = gate;

  final SupabaseClient _client;
  final LocalStorage _storage;
  final ConnectivityGate _gate;

  static const _cacheKey = 'subjects';

  Future<List<Subject>> fetchSubjects() {
    return remoteFirst<List<Subject>>(
      gate: _gate,
      offlineMessage: 'Connect to the internet once to download your subjects.',
      remote: () async {
        final rows = await _client
            .from('subjects')
            .select()
            .order('nqf_level')
            .order('code');
        await _storage.writeJson(_storage.catalog, _cacheKey, rows);
        return rows.map(Subject.fromJson).toList(growable: false);
      },
      local: () {
        final cached = _storage.readList(_storage.catalog, _cacheKey);
        return cached
            ?.map((row) => Subject.fromJson(row as Map<String, dynamic>))
            .toList(growable: false);
      },
    );
  }
}

@Riverpod(keepAlive: true)
SubjectsRepository subjectsRepository(Ref ref) {
  return SubjectsRepository(
    client: ref.watch(supabaseProvider),
    storage: ref.watch(localStorageProvider),
    gate: ref.watch(connectivityGateProvider),
  );
}
