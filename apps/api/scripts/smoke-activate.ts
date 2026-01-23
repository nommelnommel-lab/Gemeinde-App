import { AuthService } from '../src/auth/auth.service';
import { ResidentsService } from '../src/auth/residents.service';

const run = async () => {
  if (!process.env.JWT_SECRET) {
    process.env.JWT_SECRET = 'dev-secret-change-me';
  }

  const tenantId = `smoke-activate-${Date.now()}`;
  const residentsService = new ResidentsService();
  const authService = new AuthService();

  const resident = await residentsService.create(tenantId, {
    firstName: 'App',
    lastName: 'Tester',
    postalCode: '36115',
    houseNumber: '12A',
  });

  const { code } = await authService.createActivationCodeForResident({
    tenantId,
    residentId: resident.id,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    createdBy: 'smoke',
  });

  const result = await authService.activate(
    tenantId,
    {
      activationCode: code,
      email: 'app.tester@example.com',
      password: 'secret-pass-123',
      postalCode: '36115',
      houseNumber: '12A',
    },
    'smoke',
  );

  const expectedDisplayName = 'App T.';
  if (result.user.displayName !== expectedDisplayName) {
    throw new Error(
      `Unexpected displayName: ${result.user.displayName} (expected ${expectedDisplayName})`,
    );
  }

  // eslint-disable-next-line no-console
  console.info('PASS');
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('FAIL', error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
