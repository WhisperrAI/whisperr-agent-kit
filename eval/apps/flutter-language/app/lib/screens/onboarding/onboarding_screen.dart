import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/fake_backend.dart';
import '../../data/models.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';

enum _Step { reason, level, dailyGoal }

/// Three questions that tailor the course. Learners can skip at any step.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _dailyGoals = [5, 10, 15];

  var _step = _Step.reason;
  var _answers = const OnboardingAnswers();
  bool _saving = false;
  String? _error;

  bool get _isLast => _step == _Step.dailyGoal;

  bool get _canContinue => switch (_step) {
        _Step.reason => _answers.reason != null,
        _Step.level => _answers.level != null,
        _Step.dailyGoal => _answers.dailyGoalMinutes != null,
      };

  Future<void> _finish(OnboardingAnswers answers) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().completeOnboarding(answers);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = messageFor(error);
      });
    }
  }

  Widget _choice(String key, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ChoiceChip(
        key: Key(key),
        label: SizedBox(width: double.infinity, child: Text(label)),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final firstName = context.watch<AuthController>().user?.firstName ?? '';
    final (title, options) = switch (_step) {
      _Step.reason => (
          'Why are you learning Spanish, $firstName?',
          [
            for (final reason in LearningReason.values)
              _choice('reason-option-${reason.name}', reason.label, _answers.reason == reason,
                  () => setState(() => _answers = _answers.copyWith(reason: reason))),
          ],
        ),
      _Step.level => (
          'How much Spanish do you know?',
          [
            for (final level in SpanishLevel.values)
              _choice('level-option-${level.name}', level.label, _answers.level == level,
                  () => setState(() => _answers = _answers.copyWith(level: level))),
          ],
        ),
      _Step.dailyGoal => (
          'Pick a daily goal',
          [
            for (final minutes in _dailyGoals)
              _choice('daily-goal-option-$minutes', '$minutes minutes a day', _answers.dailyGoalMinutes == minutes,
                  () => setState(() => _answers = _answers.copyWith(dailyGoalMinutes: minutes))),
          ],
        ),
    };
    return Scaffold(
      key: Key('onboarding-step-${_step.name}'),
      body: PageBody(
        children: [
          const SizedBox(height: 24),
          Text('Step ${_step.index + 1} of ${_Step.values.length}', style: text.labelMedium),
          const SizedBox(height: 8),
          Text(title, style: text.headlineSmall),
          const SizedBox(height: 24),
          ErrorBanner(message: _error),
          ...options,
          const SizedBox(height: 24),
          PrimaryButton(
            key: Key(_isLast ? 'onboarding-finish' : 'onboarding-next'),
            label: _isLast ? 'Start learning' : 'Continue',
            busy: _saving,
            onPressed: !_canContinue
                ? null
                : () => _isLast ? _finish(_answers) : setState(() => _step = _Step.values[_step.index + 1]),
          ),
          SecondaryButton(
            key: const Key('onboarding-skip'),
            label: 'Skip for now',
            onPressed: _saving ? null : () => _finish(_answers),
          ),
        ],
      ),
    );
  }
}
