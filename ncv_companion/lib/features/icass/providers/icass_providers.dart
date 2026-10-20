import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/providers/catalog_providers.dart';
import 'package:ncv_companion/core/sync/sync_coordinator.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/utils/ids.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';
import 'package:ncv_companion/features/icass/data/icass_repository.dart';
import 'package:ncv_companion/features/icass/domain/icass_calculator.dart';
import 'package:ncv_companion/features/icass/models/icass_record.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';

part 'icass_providers.g.dart';

@Riverpod(keepAlive: true)
IcassRepository icassRepository(Ref ref) {
  return IcassRepository(
    client: ref.watch(supabaseProvider),
    storage: ref.watch(localStorageProvider),
  );
}

/// Single source of truth for ICASS data. Every edit goes through here:
/// it updates state, writes to Hive, and schedules a debounced sync.
@Riverpod(keepAlive: true)
class IcassRecordsController extends _$IcassRecordsController {
  @override
  Map<String, IcassRecord> build() {
    // Re-read the cache when the signed-in user changes.
    ref.watch(authStateProvider);
    return ref.watch(icassRepositoryProvider).readAllLocal();
  }

  Future<void> saveTask(String subjectId, IcassTask task) =>
      _update(subjectId, (r) => r.upsertTask(task));

  Future<void> removeTask(String subjectId, String taskId) =>
      _update(subjectId, (r) => r.withoutTask(taskId));

  Future<void> setTargetExam(String subjectId, double percent) =>
      _update(subjectId, (r) => r.copyWith(targetExamScore: percent));

  Future<void> _update(
    String subjectId,
    IcassRecord Function(IcassRecord current) change,
  ) async {
    final current = state[subjectId] ?? IcassRecord.empty(subjectId);
    final updated = change(current).copyWith(
      updatedAt: DateTime.now().toUtc(),
      dirty: true,
    );

    state = {...state, subjectId: updated};
    await ref.read(icassRepositoryProvider).saveLocal(updated);
    ref.read(syncCoordinatorProvider.notifier).scheduleSync();
  }

  /// Push local changes, then pull remote ones. Called by SyncCoordinator.
  Future<void> sync() async {
    final repo = ref.read(icassRepositoryProvider);
    await repo.pushPending();
    await repo.pullRemote();
    state = repo.readAllLocal();
  }
}

/// The subject currently chosen in the ICASS screen. Null means "first applicable".
@Riverpod(keepAlive: true)
class SelectedSubjectId extends _$SelectedSubjectId {
  @override
  String? build() => null;

  void select(String subjectId) => state = subjectId;
}

/// Applicable subject currently shown. Falls back to the first one.
@riverpod
Subject? activeSubject(Ref ref) {
  final subjects = ref.watch(applicableSubjectsProvider);
  if (subjects.isEmpty) return null;

  final selectedId = ref.watch(selectedSubjectIdProvider);
  for (final subject in subjects) {
    if (subject.id == selectedId) return subject;
  }
  return subjects.first;
}

/// Working copy of the active subject's ICASS record. Empty if nothing is saved.
@riverpod
IcassRecord? icassDraft(Ref ref) {
  final subject = ref.watch(activeSubjectProvider);
  if (subject == null) return null;
  final records = ref.watch(icassRecordsControllerProvider);
  return records[subject.id] ?? IcassRecord.empty(subject.id);
}

/// Live pass-check. Recomputes on every keystroke because it watches the draft.
@riverpod
IcassEvaluation? icassEvaluation(Ref ref) {
  final subject = ref.watch(activeSubjectProvider);
  final draft = ref.watch(icassDraftProvider);
  if (subject == null || draft == null) return null;

  return IcassCalculator.evaluate(
    icassPercentage: draft.icassPercentage,
    targetExamPercentage: draft.targetExamScore,
    passPercentage: subject.passPercentage,
    isFundamental: subject.isFundamental,
  );
}

class IcassOverview {
  const IcassOverview({
    required this.averageIcass,
    required this.tracked,
    required this.applicable,
    required this.onTrack,
    required this.needsAttention,
  });

  final double averageIcass;
  final int tracked;
  final int applicable;
  final int onTrack;
  final int needsAttention;

  double get progress => applicable == 0 ? 0 : tracked / applicable;
}

/// Dashboard summary across all of the learner's subjects.
@riverpod
IcassOverview icassOverview(Ref ref) {
  final records = ref.watch(icassRecordsControllerProvider);
  final subjects = ref.watch(applicableSubjectsProvider);
  final byId = {for (final s in subjects) s.id: s};

  var sum = 0.0;
  var tracked = 0;
  var onTrack = 0;
  var attention = 0;

  for (final record in records.values) {
    if (record.tasks.isEmpty) continue;
    tracked++;
    sum += record.icassPercentage;

    final subject = byId[record.subjectId];
    if (subject == null) continue;
    final evaluation = IcassCalculator.evaluate(
      icassPercentage: record.icassPercentage,
      targetExamPercentage: record.targetExamScore,
      passPercentage: subject.passPercentage,
      isFundamental: subject.isFundamental,
    );
    if (evaluation.isOnTrack) {
      onTrack++;
    } else {
      attention++;
    }
  }

  return IcassOverview(
    averageIcass: tracked == 0 ? 0 : sum / tracked,
    tracked: tracked,
    applicable: subjects.length,
    onTrack: onTrack,
    needsAttention: attention,
  );
}

/// Builds a new task with a unique id and a sensible default name.
IcassTask buildNewTask(IcassCategory category, List<IcassTask> existing) {
  final sameCategory = existing.where((t) => t.category == category).length;
  return IcassTask(
    id: newLocalId(),
    name: '${category.label} ${sameCategory + 1}',
    category: category,
    score: 0,
    maxScore: AppConstants.defaultTaskMaxScore,
  );
}
