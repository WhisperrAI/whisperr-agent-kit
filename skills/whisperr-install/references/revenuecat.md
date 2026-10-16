# RevenueCat

Do this only when the app already uses RevenueCat. Do not add RevenueCat.

Whisperr receives subscription events from RevenueCat through a webhook that
a workspace owner or admin connects in the Whisperr dashboard. Call
`get_dashboard_link` with flow `setup_revenuecat` and give the user the
link. Without the MCP tools, the user opens Integrations → RevenueCat, or
`https://app.whisperr.net/integrations?source=revenuecat`.
You cannot connect RevenueCat yourself. Never ask for RevenueCat keys or
webhook secrets, and never put one in code, chat or a commit.

Tell the user how to connect:

1. In RevenueCat, open **API keys** → **+ New secret API key**, choose
   version **V2**, and grant only these permissions:
   - `customer_information:customers:read`
   - `customer_information:subscriptions:read`
   - `customer_information:purchases:read`
   - `project_configuration:integrations:read_write`
   (`project_configuration:projects:read` is optional: it lets Whisperr find
   the project, so the user need not paste the project ID.)
2. In the Whisperr dashboard RevenueCat setup, paste the key (and the
   **Project ID** from RevenueCat Project settings → General settings, if
   the dashboard asks for it) and click **Connect**. Whisperr creates its
   webhook in the project and imports the current state of each App Store
   and Google Play subscription. Importing does not message anyone about
   past changes.

Fallback, without an API key: in the same setup, **Set up the webhook by hand
instead**. The user creates the webhook values in Whisperr, adds a webhook in
RevenueCat (Integrations → Webhooks) with them, and sends a test event. This
path imports no history.

Whisperr uses one billing source per app: if the app already has Superwall or
Adapty connected, the user must disconnect it before connecting RevenueCat.

The webhook matches a RevenueCat customer to a Whisperr user by the
**RevenueCat app user id**. So the id must be the same id that you pass to
`whisperr.identify(userId)`.

RevenueCat is the source of membership facts (start, renewal, payment
failure, cancellation, expiry). Do not add client purchase events such as
`subscription_started` for these facts. They would count each fact twice
and miss renewals that happen outside the app.

## Apps with login

Call `logIn` with the same id, at the same places as `identify` (sign-up,
login, and app start with a signed-in user), and `logOut` at the same place
as `reset`:

| Platform | Login | Logout |
|---|---|---|
| Swift (`RevenueCat`) | `_ = try await Purchases.shared.logIn(user.id)` | `_ = try? await Purchases.shared.logOut()` |
| React Native (`react-native-purchases`) | `await Purchases.logIn(user.id)` | `await Purchases.logOut()` |
| Flutter (`purchases_flutter`) | `await Purchases.logIn(user.id)` | `await Purchases.logOut()` |
| Web (`@revenuecat/purchases-js`) | `await Purchases.getSharedInstance().changeUser(user.id)` | — |

`logOut` fails when the current RevenueCat user is anonymous; guard it with
the SDK's `isAnonymous` check or a `try`.

If the app already calls `Purchases.configure(…, appUserID: …)` with the
same id, keep it and add nothing.

## Apps without login

Set the RevenueCat subscriber attribute `whisperr_id` to the Whisperr
anonymous id, when the Whisperr SDK exposes it (Flutter:
`Whisperr.instance.anonymousId`):

```dart
final id = Whisperr.instance.anonymousId;
if (id != null) await Purchases.setAttributes({'whisperr_id': id});
```

Whisperr reads no other RevenueCat subscriber attribute. Do not send
`$email`, `$phoneNumber` or `$displayName` for Whisperr.

## Check

After a test purchase in the sandbox, the Whisperr tool
`get_revenuecat_status` shows the share of RevenueCat
customers matched to Whisperr users.
