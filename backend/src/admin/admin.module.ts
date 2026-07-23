import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { AdminUploadsController } from './admin-uploads.controller';
import { AdminUsersController } from './admin-users.controller';

/**
 * Nest admin module — users list + media uploads.
 * Catalog/orders/support admin routes live in their feature modules under /admin/*.
 */
@Module({
  imports: [StorageModule],
  controllers: [AdminUsersController, AdminUploadsController],
})
export class AdminModule {}
