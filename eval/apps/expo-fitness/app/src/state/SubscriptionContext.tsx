import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

import { billingApi, type PurchaseInput } from '../api/billing';
import type { CancelReason, Receipt, Subscription } from '../api/types';
import { useAuth } from './AuthContext';

interface SubscriptionContextValue {
  subscription: Subscription | null;
  isPro: boolean;
  purchase(input: PurchaseInput): Promise<Receipt>;
  cancel(reason: CancelReason, feedback: string): Promise<Subscription>;
}

const SubscriptionContext = createContext<SubscriptionContextValue | null>(null);

export function SubscriptionProvider({ children }: { children: ReactNode }) {
  const { token } = useAuth();
  // Keyed by session so a logout never shows the previous user's plan.
  const [loaded, setLoaded] = useState<{ token: string; subscription: Subscription | null } | null>(null);
  const subscription = loaded && loaded.token === token ? loaded.subscription : null;

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    billingApi.getSubscription(token).then(
      (current) => {
        if (!cancelled) setLoaded({ token, subscription: current });
      },
      () => undefined,
    );
    return () => {
      cancelled = true;
    };
  }, [token]);

  const purchase = useCallback(
    async (input: PurchaseInput) => {
      if (!token) throw new Error('Not signed in');
      const receipt = await billingApi.purchase(token, input);
      setLoaded({ token, subscription: receipt.subscription });
      return receipt;
    },
    [token],
  );

  const cancel = useCallback(
    async (reason: CancelReason, feedback: string) => {
      if (!token) throw new Error('Not signed in');
      const next = await billingApi.cancel(token, reason, feedback);
      setLoaded({ token, subscription: next });
      return next;
    },
    [token],
  );

  const value = useMemo(
    () => ({ subscription, isPro: subscription?.status === 'active', purchase, cancel }),
    [subscription, purchase, cancel],
  );
  return <SubscriptionContext.Provider value={value}>{children}</SubscriptionContext.Provider>;
}

export function useSubscription(): SubscriptionContextValue {
  const value = useContext(SubscriptionContext);
  if (!value) throw new Error('useSubscription must be used inside <SubscriptionProvider>');
  return value;
}
