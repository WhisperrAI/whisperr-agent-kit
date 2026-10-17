import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../data/models.dart';
import '../../state/progress_controller.dart';
import '../../widgets/common.dart';
import 'lesson_result_screen.dart';

/// Plays a lesson: one multiple-choice exercise at a time, graded at the end.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final List<int> _answers = [];
  int? _selected;
  bool _busy = false;
  String? _error;

  int get _index => _answers.length;
  bool get _isLast => _index == widget.lesson.questions.length - 1;

  Future<void> _next() async {
    final selected = _selected;
    if (selected == null) return;
    if (!_isLast) {
      setState(() {
        _answers.add(selected);
        _selected = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final completion =
          await context.read<ProgressController>().completeLesson(widget.lesson.id, [..._answers, selected]);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => LessonResultScreen(lesson: widget.lesson, completion: completion),
      ));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = messageFor(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final question = lesson.questions[_index];
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('lesson-screen'),
      appBar: AppBar(title: Text(lesson.title)),
      body: PageBody(
        children: [
          LinearProgressIndicator(value: _index / lesson.questions.length),
          const SizedBox(height: 24),
          ErrorBanner(key: const Key('lesson-error'), message: _error),
          Text(question.prompt, key: const Key('lesson-question'), style: text.titleLarge),
          const SizedBox(height: 16),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                key: Key('answer-option-$i'),
                label: SizedBox(width: double.infinity, child: Text(question.options[i])),
                selected: _selected == i,
                onSelected: _busy ? null : (_) => setState(() => _selected = i),
              ),
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            key: const Key('lesson-next'),
            label: _isLast ? 'Finish lesson' : 'Next',
            busy: _busy,
            onPressed: _selected == null ? null : _next,
          ),
        ],
      ),
    );
  }
}
