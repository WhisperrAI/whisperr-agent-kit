import { useNavigation } from '@react-navigation/native';
import { useState } from 'react';
import { View } from 'react-native';

import { messageFor } from '../../api/client';
import type { WorkoutType } from '../../api/types';
import { Button, Choice, ErrorBanner, Field, Screen } from '../../components/ui';
import { useWorkouts } from '../../state/WorkoutsContext';

const TYPES: { id: WorkoutType; label: string }[] = [
  { id: 'strength', label: 'Strength' },
  { id: 'run', label: 'Run' },
  { id: 'hiit', label: 'HIIT' },
  { id: 'yoga', label: 'Yoga' },
];

export function LogWorkoutScreen() {
  const navigation = useNavigation();
  const { logWorkout } = useWorkouts();
  const [type, setType] = useState<WorkoutType>('strength');
  const [duration, setDuration] = useState('30');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async () => {
    setSaving(true);
    setError(null);
    try {
      await logWorkout({ type, durationMinutes: Number.parseInt(duration, 10), notes });
      navigation.goBack();
    } catch (e) {
      setError(messageFor(e));
      setSaving(false);
    }
  };

  return (
    <Screen testID="log-workout-screen">
      <View style={{ gap: 8 }}>
        {TYPES.map((option) => (
          <Choice
            key={option.id}
            testID={`workout-type-${option.id}`}
            label={option.label}
            selected={type === option.id}
            onPress={() => setType(option.id)}
          />
        ))}
      </View>
      <Field label="Duration (minutes)" testID="workout-duration" value={duration} onChangeText={setDuration} keyboardType="number-pad" />
      <Field label="Notes" testID="workout-notes" value={notes} onChangeText={setNotes} multiline placeholder="How did it feel?" />
      <ErrorBanner message={error} testID="workout-error" />
      <Button title="Save workout" testID="workout-save" loading={saving} onPress={save} />
    </Screen>
  );
}
