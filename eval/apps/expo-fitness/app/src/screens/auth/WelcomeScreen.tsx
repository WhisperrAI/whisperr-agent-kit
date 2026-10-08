import { useNavigation } from '@react-navigation/native';
import { useEffect, useState } from 'react';
import { Text } from 'react-native';

import { workoutsApi } from '../../api/workouts';
import type { Program } from '../../api/types';
import { Body, Button, Card, ErrorBanner, Screen, Title } from '../../components/ui';
import { messageFor } from '../../api/client';

export function WelcomeScreen() {
  const navigation = useNavigation();
  const [programs, setPrograms] = useState<Program[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    workoutsApi.listPrograms().then(setPrograms, (e) => setError(messageFor(e)));
  }, []);

  return (
    <Screen testID="welcome-screen">
      <Title>Train smarter with Repwise</Title>
      <Body muted>Pick a program, log every session, and watch your streak grow.</Body>
      <ErrorBanner message={error} />
      {programs.map((program) => (
        <Card
          key={program.id}
          testID={`program-card-${program.id}`}
          onPress={() => navigation.navigate('ProgramDetail', { programId: program.id })}
        >
          <Text style={{ color: '#F4F5F7', fontSize: 18, fontWeight: '600' }}>{program.title}</Text>
          <Body muted>
            {program.weeks} weeks · {program.sessionsPerWeek}x per week{program.premium ? ' · Pro' : ''}
          </Body>
        </Card>
      ))}
      <Button title="Create free account" testID="welcome-signup" onPress={() => navigation.navigate('Signup')} />
      <Button
        title="I already have an account"
        variant="secondary"
        testID="welcome-login"
        onPress={() => navigation.navigate('Login')}
      />
    </Screen>
  );
}
