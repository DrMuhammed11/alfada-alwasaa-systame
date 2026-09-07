-- CreateEnum
CREATE TYPE "OutboxMailStatus" AS ENUM ('QUEUED', 'SENT', 'FAILED', 'PAUSED');

-- CreateTable
CREATE TABLE "OutboxMail" (
    "id" TEXT NOT NULL,
    "replyId" TEXT,
    "refNumber" TEXT NOT NULL,
    "to" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "html" TEXT,
    "body" TEXT,
    "attachments" JSONB,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 3,
    "nextRetryAt" TIMESTAMP(3) NOT NULL,
    "status" "OutboxMailStatus" NOT NULL DEFAULT 'QUEUED',
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "sentAt" TIMESTAMP(3),

    CONSTRAINT "OutboxMail_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "OutboxMail_status_nextRetryAt_idx" ON "OutboxMail"("status", "nextRetryAt");

-- CreateIndex
CREATE INDEX "OutboxMail_refNumber_idx" ON "OutboxMail"("refNumber");

-- AddForeignKey
ALTER TABLE "OutboxMail" ADD CONSTRAINT "OutboxMail_replyId_fkey" FOREIGN KEY ("replyId") REFERENCES "Reply"("id") ON DELETE SET NULL ON UPDATE CASCADE;
