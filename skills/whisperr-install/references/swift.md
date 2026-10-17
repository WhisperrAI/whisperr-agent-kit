# Swift / iOS

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

One helper. Call it after sign-up succeeds, after login succeeds, and at
every app start after `initialize` when the app's auth state already has a
user (session restore):

```swift
var lastPushToken: Data? // set by the push code below

func identifyWhisperrUser(_ user: AppUser) async {
    try? await Whisperr.shared?.identify(
        user.id,
        traits: [
            "first_name": .string(user.firstName),
            "is_subscriber": .bool(user.isSubscriber),
            // only when the app knows them:
            "app_language": .string(user.appLanguage), // the in-app choice, not the device locale
            "subscription_price": 9.99,
            "subscription_currency": "USD",
            "plan_period": "month",
        ],
        // only if the app has the user's email:
        email: user.email,
        // only when the app asks users for email permission: their answer
        emailOptedIn: user.emailPermission // true or false; leave out when the app does not ask
    )
    if let token = lastPushToken { Whisperr.setPushToken(token) }
}
```

Trait and property values are `JSONValue`. A literal works as is
(`"pro"`, `42`, `true`). A variable needs its case: `.string(name)`,
`.number(Double(count))`, `.bool(flag)`.

Leave out a channel the app does not use.

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

`emailOptedIn` needs a recent `Whisperr` package: install the latest version
(https://docs.whisperr.net/sdk-versions.json lists it), and say so in your summary if the app pins an older one.
Never send `verified: true` or opt in a phone from client code, and never
use the `phone` shortcut.

On logout, in this order:

```swift
Task {
    try? await Whisperr.shared?.track("user_logged_out") // only when it is in the work order
    await Whisperr.shared?.reset()
}
```

## Track

Use the event codes from the work order. For example, a photo app might
send:

```swift
Task { try? await Whisperr.shared?.track("album_shared", properties: ["photo_count": .number(Double(album.count))]) }
```

Screen views are manual: `try? await Whisperr.shared?.screen("Paywall")`.
Add them only when the event plan asks for a screen event.

## Push (only if the app already registers for remote notifications)

These static calls are synchronous. They wait for `initialize` by
themselves. Send the token only after `identify`: keep it in
`lastPushToken` so the helper sends it on every launch and login, and send
it here only while a user is signed in.

```swift
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    lastPushToken = deviceToken
    if session.currentUser != nil { Whisperr.setPushToken(deviceToken) } // the app's own signed-in check
}
```

With Firebase Cloud Messaging, in
`messaging(_:didReceiveRegistrationToken:)`: keep `fcmToken` the same way
(a `String?`), call `Whisperr.setPushToken(fcmToken: fcmToken)` only while
signed in, and in the helper.

Push opens, in `userNotificationCenter(_:didReceive:withCompletionHandler:)`:

```swift
Whisperr.handleNotificationResponse(response) // records the open; ignores pushes from other senders
completionHandler()
```

The call returns the push's deep link (`URL?`, nil for pushes from other
senders). Keep and route it only if the app already handles deep links:
`if let url = Whisperr.handleNotificationResponse(response) { … }`. An
unused `let deepLink = …` adds a compiler warning.

After `reset()`, call `setPushToken` again only when the next user logs in
(the helper does this).

## Build

`xcodebuild -scheme <App> -destination 'generic/platform=iOS Simulator' build`
before and after. To run: boot a simulator, install and launch the app
(`xcrun simctl`), then verify with `get_received_events`.
