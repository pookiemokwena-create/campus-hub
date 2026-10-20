import 'package:flutter/material.dart';

import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/theme/app_theme.dart';
import 'package:ncv_companion/core/utils/format.dart';
import 'package:ncv_companion/features/icass/domain/icass_calculator.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';

/// Live pass check. Shows what is needed in the exam and how ICASS is split by category.
class ThresholdResultCard extends StatelessWidget {
  const ThresholdResultCard({
    super.key,
    required this.subject,
    required this.evaluation,
    required this.breakdown,
    required this.hasTasks,
  });

  final Subject subject;
  final IcassEvaluation evaluation;
  final Map<IcassCategory, double> breakdown;
  final bool hasTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (color, icon, title, message) = _describe(evaluation.status);
    final weightPct = (evaluation.icassWeight * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(label: 'ICASS', value: evaluation.icassPercentage),
                _Stat(label: 'Target exam', value: evaluation.targetExamPercentage),
                _Stat(label: 'Projected final', value: evaluation.projectedFinal),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampUnit(evaluation.projectedFinal / 100),
                minHeight: 10,
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final pass mark ${subject.passPercentage}% · ICASS $weightPct% of final mark',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (hasTasks && breakdown.isNotEmpty) ...[
              const Divider(height: 28),
              Text('ICASS by assessment', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final entry in breakdown.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 90, child: Text(entry.key.label)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: clampUnit(entry.value / 100),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${formatPercent(entry.value)}%',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, IconData, String, String) _describe(ThresholdStatus status) {
    final pass = subject.passPercentage;
    final icass = formatPercent(evaluation.icassPercentage);
    final needed = formatPercent(evaluation.examMarkNeeded);
    final target = formatPercent(evaluation.targetExamPercentage);

    return switch (status) {
      ThresholdStatus.onTrack => (
          AppTheme.success,
          Icons.check_circle_outline,
          'On track',
          'ICASS ($icass%) and your target exam mark ($target%) both meet the '
              '$pass% sub-minimum.',
        ),
      ThresholdStatus.needsHigherExam => (
          AppTheme.warning,
          Icons.trending_up,
          'Exam mark needed: $needed%',
          'ICASS is $icass%, which meets the sub-minimum. Your target exam mark '
              'is $target%. You need at least $needed% in the exam to pass.',
        ),
      ThresholdStatus.icassBelowMinimum => (
          AppTheme.danger,
          Icons.report_gpp_outlined,
          'ICASS below sub-minimum',
          'ICASS is $icass%, but the sub-minimum is $pass%. Under NC(V) rules, a '
              'learner must meet the sub-minimum in ICASS and in the exam. Improve '
              'upcoming tasks, PATs and tests to close the gap.',
        ),
    };
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatPercent(value)}%',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
