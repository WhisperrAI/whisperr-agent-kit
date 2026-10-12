# Node and other servers

Source: https://docs.whisperr.net/sdks/node/

Server events carry the highest-value churn signals: payment failed,
subscription cancelled, trial expired.

## Install

`<pm> add @whisperr/node@<version>` (Node 18+).

## Key

Server key (`wrk_…`) in `WHISPERR_API_KEY`, set in the server's secret store.
Add the name (empty) to `.env.example`. Never send it to a client.

## Use

```ts
import { createWhisperr } from "@whisperr/node";
export const whisperr = createWhisperr({ apiKey: process.env.WHISPERR_API_KEY! });

whisperr.track(userId, "payment_failed", { amount_cents: 4900, reason: "card_declined" });
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

Send the app's own flags, never a guess. An `sms` channel without `optedIn`
is not opted in. A consent change outside identify can use
`POST /v1/consent/assertions` (server key only). Docs:
https://docs.whisperr.net/concepts/consent/

Serverless (Lambda, Vercel functions): `await whisperr.flush()` before the
handler returns. Long-running servers: `await whisperr.shutdown()` on exit.

Express helper: `app.use(whisperrExpress(whisperr))` from
`@whisperr/node/express`, after auth middleware.

## Other languages

Python, PHP/Laravel and .NET have SDKs with the same calls. Follow the quick
start for the stack at https://docs.whisperr.net/ and the same rules.
