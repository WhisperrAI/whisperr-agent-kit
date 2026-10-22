import { useNavigation } from '@react-navigation/native';
import { useState } from 'react';

import { messageFor } from '../../api/client';
import { Body, Button, ErrorBanner, Field, Screen, ToggleRow } from '../../components/ui';
import { useAuth } from '../../state/AuthContext';

export function SignupScreen() {
  const navigation = useNavigation();
  const { signUp } = useAuth();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [marketingOptIn, setMarketingOptIn] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    setSubmitting(true);
    setError(null);
    try {
      await signUp({ fullName, email, password, marketingOptIn });
      // AuthProvider switches the navigator to onboarding.
    } catch (e) {
      setError(messageFor(e));
      setSubmitting(false);
    }
  };

  return (
    <Screen testID="signup-screen">
      <Body muted>Free forever for logging workouts. Upgrade to Pro any time.</Body>
      <ErrorBanner message={error} testID="signup-error" />
      <Field
        label="Full name"
        testID="signup-name"
        value={fullName}
        onChangeText={setFullName}
        autoComplete="name"
        textContentType="name"
      />
      <Field
        label="Email"
        testID="signup-email"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        autoComplete="email"
        keyboardType="email-address"
      />
      <Field
        label="Password"
        testID="signup-password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        autoComplete="new-password"
      />
      <ToggleRow
        label="Email me training tips and offers"
        testID="signup-marketing-consent"
        value={marketingOptIn}
        onValueChange={setMarketingOptIn}
      />
      <Button title="Create account" testID="signup-submit" loading={submitting} onPress={submit} />
      <Button
        title="Already have an account? Log in"
        variant="secondary"
        testID="signup-login-link"
        onPress={() => navigation.navigate('Login')}
      />
    </Screen>
  );
}
