import { ApiError, request } from './client';
import { DEMO_PROFILES, TAKEN_EMAILS } from './fixtures';
import { loadDb, newId, saveDb, userIdForEmail } from './mockServer';
import type { OnboardingAnswers, Session, User } from './types';

export interface SignUpInput {
  fullName: string;
  email: string;
  password: string;
  marketingOptIn: boolean;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

async function userForToken(token: string): Promise<User> {
  const db = await loadDb();
  const email = db.sessions[token];
  const account = email ? db.accounts[email] : undefined;
  if (!account) throw new ApiError('unauthorized', 'Your session has expired. Please log in again.', 401);
  return account.user;
}

async function openSession(email: string): Promise<Session> {
  const db = await loadDb();
  const token = newId('sess');
  db.sessions[token] = email;
  await saveDb();
  return { token, user: db.accounts[email].user };
}

export const authApi = {
  signUp(input: SignUpInput): Promise<Session> {
    return request(async () => {
      const email = input.email.trim().toLowerCase();
      if (!input.fullName.trim()) throw new ApiError('validation_error', 'Please enter your name.', 422);
      if (!EMAIL_RE.test(email)) throw new ApiError('validation_error', 'Please enter a valid email address.', 422);
      if (input.password.length < 8) {
        throw new ApiError('validation_error', 'Password must be at least 8 characters.', 422);
      }
      const db = await loadDb();
      if (TAKEN_EMAILS.includes(email) || db.accounts[email]) {
        throw new ApiError('email_taken', 'An account with this email already exists. Try logging in.', 409);
      }
      const user: User = {
        id: userIdForEmail(email),
        email,
        fullName: input.fullName.trim(),
        phone: DEMO_PROFILES[email]?.phone,
        marketingOptIn: input.marketingOptIn,
        onboarded: false,
        createdAt: new Date().toISOString(),
      };
      db.accounts[email] = { user, password: input.password };
      return openSession(email);
    });
  },

  logIn(emailInput: string, password: string): Promise<Session> {
    return request(async () => {
      const email = emailInput.trim().toLowerCase();
      const db = await loadDb();
      const account = db.accounts[email];
      if (!account || account.password !== password) {
        throw new ApiError('invalid_credentials', 'That email and password do not match.', 401);
      }
      return openSession(email);
    });
  },

  me(token: string): Promise<User> {
    return request(() => userForToken(token));
  },

  logOut(token: string): Promise<void> {
    return request(async () => {
      const db = await loadDb();
      delete db.sessions[token];
      await saveDb();
    });
  },

  saveOnboarding(token: string, answers: OnboardingAnswers): Promise<User> {
    return request(async () => {
      const current = await userForToken(token);
      const db = await loadDb();
      const user: User = { ...current, ...answers, onboarded: true };
      db.accounts[user.email].user = user;
      await saveDb();
      return user;
    });
  },
};
