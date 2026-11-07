import { useNavigation } from '@react-navigation/native';
import { Text } from 'react-native';

import { Body, Button, Card, Screen, colors } from '../../components/ui';
import { useSubscription } from '../../state/SubscriptionContext';

export function ManageSubscriptionScreen() {
  const navigation = useNavigation();
  const { subscription } = useSubscription();
  if (!subscription) {
    return (
      <Screen testID="manage-subscription-screen">
        <Body muted>You are on the free plan.</Body>
      </Screen>
    );
  }

  const until = new Date(subscription.currentPeriodEnd).toLocaleDateString();
  return (
    <Screen testID="manage-subscription-screen">
      <Card>
        <Body>{subscription.planId === 'pro_annual' ? 'Pro Annual' : 'Pro Monthly'}</Body>
        <Text testID="subscription-status" style={{ color: colors.muted }}>
          {subscription.status === 'active' ? `Renews on ${until}` : `Canceled. Pro stays active until ${until}.`}
        </Text>
      </Card>
      {subscription.status === 'active' && (
        <Button
          title="Cancel subscription"
          variant="danger"
          testID="subscription-cancel"
          onPress={() => navigation.navigate('CancelSubscription')}
        />
      )}
    </Screen>
  );
}
