import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LocalFsStorageService } from './local-fs-storage.service';
import { S3StorageService } from './s3-storage.service';
import { STORAGE_SERVICE } from './storage.interface';

@Module({
  providers: [
    {
      provide: STORAGE_SERVICE,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const driver = (
          config.get<string>('storage.driver') ?? 'local'
        ).toLowerCase();
        if (driver === 's3') {
          return new S3StorageService(config);
        }
        return new LocalFsStorageService(config);
      },
    },
  ],
  exports: [STORAGE_SERVICE],
})
export class StorageModule {}
