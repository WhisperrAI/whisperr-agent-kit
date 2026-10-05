# Flutter (whisperr 0.4+, Flutter 3.19+)

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

## Init

In `main()` after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
import 'package:whisperr/whisperr.dart';

const whisperrKey = String.fromEnvironment('WHISPERR_KEY');
if (whisperrKey.isNotEmpty) {
  await Whisperr.initialize(apiKey: whisperrKey);
}
```

## Identify and reset

After login or sign-up, and on session restore:

```dart
await Whisperr.instance.identify(
  user.id,
  traits: {'first_name': user.firstName, 'plan': user.plan},
  channels: [
    WhisperrChannel.email(user.email, optedIn: user.emailConsent), // only if the app has these
  ],
);
```

On logout: `await Whisperr.instance.reset();`

## Track

`Whisperr.instance.track('checkout_completed', properties: {'amount': 42});`
in the success path (bloc/cubit/provider action), never in `build()`.

Screens (only if the event plan has one): `Whisperr.instance.screen('Checkout')`
from a `NavigatorObserver` or the router.

## Push (only if the app already uses firebase_messaging)

```dart
final messaging = FirebaseMessaging.instance;
final token = await messaging.getToken();
if (token != null) await Whisperr.instance.setPushToken(token);
Whisperr.instance.attachPushTokenStream(messaging.onTokenRefresh);

FirebaseMessaging.onMessageOpenedApp
    .listen((m) => Whisperr.instance.trackPushOpened(m.data));
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) await Whisperr.instance.trackPushOpened(initial.data);
```

Call `setPushToken` only while the OS reports notification permission.

## Build

`flutter analyze` before and after. Zero new issues. Run with
`flutter run --dart-define=WHISPERR_KEY=wpk_…`.
