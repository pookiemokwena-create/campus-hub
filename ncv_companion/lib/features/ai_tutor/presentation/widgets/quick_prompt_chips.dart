import 'package:flutter/material.dart';

/// Quick actions. Each chip pre-fills the composer, so the learner adds the topic.
class QuickPromptChips extends StatelessWidget {
  const QuickPromptChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const prompts = <({String label, IconData icon, String template})>[
    (
      label: 'Explain this concept',
      icon: Icons.lightbulb_outline,
      template: 'Explain this concept in simple terms, with a South African example: ',
    ),
    (
      label: 'Summarize lesson',
      icon: Icons.summarize_outlined,
      template: 'Summarise this lesson in five bullet points: ',
    ),
    (
      label: 'Create 5 practice questions',
      icon: Icons.quiz_outlined,
      template: 'Create 5 practice questions, with memo answers, on: ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final prompt in prompts)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(prompt.icon, size: 18),
                label: Text(prompt.label),
                onPressed: () => onSelected(prompt.template),
              ),
            ),
        ],
      ),
    );
  }
}
