import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useState } from 'react';

import { messageFor } from '../../api/client';
import type { CancelReason } from '../../api/types';
import { Body, Button, Choice, ErrorBanner, Field, Screen } from '../../components/ui';
import type { RootStackParamList } from '../../navigation/types';
import { useSubscription } from '../../state/SubscriptionContext';

const REASONS: { id: CancelReason; label: string }[] = [
  { id: 'too_expensive', label: 'It is too expensive' },
  { id: 'not_using', label: 'I am not using it enough' },
  { id: 'missing_features', label: 'It is missing something I need' },
  { id: 'switching_app', label: 'I am switching to another app' },
  { id: 'other', label: 'Something else' },
];

export function CancelSubscriptionScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { cancel } = useSubscription();
  const [reason, setReason] = useState<CancelReason | null>(null);
  const [feedback, setFeedback] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const confirm = async () => {
    if (!reason) return;
    setSubmitting(true);
    setError(null);
    try {
      await cancel(reason, feedback);
      navigation.popTo('Main', { screen: 'Profile' });
    } catch (e) {
      setError(messageFor(e));
      setSubmitting(false);
    }
  };

  return (
    <Screen testID="cancel-subscription-screen">
      <Body>Sorry to see you go. Why are you canceling?</Body>
      {REASONS.map((option) => (
        <Choice
          key={option.id}
          testID={`cancel-reason-${option.id}`}
          label={option.label}
          selected={reason === option.id}
          onPress={() => setReason(option.id)}
        />
      ))}
      <Field
        label="Anything else we should know?"
        testID="cancel-feedback"
        value={feedback}
        onChangeText={setFeedback}
        multiline
      />
      <ErrorBanner message={error} testID="cancel-error" />
      <Button title="Cancel subscription" variant="danger" testID="cancel-confirm" disabled={!reason} loading={submitting} onPress={confirm} />
      <Button title="Keep Pro" variant="secondary" testID="cancel-keep" onPress={() => navigation.goBack()} />
    </Screen>
  );
}
