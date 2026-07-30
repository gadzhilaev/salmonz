export default () => ({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: parseInt(process.env.PORT ?? '3000', 10),
  databaseUrl: process.env.DATABASE_URL,
  corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:3000')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessTtl: process.env.JWT_ACCESS_TTL ?? '15m',
    refreshTtl: process.env.JWT_REFRESH_TTL ?? '30d',
  },
  storage: {
    driver: process.env.STORAGE_DRIVER ?? 'local',
    localUploadDir: process.env.LOCAL_UPLOAD_DIR ?? 'uploads',
    publicMediaBaseUrl:
      process.env.PUBLIC_MEDIA_BASE_URL ?? 'http://localhost:3000/media',
  },
  s3: {
    endpoint: process.env.S3_ENDPOINT,
    region: process.env.S3_REGION ?? 'us-east-1',
    accessKey: process.env.S3_ACCESS_KEY,
    secretKey: process.env.S3_SECRET_KEY,
    bucket: process.env.S3_BUCKET ?? 'salmonz',
    publicBaseUrl: process.env.S3_PUBLIC_BASE_URL,
    forcePathStyle: process.env.S3_FORCE_PATH_STYLE !== 'false',
  },
  upload: {
    maxBytes: 5 * 1024 * 1024,
  },
  throttler: {
    ttlMs: parseInt(process.env.THROTTLE_TTL_MS ?? '60000', 10),
    limit: parseInt(process.env.THROTTLE_LIMIT ?? '100', 10),
  },
});
