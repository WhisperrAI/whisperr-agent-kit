# Web, React, Next.js (@whisperr/web 0.2+)

Sources: https://docs.whisperr.net/sdks/web/,
https://docs.whisperr.net/sdks/react/, https://docs.whisperr.net/sdks/next/

## Install

- Any JS app: `<pm> add @whisperr/web@<version>`
- React (not Next.js): `<pm> add @whisperr/react@<version> @whisperr/web@<version>`
- Next.js App Router: `<pm> add @whisperr/next@<version> @whisperr/web@<version>`

## Key

Use the framework's public variable with the publishable `wpk_…` key:
`VITE_WHISPERR_KEY`, `NEXT_PUBLIC_WHISPERR_KEY`, `REACT_APP_WHISPERR_KEY`.
Add the name (empty value) to `.env.example`. Do not write a real key into a
tracked file. Next.js embeds `NEXT_PUBLIC_` values at build time: tell the
user to set the variable in the hosting provider and rebuild.

Server code in the same repo (API routes, server actions, webhooks) uses
`@whisperr/node` with the server key in `WHISPERR_API_KEY` (see
[server.md](server.md)). Never expose that key to the browser.

## Init

Any JS app, one module:

```ts
import { Whisperr } from "@whisperr/web";
export const whisperr = Whisperr.init({ apiKey: import.meta.env.VITE_WHISPERR_KEY });
```

React: wrap the root with
`<WhisperrProvider apiKey={import.meta.env.VITE_WHISPERR_KEY}>` and use
`useWhisperr()` in components.

Next.js: in `app/layout.tsx` (server component; the provider is already a
client boundary):

```tsx
import { WhisperrProvider } from "@whisperr/next";
<WhisperrProvider apiKey={process.env.NEXT_PUBLIC_WHISPERR_KEY!}>{children}</WhisperrProvider>
```

Client components: `"use client"` + `const whisperr = useWhisperr();`.

## Identify and reset

Call identify after sign-up, after login, and on **every page load** when
the auth state already has a user (the auth listener or the effect that
reads the session):

```ts
whisperr.identify(user.id, {
  traits: {
    first_name: user.firstName,
    is_subscriber: user.isSubscriber,
    // only when the app knows them:
    app_language: user.contentLanguage, // the in-app choice, not navigator.language
    subscription_price: 9.99,
    subscription_currency: "USD",
    plan_period: "month",
  },
  channels: [{ type: "email", address: user.email }], // only if the app has email
});
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

`whisperr.track("checkout_started", { cart_value: 49 });` in handlers or
after a successful request. Do not `await` it. Page views are captured
automatically; do not add them.

## Build

The repo's `typecheck`, `lint` and `build` scripts before and after. Run the
dev server and click through the flows to verify.
