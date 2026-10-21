import 'dart:math' as math;

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';

/// Where a learner stands against the sub-minimum.
enum ThresholdStatus {
  /// ICASS and the target exam mark both meet the sub-minimum.
  onTrack,

  /// ICASS is sufficient, but the target exam mark is below what is required.
  needsHigherExam,

  /// ICASS is below the sub-minimum. Under DHET rules the learner cannot be
  /// resulted, however well they do in the exam.
  icassBelowMinimum,
}

class IcassEvaluation {
  const IcassEvaluation({
    required this.icassPercentage,
    required this.targetExamPercentage,
    required this.passPercentage,
    required this.icassWeight,
    required this.projectedFinal,
    required this.examMarkNeeded,
    required this.status,
  });

  final double icassPercentage;
  final double targetExamPercentage;
  final int passPercentage;

  /// 0.25 for fundamental subjects, 0.50 for vocational.
  final double icassWeight;

  /// Final mark if the target exam mark is achieved.
  final double projectedFinal;

  /// Lowest exam mark that satisfies both the exam sub-minimum and the final
  /// pass mark, capped at 100.
  final double examMarkNeeded;

  final ThresholdStatus status;

  double get examWeight => 1 - icassWeight;
  bool get isOnTrack => status == ThresholdStatus.onTrack;
}

/// Pure, framework-free ICASS rules. Covered by unit tests.
///
/// Rules (DHET NC(V) ICASS guidelines):
///  * ICASS% = earned marks / possible marks x 100 across all tasks.
///  * Final mark = ICASS% x weight + exam% x (1 - weight).
///    Fundamental: 25 / 75. Vocational: 50 / 50.
///  * Each component must meet the subject's sub-minimum: 50 vocational,
///    40 LO/FAL, 30 Maths.
abstract final class IcassCalculator {
  static double icassPercentage(Iterable<IcassTask> tasks) {
    var earned = 0.0;
    var possible = 0.0;
    for (final task in tasks) {
      if (task.maxScore <= 0) continue;
      earned += task.clampedScore;
      possible += task.maxScore;
    }
    return possible == 0 ? 0 : earned / possible * 100;
  }

  /// Percentage per assessment category, e.g. {test: 62.0, pat: 80.0}.
  static Map<IcassCategory, double> categoryBreakdown(Iterable<IcassTask> tasks) {
    final earned = <IcassCategory, double>{};
    final possible = <IcassCategory, double>{};
    for (final task in tasks) {
      if (task.maxScore <= 0) continue;
      earned.update(task.category, (v) => v + task.clampedScore,
          ifAbsent: () => task.clampedScore);
      possible.update(task.category, (v) => v + task.maxScore,
          ifAbsent: () => task.maxScore);
    }
    return {
      for (final category in possible.keys)
        category: earned[category]! / possible[category]! * 100,
    };
  }

  static IcassEvaluation evaluate({
    required double icassPercentage,
    required double targetExamPercentage,
    required int passPercentage,
    required bool isFundamental,
  }) {
    final icassWeight = isFundamental
        ? AppConstants.icassWeightFundamental
        : AppConstants.icassWeightVocational;
    final examWeight = 1 - icassWeight;
    final pass = passPercentage.toDouble();

    final projectedFinal =
        icassPercentage * icassWeight + targetExamPercentage * examWeight;

    // Exam mark needed for the final pass mark, given current ICASS.
    final examForFinal = (pass - icassPercentage * icassWeight) / examWeight;
    // The exam must also meet its own sub-minimum.
    final examMarkNeeded = math.min(100.0, math.max(pass, examForFinal));

    final ThresholdStatus status;
    if (icassPercentage < pass) {
      status = ThresholdStatus.icassBelowMinimum;
    } else if (targetExamPercentage + 1e-9 < examMarkNeeded) {
      status = ThresholdStatus.needsHigherExam;
    } else {
      status = ThresholdStatus.onTrack;
    }

    return IcassEvaluation(
      icassPercentage: icassPercentage,
      targetExamPercentage: targetExamPercentage,
      passPercentage: passPercentage,
      icassWeight: icassWeight,
      projectedFinal: projectedFinal,
      examMarkNeeded: examMarkNeeded,
      status: status,
    );
  }
}
