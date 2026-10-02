-- CreateTable
CREATE TABLE "PlatformConfig" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "categoriesJson" TEXT NOT NULL DEFAULT '[]',
    "featuredSlidesJson" TEXT NOT NULL DEFAULT '[]',
    "deliveryOptionsJson" TEXT NOT NULL DEFAULT '[]',
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlatformConfig_pkey" PRIMARY KEY ("id")
);
