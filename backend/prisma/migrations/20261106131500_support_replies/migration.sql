-- CreateTable
CREATE TABLE IF NOT EXISTS "support_replies" (
    "id" UUID NOT NULL,
    "messageId" UUID NOT NULL,
    "authorUserId" UUID,
    "body" TEXT NOT NULL,
    "isStaff" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_replies_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "support_replies_messageId_idx" ON "support_replies"("messageId");

-- AddForeignKey
DO $$ BEGIN
 ALTER TABLE "support_replies" ADD CONSTRAINT "support_replies_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "support_messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
