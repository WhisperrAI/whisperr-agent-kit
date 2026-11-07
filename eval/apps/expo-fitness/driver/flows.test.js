/* eslint-disable no-undef */
// Drives the Repwise UI through the eval flows and writes one JSON line per
// step to EVAL_OUT. It only touches the UI (testIDs), the simulated OS
// lifecycle and storage; it never imports the app's analytics code.
const fs = require('fs');
const path = require('path');

const APP_DIR = process.env.EVAL_APP_DIR;
const OUT = process.env.EVAL_OUT;
const FLUSH_WAIT_MS = Number(process.env.EVAL_FLUSH_WAIT_MS || 12000);
const STEP_SETTLE_MS = Number(process.env.EVAL_STEP_SETTLE_MS || 600);
const FIND_TIMEOUT_MS = Number(process.env.EVAL_FIND_TIMEOUT_MS || 10000);

const JANE = { name: 'Jane Evalson', email: 'jane.eval@example.com', password: 'correct-horse-9' };
const SAM = { name: 'Sam Optout', email: 'sam.noconsent@example.com', password: 'battery-staple-7' };
const GOOD_CARD = '4242424242424242';
const DECLINED_CARD = '4000000000000002';

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const lifecycle = () => globalThis.__evalLifecycle;

let rtl = null;
let mounted = null;

async function setAppState(state) {
  const { act } = rtl;
  lifecycle().state = state;
  await act(async () => {
    for (const listener of [...lifecycle().listeners]) listener(state);
  });
}

/** Cold start: fresh module registry (fresh JS process), same storage (disk). */
async function launchApp() {
  jest.resetModules();
  lifecycle().state = 'active';
  lifecycle().listeners.clear();
  globalThis.__evalInstallAppState(require('react-native').AppState);

  let root = null;
  jest.doMock('expo', () => ({
    ...jest.requireActual('expo'),
    registerRootComponent: (component) => {
      root = component;
    },
  }));
  const pkg = JSON.parse(fs.readFileSync(path.join(APP_DIR, 'package.json'), 'utf8'));
  const entry = pkg.main && pkg.main !== 'expo/AppEntry' ? path.join(APP_DIR, pkg.main) : path.join(APP_DIR, 'App');
  const exported = require(entry);
  if (!root) root = exported && exported.default ? exported.default : require(path.join(APP_DIR, 'App')).default;
  globalThis.__evalInstallFetch();

  rtl = require('@testing-library/react-native/pure');
  const React = require('react');
  mounted = await rtl.render(React.createElement(root));
}

/** The user leaves the app and the OS kills it. */
async function killApp() {
  await setAppState('background');
  await sleep(1500);
  if (mounted) await mounted.unmount();
  mounted = null;
  lifecycle().listeners.clear();
}

const find = (testID) => rtl.screen.findByTestId(testID, {}, { timeout: FIND_TIMEOUT_MS });
const press = async (testID) => rtl.fireEvent.press(await find(testID));
const type = async (testID, text) => rtl.fireEvent.changeText(await find(testID), text);
const toggle = async (testID, value) => rtl.fireEvent(await find(testID), 'valueChange', value);
const gone = (testID) =>
  rtl.waitFor(
    () => {
      if (rtl.screen.queryByTestId(testID)) throw new Error(`${testID} still visible`);
    },
    { timeout: FIND_TIMEOUT_MS },
  );
async function expectText(testID, pattern) {
  await rtl.waitFor(
    () => {
      const node = rtl.screen.getByTestId(testID);
      const text = [].concat(node.props.children).join('');
      if (!pattern.test(text)) throw new Error(`${testID} text "${text}" does not match ${pattern}`);
    },
    { timeout: FIND_TIMEOUT_MS },
  );
}

function visibleTestIDs() {
  const ids = [];
  const walk = (node) => {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node)) return node.forEach(walk);
    if (node.props && node.props.testID) ids.push(node.props.testID);
    (node.children || []).forEach(walk);
  };
  walk(rtl.screen.toJSON());
  return ids;
}

async function step(id, fn) {
  const startedAt = new Date().toISOString();
  const marks = {};
  let ok = true;
  let error;
  try {
    await fn((name) => {
      marks[name] = new Date().toISOString();
    });
  } catch (e) {
    ok = false;
    error = String((e && e.message) || e).split('\n')[0].slice(0, 300);
    if (process.env.EVAL_DEBUG && rtl) process.stdout.write(`visible testIDs: ${visibleTestIDs().join(', ')}\n`);
  }
  // Let work that follows the visible result (awaits after navigation) land inside the step.
  await sleep(STEP_SETTLE_MS);
  const line = { step: id, started_at: startedAt, ended_at: new Date().toISOString(), ok };
  if (Object.keys(marks).length) line.marks = marks;
  if (!ok) line.error = error;
  fs.appendFileSync(OUT, `${JSON.stringify(line)}\n`);
  process.stdout.write(`${ok ? 'ok  ' : 'FAIL'} ${id}${ok ? '' : ` (${error})`}\n`);
  await sleep(200);
}

async function signUp(user, consent) {
  await type('signup-name', user.name);
  await type('signup-email', user.email);
  await type('signup-password', user.password);
  await toggle('signup-marketing-consent', consent);
  await press('signup-submit');
}

async function logWorkout(workoutType, minutes, notes) {
  await press('home-log-workout');
  await press(`workout-type-${workoutType}`);
  await type('workout-duration', String(minutes));
  if (notes) await type('workout-notes', notes);
  await press('workout-save');
  await gone('log-workout-screen');
  await find('home-screen');
}

async function logOut() {
  await press('tab-profile');
  await press('profile-logout');
  await find('welcome-screen');
}

test('eval flows', async () => {
  if (!APP_DIR || !OUT) throw new Error('EVAL_APP_DIR and EVAL_OUT are required');
  globalThis.__evalStorage.clear();

  await step('anon_browse', async () => {
    await launchApp();
    await find('welcome-screen');
    await press('program-card-prg_strength_foundations');
    await find('program-detail-screen');
    await press('program-start');
    await find('signup-screen');
  });

  await step('signup_taken', async () => {
    await signUp({ ...JANE, email: 'taken@example.com' }, true);
    await expectText('signup-error', /already exists/);
  });

  await step('signup_ok', async () => {
    await signUp(JANE, true);
    await find('onboarding-step-goal');
  });

  await step('onboarding_done', async () => {
    await press('goal-option-build_strength');
    await press('onboarding-next');
    await press('experience-option-intermediate');
    await press('onboarding-next');
    await press('weekly-target-option-4');
    await press('onboarding-finish');
    await find('home-screen');
  });

  await step('core_action_x3', async () => {
    await logWorkout('strength', 45, 'Felt strong, call Jane Evalson at +15555550123 about the gym');
    await logWorkout('run', 25);
    await logWorkout('yoga', 30);
    await expectText('home-week-progress', /^3 of 4/);
  });

  await step('paywall_view', async () => {
    await press('home-upgrade');
    await find('paywall-screen');
    await find('plan-option-pro_annual');
  });

  await step('purchase_declined', async () => {
    await press('plan-option-pro_annual');
    await press('paywall-continue');
    await type('checkout-card-number', DECLINED_CARD);
    await type('checkout-expiry', '12/30');
    await type('checkout-cvc', '123');
    await press('checkout-submit');
    await expectText('checkout-error', /declined/);
  });

  await step('purchase_ok', async () => {
    await type('checkout-card-number', GOOD_CARD);
    await press('checkout-submit');
    await find('purchase-success-screen');
    await press('purchase-success-done');
    await find('home-screen');
  });

  await step('cancel_with_reason', async () => {
    await press('tab-profile');
    await press('profile-manage-subscription');
    await press('subscription-cancel');
    await press('cancel-reason-too_expensive');
    await type('cancel-feedback', 'Money is tight this month');
    await press('cancel-confirm');
    await expectText('profile-plan', /Canceled/);
  });

  await step('logout', async () => {
    await press('profile-logout');
    await find('welcome-screen');
    // Jane logs back in next, so stitching moves this anonymous browse onto her
    // whether or not the SDK was reset; signup_ok_noconsent checks the reset.
    await press('program-card-prg_5k_ready');
    await find('program-detail-screen');
  });

  await step('login_ok', async () => {
    await press('program-start');
    await press('signup-login-link');
    await type('login-email', JANE.email);
    await type('login-password', JANE.password);
    await press('login-submit');
    await find('home-screen');
  });

  await step('restore', async () => {
    await killApp();
    await launchApp();
    await find('home-screen');
  });

  await step('signup_ok_noconsent', async (mark) => {
    await logOut();
    // From here until Sam signs up the device is anonymous: the lifecycle
    // events of this background/foreground cycle must not carry Jane's id.
    mark('logout_at');
    await sleep(50); // events are stored with millisecond precision
    await setAppState('background');
    await sleep(1500);
    await setAppState('active');
    await press('program-card-prg_hiit_express');
    await find('program-detail-screen');
    await press('program-start');
    await find('signup-screen');
    mark('signup_at');
    await signUp(SAM, false);
    await find('onboarding-step-goal');
  });

  // Leave the app so the SDK flushes, then give delivery time to finish.
  await setAppState('background');
  const deadline = Date.now() + FLUSH_WAIT_MS + 20000;
  await sleep(FLUSH_WAIT_MS);
  while (globalThis.__evalTraffic.inFlight > 0 && Date.now() < deadline) await sleep(250);
  if (mounted) await mounted.unmount();
  const traffic = globalThis.__evalTraffic;
  process.stdout.write(`whisperr api traffic: ${JSON.stringify(traffic)}\n`);
});
