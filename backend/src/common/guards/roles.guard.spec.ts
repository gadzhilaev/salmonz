import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '../../../generated/prisma/enums';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { RolesGuard } from './roles.guard';

function mockContext(user?: { id: string; email: string; role: Role }) {
  return {
    getHandler: () => ({}),
    getClass: () => ({}),
    switchToHttp: () => ({
      getRequest: () => ({ user }),
    }),
  } as unknown as ExecutionContext;
}

describe('RolesGuard', () => {
  it('allows when no roles required', () => {
    const reflector = {
      getAllAndOverride: () => undefined,
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);
    expect(guard.canActivate(mockContext())).toBe(true);
  });

  it('allows matching role', () => {
    const reflector = {
      getAllAndOverride: (key: string) =>
        key === ROLES_KEY ? [Role.ADMIN] : undefined,
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);
    expect(
      guard.canActivate(
        mockContext({ id: '1', email: 'a@b.c', role: Role.ADMIN }),
      ),
    ).toBe(true);
  });

  it('rejects mismatched role', () => {
    const reflector = {
      getAllAndOverride: () => [Role.ADMIN],
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);
    expect(() =>
      guard.canActivate(
        mockContext({ id: '1', email: 'a@b.c', role: Role.USER }),
      ),
    ).toThrow(ForbiddenException);
  });
});
