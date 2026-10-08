// React Native's Jest environment, plus Node's own fetch. Expo's runtime
// replaces global fetch with expo/fetch (a native module, stubbed in Jest), so
// the driver hands the app real networking through this saved reference.
const path = require('path');

const base = require.resolve('@react-native/jest-preset/jest/react-native-env.js', {
  paths: [process.env.EVAL_APP_DIR || process.cwd()],
});
const ReactNativeEnv = require(base);

module.exports = class EvalEnvironment extends ReactNativeEnv {
  constructor(config, context) {
    super(config, context);
    this.global.__evalNodeFetch = fetch;
    this.global.__evalDriverDir = path.dirname(__filename);
  }
};
