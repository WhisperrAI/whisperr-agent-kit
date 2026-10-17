// Jest config for the flow driver. It runs against the app copy in EVAL_APP_DIR
// (with that app's own node_modules) and never touches files in it.
const path = require('path');

const fs = require('fs');

const appDir = process.env.EVAL_APP_DIR;
if (!appDir) throw new Error('EVAL_APP_DIR is required');

// Load the app's .env files the way `expo start` does in development (the
// shell environment wins, then .env.development.local, .env.local,
// .env.development, .env).
for (const name of ['.env.development.local', '.env.local', '.env.development', '.env']) {
  const file = path.join(appDir, name);
  if (!fs.existsSync(file)) continue;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)?\s*$/);
    if (!match || process.env[match[1]] !== undefined) continue;
    let value = (match[2] || '').trim();
    if (/^(['"]).*\1$/.test(value)) value = value.slice(1, -1);
    else value = value.replace(/\s+#.*$/, '');
    process.env[match[1]] = value;
  }
}

module.exports = {
  rootDir: appDir,
  roots: [__dirname],
  preset: 'jest-expo',
  testEnvironment: path.join(__dirname, 'environment.cjs'),
  testMatch: ['**/flows.test.js'],
  modulePaths: [path.join(appDir, 'node_modules')],
  setupFiles: [path.join(__dirname, 'setup.js')],
  moduleNameMapper: {
    '^@react-native-async-storage/async-storage$': path.join(__dirname, 'mocks', 'async-storage.js'),
  },
  testTimeout: 15 * 60 * 1000,
  watchman: false,
  cacheDirectory: path.join(appDir, 'node_modules', '.cache', 'eval-driver-jest'),
};
