import type { NavigatorScreenParams } from '@react-navigation/native';

import type { Plan } from '../api/types';

export type PaywallSource = 'home_banner' | 'history_insights' | 'premium_program' | 'profile';

export type MainTabParamList = {
  Home: undefined;
  History: undefined;
  Profile: undefined;
};

export type RootStackParamList = {
  Welcome: undefined;
  ProgramDetail: { programId: string };
  Signup: undefined;
  Login: undefined;
  Onboarding: undefined;
  Main: NavigatorScreenParams<MainTabParamList> | undefined;
  LogWorkout: undefined;
  Paywall: { source: PaywallSource };
  Checkout: { planId: Plan['id']; source: PaywallSource };
  PurchaseSuccess: { planId: Plan['id'] };
  ManageSubscription: undefined;
  CancelSubscription: undefined;
};

declare global {
  namespace ReactNavigation {
    // eslint-disable-next-line @typescript-eslint/no-empty-object-type
    interface RootParamList extends RootStackParamList {}
  }
}
