# React Native / Expo (@whisperr/react-native 0.3+)

Source: https://docs.whisperr.net/sdks/react-native/

Pure TypeScript, no native code. Works in Expo Go, dev clients and bare
React Native. Never suggest `expo prebuild` for this SDK.

## Install

- Expo: `npx expo install @whisperr/react-native@<version> @react-native-async-storage/async-storage`
- Bare React Native: `<pm> add @whisperr/react-native@<version> @react-native-async-storage/async-storage`,
  then tell the user to run `npx pod-install` before the next iOS build.

If the app already uses `react-native-mmkv`, reuse it with a small adapter
(`getItem`/`setItem`/`removeItem`) instead of adding AsyncStorage.

## Key

- Expo: `EXPO_PUBLIC_WHISPERR_KEY` in `.env` (and the name, empty, in
  `.env.example`). Read `process.env.EXPO_PUBLIC_WHISPERR_KEY`.
- Bare with `react-native-config`: `WHISPERR_KEY`, read `Config.WHISPERR_KEY`.
- The value is the publishable `wpk_…` key. Never `wrk_`.

For EAS builds, tell the user to add the variable to the EAS environment.

## Init

One module singleton, for example `src/lib/whisperr.ts` (match the repo
layout):

```ts
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Whisperr } from "@whisperr/react-native";

export const whisperr = Whisperr.init({
  apiKey: process.env.EXPO_PUBLIC_WHISPERR_KEY!,
  storage: AsyncStorage,
});
```

Import it from the entry: Expo Router `app/_layout.tsx`, otherwise `App.tsx`.
Do not create a second client. `<WhisperrProvider>` / `useWhisperr()` are
optional.

## Identify and reset

After login or sign-up, and on session restore:

```ts
whisperr.identify(user.id, {
  traits: { first_name: user.firstName, plan: user.plan },
  channels: [
    { type: "email", address: user.email, optedIn: user.emailConsent }, // only if the app has these
  ],
});
```

On logout: `whisperr.reset();`

## Track

`whisperr.track("subscription_cancelled", { reason: "too_expensive" });`
in handlers or after a successful mutation, never in render. It returns
`void`; do not `await` it.

Screens (only if the event plan has a screen event):
`whisperr.screen(routeName)` from the navigation state-change callback.

## Push (only if the app already uses expo-notifications or Firebase messaging)

```tsx
import { useWhisperrPushToken } from "@whisperr/react-native";
// expo-notifications:
const [token, setToken] = useState<string | null>(null);
useEffect(() => {
  Notifications.getDevicePushTokenAsync().then((t) => setToken(t.data));
  const sub = Notifications.addPushTokenListener((t) => setToken(t.data));
  return () => sub.remove();
}, []);
useWhisperrPushToken(token);
```

Push opens (expo-notifications):

```tsx
useEffect(() => {
  Notifications.getLastNotificationResponseAsync().then((r) => { if (r) whisperr.trackPushOpened(r); });
  const sub = Notifications.addNotificationResponseReceivedListener((r) => whisperr.trackPushOpened(r));
  return () => sub.remove();
}, []);
```

Firebase: `messaging().getInitialNotification()` and
`messaging().onNotificationOpenedApp()` → `whisperr.trackPushOpened(m)`.

## Build

`npx tsc --noEmit` and the repo's lint script before and after. Run with
`npx expo start` (or the repo's `ios` / `android` script).
