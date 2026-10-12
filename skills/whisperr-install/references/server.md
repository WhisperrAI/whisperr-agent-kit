# Node and other servers

Source: https://docs.whisperr.net/sdks/node/

Server events carry the highest-value churn signals: payment failed,
subscription cancelled, subscription ended.

## Install

`<pm> add @whisperr/node@<version>` (Node 18+).

## Key

Server key (`wrk_…`) in `WHISPERR_API_KEY`, set in the server's secret store.
Add the name (empty) to `.env.example`. Never send it to a client.

## Use

```ts
import { createWhisperr } from "@whisperr/node";
export const whisperr = createWhisperr({ apiKey: process.env.WHISPERR_API_KEY! });

whisperr.track(userId, "subscription_cancelled", { reason: "too_expensive" });
```

The user id is always explicit and must be the same id that the client SDK
passes to `identify`. Same privacy rules: no email or phone as traits.

## Confirm consent

Consent must be confirmed from your backend with the server key. Client code
cannot do it. Where the backend stores the user's consent, send it with
`identify`:

```ts
whisperr.identify(userId, {
  channels: [
    { type: "email", address: user.email, optedIn: user.emailOptIn, verified: user.emailVerified },
  ],
});
```

Send the app's own flags, never a guess. This server-key `identify` is what
makes the contact sendable, also for an address the app sent first. Whisperr
never opts in SMS by default: send `optedIn: true` for SMS consent.

The Node, Python and PHP SDKs send `opted_in: true` when `optedIn` is
omitted, and their `phone` shortcut does the same. Wire a channel only when
the app holds consent for it, or pass `optedIn: false`.

`POST /v1/consent/assertions` (server key only) records consent proof or an
opt-out. It does not make a contact sendable by itself. Docs:
https://docs.whisperr.net/concepts/consent/

Serverless (Lambda, Vercel functions): `await whisperr.flush()` before the
handler returns. Long-running servers: `await whisperr.shutdown()` on exit.

Express helper: `app.use(whisperrExpress(whisperr))` from
`@whisperr/node/express`, after auth middleware.

## Billing events

Use this section when the app bills through Adapty, Superwall, Stripe (SDK
or webhooks), App Store Server Notifications, Google Play RTDN or its own
billing backend. Whisperr has no direct source for these yet. With
RevenueCat, use [revenuecat.md](revenuecat.md) instead.

Add the call to the server code that already handles the purchase or the
webhook, **after** the app updates its own state (for example, after the
database write succeeds). Send each event once per billing fact:

| Event | When |
|---|---|
| `subscription_started` | A paid subscription starts |
| `subscription_renewed` | A renewal payment succeeds |
| `subscription_payment_failed` | A renewal payment fails |
| `subscription_cancelled` | The user turns off renewal |
| `trial_started` | A trial starts (only when the app has trials) |
| `subscription_ended` | Access ends (only when the app records it) |

```ts
// In the Stripe webhook handler, after the app saved the new state:
whisperr.track(appUserId, "subscription_renewed", {
  price: invoice.amount_paid / 100, // major units; check zero-decimal currencies such as JPY
  currency: invoice.currency.toUpperCase(), // ISO 4217
  plan_period: "month", // week, month, year or lifetime
  product_id: priceId,
});
```

- `appUserId` is the app's own user id, the same id as `identify`. Map the
  provider's customer id to it with the app's own data. Never use an email.
- `price` is a number in major units (`9.99`), not cents.
- Webhooks can arrive twice. Send the event only when the app's own handler
  accepts the webhook as new.
- Register these events (install skill, step 9) when they are not
  registered.
- Never send these events from the client.

## Other languages

Python, PHP/Laravel and .NET have SDKs with the same calls. Follow the quick
start for the stack at https://docs.whisperr.net/ and the same rules.
