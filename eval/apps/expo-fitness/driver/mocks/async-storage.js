// AsyncStorage backed by a map on globalThis, so data survives the module
// registry reset the driver uses to simulate an app relaunch (like disk does).
const store = (globalThis.__evalStorage = globalThis.__evalStorage || new Map());

const api = {
  getItem: async (key) => (store.has(key) ? store.get(key) : null),
  setItem: async (key, value) => {
    store.set(key, String(value));
  },
  removeItem: async (key) => {
    store.delete(key);
  },
  mergeItem: async (key, value) => {
    const current = store.has(key) ? JSON.parse(store.get(key)) : {};
    store.set(key, JSON.stringify({ ...current, ...JSON.parse(value) }));
  },
  clear: async () => store.clear(),
  getAllKeys: async () => [...store.keys()],
  multiGet: async (keys) => keys.map((key) => [key, store.has(key) ? store.get(key) : null]),
  multiSet: async (pairs) => pairs.forEach(([key, value]) => store.set(key, String(value))),
  multiRemove: async (keys) => keys.forEach((key) => store.delete(key)),
  flushGetRequests: () => undefined,
};

api.useAsyncStorage = (key) => ({
  getItem: () => api.getItem(key),
  setItem: (value) => api.setItem(key, value),
  removeItem: () => api.removeItem(key),
  mergeItem: (value) => api.mergeItem(key, value),
});

module.exports = { __esModule: true, default: api, ...api };
