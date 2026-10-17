# Flutter (Flutter 3.19+)

Source: https://docs.whisperr.net/sdks/flutter/

## Install

`flutter pub add whisperr` (or add `whisperr: ^<version>` to `pubspec.yaml`
and run `flutter pub get`).

## Key

Pass the publishable key at build time:
`--dart-define=WHISPERR_KEY=wpk_…`, read with
`const String.fromEnvironment('WHISPERR_KEY')`. If the app already uses a
config package (`flutter_dotenv`, `envied`, flavors), use that instead. Tell
the user to add the define to their run configuration and CI.

When the user gives an API base URL (local, dev, or a proxy), pass it too:
`--dart-define=WHISPERR_BASE_URL=https://…`. Do not default that define to
`https://api.whisperr.net` or any other host. An empty base URL lets the SDK
use its own production default; a hardcoded host sends events there even when
the user asked for somewhere else.

## Init

In `main()` after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
import 'package:whisperr/whisperr.dart';

const apiKey = String.fromEnvironment('WHISPERR_KEY');
const baseUrl = String.fromEnvironment('WHISPERR_BASE_URL');
if (baseUrl.isEmpty) {
  await Whisperr.initialize(apiKey: apiKey);
} else {
  await Whisperr.initialize(apiKey: apiKey, baseUrl: baseUrl);
}
```

Omit `baseUrl` when `WHISPERR_BASE_URL` is empty so the SDK keeps its own
default. Do not substitute a hardcoded host. `initialize` throws an
`ArgumentError` when the key is empty, so a missing define fails at start.
`Whisperr.instance` throws a `StateError` before `initialize`. Do not skip
`initialize` and call `Whisperr.instance` later.

## Identify and reset

One helper, called after sign-up, after login, and in `main()` after
`initialize` when the app's auth state already has a user (session restore):

```dart
String? lastPushToken; // set by the push code below

Future<void> identifyWhisperrUser(AppUser user) async {
  await Whisperr.instance.identify(
    user.id,
    traits: {
      'first_name': user.firstName,
      'is_subscriber': user.isSubscriber,
      // only when the app knows them:
      'app_language': user.appLanguage, // the in-app choice, not the device locale
      'subscription_price': 9.99,
      'subscription_currency': 'USD',
      'plan_period': 'month',
    },
    // only if the app has the user's email:
    email: user.email,
    // only when the app asks users for email permission: their answer
    emailOptedIn: user.emailPermission, // true or false; leave out when the app does not ask
  );
  final token = lastPushToken;
  if (token != null) {
    await Whisperr.instance.setPushToken(token, kind: WhisperrPushTokenKind.fcm);
  }
}
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

`emailOptedIn` needs a recent `whisperr`: install the latest version
(https://docs.whisperr.net/sdk-versions.json lists it), and say so in your summary if the app pins an older one.
Never send `verified: true` or opt in a phone from client code, and never
use the `phone` shortcut.

On logout, in this order:

```dart
await Whisperr.instance.track('user_logged_out'); // only when it is in the work order
await Whisperr.instance.reset();
```

## Track

Use the event codes from the work order. For example, a habit tracker might
send `Whisperr.instance.track('habit_checked_in', properties: {'streak_days': 12});`
in the success path (bloc/cubit/provider action), never in `build()`.

Screens (only if the event plan has one): `Whisperr.instance.screen('Settings')`
from a `NavigatorObserver` or the router.

## Push (only if the app already uses firebase_messaging)

Send the token only after `identify`. Keep it in `lastPushToken` so the
helper sends it on every launch and login:

```dart
final messaging = FirebaseMessaging.instance;
lastPushToken = await messaging.getToken();
messaging.onTokenRefresh.listen((token) {
  lastPushToken = token;
  if (currentUser != null) { // the app's own signed-in check
    Whisperr.instance.setPushToken(token, kind: WhisperrPushTokenKind.fcm);
  }
});

FirebaseMessaging.onMessageOpenedApp
    .listen((m) => Whisperr.instance.trackPushOpened(m.data));
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) await Whisperr.instance.trackPushOpened(initial.data);
```

Do not use `attachPushTokenStream`: it sends tokens before `identify` and
after `reset()`. Call `setPushToken` only while the OS reports notification
permission.

## Build

`flutter analyze` before and after. Zero new issues. Run with
`flutter run --dart-define=WHISPERR_KEY=wpk_…`.
