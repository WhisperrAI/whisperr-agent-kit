import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import { useState } from 'react';

import { billingApi } from '../../api/billing';
import { messageFor } from '../../api/client';
import { PLANS } from '../../api/fixtures';
import { Body, Button, ErrorBanner, Field, Screen, formatPrice } from '../../components/ui';
import type { RootStackParamList } from '../../navigation/types';
import { useAuth } from '../../state/AuthContext';
import { useSubscription } from '../../state/SubscriptionContext';

export function CheckoutScreen() {
  const navigation = useNavigation();
  const { params } = useRoute<RouteProp<RootStackParamList, 'Checkout'>>();
  const { user } = useAuth();
  const { purchase } = useSubscription();
  const plan = PLANS.find((p) => p.id === params.planId)!;

  const [cardNumber, setCardNumber] = useState('');
  const [expiry, setExpiry] = useState('');
  const [cvc, setCvc] = useState('');
  const [billingAddress, setBillingAddress] = useState(() => (user ? billingApi.billingAddressFor(user.email) : ''));
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const pay = async () => {
    setSubmitting(true);
    setError(null);
    try {
      await purchase({ planId: plan.id, cardNumber, expiry, cvc, billingAddress });
      navigation.reset({
        index: 1,
        routes: [{ name: 'Main' }, { name: 'PurchaseSuccess', params: { planId: plan.id } }],
      });
    } catch (e) {
      setError(messageFor(e));
      setSubmitting(false);
    }
  };

  return (
    <Screen testID="checkout-screen">
      <Body>
        {plan.name}: {formatPrice(plan.priceCents, plan.currency)} per {plan.period}
      </Body>
      <ErrorBanner message={error} testID="checkout-error" />
      <Field label="Card number" testID="checkout-card-number" value={cardNumber} onChangeText={setCardNumber} keyboardType="number-pad" />
      <Field label="Expiry (MM/YY)" testID="checkout-expiry" value={expiry} onChangeText={setExpiry} />
      <Field label="CVC" testID="checkout-cvc" value={cvc} onChangeText={setCvc} keyboardType="number-pad" />
      <Field label="Billing address" testID="checkout-billing-address" value={billingAddress} onChangeText={setBillingAddress} />
      <Button title={`Pay ${formatPrice(plan.priceCents, plan.currency)}`} testID="checkout-submit" loading={submitting} onPress={pay} />
    </Screen>
  );
}
