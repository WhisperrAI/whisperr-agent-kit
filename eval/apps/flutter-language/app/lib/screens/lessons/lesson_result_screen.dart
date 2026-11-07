import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/progress_controller.dart';
import '../../widgets/common.dart';

class LessonResultScreen extends StatelessWidget {
  const LessonResultScreen({super.key, required this.lesson, required this.completion});

  final Lesson lesson;
  final LessonCompletion completion;

  @override
  Widget build(BuildContext context) {
    final result = completion.result;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('lesson-result-screen'),
      body: PageBody(
        children: [
          const SizedBox(height: 48),
          Text('¡Muy bien!', style: text.displaySmall),
          const SizedBox(height: 8),
          Text('You finished "${lesson.title}".', style: text.titleMedium),
          const SizedBox(height: 24),
          Text(
            '${result.correct} of ${result.total} correct · +${result.xpEarned} XP',
            key: const Key('lesson-result-score'),
            style: text.titleLarge,
          ),
          if (completion.reachedDailyGoal) ...[
            const SizedBox(height: 16),
            const Card(
              key: Key('lesson-result-goal'),
              child: ListTile(leading: Icon(Icons.local_fire_department), title: Text('Daily goal reached!')),
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            key: const Key('lesson-result-done'),
            label: 'Continue',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
