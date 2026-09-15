-- AlterTable
ALTER TABLE "Correspondence" ADD COLUMN "messageId" TEXT;
ALTER TABLE "Correspondence" ADD COLUMN "sourceReplyId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Correspondence_messageId_key" ON "Correspondence"("messageId");

-- CreateIndex
CREATE INDEX "Correspondence_sourceReplyId_idx" ON "Correspondence"("sourceReplyId");

-- AddForeignKey
ALTER TABLE "Correspondence" ADD CONSTRAINT "Correspondence_sourceReplyId_fkey" FOREIGN KEY ("sourceReplyId") REFERENCES "Reply"("id") ON DELETE SET NULL ON UPDATE CASCADE;
