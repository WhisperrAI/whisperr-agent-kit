import AsyncStorage from '@react-native-async-storage/async-storage';

import type { Subscription, User, Workout } from './types';

/**
 * In-process stand-in for the Repwise backend. State is kept on the device so
 * accounts survive app restarts during development.
 */
interface Db {
  accounts: Record<string, { user: User; password: string }>;
  sessions: Record<string, string>;
  workouts: Record<string, Workout[]>;
  subscriptions: Record<string, Subscription>;
  /** Free-text cancellation feedback, read by support. */
  feedback: { userId: string; text: string; at: string }[];
}

const STORAGE_KEY = 'repwise.mock-server.v1';
const empty = (): Db => ({ accounts: {}, sessions: {}, workouts: {}, subscriptions: {}, feedback: [] });

let db: Db | null = null;

export async function loadDb(): Promise<Db> {
  if (db) return db;
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  db = raw ? { ...empty(), ...(JSON.parse(raw) as Partial<Db>) } : empty();
  return db;
}

export async function saveDb(): Promise<void> {
  if (db) await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(db));
}

/** Stable backend id for an email: `usr_` + 16 hex chars (two FNV-1a 32-bit hashes). */
export function userIdForEmail(email: string): string {
  const input = email.trim().toLowerCase();
  const fnv = (seed: number) => {
    let hash = seed;
    for (let i = 0; i < input.length; i += 1) {
      hash ^= input.charCodeAt(i);
      hash = Math.imul(hash, 0x01000193) >>> 0;
    }
    return hash.toString(16).padStart(8, '0');
  };
  return `usr_${fnv(0x811c9dc5)}${fnv(0x2f2f2f2f)}`;
}

export function newId(prefix: string): string {
  const random = Math.random().toString(16).slice(2, 10).padEnd(8, '0');
  return `${prefix}_${Date.now().toString(16)}${random}`;
}
