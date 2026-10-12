# Flutter (whisperr 0.5+, Flutter 3.19+)

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
      'app_language': user.learningLanguage, // the in-app choice, not the device locale
      'subscription_price': 9.99,
      'subscription_currency': 'USD',
      'plan_period': 'month',
    },
    channels: [
      WhisperrChannel.email(user.email, optedIn: user.emailOptedOut ? false : null), // only if the app has email
    ],
  );
  final token = lastPushToken;
  if (token != null) {
    await Whisperr.instance.setPushToken(token, kind: WhisperrPushTokenKind.fcm);
  }
}
```

Client code sends contacts without consent. Whisperr stores them
unverified and not opted in. Pass `optedIn: false` only when the user opted
out. Never pass `optedIn: true`, and never use the `phone` shortcut. Consent
must be confirmed from your backend with the server key
([server.md](server.md)).

On logout, in this order:

```dart
await Whisperr.instance.track('user_logged_out'); // only when it is in the work order
await Whisperr.instance.reset();
```

## Track

`Whisperr.instance.track('checkout_completed', properties: {'amount': 42});`
in the success path (bloc/cubit/provider action), never in `build()`.

Screens (only if the event plan has one): `Whisperr.instance.screen('Checkout')`
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
