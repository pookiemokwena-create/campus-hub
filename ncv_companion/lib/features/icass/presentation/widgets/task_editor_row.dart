import 'package:flutter/material.dart';

import 'package:ncv_companion/core/utils/format.dart';
import 'package:ncv_companion/features/icass/models/icass_task.dart';

/// One assessment: name, score, and maximum. Field values are seeded once via
/// initialValue, and the parent keys this widget by task id to keep focus stable.
class TaskEditorRow extends StatelessWidget {
  const TaskEditorRow({
    super.key,
    required this.task,
    required this.onChanged,
    required this.onDelete,
  });

  final IcassTask task;
  final ValueChanged<IcassTask> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreTooHigh = task.score > task.maxScore && task.maxScore > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(task.category.label),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: task.name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Task name'),
                    onChanged: (value) => onChanged(task.copyWith(name: value)),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove task',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: formatPercent(task.score),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Mark',
                      errorText: scoreTooHigh ? 'Above maximum' : null,
                    ),
                    onChanged: (value) =>
                        onChanged(task.copyWith(score: parseDecimal(value))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: formatPercent(task.maxScore),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Out of'),
                    onChanged: (value) =>
                        onChanged(task.copyWith(maxScore: parseDecimal(value))),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${formatPercent(task.percentage)}%',
                    style: theme.textTheme.titleSmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
