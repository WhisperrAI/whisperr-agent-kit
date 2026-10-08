import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import { useEffect, useState } from 'react';

import { billingApi } from '../../api/billing';
import { messageFor } from '../../api/client';
import type { Plan } from '../../api/types';
import { Body, Button, Choice, ErrorBanner, Screen, Title, formatPrice } from '../../components/ui';
import type { RootStackParamList } from '../../navigation/types';

const PERKS = ['Every program, including HIIT and Mobility', 'Progress insights and trends', 'Custom weekly plans'];

export function PaywallScreen() {
  const navigation = useNavigation();
  const { params } = useRoute<RouteProp<RootStackParamList, 'Paywall'>>();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [selected, setSelected] = useState<Plan['id']>('pro_annual');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    billingApi.listPlans().then(setPlans, (e) => setError(messageFor(e)));
  }, []);

  return (
    <Screen testID="paywall-screen">
      <Title>Go further with Repwise Pro</Title>
      {PERKS.map((perk) => (
        <Body key={perk}>• {perk}</Body>
      ))}
      <ErrorBanner message={error} />
      {plans.map((plan) => (
        <Choice
          key={plan.id}
          testID={`plan-option-${plan.id}`}
          label={`${plan.name}${plan.badge ? ` · ${plan.badge}` : ''}`}
          detail={`${formatPrice(plan.priceCents, plan.currency)} per ${plan.period}`}
          selected={selected === plan.id}
          onPress={() => setSelected(plan.id)}
        />
      ))}
      <Button
        title="Continue"
        testID="paywall-continue"
        disabled={plans.length === 0}
        onPress={() => navigation.navigate('Checkout', { planId: selected, source: params.source })}
      />
      <Button title="Not now" variant="secondary" testID="paywall-dismiss" onPress={() => navigation.goBack()} />
    </Screen>
  );
}
