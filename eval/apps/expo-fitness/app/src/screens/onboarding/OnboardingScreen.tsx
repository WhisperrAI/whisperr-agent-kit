import { useState } from 'react';
import { View } from 'react-native';

import { messageFor } from '../../api/client';
import type { ExperienceLevel, Goal, OnboardingAnswers } from '../../api/types';
import { Body, Button, Choice, ErrorBanner, Screen, Title } from '../../components/ui';
import { useAuth } from '../../state/AuthContext';

const GOALS: { id: Goal; label: string }[] = [
  { id: 'build_strength', label: 'Build strength' },
  { id: 'lose_weight', label: 'Lose weight' },
  { id: 'run_faster', label: 'Run faster' },
  { id: 'stay_active', label: 'Stay active' },
];

const LEVELS: { id: ExperienceLevel; label: string; detail: string }[] = [
  { id: 'beginner', label: 'New to training', detail: 'Less than 6 months' },
  { id: 'intermediate', label: 'Some experience', detail: '6 months to 2 years' },
  { id: 'advanced', label: 'Experienced', detail: 'More than 2 years' },
];

const TARGETS = [2, 3, 4, 5];

const STEPS = ['goal', 'experience', 'schedule'] as const;

export function OnboardingScreen() {
  const { user, completeOnboarding } = useAuth();
  const [step, setStep] = useState(0);
  const [answers, setAnswers] = useState<OnboardingAnswers>({});
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const firstName = user?.fullName.split(' ')[0] ?? 'there';
  const current = STEPS[step];
  const isLast = step === STEPS.length - 1;
  const canContinue =
    (current === 'goal' && !!answers.goal) ||
    (current === 'experience' && !!answers.experience) ||
    (current === 'schedule' && !!answers.weeklyTarget);

  const finish = async (final: OnboardingAnswers) => {
    setSaving(true);
    setError(null);
    try {
      await completeOnboarding(final);
    } catch (e) {
      setError(messageFor(e));
      setSaving(false);
    }
  };

  return (
    <Screen testID={`onboarding-step-${current}`}>
      <Body muted>
        Step {step + 1} of {STEPS.length}
      </Body>
      {current === 'goal' && (
        <>
          <Title>Welcome, {firstName}! What is your main goal?</Title>
          {GOALS.map((goal) => (
            <Choice
              key={goal.id}
              testID={`goal-option-${goal.id}`}
              label={goal.label}
              selected={answers.goal === goal.id}
              onPress={() => setAnswers((a) => ({ ...a, goal: goal.id }))}
            />
          ))}
        </>
      )}
      {current === 'experience' && (
        <>
          <Title>How much have you trained before?</Title>
          {LEVELS.map((level) => (
            <Choice
              key={level.id}
              testID={`experience-option-${level.id}`}
              label={level.label}
              detail={level.detail}
              selected={answers.experience === level.id}
              onPress={() => setAnswers((a) => ({ ...a, experience: level.id }))}
            />
          ))}
        </>
      )}
      {current === 'schedule' && (
        <>
          <Title>How many workouts per week?</Title>
          {TARGETS.map((target) => (
            <Choice
              key={target}
              testID={`weekly-target-option-${target}`}
              label={`${target} workouts`}
              selected={answers.weeklyTarget === target}
              onPress={() => setAnswers((a) => ({ ...a, weeklyTarget: target }))}
            />
          ))}
        </>
      )}
      <ErrorBanner message={error} testID="onboarding-error" />
      <View style={{ gap: 10 }}>
        <Button
          title={isLast ? 'Start training' : 'Continue'}
          testID={isLast ? 'onboarding-finish' : 'onboarding-next'}
          disabled={!canContinue}
          loading={saving}
          onPress={() => (isLast ? finish(answers) : setStep((s) => s + 1))}
        />
        <Button title="Skip for now" variant="secondary" testID="onboarding-skip" onPress={() => finish(answers)} />
      </View>
    </Screen>
  );
}
