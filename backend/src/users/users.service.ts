import { randomUUID } from 'crypto';
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  assertAllowedImage,
  extensionForMime,
} from '../common/utils/image-mime.util';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_SERVICE } from '../storage/storage.interface';
import type { StorageService } from '../storage/storage.interface';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        avatarKey: true,
        role: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return {
      ...user,
      avatarUrl: user.avatarKey
        ? this.storage.getPublicUrl(user.avatarKey)
        : null,
    };
  }

  async updateMe(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        name: dto.name?.trim(),
        phone: dto.phone,
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        avatarKey: true,
        role: true,
        updatedAt: true,
      },
    });
    return {
      ...user,
      avatarUrl: user.avatarKey
        ? this.storage.getPublicUrl(user.avatarKey)
        : null,
    };
  }

  async uploadAvatar(userId: string, file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Avatar file is required');
    }
    let mime;
    try {
      mime = assertAllowedImage(file.buffer);
    } catch (e) {
      throw new BadRequestException((e as Error).message);
    }

    const ext = extensionForMime(mime);
    const key = `avatars/${userId}/${randomUUID()}.${ext}`;
    await this.storage.upload({
      key,
      body: file.buffer,
      contentType: mime,
    });

    const previous = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { avatarKey: true },
    });

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarKey: key },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        avatarKey: true,
        role: true,
      },
    });

    if (previous?.avatarKey && previous.avatarKey !== key) {
      try {
        await this.storage.delete(previous.avatarKey);
      } catch {
        // best-effort cleanup
      }
    }

    return {
      ...user,
      avatarUrl: this.storage.getPublicUrl(key),
    };
  }
}
