import { useState } from 'react';

import { messageFor } from '../../api/client';
import { Button, ErrorBanner, Field, Screen } from '../../components/ui';
import { useAuth } from '../../state/AuthContext';

export function LoginScreen() {
  const { logIn } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    setSubmitting(true);
    setError(null);
    try {
      await logIn(email, password);
    } catch (e) {
      setError(messageFor(e));
      setSubmitting(false);
    }
  };

  return (
    <Screen testID="login-screen">
      <ErrorBanner message={error} testID="login-error" />
      <Field
        label="Email"
        testID="login-email"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        autoComplete="email"
        keyboardType="email-address"
      />
      <Field
        label="Password"
        testID="login-password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        autoComplete="current-password"
      />
      <Button title="Log in" testID="login-submit" loading={submitting} onPress={submit} />
    </Screen>
  );
}
