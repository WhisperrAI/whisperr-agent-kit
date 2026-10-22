const num = (value: string | undefined, fallback: number) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) && value !== undefined && value !== '' ? parsed : fallback;
};

export const config = {
  appName: 'Repwise',
  apiUrl: process.env.EXPO_PUBLIC_API_URL ?? 'https://api.repwise.example',
  supportEmail: process.env.EXPO_PUBLIC_SUPPORT_EMAIL ?? 'support@repwise.example',
  /** The API is mocked in-process until the backend ships; this is its simulated latency. */
  mockLatencyMs: num(process.env.EXPO_PUBLIC_MOCK_LATENCY_MS, 300),
};
