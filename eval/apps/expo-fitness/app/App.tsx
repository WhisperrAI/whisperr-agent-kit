import { DarkTheme, NavigationContainer } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { colors } from './src/components/ui';
import { RootNavigator } from './src/navigation/RootNavigator';
import { AuthProvider } from './src/state/AuthContext';
import { SubscriptionProvider } from './src/state/SubscriptionContext';
import { WorkoutsProvider } from './src/state/WorkoutsContext';

const theme = {
  ...DarkTheme,
  colors: { ...DarkTheme.colors, primary: colors.accent, background: colors.background, card: colors.surface },
};

export default function App() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <SubscriptionProvider>
          <WorkoutsProvider>
            <NavigationContainer theme={theme}>
              <RootNavigator />
            </NavigationContainer>
          </WorkoutsProvider>
        </SubscriptionProvider>
      </AuthProvider>
      <StatusBar style="light" />
    </SafeAreaProvider>
  );
}
