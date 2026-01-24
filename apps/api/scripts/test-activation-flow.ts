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

  const expectUnauthorized = async (action: () => Promise<void>) => {
    try {
      await action();
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        return;
      }
      throw error;
    }
    throw new Error('Expected activation to fail for already used code');
  };

  const createResident = (suffix: string) =>
    residentsService.create(tenantId, {
      firstName: `Activation${suffix}`,
      lastName: 'Tester',
      postalCode: '36115',
      houseNumber: '12A',
    });

  const createCodeFor = async (residentId: string) =>
    authService.createActivationCodeForResident({
      tenantId,
      residentId,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      createdBy: 'integration-test',
    });

  const residentExact = await createResident('Exact');
  const { code: codeExact } = await createCodeFor(residentExact.id);
  if (!codeExact.includes('-')) {
    throw new Error('Expected activation code to include dashes');
  }

  await authService.activate(
    tenantId,
    {
      activationCode: codeExact,
      email: 'activation.tester.exact@example.com',
      password: 'secret-pass-123',
      postalCode: residentExact.postalCode,
      houseNumber: residentExact.houseNumber,
    },
    'integration-test',
  );

  await expectUnauthorized(() =>
    authService.activate(
      tenantId,
      {
        activationCode: codeExact,
        email: 'activation.tester.exact.retry@example.com',
        password: 'secret-pass-123',
        postalCode: residentExact.postalCode,
        houseNumber: residentExact.houseNumber,
      },
      'integration-test',
    ),
  );

  const residentNormalized = await createResident('Normalized');
  const { code: normalizedCode } = await createCodeFor(residentNormalized.id);

  await authService.activate(
    tenantId,
    {
      activationCode: normalizedCode.replace(/[-\\s]/g, ''),
      email: 'activation.tester.normalized@example.com',
      password: 'secret-pass-123',
      postalCode: residentNormalized.postalCode,
      houseNumber: residentNormalized.houseNumber,
    },
    'integration-test',
  );

  const residentTrimmed = await createResident('Trimmed');
  const { code: trimmedCode } = await createCodeFor(residentTrimmed.id);

  await authService.activate(
    tenantId,
    {
      activationCode: `  ${trimmedCode}  `,
      email: 'activation.tester.trimmed@example.com',
      password: 'secret-pass-123',
      postalCode: residentTrimmed.postalCode,
      houseNumber: residentTrimmed.houseNumber,
    },
    'integration-test',
  );

  // eslint-disable-next-line no-console
  console.info('PASS');
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('FAIL', error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
