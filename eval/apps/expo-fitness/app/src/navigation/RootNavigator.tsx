import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ActivityIndicator, View } from 'react-native';

import { colors } from '../components/ui';
import { CancelSubscriptionScreen } from '../screens/billing/CancelSubscriptionScreen';
import { CheckoutScreen } from '../screens/billing/CheckoutScreen';
import { ManageSubscriptionScreen } from '../screens/billing/ManageSubscriptionScreen';
import { PaywallScreen } from '../screens/billing/PaywallScreen';
import { PurchaseSuccessScreen } from '../screens/billing/PurchaseSuccessScreen';
import { LoginScreen } from '../screens/auth/LoginScreen';
import { SignupScreen } from '../screens/auth/SignupScreen';
import { WelcomeScreen } from '../screens/auth/WelcomeScreen';
import { HistoryScreen } from '../screens/main/HistoryScreen';
import { HomeScreen } from '../screens/main/HomeScreen';
import { LogWorkoutScreen } from '../screens/main/LogWorkoutScreen';
import { ProfileScreen } from '../screens/main/ProfileScreen';
import { ProgramDetailScreen } from '../screens/main/ProgramDetailScreen';
import { OnboardingScreen } from '../screens/onboarding/OnboardingScreen';
import { useAuth } from '../state/AuthContext';
import type { MainTabParamList, RootStackParamList } from './types';

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tabs = createBottomTabNavigator<MainTabParamList>();

const headerOptions = {
  headerStyle: { backgroundColor: colors.background },
  headerTintColor: colors.text,
  contentStyle: { backgroundColor: colors.background },
};

function MainTabs() {
  return (
    <Tabs.Navigator
      screenOptions={{
        ...headerOptions,
        tabBarStyle: { backgroundColor: colors.surface, borderTopColor: colors.border },
        tabBarActiveTintColor: colors.accent,
      }}
    >
      <Tabs.Screen name="Home" component={HomeScreen} options={{ title: 'Today', tabBarButtonTestID: 'tab-home' }} />
      <Tabs.Screen name="History" component={HistoryScreen} options={{ tabBarButtonTestID: 'tab-history' }} />
      <Tabs.Screen name="Profile" component={ProfileScreen} options={{ tabBarButtonTestID: 'tab-profile' }} />
    </Tabs.Navigator>
  );
}

export function RootNavigator() {
  const { status, user } = useAuth();

  if (status === 'restoring') {
    return (
      <View testID="splash" style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.background }}>
        <ActivityIndicator color={colors.accent} />
      </View>
    );
  }

  return (
    <Stack.Navigator screenOptions={headerOptions}>
      {status === 'signedOut' ? (
        <Stack.Group navigationKey="guest">
          <Stack.Screen name="Welcome" component={WelcomeScreen} options={{ headerShown: false }} />
          <Stack.Screen name="ProgramDetail" component={ProgramDetailScreen} options={{ title: 'Program' }} />
          <Stack.Screen name="Signup" component={SignupScreen} options={{ title: 'Create account' }} />
          <Stack.Screen name="Login" component={LoginScreen} options={{ title: 'Log in' }} />
        </Stack.Group>
      ) : !user?.onboarded ? (
        <Stack.Screen name="Onboarding" component={OnboardingScreen} options={{ headerShown: false }} />
      ) : (
        <Stack.Group navigationKey="member">
          <Stack.Screen name="Main" component={MainTabs} options={{ headerShown: false }} />
          <Stack.Screen name="ProgramDetail" component={ProgramDetailScreen} options={{ title: 'Program' }} />
          <Stack.Screen name="LogWorkout" component={LogWorkoutScreen} options={{ title: 'Log workout', presentation: 'modal' }} />
          <Stack.Screen name="Paywall" component={PaywallScreen} options={{ title: 'Repwise Pro', presentation: 'modal' }} />
          <Stack.Screen name="Checkout" component={CheckoutScreen} options={{ title: 'Checkout' }} />
          <Stack.Screen name="PurchaseSuccess" component={PurchaseSuccessScreen} options={{ headerShown: false, gestureEnabled: false }} />
          <Stack.Screen name="ManageSubscription" component={ManageSubscriptionScreen} options={{ title: 'Subscription' }} />
          <Stack.Screen name="CancelSubscription" component={CancelSubscriptionScreen} options={{ title: 'Cancel subscription' }} />
        </Stack.Group>
      )}
    </Stack.Navigator>
  );
}
