import { ApiError, request } from './client';
import { PROGRAMS } from './fixtures';
import { loadDb, newId, saveDb } from './mockServer';
import type { Program, Workout, WorkoutType } from './types';

export interface LogWorkoutInput {
  type: WorkoutType;
  durationMinutes: number;
  notes?: string;
}

async function emailForToken(token: string): Promise<string> {
  const db = await loadDb();
  const email = db.sessions[token];
  if (!email) throw new ApiError('unauthorized', 'Your session has expired. Please log in again.', 401);
  return email;
}

export const workoutsApi = {
  listPrograms(): Promise<Program[]> {
    return request(() => PROGRAMS);
  },

  getProgram(id: string): Promise<Program> {
    return request(() => {
      const program = PROGRAMS.find((p) => p.id === id);
      if (!program) throw new ApiError('not_found', 'Program not found.', 404);
      return program;
    });
  },

  list(token: string): Promise<Workout[]> {
    return request(async () => {
      const email = await emailForToken(token);
      const db = await loadDb();
      return db.workouts[db.accounts[email].user.id] ?? [];
    });
  },

  log(token: string, input: LogWorkoutInput): Promise<Workout> {
    return request(async () => {
      if (!Number.isInteger(input.durationMinutes) || input.durationMinutes <= 0 || input.durationMinutes > 600) {
        throw new ApiError('validation_error', 'Duration must be between 1 and 600 minutes.', 422);
      }
      const email = await emailForToken(token);
      const db = await loadDb();
      const userId = db.accounts[email].user.id;
      const workout: Workout = {
        id: newId('wko'),
        type: input.type,
        durationMinutes: input.durationMinutes,
        notes: input.notes?.trim() || undefined,
        loggedAt: new Date().toISOString(),
      };
      db.workouts[userId] = [workout, ...(db.workouts[userId] ?? [])];
      await saveDb();
      return workout;
    });
  },
};
