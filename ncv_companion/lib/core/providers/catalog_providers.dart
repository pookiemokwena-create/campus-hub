import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ncv_companion/core/data/subjects_repository.dart';
import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';

part 'catalog_providers.g.dart';

/// All subjects. Re-fetches when the user signs in or connectivity returns.
@riverpod
Future<List<Subject>> subjects(Ref ref) {
  ref.watch(authStateProvider);
  ref.watch(isOnlineProvider);
  return ref.watch(subjectsRepositoryProvider).fetchSubjects();
}

/// Subjects that match the signed-in learner's NQF level and stream.
/// Falls back to the full list until the profile has loaded.
@riverpod
List<Subject> applicableSubjects(Ref ref) {
  final all = ref.watch(subjectsProvider).value ?? const <Subject>[];
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return all;

  return all
      .where(
        (subject) => subject.appliesTo(
          nqfLevel: profile.nqfLevel,
          stream: profile.vocationalStream,
        ),
      )
      .toList(growable: false);
}

@riverpod
Subject? subjectById(Ref ref, String subjectId) {
  final all = ref.watch(subjectsProvider).value ?? const <Subject>[];
  for (final subject in all) {
    if (subject.id == subjectId) return subject;
  }
  return null;
}
