# flutter-language (Parla)

Flutter Spanish-lessons app with a Premium subscription. `app/` is the pristine app the agent gets (no Whisperr code); `eval.yaml` is the ground truth; `driver/` taps through the flows; `reference.patch` is an ideal integration with the published `whisperr` pub package.

## App

- Navigation: `_RootGate` in `lib/app.dart` switches between splash, guest, onboarding and member flows, each with its own `Navigator`; the member flow is a `NavigationBar` shell with Learn and Profile tabs.
- State: `provider` `ChangeNotifier`s in `lib/state/`: `AuthController` (session persisted in `shared_preferences`, restored on launch), `ProgressController`, `SubscriptionController`.
- Fake backend: `lib/data/fake_backend.dart` persists to `shared_preferences`, adds `PARLA_MOCK_LATENCY_MS` latency (default 300), and derives `usr_<hex>` ids from the email. Repositories in `lib/data/` wrap it.
- Failure triggers: signup with `taken@example.com` fails, card `4000000000000002` declines, and Profile has a "Simulate network failure" switch (`dev-network-failure`).
- PII sentinels: `jane.eval@example.com` has phone `+15555550123` and billing address `221B Eval Street` in `lib/data/fixtures.dart`; the checkout form prefills the address.
- Widgets carry stable `ValueKey<String>`s (`signup-submit`, `lesson-card-les_cafe`, `plan-option-premium_annual`, ...).
- Only `lib/`, `test/` and the pub files are checked in. Run `flutter create --platforms=ios,android .` inside a copy of `app/` to get runnable platform folders.

Build checks: `flutter analyze` and `flutter test` (tested with Flutter 3.47.6 / Dart 3.13.5).

## Driver

```sh
EVAL_APP_DIR=/path/to/app-copy EVAL_API_BASE=http://localhost:8080 EVAL_OUT=/tmp/steps.jsonl bash driver/run
```

Needs the Flutter SDK on `PATH` (or `EVAL_FLUTTER=/path/to/flutter`); no device or emulator. `driver/run` runs `flutter pub get` if needed, copies `driver/flows_test.dart` into `app/eval_driver_test/` (removed on exit) and runs it with `flutter test`. A full run takes about a minute.

- The test uses `LiveTestWidgetsFlutterBinding` with a fully live frame policy, so timers, latency and HTTP are real and the SDK reaches `EVAL_API_BASE`.
- `shared_preferences` is the in-memory test store, which survives the simulated relaunch. A relaunch backgrounds the app, unmounts it and calls the app's `main()` again in the same isolate, so Dart statics (and any SDK singleton) persist as in a warm process.
- App lifecycle is driven through the binding with legal transition sequences. Backgrounding is the SDK's flush trigger; after the last step the driver backgrounds the app and waits `EVAL_FLUSH_WAIT_MS` (default 12000).
- `EVAL_DART_DEFINES="KEY=value OTHER=value"` becomes `--dart-define` flags.

Each step appends `{"step","started_at","ended_at","ok"}`. `signup_ok_noconsent` also carries `marks.logout_at` and `marks.signup_at` for the reset check in `eval.yaml`. The driver prints the request paths it saw for the `EVAL_API_BASE` host. Exit code: 0 all steps ok, 1 a step failed, 2 setup error. `EVAL_DEBUG=1` prints the visible keys when a step fails.

## Reference

```sh
cd app-copy && git apply ../reference.patch && flutter pub get
EVAL_DART_DEFINES="WHISPERR_API_KEY=wpk_..." EVAL_APP_DIR=$PWD ... bash ../driver/run
```

The patch reads `WHISPERR_API_KEY` and `WHISPERR_BASE_URL` (default `http://localhost:8080`) from `--dart-define`; the key defaults to a placeholder.
