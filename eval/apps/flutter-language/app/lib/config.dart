/// App-wide configuration. Values can be overridden at build time with
/// `--dart-define=NAME=value`.
class AppConfig {
  const AppConfig._();

  static const appName = 'Parla';
  static const apiUrl = String.fromEnvironment(
    'PARLA_API_URL',
    defaultValue: 'https://api.parla.example',
  );
  static const supportEmail = 'support@parla.example';

  /// Simulated round-trip time of the fake backend.
  static const mockLatency = Duration(
    milliseconds: int.fromEnvironment('PARLA_MOCK_LATENCY_MS', defaultValue: 300),
  );
}
