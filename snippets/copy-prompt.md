# Copy-prompt fallback

Use this prompt in AI app builders that cannot add a custom MCP server, or
when you do not want to connect one: Lovable, Bolt, Replit, Rork, v0 and
similar tools.

The Whisperr dashboard fills the prompt for you: on **Home**, open
**Connect your code → Copy prompt**, pick the platform and click **Add a
browser key**. The prompt then has your publishable key and the events from
your plan. Copy it and paste it into the tool.

To fill it by hand:

1. In the Whisperr dashboard, open **Settings → API keys → Create key**
   and choose **App**. This is a publishable key (`wpk_…`). Publishable keys
   are safe in app code. The secret shows only once.
2. Copy your event list from **Data → Events** (event code and one line on
   when it happens).
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
4. Call identify right after sign-up succeeds, right after login succeeds,
   AND on every app start when the app already has a signed-in user (the
   SDK does not send identify again by itself; this covers users who
   signed in before the install):
   whisperr.identify(user.id, {
     traits: {
       first_name: <the user's first name, if the app has it>,
       is_subscriber: <true or false>,
       // only when the app knows them:
       app_language: <the language the user picked in the app, not the device language>,
       subscription_price: <number, e.g. 9.99>,
       subscription_currency: <ISO code, e.g. "USD">,
       plan_period: <"week" | "month" | "year" | "lifetime">
     },
     channels: [ { type: "email", address: user.email } ]
   })
   Use the app's stable user id, never the email. Leave out traits and
   channels the app does not have. The app sends contacts without consent:
   pass optedIn: false only when the user opted out, never optedIn: true,
   and never the phone shortcut. Consent must be confirmed from your
   backend with the server key. Tell me if the backend needs that change.
5. On logout: if user_logged_out is in the list, call
   whisperr.track("user_logged_out") first. Then call whisperr.reset().
6. For each event in the list, call whisperr.track("<code>", { ...plain
   properties }) where the action SUCCEEDS (after the save, payment or API
   call succeeds), not on button tap and not during render. Use the codes
   exactly as listed. No heartbeats or timers. Do not add other events.
   Instead, list other real user actions in this app that would make good
   events (code, when it happens, properties). I will add them in the
   Whisperr dashboard.
7. Privacy: send first_name as the only name. Never send last name, full
   name, email, phone, address or birth date as traits or event properties.
   No free text from users in properties.
8. Billing: if the app uses RevenueCat, call Purchases.logIn(user.id) with
   the same id as identify, and Purchases.logOut() on logout. Do not send
   subscription events from the app. If the app takes payments another way
   (Stripe, Adapty, Superwall, app store notifications), do not send
   subscription events from the app either. Tell me which billing system the
   app uses.
9. Expo / React Native only: if the app already has push notifications,
   pass the device token to whisperr.setPushToken(token) only after
   identify, on every app start and on token refresh while a user is signed
   in. Call whisperr.trackPushOpened(response) when the user taps a
   notification. Do not add push notifications if the app has none.
10. Make sure the app still builds with no new errors.
11. Tell me which flows to click so each event fires once. I will check the
    Whisperr dashboard to see the events arrive.
```

---

When the app runs, open the app, sign in and do the listed flows. The
events show in the Whisperr dashboard under **Data → Live** within about 15
seconds.
