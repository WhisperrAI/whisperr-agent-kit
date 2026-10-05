# RevenueCat

Do this only when the app already uses RevenueCat. Do not add RevenueCat.

Whisperr receives subscription events from RevenueCat through a webhook that
the user connects in the Whisperr dashboard (Integrations → RevenueCat). The
webhook matches a RevenueCat customer to a Whisperr user by the **RevenueCat
app user id**. So the id must be the same id that you pass to
`whisperr.identify(userId)`.

## Apps with login

Call `logIn` with the same id, at the same place as `identify`, and `logOut`
at the same place as `reset`:

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
`get_revenuecat_status` (when available) shows the share of RevenueCat
customers matched to Whisperr users.
