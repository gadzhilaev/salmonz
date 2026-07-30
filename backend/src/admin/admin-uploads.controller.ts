import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Role } from '../../generated/prisma/enums';
import { randomUUID } from 'crypto';
import { memoryStorage } from 'multer';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import {
  assertAllowedImage,
  extensionForMime,
} from '../common/utils/image-mime.util';
import { STORAGE_SERVICE } from '../storage/storage.interface';
import type { StorageService } from '../storage/storage.interface';
import { Inject } from '@nestjs/common';

@ApiTags('admin-uploads')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin/uploads')
export class AdminUploadsController {
  constructor(
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  @Post('product')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  uploadProduct(@UploadedFile() file?: Express.Multer.File) {
    return this.upload('products', file);
  }

  @Post('category')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  uploadCategory(@UploadedFile() file?: Express.Multer.File) {
    return this.upload('categories', file);
  }

  @Post('promotion')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  uploadPromotion(@UploadedFile() file?: Express.Multer.File) {
    return this.upload('promotions', file);
  }

  private async upload(folder: string, file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('file is required');
    }
    let mime;
    try {
      mime = assertAllowedImage(file.buffer);
    } catch (e) {
      throw new BadRequestException(
        e instanceof Error ? e.message : 'Invalid image',
      );
    }
    const key = `${folder}/${randomUUID()}.${extensionForMime(mime)}`;
    const result = await this.storage.upload({
      key,
      body: file.buffer,
      contentType: mime,
    });
    return { key: result.key, url: result.url };
  }
}
