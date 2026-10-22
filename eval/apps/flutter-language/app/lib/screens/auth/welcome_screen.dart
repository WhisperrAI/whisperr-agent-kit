import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/progress_controller.dart';
import '../../widgets/common.dart';
import '../lessons/lesson_preview_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<ProgressController>().lessons;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('welcome-screen'),
      body: PageBody(
        children: [
          const SizedBox(height: 24),
          Text('Parla', style: text.displaySmall),
          const SizedBox(height: 8),
          Text('Speak Spanish in five minutes a day.', style: text.titleMedium),
          const SizedBox(height: 24),
          Text('Peek at the course', style: text.titleSmall),
          for (final lesson in lessons)
            ListTile(
              key: Key('lesson-card-${lesson.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(lesson.title),
              subtitle: Text('${lesson.unit} · ${lesson.minutes} min'),
              trailing: Icon(lesson.premium ? Icons.lock_outline : Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => LessonPreviewScreen(lessonId: lesson.id)),
              ),
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const Key('welcome-signup'),
            label: 'Start learning for free',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SignupScreen())),
          ),
          SecondaryButton(
            key: const Key('welcome-login'),
            label: 'I already have an account',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
    );
  }
}
