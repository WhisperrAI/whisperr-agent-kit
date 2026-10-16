# React Native / Expo (@whisperr/react-native 0.4+)

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

Import it from the entry: Expo Router `app/_layout.tsx` (or
`src/app/_layout.tsx` when the app lives in `src/`), otherwise `App.tsx`.
Do not create a second client. Use the singleton everywhere. If the app
wants `useWhisperr()`, wrap the root in `<WhisperrProvider client={whisperr}>`;
`useWhisperr()` throws outside the provider.

## Identify and reset

One helper in the singleton module. Call it after sign-up, after login, and
at every app start when the app's auth state already has a user (session
restore: the auth listener or the root layout effect that reads the session):

```ts
type PushToken = Parameters<typeof whisperr.setPushToken>[0];
let lastPushToken: PushToken | null = null;

// The push code calls this. It sends the token only while a user is signed in.
export function rememberPushToken(token: PushToken, signedIn: boolean) {
  lastPushToken = token;
  if (signedIn) whisperr.setPushToken(token);
}

export function identifyWhisperrUser(user: AppUser) {
  whisperr.identify(user.id, {
    traits: {
      first_name: user.firstName,
      is_subscriber: user.isSubscriber,
      // only when the app knows them:
      app_language: user.learningLanguage, // the in-app choice, not the device locale
      subscription_price: 9.99,
      subscription_currency: "USD",
      plan_period: "month",
    },
    channels: [
      { type: "email", address: user.email }, // only if the app has email
    ],
  });
  if (lastPushToken) whisperr.setPushToken(lastPushToken);
}
```

Client code sends email and phone without `optedIn` by default. Whisperr
then stores them unverified and not opted in, and your backend confirms
consent with the server key ([server.md](server.md)). Pass `optedIn: true`
on the email channel only when the app itself records that this user agreed
to email (a checked box at signup, an email setting). It counts only when the
owner answered "Does your signup get permission to email users?" in the
Whisperr dashboard with Yes or Per user (with Yes, an email the app sends
counts even without it); otherwise Whisperr ignores it. An earlier opt-out,
including the unsubscribe link, is kept. Pass `optedIn: false` when the user
opted out in the app. Never send `optedIn: true` for a phone or `verified:
true` from client code, and never use the `phone` shortcut.

On logout, in this order:

```ts
whisperr.track("user_logged_out"); // only when it is in the work order
whisperr.reset();
```

## Track

`whisperr.track("subscription_cancelled", { reason: "too_expensive" });`
in handlers or after a successful mutation, never in render. It returns
`void`; do not `await` it.

Screens (only if the event plan has a screen event):
`whisperr.screen(routeName)` from the navigation state-change callback.

## Push (only if the app already uses push notifications)

Never add push to an app without it, and never add a permission prompt.
Whisperr code reads the permission that the app already asks for.

### Expo with expo-notifications: use @whisperr/expo

`@whisperr/expo` is Whisperr's helper on top of the app's own
`expo-notifications`. It is not a new push library. Read its version with
`npm view @whisperr/expo version`, then:

`npx expo install @whisperr/expo@<version> expo-constants expo-application`

It needs `@whisperr/react-native` 0.5 or later.

```tsx
import { registerForPushNotifications } from "@whisperr/expo";

// After identifyWhisperrUser(user), and again right after the app's own
// permission request:
void registerForPushNotifications({ requestPermission: false });
```

- With `requestPermission: false` it never shows a prompt. It reports the
  permission, sends the token when push is allowed, and keeps both current
  when the user changes the permission in Settings or the token rotates.
- It sends the Expo push token. When the app sends through its own APNs key
  or Firebase project (it calls `getDevicePushTokenAsync()`), pass
  `tokenType: "device"`, and on Android `providerProject` with the Firebase
  project id.
- Its config plugin changes native code and needs a new build. The app
  already configures `expo-notifications`, so add the plugin only when the
  user agrees.

Push opens: call `useWhisperrNotificationResponse()` once in the root
layout (Expo Router `app/_layout.tsx`). It records `push_opened`, including
the tap that launched the app, and returns the deep link. Route that link
only if the app already routes from notifications.

### Bare React Native, or Firebase messaging

Send the token only after `identify`. Pass every token to
`rememberPushToken`. The helper above then sends it on every launch and
login, and a refresh sends it only while a user is signed in:

```tsx
// expo-notifications without @whisperr/expo: pass the token object; the SDK reads its type.
useEffect(() => {
  const signedIn = session != null; // the app's own signed-in check
  Notifications.getDevicePushTokenAsync().then((t) => rememberPushToken(t, signedIn));
  const sub = Notifications.addPushTokenListener((t) => rememberPushToken(t, signedIn));
  return () => sub.remove();
}, [session]);
```

Firebase: `messaging().getToken()` and `messaging().onTokenRefresh()` →
`rememberPushToken({ token, kind: "fcm" }, signedIn)`.

Firebase opens: `messaging().getInitialNotification()` and
`messaging().onNotificationOpenedApp()` → `whisperr.trackPushOpened(m)`.

### Expo app without push

Add no push code. In your summary, tell the user that `@whisperr/expo` adds
push (config plugin, EAS push credentials, a new build), and that they choose
where the OS prompt appears.

## Build

`npx tsc --noEmit` and the repo's lint script before and after. Run with
`npx expo start` (or the repo's `ios` / `android` script).
