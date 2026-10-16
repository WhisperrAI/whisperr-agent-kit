# Superwall

Do this only when the app already uses Superwall to make purchases. Do not
add Superwall. If the app makes purchases through RevenueCat (even with
Superwall paywalls), follow [revenuecat.md](revenuecat.md) instead: an app
has one billing source.

Whisperr receives subscription events from Superwall through a webhook that
a workspace owner or admin connects in the Whisperr dashboard. Call
`get_dashboard_link` with flow `setup_superwall` and give the user the link.
Without the MCP tools, the user opens Integrations → Billing → Superwall, or
`https://app.whisperr.net/integrations?source=superwall`. You cannot connect
Superwall yourself. Never ask for the Superwall signing secret.

The webhook matches a Superwall customer to a Whisperr user by Superwall's
`originalAppUserId`: the user id the app passed to Superwall `identify`
before the purchase. So the id must be the same id that you pass to
`whisperr.identify(userId)`.

Superwall is the source of membership facts (start, renewal, payment
failure, cancellation, expiry). Do not add client purchase events such as
`subscription_started` for these facts.

## Apps with login

Call Superwall `identify` with the same id, at the same places as
`identify`, before any purchase, and Superwall `reset` at the same place as
`reset`:

| Platform | Login | Logout |
|---|---|---|
| Swift (`SuperwallKit`) | `Superwall.shared.identify(userId: user.id)` | `Superwall.shared.reset()` |
| Android | `Superwall.instance.identify(user.id)` | `Superwall.instance.reset()` |
| Flutter | `Superwall.shared.identify(user.id);` | `Superwall.shared.reset();` |
| Expo (`expo-superwall`) | `await identify(user.id)` from `useUser()` | `signOut()` from `useUser()` |

On Android, set `passIdentifiersToPlayStore` to `true` in the Superwall
options; otherwise Google Play gets a hashed id. On iOS, App Store events
carry the id only when it is a UUID; otherwise use the attribute below.

## Apps without login, or ids Superwall cannot pass

Set the Superwall user attribute `whisperr_id` to the Whisperr anonymous id,
when the Whisperr SDK exposes it:

```swift
Superwall.shared.setUserAttributes(["whisperr_id": anonymousId])
```

Whisperr reads no other Superwall user attribute. Do not send emails or
names in Superwall attributes for Whisperr.

## Check

After a sandbox purchase, the Whisperr tool `get_superwall_status` shows
the first event and the share of Superwall customers matched to Whisperr
users.
