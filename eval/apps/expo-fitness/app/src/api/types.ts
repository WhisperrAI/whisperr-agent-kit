export type Goal = 'build_strength' | 'lose_weight' | 'run_faster' | 'stay_active';
export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';
export type WorkoutType = 'strength' | 'run' | 'hiit' | 'yoga';
export type CancelReason = 'too_expensive' | 'not_using' | 'missing_features' | 'switching_app' | 'other';

export interface User {
  id: string;
  email: string;
  fullName: string;
  phone?: string;
  marketingOptIn: boolean;
  onboarded: boolean;
  goal?: Goal;
  experience?: ExperienceLevel;
  weeklyTarget?: number;
  createdAt: string;
}

export interface Session {
  token: string;
  user: User;
}

export interface Program {
  id: string;
  title: string;
  level: 'beginner' | 'intermediate' | 'all';
  weeks: number;
  sessionsPerWeek: number;
  summary: string;
  premium: boolean;
}

export interface Workout {
  id: string;
  type: WorkoutType;
  durationMinutes: number;
  notes?: string;
  loggedAt: string;
}

export interface Plan {
  id: 'pro_monthly' | 'pro_annual';
  name: string;
  period: 'month' | 'year';
  priceCents: number;
  currency: 'USD';
  badge?: string;
}

export interface Subscription {
  id: string;
  planId: Plan['id'];
  status: 'active' | 'canceled';
  currentPeriodEnd: string;
  canceledAt?: string;
  cancelReason?: CancelReason;
}

export interface Receipt {
  subscription: Subscription;
  amountCents: number;
  currency: 'USD';
  cardLast4: string;
  billingAddress: string;
}

export interface OnboardingAnswers {
  goal?: Goal;
  experience?: ExperienceLevel;
  weeklyTarget?: number;
}
