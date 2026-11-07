import { ApiError, request } from './client';
import { DECLINED_CARDS, DEMO_PROFILES, PLANS } from './fixtures';
import { loadDb, newId, saveDb } from './mockServer';
import type { CancelReason, Plan, Receipt, Subscription } from './types';

export interface PurchaseInput {
  planId: Plan['id'];
  cardNumber: string;
  expiry: string;
  cvc: string;
  billingAddress: string;
}

async function accountForToken(token: string) {
  const db = await loadDb();
  const email = db.sessions[token];
  if (!email) throw new ApiError('unauthorized', 'Your session has expired. Please log in again.', 401);
  return db.accounts[email].user;
}

function periodEnd(plan: Plan): string {
  const end = new Date();
  if (plan.period === 'year') end.setFullYear(end.getFullYear() + 1);
  else end.setMonth(end.getMonth() + 1);
  return end.toISOString();
}

export const billingApi = {
  listPlans(): Promise<Plan[]> {
    return request(() => PLANS);
  },

  getSubscription(token: string): Promise<Subscription | null> {
    return request(async () => {
      const user = await accountForToken(token);
      const db = await loadDb();
      return db.subscriptions[user.id] ?? null;
    });
  },

  billingAddressFor(email: string): string {
    return DEMO_PROFILES[email]?.billingAddress ?? '';
  },

  purchase(token: string, input: PurchaseInput): Promise<Receipt> {
    return request(async () => {
      const user = await accountForToken(token);
      const plan = PLANS.find((p) => p.id === input.planId);
      if (!plan) throw new ApiError('not_found', 'That plan is no longer available.', 404);
      const card = input.cardNumber.replace(/\s+/g, '');
      if (!/^\d{16}$/.test(card) || !/^\d{2}\/\d{2}$/.test(input.expiry) || !/^\d{3,4}$/.test(input.cvc)) {
        throw new ApiError('validation_error', 'Check your card details and try again.', 422);
      }
      if (DECLINED_CARDS.includes(card)) {
        throw new ApiError('card_declined', 'Your card was declined. Try a different card.', 402);
      }
      const db = await loadDb();
      const subscription: Subscription = {
        id: newId('sub'),
        planId: plan.id,
        status: 'active',
        currentPeriodEnd: periodEnd(plan),
      };
      db.subscriptions[user.id] = subscription;
      await saveDb();
      return {
        subscription,
        amountCents: plan.priceCents,
        currency: plan.currency,
        cardLast4: card.slice(-4),
        billingAddress: input.billingAddress,
      };
    });
  },

  cancel(token: string, reason: CancelReason, feedback: string): Promise<Subscription> {
    return request(async () => {
      const user = await accountForToken(token);
      const db = await loadDb();
      const current = db.subscriptions[user.id];
      if (!current || current.status !== 'active') {
        throw new ApiError('not_found', 'There is no active subscription to cancel.', 404);
      }
      const subscription: Subscription = {
        ...current,
        status: 'canceled',
        canceledAt: new Date().toISOString(),
        cancelReason: reason,
      };
      db.subscriptions[user.id] = subscription;
      if (feedback.trim()) {
        db.feedback.push({ userId: user.id, text: feedback.trim(), at: subscription.canceledAt! });
      }
      await saveDb();
      return subscription;
    });
  },
};
