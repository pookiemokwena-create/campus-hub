import 'dart:math' as math;

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/utils/ids.dart';

enum IcassCategory { test, assignment, pat }

extension IcassCategoryLabel on IcassCategory {
  String get label => switch (this) {
        IcassCategory.test => 'Test',
        IcassCategory.assignment => 'Assignment',
        IcassCategory.pat => 'PAT',
      };
}

/// One assessed task inside a subject's ICASS portfolio.
/// Stored inside student_icass.task_scores (jsonb list).
class IcassTask {
  const IcassTask({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
    required this.maxScore,
  });

  factory IcassTask.create({
    required IcassCategory category,
    required String name,
    double maxScore = AppConstants.defaultTaskMaxScore,
  }) {
    return IcassTask(
      id: newLocalId(),
      name: name,
      category: category,
      score: 0,
      maxScore: maxScore,
    );
  }

  factory IcassTask.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String?;
    return IcassTask(
      id: json['id'] as String? ?? newLocalId(),
      name: json['name'] as String? ?? '',
      category: IcassCategory.values.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => IcassCategory.test,
      ),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String name;
  final IcassCategory category;
  final double score;
  final double maxScore;

  /// Score clamped to [0, maxScore]. Over-entry cannot inflate the result.
  double get clampedScore => math.min(math.max(score, 0.0), maxScore);

  double get percentage => maxScore <= 0 ? 0 : clampedScore / maxScore * 100;

  IcassTask copyWith({
    String? name,
    IcassCategory? category,
    double? score,
    double? maxScore,
  }) {
    return IcassTask(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'score': score,
        'max_score': maxScore,
      };
}
