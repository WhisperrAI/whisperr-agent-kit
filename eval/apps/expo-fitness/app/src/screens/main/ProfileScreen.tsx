import { useNavigation } from '@react-navigation/native';
import { useEffect, useState } from 'react';
import { Text } from 'react-native';

import { networkSimulator } from '../../api/client';
import type { Subscription } from '../../api/types';
import { Body, Button, Card, Screen, ToggleRow, colors } from '../../components/ui';
import { useAuth } from '../../state/AuthContext';
import { useSubscription } from '../../state/SubscriptionContext';

export function ProfileScreen() {
  const navigation = useNavigation();
  const { user, logOut } = useAuth();
  const { subscription } = useSubscription();
  const [offline, setOffline] = useState(networkSimulator.isOffline());
  const [loggingOut, setLoggingOut] = useState(false);

  useEffect(() => networkSimulator.subscribe(setOffline), []);

  return (
    <Screen testID="profile-screen">
      <Card>
        <Body>{user?.fullName}</Body>
        <Body muted>{user?.email}</Body>
        {user?.phone ? <Body muted>{user.phone}</Body> : null}
      </Card>
      <Card>
        <Text testID="profile-plan" style={{ color: colors.text, fontSize: 16 }}>
          {planLabel(subscription)}
        </Text>
      </Card>
      {subscription ? (
        <Button
          title="Manage subscription"
          variant="secondary"
          testID="profile-manage-subscription"
          onPress={() => navigation.navigate('ManageSubscription')}
        />
      ) : (
        <Button
          title="Upgrade to Pro"
          testID="profile-upgrade"
          onPress={() => navigation.navigate('Paywall', { source: 'profile' })}
        />
      )}
      <ToggleRow
        label="Developer: simulate offline API"
        testID="dev-network-failure"
        value={offline}
        onValueChange={(value) => networkSimulator.setOffline(value)}
      />
      <Button
        title="Log out"
        variant="danger"
        testID="profile-logout"
        loading={loggingOut}
        onPress={async () => {
          setLoggingOut(true);
          await logOut();
        }}
      />
    </Screen>
  );
}

function planLabel(subscription: Subscription | null): string {
  if (!subscription) return 'Free plan';
  const name = subscription.planId === 'pro_annual' ? 'Pro Annual' : 'Pro Monthly';
  if (subscription.status === 'active') return name;
  return `${name}: Canceled, active until ${new Date(subscription.currentPeriodEnd).toLocaleDateString()}`;
}
