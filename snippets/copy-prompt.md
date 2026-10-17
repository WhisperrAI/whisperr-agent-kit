# Copy-prompt fallback

Use this prompt in AI app builders that cannot add a custom MCP server, or
when you do not want to connect one: Lovable, Bolt, Replit, Rork, v0 and
similar tools.

The Whisperr dashboard builds the prompt for you: on **Home**, open
**Connect your code → Copy prompt**, pick the platform, answer the email
permission question and click **Add an app key**. Copy the prompt and paste
it into the tool. The install steps live in
https://docs.whisperr.net/setup.md, so the prompt stays short and never goes
out of date.

The prompt has this shape. The dashboard leaves out a line when it has no
value for it:

```text
Install Whisperr in this app: follow https://docs.whisperr.net/setup.md
Whisperr publishable key: <WPK_KEY>
Platform: <Web | Next.js | React | Expo | React Native | Flutter | Swift>
Email permission: <Yes | Per user | No | Not answered>
Main action in this app: <MAIN_ACTION>
Events already registered: <EVENT_CODES>
```

- `<WPK_KEY>`: a publishable key (`wpk_…`). The dashboard adds it only when
  you just created one. Without it, create a key in **Settings → API keys →
  Create key → App**, then add the line yourself. Publishable keys are safe
  in app code. The key shows only once.
- `Email permission`: your answer to "Does your signup get permission to
  email users?" in the dashboard.
- `<MAIN_ACTION>`: the moment your users get value, in your words (for
  example "A user books a class"). The coding agent names the event for it
  from your app's code. Whisperr does not pick an event name for you.
- `<EVENT_CODES>`: the event codes that are already registered for your
  app, comma-separated.

The prompt has no SDK versions and no install steps: setup.md installs the
latest version of the right SDK.

When the app runs, sign in and do the flows the agent tells you to click.
The Connect-code step on **Home** and the **Data** page show the events
within about a minute.
