export type UploadObjectInput = {
  key: string;
  body: Buffer;
  contentType: string;
};

export interface StorageService {
  upload(input: UploadObjectInput): Promise<{ key: string; url: string }>;
  delete(key: string): Promise<void>;
  getPublicUrl(key: string): string;
}

export const STORAGE_SERVICE = Symbol('STORAGE_SERVICE');
