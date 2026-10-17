import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

import { workoutsApi, type LogWorkoutInput } from '../api/workouts';
import type { Workout } from '../api/types';
import { useAuth } from './AuthContext';

interface WorkoutsContextValue {
  workouts: Workout[];
  logWorkout(input: LogWorkoutInput): Promise<Workout>;
}

const WorkoutsContext = createContext<WorkoutsContextValue | null>(null);

export function WorkoutsProvider({ children }: { children: ReactNode }) {
  const { token } = useAuth();
  // Keyed by session so a logout never shows the previous user's history.
  const [loaded, setLoaded] = useState<{ token: string; workouts: Workout[] } | null>(null);
  const workouts = useMemo(() => (loaded && loaded.token === token ? loaded.workouts : []), [loaded, token]);

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    workoutsApi.list(token).then(
      (list) => {
        if (!cancelled) setLoaded({ token, workouts: list });
      },
      () => undefined,
    );
    return () => {
      cancelled = true;
    };
  }, [token]);

  const logWorkout = useCallback(
    async (input: LogWorkoutInput) => {
      if (!token) throw new Error('Not signed in');
      const workout = await workoutsApi.log(token, input);
      setLoaded((current) => ({
        token,
        workouts: [workout, ...(current?.token === token ? current.workouts : [])],
      }));
      return workout;
    },
    [token],
  );

  const value = useMemo(() => ({ workouts, logWorkout }), [workouts, logWorkout]);
  return <WorkoutsContext.Provider value={value}>{children}</WorkoutsContext.Provider>;
}

export function useWorkouts(): WorkoutsContextValue {
  const value = useContext(WorkoutsContext);
  if (!value) throw new Error('useWorkouts must be used inside <WorkoutsProvider>');
  return value;
}

export function countSince(workouts: Workout[], days: number, now = Date.now()): number {
  const since = now - days * 24 * 60 * 60 * 1000;
  return workouts.filter((w) => Date.parse(w.loggedAt) >= since).length;
}

/** Consecutive days, ending today or yesterday, with at least one workout. */
export function currentStreak(workouts: Workout[], now = new Date()): number {
  const days = new Set(workouts.map((w) => w.loggedAt.slice(0, 10)));
  const cursor = new Date(now);
  if (!days.has(cursor.toISOString().slice(0, 10))) cursor.setDate(cursor.getDate() - 1);
  let streak = 0;
  while (days.has(cursor.toISOString().slice(0, 10))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}
