import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/auth_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/subscription_controller.dart';
import '../billing/paywall_screen.dart';
import '../lessons/lesson_screen.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  void _open(BuildContext context, Lesson lesson) {
    final locked = lesson.premium && !context.read<SubscriptionController>().isPremium;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => locked ? const PaywallScreen(source: PaywallSource.lockedLesson) : LessonScreen(lesson: lesson),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    final progress = context.watch<ProgressController>();
    final premium = context.watch<SubscriptionController>().isPremium;
    final now = DateTime.now();
    final minutes = progress.minutesOn(now);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('home-screen'),
      appBar: AppBar(title: Text('¡Hola, ${user.firstName}!')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$minutes of ${user.dailyGoal} minutes today',
                    key: const Key('home-daily-progress'),
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: (minutes / user.dailyGoal).clamp(0, 1).toDouble()),
                  const SizedBox(height: 8),
                  Text('${progress.streakDays(now)}-day streak · ${progress.totalXp} XP', style: text.bodySmall),
                ],
              ),
            ),
          ),
          if (!premium)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                key: const Key('home-upgrade'),
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Unlock the Travel unit'),
                subtitle: const Text('Try Parla Premium'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const PaywallScreen(source: PaywallSource.homeBanner),
                )),
              ),
            ),
          const SizedBox(height: 16),
          for (final lesson in progress.lessons)
            ListTile(
              key: Key('lesson-tile-${lesson.id}'),
              leading: Icon(progress.isCompleted(lesson.id) ? Icons.check_circle : Icons.play_circle_outline),
              title: Text(lesson.title),
              subtitle: Text('${lesson.unit} · ${lesson.minutes} min'),
              trailing: lesson.premium && !premium ? const Icon(Icons.lock_outline) : null,
              onTap: () => _open(context, lesson),
            ),
        ],
      ),
    );
  }
}
