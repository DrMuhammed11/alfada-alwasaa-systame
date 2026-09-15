-- AlterTable
ALTER TABLE "Correspondence" ADD COLUMN IF NOT EXISTS "messageId" TEXT;
ALTER TABLE "Correspondence" ADD COLUMN IF NOT EXISTS "sourceReplyId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "Correspondence_messageId_key" ON "Correspondence"("messageId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "Correspondence_sourceReplyId_idx" ON "Correspondence"("sourceReplyId");

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Correspondence_sourceReplyId_fkey'
  ) THEN
    ALTER TABLE "Correspondence" ADD CONSTRAINT "Correspondence_sourceReplyId_fkey" FOREIGN KEY ("sourceReplyId") REFERENCES "Reply"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
