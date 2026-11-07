import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../data/models.dart';
import '../../state/auth_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/subscription_controller.dart';
import '../../widgets/common.dart';
import '../auth/signup_screen.dart';
import '../billing/paywall_screen.dart';
import 'lesson_screen.dart';

/// What a lesson covers. Guests can browse it; members start it from here.
class LessonPreviewScreen extends StatefulWidget {
  const LessonPreviewScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonPreviewScreen> createState() => _LessonPreviewScreenState();
}

class _LessonPreviewScreenState extends State<LessonPreviewScreen> {
  Lesson? _lesson;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<ProgressController>().fetchLesson(widget.lessonId).then(
      (lesson) {
        if (mounted) setState(() => _lesson = lesson);
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = messageFor(error));
      },
    );
  }

  void _start() {
    final lesson = _lesson!;
    final navigator = Navigator.of(context);
    if (context.read<AuthController>().status != AuthStatus.signedIn) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => const SignupScreen()));
    } else if (lesson.premium && !context.read<SubscriptionController>().isPremium) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => const PaywallScreen(source: PaywallSource.lockedLesson)));
    } else {
      navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final signedIn = context.watch<AuthController>().status == AuthStatus.signedIn;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('lesson-preview-screen'),
      appBar: AppBar(title: Text(lesson?.unit ?? '')),
      body: PageBody(
        children: [
          ErrorBanner(message: _error),
          if (lesson != null) ...[
            Text(lesson.title, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text('${lesson.minutes} minutes · ${lesson.questions.length} exercises', style: text.bodySmall),
            const SizedBox(height: 16),
            Text(lesson.summary, style: text.bodyLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Try it: ${lesson.questions.first.prompt}'),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('lesson-start'),
              label: signedIn ? 'Start lesson' : 'Sign up to start',
              onPressed: _start,
            ),
          ],
        ],
      ),
    );
  }
}
