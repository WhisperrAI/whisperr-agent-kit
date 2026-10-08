import AsyncStorage from '@react-native-async-storage/async-storage';
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

import { authApi, type SignUpInput } from '../api/auth';
import { ApiError } from '../api/client';
import type { OnboardingAnswers, Session, User } from '../api/types';

const SESSION_KEY = 'repwise.session';

type AuthStatus = 'restoring' | 'signedOut' | 'signedIn';

interface AuthContextValue {
  status: AuthStatus;
  user: User | null;
  token: string | null;
  signUp(input: SignUpInput): Promise<User>;
  logIn(email: string, password: string): Promise<User>;
  logOut(): Promise<void>;
  completeOnboarding(answers: OnboardingAnswers): Promise<User>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>('restoring');
  const [session, setSession] = useState<Session | null>(null);

  const persist = useCallback(async (next: Session | null) => {
    setSession(next);
    setStatus(next ? 'signedIn' : 'signedOut');
    if (next) await AsyncStorage.setItem(SESSION_KEY, JSON.stringify(next));
    else await AsyncStorage.removeItem(SESSION_KEY);
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const raw = await AsyncStorage.getItem(SESSION_KEY);
      if (!raw) {
        if (!cancelled) setStatus('signedOut');
        return;
      }
      const saved = JSON.parse(raw) as Session;
      try {
        const user = await authApi.me(saved.token);
        if (!cancelled) await persist({ token: saved.token, user });
      } catch (error) {
        if (cancelled) return;
        if (error instanceof ApiError && error.code === 'network_error') {
          // Offline at launch: keep the cached session so the app stays usable.
          setSession(saved);
          setStatus('signedIn');
        } else {
          await persist(null);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [persist]);

  const signUp = useCallback(
    async (input: SignUpInput) => {
      const next = await authApi.signUp(input);
      await persist(next);
      return next.user;
    },
    [persist],
  );

  const logIn = useCallback(
    async (email: string, password: string) => {
      const next = await authApi.logIn(email, password);
      await persist(next);
      return next.user;
    },
    [persist],
  );

  const logOut = useCallback(async () => {
    const token = session?.token;
    await persist(null);
    if (token) {
      try {
        await authApi.logOut(token);
      } catch {
        // The local session is gone either way; the server expires it later.
      }
    }
  }, [persist, session?.token]);

  const completeOnboarding = useCallback(
    async (answers: OnboardingAnswers) => {
      if (!session) throw new ApiError('unauthorized', 'Please log in again.', 401);
      const user = await authApi.saveOnboarding(session.token, answers);
      await persist({ token: session.token, user });
      return user;
    },
    [persist, session],
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      status,
      user: session?.user ?? null,
      token: session?.token ?? null,
      signUp,
      logIn,
      logOut,
      completeOnboarding,
    }),
    [status, session, signUp, logIn, logOut, completeOnboarding],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (!value) throw new Error('useAuth must be used inside <AuthProvider>');
  return value;
}
