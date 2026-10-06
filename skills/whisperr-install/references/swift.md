# Swift / iOS (whisperr-swift 0.4+)

Source: https://docs.whisperr.net/sdks/swift/

## Add the package

- Swift package (`Package.swift`): add
  `.package(url: "https://github.com/WhisperrAI/whisperr-swift.git", from: "<version>")`
  and the product `Whisperr` to the app target.
- Xcode project with Tuist or XcodeGen: add the package to that manifest and
  regenerate.
- Plain `.xcodeproj`: ask the user to do one step in Xcode:
  **File → Add Package Dependencies…**, URL
  `https://github.com/WhisperrAI/whisperr-swift.git`, rule "Up to Next Major"
  from `<version>`, product `Whisperr` on the app target. Do not hand-edit
  `project.pbxproj` unless the user asks. Wait for the user, then build.

Put any new Swift file inside a folder that the app target compiles. A file
outside the target does not build.

## Key

Read the publishable key from configuration, not from a string literal in
code:

1. Add `WHISPERR_PUBLISHABLE_KEY = wpk_…` to the app's `.xcconfig` (create
   `Config/Whisperr.xcconfig` only if the project has no xcconfig, and ask
   the user to attach it to the target).
2. Add `WhisperrPublishableKey` = `$(WHISPERR_PUBLISHABLE_KEY)` to
   `Info.plist`.
3. Read it with `Bundle.main.object(forInfoDictionaryKey: "WhisperrPublishableKey") as? String`.

If the project already has a config pattern (a `Secrets.swift`, an
`Environment` enum), use that pattern instead.

## Init

Once, at startup (SwiftUI `App.init` in a `Task`, or
`application(_:didFinishLaunchingWithOptions:)`):

```swift
import Whisperr

Task {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "WhisperrPublishableKey") as? String,
          !key.isEmpty else { return }
    await Whisperr.initialize(apiKey: key)
}
```

Use the client through `await Whisperr.shared` (it is `nil` before init).

## Identify and reset

After login or sign-up succeeds, and on session restore:

```swift
Task {
    try? await Whisperr.shared?.identify(
        user.id,
        traits: ["first_name": .string(user.firstName), "plan": .string(user.plan)],
        channels: [
            .email(user.email, optedIn: user.emailConsent)   // only if the app has email and a consent flag
        ]
    )
}
```

Trait and property values are `JSONValue`. A literal works as is
(`"pro"`, `42`, `true`). A variable needs its case: `.string(name)`,
`.number(Double(count))`, `.bool(flag)`.

Leave out a channel the app does not use. Do not use the `email:` /
`phone:` / `pushToken:` shortcuts unless the user opted in to that address.

On logout: `Task { await Whisperr.shared?.reset() }`.

## Track

```swift
Task { try? await Whisperr.shared?.track("checkout_completed", properties: ["amount": .number(order.total), "currency": "USD"]) }
```

Screen views are manual: `try? await Whisperr.shared?.screen("Paywall")`.
Add them only when the event plan asks for a screen event.

## Push (only if the app already registers for remote notifications)

These static calls are synchronous. They wait for `initialize` by
themselves.

```swift
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Whisperr.setPushToken(deviceToken)
}
```

With Firebase Cloud Messaging, in
`messaging(_:didReceiveRegistrationToken:)`:
`if let fcmToken { Whisperr.setPushToken(fcmToken: fcmToken) }`.

Push opens, in `userNotificationCenter(_:didReceive:withCompletionHandler:)`:

```swift
Whisperr.handleNotificationResponse(response) // records the open; ignores pushes from other senders
completionHandler()
```

The call returns the push's deep link (`URL?`, nil for pushes from other
senders). Keep and route it only if the app already handles deep links:
`if let url = Whisperr.handleNotificationResponse(response) { … }`. An
unused `let deepLink = …` adds a compiler warning.

After `reset()`, call `setPushToken` again when the next user logs in.

## Build

`xcodebuild -scheme <App> -destination 'generic/platform=iOS Simulator' build`
before and after. To run: boot a simulator, install and launch the app
(`xcrun simctl`), then verify with `get_received_events`.
