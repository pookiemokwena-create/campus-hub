import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/widgets/labeled_dropdown.dart';
import 'package:ncv_companion/features/past_papers/providers/past_paper_providers.dart';

/// Nested filters, in order: NQF level > stream > subject > year.
class PaperFilterBar extends ConsumerWidget {
  const PaperFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(paperFiltersProvider);
    final options = ref.watch(paperFilterOptionsProvider);
    final notifier = ref.read(paperFiltersProvider.notifier);

    final streamValue =
        options.streams.contains(filters.stream) ? filters.stream : null;
    final subjectValue = options.subjects.any((s) => s.id == filters.subjectId)
        ? filters.subjectId
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final level in AppConstants.nqfLevels)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('NQF $level'),
                      selected: filters.nqfLevel == level,
                      onSelected: (_) => notifier.setNqfLevel(level),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LabeledDropdown<String?>(
            label: 'Stream',
            value: streamValue,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All streams')),
              for (final stream in options.streams)
                DropdownMenuItem<String?>(
                  value: stream,
                  child: Text(stream, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: notifier.setStream,
          ),
          const SizedBox(height: 8),
          LabeledDropdown<String?>(
            label: 'Subject',
            value: subjectValue,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All subjects')),
              for (final subject in options.subjects)
                DropdownMenuItem<String?>(
                  value: subject.id,
                  child: Text(
                    '${subject.code} · ${subject.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: notifier.setSubject,
          ),
          if (options.years.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All years'),
                      selected: filters.year == null,
                      onSelected: (_) => notifier.setYear(null),
                    ),
                  ),
                  for (final year in options.years)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$year'),
                        selected: filters.year == year,
                        onSelected: (_) => notifier.setYear(year),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
