import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';

import { PLANS } from '../../api/fixtures';
import { Body, Button, Screen, Title } from '../../components/ui';
import type { RootStackParamList } from '../../navigation/types';

export function PurchaseSuccessScreen() {
  const navigation = useNavigation();
  const { params } = useRoute<RouteProp<RootStackParamList, 'PurchaseSuccess'>>();
  const plan = PLANS.find((p) => p.id === params.planId);

  return (
    <Screen testID="purchase-success-screen">
      <Title>You are on Repwise Pro</Title>
      <Body>Your {plan?.name ?? 'Pro'} plan is active. Every program is now unlocked.</Body>
      <Button title="Let's go" testID="purchase-success-done" onPress={() => navigation.navigate('Main', { screen: 'Home' })} />
    </Screen>
  );
}
