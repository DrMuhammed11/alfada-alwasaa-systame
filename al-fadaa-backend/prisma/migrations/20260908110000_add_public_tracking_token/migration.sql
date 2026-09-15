-- AlterTable
ALTER TABLE "Correspondence" ADD COLUMN IF NOT EXISTS "publicTrackingToken" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "Correspondence_publicTrackingToken_key" ON "Correspondence"("publicTrackingToken");
