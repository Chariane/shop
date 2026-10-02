import { ApplicationError } from '../domain/errors';
import type { CheckoutPaymentsRepository, FedaPayGateway } from '../domain/repositories';

export class CheckoutPaymentUseCases {
  constructor(
    private readonly payments: CheckoutPaymentsRepository,
    private readonly gateway: FedaPayGateway,
  ) {}

  async start(input: { clientId: string; orderIds: string[]; name: string; email: string; phone: string }) {
    if (!input.orderIds.length || !input.name.trim() || !input.email.trim() || !input.phone.trim()) {
      throw new ApplicationError('VALIDATION', 'Les informations de paiement sont incomplètes.');
    }
    const payment = await this.payments.createForOrders(input.clientId, input.orderIds);
    try {
      const session = await this.gateway.createSession({
        amountXof: payment.amountXof,
        reference: payment.id,
        customer: { name: input.name.trim(), email: input.email.trim(), phone: input.phone.trim() },
      });
      return this.payments.attachProviderSession(payment.id, session.transactionId, session.checkoutUrl);
    } catch (error) {
      await this.payments.syncProviderStatus(payment.id, 'failed');
      throw error;
    }
  }

  async processProviderEvent(transactionId: string) {
    const payment = await this.payments.getByProviderTransactionId(transactionId);
    if (!payment) return false;
    const status = await this.gateway.getStatus(transactionId);
    await this.payments.syncProviderStatus(payment.id, status);
    return true;
  }

  async refresh(paymentId: string, clientId: string) {
    const payment = await this.payments.getForClient(paymentId, clientId);
    if (!payment.providerTransactionId) throw new ApplicationError('CONFLICT', 'La session de paiement n’est pas encore initialisée.');
    const status = await this.gateway.getStatus(payment.providerTransactionId);
    return this.payments.syncProviderStatus(payment.id, status);
  }
}
