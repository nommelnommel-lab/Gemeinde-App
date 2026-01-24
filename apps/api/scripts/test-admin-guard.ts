import assert from 'assert';
import { UnauthorizedException } from '@nestjs/common';
import { ExecutionContext } from '@nestjs/common';
import { AdminGuard } from '../src/admin/admin.guard';

const makeContext = (
  headers: Record<string, string>,
): ExecutionContext =>
  ({
    switchToHttp: () => ({
      getRequest: () => ({ headers }),
    }),
  }) as ExecutionContext;

const guard = new AdminGuard();

process.env.ADMIN_KEYS_JSON = JSON.stringify({
  'valid-key': 'tenant-a',
});

const expectUnauthorized = (label: string, fn: () => boolean) => {
  let thrown = false;
  try {
    fn();
  } catch (error) {
    if (error instanceof UnauthorizedException) {
      thrown = true;
    } else {
      throw error;
    }
  }
  assert.ok(thrown, `${label} should throw UnauthorizedException`);
};

expectUnauthorized('invalid key', () =>
  guard.canActivate(
    makeContext({
      'x-admin-key': 'invalid-key',
      'x-tenant': 'tenant-a',
    }),
  ),
);

const allowed = guard.canActivate(
  makeContext({
    'x-admin-key': 'valid-key',
    'x-tenant': 'tenant-a',
  }),
);

assert.strictEqual(allowed, true, 'valid key should allow access');

// eslint-disable-next-line no-console
console.log('AdminGuard tests passed');
