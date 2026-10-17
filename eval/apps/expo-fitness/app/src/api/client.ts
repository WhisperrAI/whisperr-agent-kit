import { config } from '../config';

export type ApiErrorCode =
  | 'email_taken'
  | 'invalid_credentials'
  | 'card_declined'
  | 'network_error'
  | 'unauthorized'
  | 'validation_error'
  | 'not_found';

export class ApiError extends Error {
  constructor(
    readonly code: ApiErrorCode,
    message: string,
    readonly status: number,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

let offline = false;
const listeners = new Set<(offline: boolean) => void>();

/** Developer toggle that makes every API call fail as if the device were offline. */
export const networkSimulator = {
  isOffline: () => offline,
  setOffline(value: boolean) {
    offline = value;
    listeners.forEach((listener) => listener(value));
  },
  subscribe(listener: (offline: boolean) => void) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};

const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/**
 * Runs a mock endpoint the way a real HTTP call behaves: after some latency,
 * and failing with a network error while the offline toggle is on.
 */
export async function request<T>(handler: () => T | Promise<T>): Promise<T> {
  const jitter = Math.floor(Math.random() * config.mockLatencyMs * 0.5);
  await sleep(config.mockLatencyMs + jitter);
  if (offline) {
    throw new ApiError('network_error', 'Could not reach Repwise. Check your connection and try again.', 0);
  }
  return handler();
}

export function messageFor(error: unknown): string {
  if (error instanceof ApiError) return error.message;
  return 'Something went wrong. Please try again.';
}
