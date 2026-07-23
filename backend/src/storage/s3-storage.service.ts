import {
  DeleteObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StorageService, UploadObjectInput } from './storage.interface';

@Injectable()
export class S3StorageService implements StorageService {
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicBaseUrl?: string;
  private readonly endpoint?: string;

  constructor(config: ConfigService) {
    this.bucket = config.getOrThrow<string>('s3.bucket');
    this.publicBaseUrl = config.get<string>('s3.publicBaseUrl') || undefined;
    this.endpoint = config.get<string>('s3.endpoint') || undefined;

    this.client = new S3Client({
      region: config.get<string>('s3.region') ?? 'us-east-1',
      endpoint: this.endpoint,
      forcePathStyle: config.get<boolean>('s3.forcePathStyle') ?? true,
      credentials: {
        accessKeyId: config.getOrThrow<string>('s3.accessKey'),
        secretAccessKey: config.getOrThrow<string>('s3.secretKey'),
      },
    });
  }

  async upload(input: UploadObjectInput) {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: input.key,
        Body: input.body,
        ContentType: input.contentType,
      }),
    );
    return { key: input.key, url: this.getPublicUrl(input.key) };
  }

  async delete(key: string) {
    await this.client.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
    );
  }

  getPublicUrl(key: string): string {
    if (this.publicBaseUrl) {
      return `${this.publicBaseUrl.replace(/\/$/, '')}/${key}`;
    }
    if (this.endpoint) {
      return `${this.endpoint.replace(/\/$/, '')}/${this.bucket}/${key}`;
    }
    return `https://${this.bucket}.s3.amazonaws.com/${key}`;
  }
}
