# Copy-prompt fallback

Use this prompt in AI app builders that cannot add a custom MCP server, or
when you do not want to connect one: Lovable, Bolt, Replit, Rork, v0 and
similar tools.

1. In the Whisperr dashboard, open **Developer → API Keys** and create a
   **publishable** key (`wpk_…`). Publishable keys are safe in app code.
2. Copy your event list from **Events** in the dashboard (event code and one
   line on when it happens).
3. Replace the three `<…>` values below and paste the whole prompt into the
   tool.

Which SDK the tool should use:

| Tool | App type | SDK |
|---|---|---|
| Lovable, Bolt, v0 | React + Vite web app | `@whisperr/react` + `@whisperr/web` |
| Rork | Expo (React Native) app | `@whisperr/react-native` |
| Replit | Any | The SDK for the app's stack (see https://docs.whisperr.net/) |

---

```text
Add Whisperr (churn-signal tracking) to this app. Follow every rule.

Whisperr publishable key: <WPK_KEY>
Platform: <web (React/Vite) | Expo React Native | other: name it>
Events to track (code: when it happens):
<EVENT_LIST>

Steps:
1. Install the latest Whisperr SDK for this platform:
   - React web: @whisperr/react and @whisperr/web. Wrap the app root in
     <WhisperrProvider apiKey={...}> and use useWhisperr() in components.
   - Any other web app: @whisperr/web. const whisperr = Whisperr.init({ apiKey }).
   - Expo / React Native: @whisperr/react-native and
     @react-native-async-storage/async-storage. In one module:
     export const whisperr = Whisperr.init({ apiKey, storage: AsyncStorage })
     and import it from the app entry (app/_layout.tsx with Expo Router).
   Docs: https://docs.whisperr.net/
2. Put the key in a public environment variable (VITE_WHISPERR_KEY,
   EXPO_PUBLIC_WHISPERR_KEY or the platform's equivalent). It is a
   publishable key and is safe in client code.
3. Initialize the SDK once at app start.
4. Right after login or sign-up succeeds, and when a saved session is
   restored at start, call:
   whisperr.identify(user.id, {
     traits: { first_name: <the user's first name, if the app has it> },
     channels: [ { type: "email", address: user.email, optedIn: <the app's own email-consent flag> } ]
   })
   Use the app's stable user id, never the email. Leave out channels the app
   does not have. Never invent consent.
5. On logout call whisperr.reset().
6. For each event in the list, call whisperr.track("<code>", { ...plain
   properties }) where the action SUCCEEDS (after the save, payment or API
   call succeeds), not on button tap and not during render. Use the codes
   exactly as listed. Do not add other events.
7. Privacy: send first_name as the only name. Never send last name, full
   name, email, phone, address or birth date as traits or event properties.
8. If the app uses RevenueCat, call Purchases.logIn(user.id) with the same
   id as identify, and Purchases.logOut() on logout.
9. If the app already has push notifications, pass the device token to
   whisperr.setPushToken(token) and call whisperr.trackPushOpened(response)
   when the user taps a notification. Do not add push notifications if the
   app has none.
10. Make sure the app still builds with no new errors.
11. Tell me which flows to click so each event fires once. I will check the
    Whisperr dashboard to see the events arrive.
```

---

When the app runs, open the app, sign in and do the listed flows. The
events show in the Whisperr dashboard within about 15 seconds.
