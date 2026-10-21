import 'dart:convert';

import 'package:ncv_companion/features/icass/domain/icass_calculator.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';

/// One learner's ICASS data for one subject. Mirrors public.student_icass.
///
/// [dirty] is local-only. It marks a change that has not reached Supabase yet,
/// and it is never sent to the server.
class IcassRecord {
  const IcassRecord({
    required this.subjectId,
    required this.tasks,
    required this.targetExamScore,
    required this.updatedAt,
    this.dirty = false,
  });

  /// Placeholder for a subject with no saved data. Its epoch timestamp means
  /// any real server row is always considered newer.
  factory IcassRecord.empty(String subjectId) => IcassRecord(
        subjectId: subjectId,
        tasks: const [],
        targetExamScore: 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  final String subjectId;
  final List<IcassTask> tasks;
  final double targetExamScore;
  final DateTime updatedAt;
  final bool dirty;

  double get icassPercentage => IcassCalculator.icassPercentage(tasks);

  IcassRecord upsertTask(IcassTask task) {
    final index = tasks.indexWhere((t) => t.id == task.id);
    final next = [...tasks];
    if (index == -1) {
      next.add(task);
    } else {
      next[index] = task;
    }
    return copyWith(tasks: next);
  }

  IcassRecord withoutTask(String taskId) =>
      copyWith(tasks: tasks.where((t) => t.id != taskId).toList());

  IcassRecord copyWith({
    List<IcassTask>? tasks,
    double? targetExamScore,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return IcassRecord(
      subjectId: subjectId,
      tasks: tasks ?? this.tasks,
      targetExamScore: targetExamScore ?? this.targetExamScore,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  /// Local cache shape. Keeps the `dirty` flag.
  Map<String, dynamic> toLocalJson() => {
        'subject_id': subjectId,
        'task_scores': tasks.map((t) => t.toJson()).toList(),
        'target_exam_score': targetExamScore,
        'icass_percentage': icassPercentage,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty,
      };

  /// Upsert payload for student_icass. Excludes local-only fields.
  Map<String, dynamic> toRemoteJson(String userId) => {
        'user_id': userId,
        'subject_id': subjectId,
        'task_scores': tasks.map((t) => t.toJson()).toList(),
        'icass_percentage': icassPercentage,
        'target_exam_score': targetExamScore,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory IcassRecord.fromJson(Map<String, dynamic> json) {
    // task_scores can arrive as a JSON list (jsonb) or as a JSON-encoded string.
    final raw = json['task_scores'];
    final list = raw is String
        ? jsonDecode(raw) as List<dynamic>
        : (raw as List<dynamic>? ?? const []);

    return IcassRecord(
      subjectId: json['subject_id'] as String,
      tasks: list
          .map((e) => IcassTask.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      targetExamScore: (json['target_exam_score'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      dirty: json['dirty'] as bool? ?? false,
    );
  }
}
