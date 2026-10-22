import type { Plan, Program } from './types';

export const PROGRAMS: Program[] = [
  {
    id: 'prg_strength_foundations',
    title: 'Strength Foundations',
    level: 'beginner',
    weeks: 6,
    sessionsPerWeek: 3,
    summary: 'Learn the big lifts with a simple linear progression.',
    premium: false,
  },
  {
    id: 'prg_5k_ready',
    title: '5K Ready',
    level: 'beginner',
    weeks: 8,
    sessionsPerWeek: 3,
    summary: 'Walk-run intervals that get you to a continuous 5K.',
    premium: false,
  },
  {
    id: 'prg_hiit_express',
    title: 'HIIT Express',
    level: 'intermediate',
    weeks: 4,
    sessionsPerWeek: 4,
    summary: 'Twenty-minute interval sessions for busy weeks.',
    premium: true,
  },
  {
    id: 'prg_mobility_reset',
    title: 'Mobility Reset',
    level: 'all',
    weeks: 3,
    sessionsPerWeek: 5,
    summary: 'Daily flows for hips, shoulders and spine.',
    premium: true,
  },
];

export const PLANS: Plan[] = [
  { id: 'pro_monthly', name: 'Pro Monthly', period: 'month', priceCents: 999, currency: 'USD' },
  { id: 'pro_annual', name: 'Pro Annual', period: 'year', priceCents: 5999, currency: 'USD', badge: 'Save 50%' },
];

/** Profile details the mock backend attaches to known demo accounts. */
export const DEMO_PROFILES: Record<string, { phone: string; billingAddress: string }> = {
  'jane.eval@example.com': { phone: '+15555550123', billingAddress: '221B Eval Street, London NW1 6XE' },
};

/** Emails the mock backend treats as already registered. */
export const TAKEN_EMAILS = ['taken@example.com'];

/** Card numbers with scripted outcomes (same as Stripe's test cards). */
export const DECLINED_CARDS = ['4000000000000002'];
