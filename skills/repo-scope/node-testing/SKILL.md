---
description: "Writing Node.js tests (TypeScript + JavaScript): Vitest, Jest, or Mocha patterns — describe/it, fixtures, mocks/spies, async, supertest for HTTP, Playwright for browser. Covers focused test runs and watch mode."
---

# Node Testing (Vitest / Jest / Mocha)

Detect the runner first. Commands and syntax overlap but differ in small ways.

```bash
# Vitest (Vite-based projects)
grep -q '"vitest"' package.json && RUNNER=vitest

# Jest
grep -q '"jest"' package.json && RUNNER=jest

# Mocha
grep -q '"mocha"' package.json && RUNNER=mocha
```

Vitest and Jest share the `describe` / `it` / `expect` API; Mocha needs a separate assertion lib (Chai, node:assert).

## Basic structure (Vitest / Jest)

```typescript
// src/auth.test.ts
import { describe, it, expect } from 'vitest';  // or: from '@jest/globals'
import { login, AuthError } from './auth';

describe('login', () => {
  it('succeeds with valid credentials', async () => {
    const result = await login({ user: 'test', password: 'correct' });
    expect(result.isAuthenticated).toBe(true);
  });

  it('throws on wrong password', async () => {
    await expect(login({ user: 'test', password: 'wrong' }))
      .rejects.toThrow(AuthError);
  });
});
```

File naming: `*.test.ts` / `*.spec.ts`. The runner's config defines the pattern; stick to it.

## Setup and teardown

```typescript
import { beforeEach, afterEach } from 'vitest';

let db: Database;
beforeEach(async () => {
  db = new Database(':memory:');
  await db.migrate();
});
afterEach(async () => {
  await db.close();
});
```

Use `beforeAll` / `afterAll` for expensive once-per-suite setup (container startup, shared client). Never leak state across test files — each file should be independently runnable.

## Mocks and spies

Prefer dependency injection. When you can't inject:

```typescript
// Vitest
import { vi } from 'vitest';

// Spy on a method
const spy = vi.spyOn(mailer, 'send').mockResolvedValue({ id: 'msg-1' });

// Replace a whole module
vi.mock('./external-api', () => ({
  fetchUser: vi.fn().mockResolvedValue({ id: 1, name: 'alice' }),
}));

// Jest is near-identical: `jest.fn()`, `jest.mock()`, `jest.spyOn()`.
```

Reset between tests:

```typescript
import { beforeEach } from 'vitest';
beforeEach(() => { vi.restoreAllMocks(); });   // Vitest
// Or add `restoreMocks: true` to vitest.config.ts / jest.config.js.
```

## Async and promises

```typescript
it('resolves to the right value', async () => {
  await expect(fetchUser(1)).resolves.toEqual({ id: 1, name: 'alice' });
});

it('rejects with a specific error', async () => {
  await expect(fetchUser(-1)).rejects.toThrow('invalid id');
});
```

Never forget `await` on promise-returning expectations — a silent pass is worse than a loud failure.

## HTTP handlers (supertest)

```typescript
import request from 'supertest';
import { app } from './app';

it('GET /healthz returns 200', async () => {
  const res = await request(app).get('/healthz');
  expect(res.status).toBe(200);
  expect(res.body).toEqual({ ok: true });
});
```

For Next.js / Nuxt / Astro, prefer their built-in test helpers (`next-test-api-route-handler`, `@vitejs/test-utils` for frameworks that integrate).

## Browser / component tests

```typescript
// React + Vitest + @testing-library/react
import { render, screen } from '@testing-library/react';
import { LoginForm } from './LoginForm';

it('shows an error on empty submit', async () => {
  render(<LoginForm />);
  await userEvent.click(screen.getByRole('button', { name: /sign in/i }));
  expect(await screen.findByText(/required/i)).toBeVisible();
});
```

For full end-to-end (real browser), use **Playwright**:

```bash
npx playwright test                                  # full suite
npx playwright test login.spec.ts                    # one file
npx playwright test -g 'login'                       # by test-name pattern
npx playwright test --ui                             # interactive runner
```

Playwright tests are orthogonal to Vitest/Jest — keep them in a separate folder (e.g. `tests/e2e/`) and run them on a different CI job.

## Focused test runs

```bash
# Vitest
npx vitest run src/auth.test.ts                      # one file, non-watch
npx vitest run -t 'succeeds with valid'              # by test-name substring
npx vitest                                            # watch mode (dev)

# Jest
npx jest auth                                         # files matching 'auth'
npx jest -t 'succeeds with valid'                     # by test-name
npx jest --watch

# Mocha
npx mocha test/auth.test.js --grep 'succeeds'
```

## Snapshot tests — use sparingly

Snapshots are easy to generate and easy to rubber-stamp. Every `toMatchSnapshot()` call is a promise to review the diff whenever the snapshot updates. If you find yourself running `-u` routinely to regenerate, delete the snapshot — the test is no longer load-bearing.

## TypeScript config

Both Jest (via `ts-jest` or `@swc/jest`) and Vitest (native, via Vite) handle TypeScript. If tests run noticeably slower than the app's build, you're probably compiling TS twice — switch to the SWC or esbuild transformer.

## Coverage

```bash
npx vitest run --coverage                # Vitest (v8 or istanbul)
npx jest --coverage
npx c8 -r text -r lcov mocha             # Mocha via c8
```

See `coverage-audit` for interpreting results.
