import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import { useEffect, useState } from 'react';

import { messageFor } from '../../api/client';
import type { Program } from '../../api/types';
import { workoutsApi } from '../../api/workouts';
import { Body, Button, ErrorBanner, Screen, Title } from '../../components/ui';
import type { RootStackParamList } from '../../navigation/types';
import { useAuth } from '../../state/AuthContext';
import { useSubscription } from '../../state/SubscriptionContext';

export function ProgramDetailScreen() {
  const navigation = useNavigation();
  const { params } = useRoute<RouteProp<RootStackParamList, 'ProgramDetail'>>();
  const { status } = useAuth();
  const { isPro } = useSubscription();
  const [program, setProgram] = useState<Program | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    workoutsApi.getProgram(params.programId).then(setProgram, (e) => setError(messageFor(e)));
  }, [params.programId]);

  const start = () => {
    if (status !== 'signedIn') navigation.navigate('Signup');
    else if (program?.premium && !isPro) navigation.navigate('Paywall', { source: 'premium_program' });
    else navigation.navigate('LogWorkout');
  };

  return (
    <Screen testID="program-detail-screen">
      <ErrorBanner message={error} />
      {program && (
        <>
          <Title>{program.title}</Title>
          <Body muted>
            {program.weeks} weeks · {program.sessionsPerWeek} sessions per week · {program.level}
          </Body>
          <Body>{program.summary}</Body>
          <Button
            title={status === 'signedIn' ? 'Start a session' : 'Sign up to start'}
            testID="program-start"
            onPress={start}
          />
        </>
      )}
    </Screen>
  );
}
