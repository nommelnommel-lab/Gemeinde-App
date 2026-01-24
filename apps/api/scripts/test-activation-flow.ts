import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../src/auth/auth.service';
import { ResidentsService } from '../src/auth/residents.service';

const run = async () => {
  if (!process.env.JWT_SECRET) {
    process.env.JWT_SECRET = 'dev-secret-change-me';
  }

  const tenantId = `activation-flow-${Date.now()}`;
  const residentsService = new ResidentsService();
  const authService = new AuthService();

  const resident = await residentsService.create(tenantId, {
    firstName: 'Activation',
    lastName: 'Tester',
    postalCode: '36115',
    houseNumber: '12A',
  });

  const { code } = await authService.createActivationCodeForResident({
    tenantId,
    residentId: resident.id,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    createdBy: 'integration-test',
  });

  await authService.activate(
    tenantId,
    {
      activationCode: code,
      email: 'activation.tester@example.com',
      password: 'secret-pass-123',
      postalCode: '36115',
      houseNumber: '12A',
    },
    'integration-test',
  );

  try {
    await authService.activate(
      tenantId,
      {
        activationCode: code,
        email: 'activation.tester+retry@example.com',
        password: 'secret-pass-123',
        postalCode: '36115',
        houseNumber: '12A',
      },
      'integration-test',
    );
  } catch (error) {
    if (error instanceof UnauthorizedException) {
      // eslint-disable-next-line no-console
      console.info('PASS');
      return;
    }
    throw error;
  }

  throw new Error('Expected activation to fail for already used code');
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('FAIL', error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
