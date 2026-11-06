-- AlterTable
ALTER TABLE "orders" ADD COLUMN IF NOT EXISTS "idempotencyPayloadHash" TEXT;
