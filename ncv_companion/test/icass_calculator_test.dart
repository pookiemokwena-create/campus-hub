import 'package:flutter_test/flutter_test.dart';

import 'package:ncv_companion/features/icass/domain/icass_calculator.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';

IcassTask _task(IcassCategory c, double score, double max) => IcassTask(
      id: '${c.name}-$score-$max',
      name: c.label,
      category: c,
      score: score,
      maxScore: max,
    );

void main() {
  group('ICASS percentage', () {
    test('is earned over possible across all tasks', () {
      final tasks = [
        _task(IcassCategory.test, 30, 50),
        _task(IcassCategory.assignment, 40, 100),
        _task(IcassCategory.pat, 45, 50),
      ];
      // 115 / 200 = 57.5%
      expect(IcassCalculator.icassPercentage(tasks), closeTo(57.5, 1e-9));
    });

    test('is zero when there are no tasks or no maximums', () {
      expect(IcassCalculator.icassPercentage(const []), 0);
      expect(IcassCalculator.icassPercentage([_task(IcassCategory.test, 5, 0)]), 0);
    });

    test('clamps over-entered scores so they cannot inflate the result', () {
      final tasks = [_task(IcassCategory.test, 80, 50)];
      expect(IcassCalculator.icassPercentage(tasks), closeTo(100, 1e-9));
    });

    test('category breakdown reports each assessment type separately', () {
      final tasks = [
        _task(IcassCategory.test, 25, 50),
        _task(IcassCategory.test, 25, 50),
        _task(IcassCategory.pat, 40, 50),
      ];
      final breakdown = IcassCalculator.categoryBreakdown(tasks);
      expect(breakdown[IcassCategory.test], closeTo(50, 1e-9));
      expect(breakdown[IcassCategory.pat], closeTo(80, 1e-9));
      expect(breakdown.containsKey(IcassCategory.assignment), isFalse);
    });
  });

  group('Threshold evaluation (vocational: ICASS 50 / exam 50, sub-minimum 50)', () {
    test('on track when ICASS and target exam both meet the sub-minimum', () {
      final e = IcassCalculator.evaluate(
        icassPercentage: 60,
        targetExamPercentage: 50,
        passPercentage: 50,
        isFundamental: false,
      );
      expect(e.status, ThresholdStatus.onTrack);
      expect(e.projectedFinal, closeTo(55, 1e-9));
      expect(e.examMarkNeeded, closeTo(50, 1e-9));
      expect(e.isOnTrack, isTrue);
    });

    test('needs a higher exam mark when the target is below the sub-minimum', () {
      final e = IcassCalculator.evaluate(
        icassPercentage: 60,
        targetExamPercentage: 45,
        passPercentage: 50,
        isFundamental: false,
      );
      expect(e.status, ThresholdStatus.needsHigherExam);
      expect(e.examMarkNeeded, closeTo(50, 1e-9));
    });

    test('flags ICASS below the sub-minimum regardless of exam mark', () {
      final e = IcassCalculator.evaluate(
        icassPercentage: 40,
        targetExamPercentage: 100,
        passPercentage: 50,
        isFundamental: false,
      );
      expect(e.status, ThresholdStatus.icassBelowMinimum);
    });
  });

  group('Threshold evaluation (fundamental: ICASS 25 / exam 75)', () {
    test('Maths uses a 30% sub-minimum and 25/75 weighting', () {
      final e = IcassCalculator.evaluate(
        icassPercentage: 60,
        targetExamPercentage: 50,
        passPercentage: 30,
        isFundamental: true,
      );
      // 0.25 * 60 + 0.75 * 50 = 52.5
      expect(e.projectedFinal, closeTo(52.5, 1e-9));
      expect(e.status, ThresholdStatus.onTrack);
    });

    test('exam requirement is raised when ICASS is weak but above the minimum', () {
      final e = IcassCalculator.evaluate(
        icassPercentage: 40,
        targetExamPercentage: 0,
        passPercentage: 30,
        isFundamental: true,
      );
      // Final pass needs (30 - 0.25*40) / 0.75 = 26.67. The exam sub-minimum of 30 binds.
      expect(e.examMarkNeeded, closeTo(30, 1e-9));
      expect(e.status, ThresholdStatus.needsHigherExam);
    });

    test('LO/FAL uses a 40% sub-minimum', () {
      final e = IcassCalculator.evaluate(
        icassPercentage: 39,
        targetExamPercentage: 90,
        passPercentage: 40,
        isFundamental: true,
      );
      expect(e.status, ThresholdStatus.icassBelowMinimum);
    });
  });
}
