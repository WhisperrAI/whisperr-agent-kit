# Copy-prompt fallback

Use this prompt in AI app builders that cannot add a custom MCP server, or
when you do not want to connect one: Lovable, Bolt, Replit, Rork, v0 and
similar tools.

The Whisperr dashboard builds the prompt for you: on **Home → Connect your
code**, under **Other ways**, choose **App builder**. Use **Change** to pick
the platform and answer the email permission question, then click **Copy the
prompt** and paste it into the tool. The install steps live in
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
If this is a git repo, before you change files: if the checked-out branch isn't main or master, ask me whether to continue from it or start from main or master (whichever exist); if there are uncommitted changes, ask me what to do with them (keep, stash, commit first or stop). Then create a new branch (e.g. whisperr/install) from the chosen one and commit there. Push or open a pull request only if I ask.
```

- `<WPK_KEY>`: a publishable key (`wpk_…`). **Copy the prompt** adds it, and
  creates one when the app has none. Without it, create a key in **Settings → API keys →
  Create key → App**, then add the line yourself. Publishable keys are safe
  in app code. The key shows only once.
- `Email permission`: your answer to "Does your signup get permission to
  email users?" in the dashboard.
- `<MAIN_ACTION>`: the moment your users get value, in your words (for
  example "A user books a class"). The coding agent names the event for it
  from your app's code. Whisperr does not pick an event name for you.
- `<EVENT_CODES>`: the event codes that are already registered for your
  app, comma-separated.
- The last line keeps the agent's changes on a new git branch. If you are not
  on `main` or `master`, or have uncommitted changes, the agent asks you first
  which branch to start from and what to do with those changes. Builders
  without git skip it.

The prompt has no SDK versions and no install steps: setup.md installs the
latest version of the right SDK.

When the app runs, sign in and do the flows the agent tells you to click.
The **Data** page shows the events within about a minute.
