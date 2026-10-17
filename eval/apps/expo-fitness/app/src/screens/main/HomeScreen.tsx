import { useNavigation } from '@react-navigation/native';
import { Text } from 'react-native';

import { Body, Button, Card, Screen, Title, colors } from '../../components/ui';
import { useAuth } from '../../state/AuthContext';
import { useSubscription } from '../../state/SubscriptionContext';
import { countSince, currentStreak, useWorkouts } from '../../state/WorkoutsContext';

const LABELS = { strength: 'Strength', run: 'Run', hiit: 'HIIT', yoga: 'Yoga' } as const;

export function HomeScreen() {
  const navigation = useNavigation();
  const { user } = useAuth();
  const { workouts } = useWorkouts();
  const { isPro } = useSubscription();

  const thisWeek = countSince(workouts, 7);
  const streak = currentStreak(workouts);

  return (
    <Screen testID="home-screen">
      <Title>Hi {user?.fullName.split(' ')[0]}</Title>
      <Card>
        <Text testID="home-week-progress" style={{ color: colors.text, fontSize: 18, fontWeight: '600' }}>
          {thisWeek} of {user?.weeklyTarget ?? 3} workouts this week
        </Text>
        <Body muted>{streak > 0 ? `${streak}-day streak. Keep it going!` : 'Log a workout to start a streak.'}</Body>
      </Card>
      <Button title="Log a workout" testID="home-log-workout" onPress={() => navigation.navigate('LogWorkout')} />
      {!isPro && (
        <Card testID="home-upgrade" onPress={() => navigation.navigate('Paywall', { source: 'home_banner' })}>
          <Text style={{ color: colors.accent, fontWeight: '700' }}>Repwise Pro</Text>
          <Body>Unlock every program, progress insights and custom plans.</Body>
        </Card>
      )}
      <Body muted>Recent</Body>
      {workouts.slice(0, 5).map((workout) => (
        <Card key={workout.id} testID="home-recent-workout">
          <Body>
            {LABELS[workout.type]} · {workout.durationMinutes} min
          </Body>
        </Card>
      ))}
    </Screen>
  );
}
