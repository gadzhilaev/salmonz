import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { CatalogAdminController } from './catalog-admin.controller';
import { CatalogPublicController } from './catalog-public.controller';
import { CatalogService } from './catalog.service';

@Module({
  imports: [StorageModule],
  controllers: [CatalogPublicController, CatalogAdminController],
  providers: [CatalogService],
  exports: [CatalogService],
})
export class CatalogModule {}
