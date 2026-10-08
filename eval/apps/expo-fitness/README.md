# expo-fitness (Repwise)

Expo SDK 57 / React Native 0.86 workout tracker with a Pro subscription. `app/` is the pristine app the agent gets (no Whisperr code); `eval.yaml` is the ground truth; `driver/` clicks through the flows; `reference.patch` is an ideal integration with the published `@whisperr/react-native`.

## App

- Navigation: react-navigation native stack + bottom tabs, split into guest, onboarding and member groups (`src/navigation/RootNavigator.tsx`).
- State: `AuthContext` (session persisted in AsyncStorage, restored on launch), `WorkoutsContext`, `SubscriptionContext`.
- Fake backend: `src/api/mockServer.ts` persists to AsyncStorage, adds `EXPO_PUBLIC_MOCK_LATENCY_MS` latency, and derives `usr_<hex>` ids from the email.
- Failure triggers: signup with `taken@example.com` fails, card `4000000000000002` declines, and Profile has a "Simulate network failure" switch (`dev-network-failure`).
- PII sentinels: `jane.eval@example.com` has phone `+15555550123` and billing address `221B Eval Street` in `src/api/fixtures.ts`; the checkout form prefills the address.

## Driver

```sh
EVAL_APP_DIR=/path/to/app-copy EVAL_API_BASE=http://localhost:8080 EVAL_OUT=/tmp/steps.jsonl bash driver/run
```

Needs Node 20+ (tested with 22.22). `driver/run` installs the app's dependencies if needed, then runs Jest with `jest-expo` and `@testing-library/react-native` over the real app tree:

- The app's `.env` files are loaded like Expo does; shell variables win.
- AsyncStorage is an in-memory map that survives simulated relaunches, which reset the module registry and render `index.ts` again.
- `fetch` is Node's real one, so the SDK reaches `EVAL_API_BASE`. Expo replaces the global `fetch` with a stub in Jest.
- `AppState` is driven by the driver. Backgrounding the app is the SDK's flush trigger. After the last step the driver backgrounds the app, waits `EVAL_FLUSH_WAIT_MS` (default 12000) and drains in-flight requests.

Each step appends `{"step","started_at","ended_at","ok"}`. `signup_ok_noconsent` also carries `marks.logout_at` and `marks.signup_at` for the reset check in `eval.yaml`. Exit code: 0 all steps ok, 1 a step failed, 2 setup error. `EVAL_DEBUG=1` prints the visible testIDs when a step fails.

## Reference

```sh
cd app-copy && git apply ../reference.patch && npm install
EXPO_PUBLIC_WHISPERR_KEY=wpk_... EVAL_APP_DIR=$PWD ... bash ../driver/run
```

The patch sets `EXPO_PUBLIC_WHISPERR_KEY` to a placeholder in `.env`; pass the real publishable key in the environment or edit `.env`.
