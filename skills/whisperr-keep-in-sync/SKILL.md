---
name: whisperr-keep-in-sync
description: Keep Whisperr tracking correct when code changes. Use when a change renames, moves, deletes or rewrites code that calls Whisperr identify, track, screen, reset, setPushToken or trackPushOpened, changes login, logout, checkout, billing, subscription or onboarding flows, upgrades a Whisperr SDK, or adds a feature that should be tracked. Also use before committing a diff that touches files with Whisperr calls.
---

# Keep Whisperr in sync

Tracked events are a contract with Whisperr. A refactor that drops or moves
a `track` call silently breaks churn prediction. Check every change that
touches tracked code.

## When the diff touches Whisperr code

1. Find the Whisperr calls in the changed files and in the code they call:
   search for `identify(`, `track(`, `screen(`, `reset(`, `setPushToken`,
   `trackPushOpened`, `WhisperrEvents`, `whisperr.` and `Whisperr.`.
2. For each call, check after the change:
   - It still runs on the **success** path of the same user action.
   - The event code is unchanged (codes are `snake_case` and registered in
     Whisperr). A renamed code is a new event; Whisperr loses history.
   - Properties are the same names and types. No new PII: no email, phone,
     full or last name, address, free text from users.
   - `identify` still runs after sign-up, after login, and on every app
     start when a user is signed in, with the same stable user id. Traits
     stay within `first_name`, `app_language`, `is_subscriber`,
     `subscription_price`, `subscription_currency` and `plan_period`.
   - `setPushToken` still runs only after `identify` (on launch and token
     refresh), and not between `reset()` and the next login.
   - Logout still sends `user_logged_out` (when registered) before
     `reset()`. If the app uses RevenueCat, `Purchases.logIn` still gets
     the same user id.
   - Billing events (`subscription_*`, `trial_started`) still come from the
     server, after the app updates its own state, with the same user id.
     With RevenueCat, no client membership events exist.
3. If a call was deleted with its feature, ask the user whether the event
   should stop. Do not delete a registered event without asking.

## When a new feature should be tracked

Whisperr works better with many tailored events. Each one is one real user
action at its success path, with typed properties. A new feature usually
deserves its own event.

1. Check the registered events first: `get_required_events` or
   `get_event_catalog`. Reuse an existing code when the meaning is the same.
2. If new codes are needed, propose them to the user as one list: code,
   trigger location, properties. Wait for the user to agree. Never track in
   render or on a button tap, never add heartbeats.
3. Wire them as the `whisperr-install` skill describes, then build.
4. Register them in one draft with step 9 of the `whisperr-install` skill
   (`prepare_code_source` … `commit_registration`). This needs
   `install:write`. Without it, the user registers the events in the
   Whisperr dashboard.

## When upgrading a Whisperr SDK

Read the SDK changelog for breaking changes (for example: React Native 0.3.0
renamed the `screen()` property to `screen_name`; Swift 0.3.0 added the
`.retryAfter` transport result). Remove manual calls for events that the SDK
now sends by itself (`app_opened`, `app_installed`, `app_updated`,
`app_backgrounded`). Build and analyze before and after.

## Verify

After the change runs (dev build or after release), check
`get_received_events`: each affected event arrives, and no new ingest error
appears. Report: event · change · verified.
