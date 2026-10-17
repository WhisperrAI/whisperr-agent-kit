import { useNavigation } from '@react-navigation/native';

import { Body, Button, Card, Screen } from '../../components/ui';
import { useSubscription } from '../../state/SubscriptionContext';
import { useWorkouts } from '../../state/WorkoutsContext';

export function HistoryScreen() {
  const navigation = useNavigation();
  const { workouts } = useWorkouts();
  const { isPro } = useSubscription();
  const totalMinutes = workouts.reduce((sum, w) => sum + w.durationMinutes, 0);

  return (
    <Screen testID="history-screen">
      <Card>
        <Body>
          {workouts.length} workouts · {totalMinutes} minutes total
        </Body>
      </Card>
      {isPro ? (
        <Card testID="history-insights">
          <Body>Average session: {workouts.length ? Math.round(totalMinutes / workouts.length) : 0} min</Body>
        </Card>
      ) : (
        <Button
          title="Unlock progress insights"
          variant="secondary"
          testID="history-unlock-insights"
          onPress={() => navigation.navigate('Paywall', { source: 'history_insights' })}
        />
      )}
      {workouts.map((workout) => (
        <Card key={workout.id}>
          <Body>
            {new Date(workout.loggedAt).toLocaleDateString()} · {workout.type} · {workout.durationMinutes} min
          </Body>
          {workout.notes ? <Body muted>{workout.notes}</Body> : null}
        </Card>
      ))}
    </Screen>
  );
}
