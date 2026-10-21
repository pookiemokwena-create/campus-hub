import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/providers/catalog_providers.dart';
import 'package:ncv_companion/core/sync/sync_coordinator.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/core/utils/format.dart';
import 'package:ncv_companion/core/widgets/labeled_dropdown.dart';
import 'package:ncv_companion/core/widgets/status_views.dart';
import 'package:ncv_companion/features/icass/domain/icass_calculator.dart';
import 'package:ncv_companion/features/icass/models/icass_record.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';
import 'package:ncv_companion/features/icass/presentation/widgets/task_editor_row.dart';
import 'package:ncv_companion/features/icass/presentation/widgets/threshold_result_card.dart';
import 'package:ncv_companion/features/icass/providers/icass_providers.dart';

/// ICASS & exam mark calculator.
///
/// Every change updates the pass check instantly. Data is saved to Hive on
/// each edit and syncs to Supabase when the device is online.
class IcassCalculatorScreen extends ConsumerWidget {
  const IcassCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(applicableSubjectsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final subject = ref.watch(activeSubjectProvider);
    final draft = ref.watch(icassDraftProvider);
    final evaluation = ref.watch(icassEvaluationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ICASS & Exam Calculator')),
      body: _buildBody(
        context,
        ref,
        subjects: subjects,
        subjectsAsync: subjectsAsync,
        subject: subject,
        draft: draft,
        evaluation: evaluation,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required List<Subject> subjects,
    required AsyncValue<List<Subject>> subjectsAsync,
    required Subject? subject,
    required IcassRecord? draft,
    required IcassEvaluation? evaluation,
  }) {
    if (subjects.isEmpty) {
      if (subjectsAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (subjectsAsync.hasError) {
        return ErrorState(
          message: friendlyError(subjectsAsync.error!),
          onRetry: () => ref.invalidate(subjectsProvider),
        );
      }
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        message: 'Subjects for your NQF level and stream appear here once they are published.',
      );
    }

    if (subject == null || draft == null || evaluation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifier = ref.read(icassRecordsControllerProvider.notifier);
    final sync = ref.watch(syncCoordinatorProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        LabeledDropdown<String>(
          label: 'Subject',
          value: subject.id,
          items: [
            for (final s in subjects)
              DropdownMenuItem(
                value: s.id,
                child: Text(
                  '${s.code} · ${s.title}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null) {
              ref.read(selectedSubjectIdProvider.notifier).select(id);
            }
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.flag_outlined, size: 18),
              label: Text('Sub-minimum ${subject.passPercentage}%'),
            ),
            Chip(
              label: Text(
                subject.isFundamental
                    ? 'Fundamental · ICASS 25%'
                    : 'Vocational · ICASS 50%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('target-${subject.id}'),
          initialValue: draft.targetExamScore > 0
              ? formatPercent(draft.targetExamScore)
              : '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Target exam mark (%)',
            prefixIcon: Icon(Icons.track_changes),
          ),
          onChanged: (value) => notifier.setTargetExam(
            subject.id,
            clampPercent(parseDecimal(value)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Assessments', style: theme.textTheme.titleMedium),
            ),
            PopupMenuButton<IcassCategory>(
              tooltip: 'Add assessment',
              onSelected: (category) => notifier.saveTask(
                subject.id,
                buildNewTask(category, draft.tasks),
              ),
              itemBuilder: (_) => [
                for (final category in IcassCategory.values)
                  PopupMenuItem(
                    value: category,
                    child: Text('Add ${category.label}'),
                  ),
              ],
              child: const Chip(
                avatar: Icon(Icons.add, size: 18),
                label: Text('Add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (draft.tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Add your test, assignment and PAT marks to see your ICASS percentage.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final task in draft.tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TaskEditorRow(
              key: ValueKey(task.id),
              task: task,
              onChanged: (updated) => notifier.saveTask(subject.id, updated),
              onDelete: () => notifier.removeTask(subject.id, task.id),
            ),
          ),
        const SizedBox(height: 16),
        ThresholdResultCard(
          subject: subject,
          evaluation: evaluation,
          breakdown: IcassCalculator.categoryBreakdown(draft.tasks),
          hasTasks: draft.tasks.isNotEmpty,
        ),
        const SizedBox(height: 12),
        Text(
          sync.syncing
              ? 'Saved on this device. Syncing…'
              : 'Saved on this device. Syncs automatically when you are online.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
