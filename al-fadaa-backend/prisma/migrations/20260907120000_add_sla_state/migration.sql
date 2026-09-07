-- CreateEnum
CREATE TYPE "SlaReminderType" AS ENUM ('APPROACHING', 'OVERDUE', 'ESCALATED');

-- CreateTable
CREATE TABLE "SlaState" (
    "id" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "lastReminderType" "SlaReminderType" NOT NULL,
    "lastSentAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SlaState_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SlaState_entityType_entityId_idx" ON "SlaState"("entityType", "entityId");

-- CreateIndex
CREATE UNIQUE INDEX "SlaState_entityType_entityId_lastReminderType_key" ON "SlaState"("entityType", "entityId", "lastReminderType");
