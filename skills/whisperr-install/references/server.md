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
passes to `identify`. Identify from the server only if the client cannot:
`whisperr.identify(userId, { traits: { first_name: user.firstName } })`.
Same privacy rules: no email or phone as traits.

Serverless (Lambda, Vercel functions): `await whisperr.flush()` before the
handler returns. Long-running servers: `await whisperr.shutdown()` on exit.

Express helper: `app.use(whisperrExpress(whisperr))` from
`@whisperr/node/express`, after auth middleware.

## Other languages

Python, PHP/Laravel and .NET have SDKs with the same calls. Follow the quick
start for the stack at https://docs.whisperr.net/ and the same rules.
