# Adapty

Do this only when the app already uses Adapty. Do not add Adapty.

Whisperr receives subscription events from Adapty's webhook integration,
which a workspace owner or admin connects in the Whisperr dashboard. Call
`get_dashboard_link` with flow `setup_adapty` and give the user the link.
Without the MCP tools, the user opens Integrations → Billing → Adapty, or
`https://app.whisperr.net/integrations?source=adapty`. You cannot connect
Adapty yourself. Never ask for the webhook authorization value.

The webhook matches an Adapty customer to a Whisperr user by the Adapty
customer user id. So the id must be the same id that you pass to
`whisperr.identify(userId)`.

Adapty is the source of membership facts (start, renewal, payment failure,
cancellation, expiry). Do not add client purchase events such as
`subscription_started` for these facts.

## Apps with login

Call Adapty `identify` with the same id, at the same places as `identify`,
and Adapty `logout` at the same place as `reset`:

| Platform | Login | Logout |
|---|---|---|
| Swift | `try await Adapty.identify(user.id)` | `try await Adapty.logout()` |
| Android | `Adapty.identify(user.id) { error -> }` | `Adapty.logout { error -> }` |
| Flutter (`adapty_flutter`) | `await Adapty().identify(user.id);` | `await Adapty().logout();` |
| React Native (`react-native-adapty`) | `await adapty.identify(user.id);` | `await adapty.logout();` |

Adapty asks to await `identify` before other Adapty calls.

## Apps without login

Set the Adapty custom attribute `whisperr_id` to the Whisperr anonymous id,
when the Whisperr SDK exposes it, and tell the user to turn on **Send user
attributes** in the Adapty webhook settings. Whisperr reads no other Adapty
attribute.

## Check

After the user saves the webhook in Adapty, the Whisperr tool
`get_adapty_status` shows Adapty's URL check, the last events and the share
of Adapty customers matched to Whisperr users.
