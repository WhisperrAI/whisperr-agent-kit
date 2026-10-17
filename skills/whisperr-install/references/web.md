# Web, React, Next.js

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
    app_language: user.appLanguage, // the in-app choice, not navigator.language
    subscription_price: 9.99,
    subscription_currency: "USD",
    plan_period: "month",
  },
  // only if the app has the user's email:
  email: user.email,
  // only when the app asks users for email permission: their answer
  emailOptedIn: user.emailPermission, // true or false; leave out when the app does not ask
});
```

Email permission: when the app asks users whether it may email them (a
checkbox at signup, an email setting), pass their answer as `emailOptedIn`:
`true` when they agreed, `false` when they declined or turned it off. When
the app does not ask, leave `emailOptedIn` out. Never pass `true` for a user
who did not agree. Pass the address as `email`, as above: the flag applies
to that address only.

The owner's answer to "Does your signup get permission to email users?" in
the Whisperr dashboard decides what the address gets. With **Yes**, it is
opted in unless `emailOptedIn` is `false`. With **Per user**, only
`emailOptedIn: true` opts it in. With **No**, with no answer yet, or when
the app requires the server key for email, client code
opts nothing in and your backend confirms consent with the server key
([server.md](server.md)). An earlier opt-out, including the unsubscribe
link, is kept.

`emailOptedIn` needs a recent `@whisperr/web` (and `@whisperr/react`, `@whisperr/next`): install the latest version
(https://docs.whisperr.net/sdk-versions.json lists it), and say so in your summary if the app pins an older one.
Never send `verified: true` or opt in a phone from client code, and never
use the `phone` shortcut.

On logout, in this order:

```ts
whisperr.track("user_logged_out"); // only when it is in the work order
whisperr.reset();
```

## Track

Use the event codes from the work order. For example, a project tool might
send `whisperr.track("project_created", { template: "kanban" });`. Call it in
handlers or after a successful request. Do not `await` it. Page views are captured
automatically; do not add them.

## Build

The repo's `typecheck`, `lint` and `build` scripts before and after. Run the
dev server and click through the flows to verify.
