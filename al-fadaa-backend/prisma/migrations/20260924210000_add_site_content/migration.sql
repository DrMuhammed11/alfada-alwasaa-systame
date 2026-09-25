-- CreateTable
CREATE TABLE "public"."SiteService" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "titleAr" TEXT NOT NULL,
    "titleEn" TEXT NOT NULL,
    "shortAr" TEXT,
    "shortEn" TEXT,
    "fullAr" TEXT,
    "fullEn" TEXT,
    "icon" TEXT,
    "image" TEXT,
    "features" JSONB,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SiteService_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SiteSector" (
    "id" TEXT NOT NULL,
    "titleAr" TEXT NOT NULL,
    "titleEn" TEXT NOT NULL,
    "descAr" TEXT,
    "descEn" TEXT,
    "icon" TEXT,
    "services" JSONB,
    "photos" JSONB,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SiteSector_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SiteProject" (
    "id" TEXT NOT NULL,
    "titleAr" TEXT NOT NULL,
    "titleEn" TEXT NOT NULL,
    "tagAr" TEXT,
    "tagEn" TEXT,
    "scopeAr" TEXT,
    "scopeEn" TEXT,
    "metrics" JSONB,
    "image" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SiteProject_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SiteFaq" (
    "id" TEXT NOT NULL,
    "questionAr" TEXT NOT NULL,
    "questionEn" TEXT NOT NULL,
    "answerAr" TEXT NOT NULL,
    "answerEn" TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SiteFaq_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SiteSetting" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SiteSetting_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SiteService_slug_key" ON "public"."SiteService"("slug");

-- CreateIndex
CREATE INDEX "SiteService_isActive_order_idx" ON "public"."SiteService"("isActive", "order");

-- CreateIndex
CREATE INDEX "SiteSector_isActive_order_idx" ON "public"."SiteSector"("isActive", "order");

-- CreateIndex
CREATE INDEX "SiteProject_isActive_order_idx" ON "public"."SiteProject"("isActive", "order");

-- CreateIndex
CREATE INDEX "SiteFaq_isActive_order_idx" ON "public"."SiteFaq"("isActive", "order");

-- CreateIndex
CREATE UNIQUE INDEX "SiteSetting_key_key" ON "public"."SiteSetting"("key");

-- CreateIndex
CREATE INDEX "Correspondence_parentId_idx" ON "public"."Correspondence"("parentId");

-- CreateIndex
CREATE INDEX "Correspondence_updatedAt_idx" ON "public"."Correspondence"("updatedAt");

