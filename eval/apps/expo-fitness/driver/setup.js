// Runs once before the flows. State on globalThis outlives the module registry
// resets the driver uses to simulate relaunches.

// Device storage (see mocks/async-storage.js).
globalThis.__evalStorage = globalThis.__evalStorage || new Map();

// Native modules without a working default in Jest. SafeAreaProvider renders
// nothing until native inset metrics arrive, so use the library's own mock.
jest.mock('react-native-safe-area-context', () => require('react-native-safe-area-context/jest/mock').default);

// The OS lifecycle. React Native's Jest mock never emits AppState changes, so
// the driver owns them: it backgrounds the app before a relaunch and at the
// end, which is how a real device makes an SDK flush its queue.
const lifecycle = (globalThis.__evalLifecycle = globalThis.__evalLifecycle || {
  state: 'active',
  listeners: new Set(),
});

globalThis.__evalInstallAppState = (AppState) => {
  Object.defineProperty(AppState, 'currentState', { configurable: true, get: () => lifecycle.state });
  AppState.addEventListener = (type, listener) => {
    if (type !== 'change') return { remove() {} };
    lifecycle.listeners.add(listener);
    return { remove: () => lifecycle.listeners.delete(listener) };
  };
};

// Real networking (Node's fetch, see environment.js) with an observer on
// traffic to the Whisperr API, so the driver can wait for in-flight deliveries
// and report how many requests the app made. Expo's runtime installs its own
// fetch whenever the app loads, so the driver calls this after every launch.
const apiBase = (process.env.EVAL_API_BASE || '').replace(/\/+$/, '');
const traffic = (globalThis.__evalTraffic = globalThis.__evalTraffic || { inFlight: 0, total: 0, byPath: {}, statuses: {} });
const nodeFetch = globalThis.__evalNodeFetch;

async function observedFetch(input, init) {
  const url = typeof input === 'string' ? input : input && input.url ? input.url : String(input);
  if (!apiBase || !url.startsWith(apiBase)) return nodeFetch(input, init);
  const path = url.slice(apiBase.length).split('?')[0];
  traffic.inFlight += 1;
  traffic.total += 1;
  traffic.byPath[path] = (traffic.byPath[path] || 0) + 1;
  try {
    const response = await nodeFetch(input, init);
    traffic.statuses[response.status] = (traffic.statuses[response.status] || 0) + 1;
    return response;
  } catch (error) {
    traffic.statuses.network_error = (traffic.statuses.network_error || 0) + 1;
    throw error;
  } finally {
    traffic.inFlight -= 1;
  }
}

globalThis.__evalInstallFetch = () => {
  Object.defineProperty(globalThis, 'fetch', {
    configurable: true,
    enumerable: true,
    writable: true,
    value: observedFetch,
  });
};
globalThis.__evalInstallFetch();

// React warns about state updates from the mock API's timers outside act();
// they are expected in a UI-only driver and drown the useful output.
const originalError = console.error;
console.error = (...args) => {
  const first = typeof args[0] === 'string' ? args[0] : '';
  if (first.includes('not wrapped in act(') || first.includes('was not wrapped in act')) return;
  originalError(...args);
};
