import { Module } from '@nestjs/common';
import { AdminUsersController } from './admin-users.controller';

/**
 * Nest admin module — aggregates admin-only user listing.
 * Catalog/orders/support admin routes live in their feature modules under /admin/*.
 */
@Module({
  controllers: [AdminUsersController],
})
export class AdminModule {}
