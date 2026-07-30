import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { mkdir, writeFile, unlink } from 'fs/promises';
import { dirname, join, normalize, sep } from 'path';
import { StorageService, UploadObjectInput } from './storage.interface';

/**
 * Local filesystem storage for demo when MinIO/Docker is unavailable.
 * Files are served under PUBLIC_MEDIA_BASE_URL (e.g. http://localhost:3000/media).
 */
@Injectable()
export class LocalFsStorageService implements StorageService {
  private readonly root: string;
  private readonly publicBaseUrl: string;

  constructor(config: ConfigService) {
    this.root = join(
      process.cwd(),
      config.get<string>('storage.localUploadDir') ?? 'uploads',
    );
    this.publicBaseUrl =
      config.get<string>('storage.publicMediaBaseUrl') ??
      'http://localhost:3000/media';
  }

  private resolveSafePath(key: string): string {
    const normalizedKey = key.replace(/\\/g, '/').replace(/^\/+/, '');
    if (
      normalizedKey.includes('..') ||
      normalizedKey.startsWith('/') ||
      normalizedKey.includes('\0')
    ) {
      throw new Error('Invalid storage key');
    }
    const full = normalize(join(this.root, normalizedKey));
    const rootNorm = normalize(this.root + sep);
    if (!full.startsWith(rootNorm) && full !== normalize(this.root)) {
      throw new Error('Path traversal rejected');
    }
    return full;
  }

  async upload(input: UploadObjectInput) {
    const full = this.resolveSafePath(input.key);
    await mkdir(dirname(full), { recursive: true });
    await writeFile(full, input.body);
    return { key: input.key, url: this.getPublicUrl(input.key) };
  }

  async delete(key: string) {
    try {
      await unlink(this.resolveSafePath(key));
    } catch {
      // ignore missing
    }
  }

  getPublicUrl(key: string): string {
    const clean = key.replace(/^\/+/, '');
    return `${this.publicBaseUrl.replace(/\/$/, '')}/${clean}`;
  }

  getRootDir(): string {
    return this.root;
  }
}
