CREATE TABLE "CheckoutPayment" (
    "id" TEXT NOT NULL,
    "clientId" TEXT NOT NULL,
    "orderIdsJson" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "amountXof" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'XOF',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "providerTransactionId" TEXT,
    "checkoutUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CheckoutPayment_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "CheckoutPayment_providerTransactionId_key" ON "CheckoutPayment"("providerTransactionId");
CREATE INDEX "CheckoutPayment_clientId_createdAt_idx" ON "CheckoutPayment"("clientId", "createdAt");
ALTER TABLE "Order" ADD COLUMN "paymentStatus" TEXT NOT NULL DEFAULT 'not_required';
ALTER TABLE "Order" ADD COLUMN "checkoutPaymentId" TEXT;
ALTER TABLE "CheckoutPayment" ADD CONSTRAINT "CheckoutPayment_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Order" ADD CONSTRAINT "Order_checkoutPaymentId_fkey" FOREIGN KEY ("checkoutPaymentId") REFERENCES "CheckoutPayment"("id") ON DELETE SET NULL ON UPDATE CASCADE;
