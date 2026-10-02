import { ApplicationError } from '../../domain/errors';
import type { FedaPayGateway } from '../../domain/repositories';

export class SandboxFedaPayGateway implements FedaPayGateway {
  private readonly apiBase: string;

  constructor(private readonly secretKey: string, environment = 'sandbox') {
    if (environment !== 'sandbox' && environment !== 'live') {
      throw new Error('FEDAPAY_ENVIRONMENT doit être sandbox ou live.');
    }
    this.apiBase = environment === 'live'
      ? 'https://api.fedapay.com/v1'
      : 'https://sandbox-api.fedapay.com/v1';
    if (environment === 'live' && secretKey.startsWith('sk_sandbox_')) {
      throw new Error('Une clé FedaPay sandbox ne peut pas être utilisée en production.');
    }
    if (environment === 'sandbox' && secretKey && !secretKey.startsWith('sk_sandbox_')) {
      throw new Error('Une clé FedaPay de test est nécessaire en environnement sandbox.');
    }
  }

  private async request(path: string, init: RequestInit = {}): Promise<Record<string, unknown>> {
    if (!this.secretKey) throw new ApplicationError('SERVICE_UNAVAILABLE', 'La clé secrète FedaPay doit être configurée sur le serveur.');
    const response = await fetch(this.apiBase + path, {
      ...init,
      signal: AbortSignal.timeout(15000),
      headers: { Authorization: 'Bearer ' + this.secretKey, 'Content-Type': 'application/json', ...init.headers },
    });
    const payload: unknown = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = payload && typeof payload === 'object' && 'message' in payload
        ? String((payload as { message: unknown }).message)
        : 'FedaPay n’a pas pu traiter la demande.';
      throw new ApplicationError('UPSTREAM', message);
    }
    if (!payload || typeof payload !== 'object') throw new ApplicationError('UPSTREAM', 'Réponse FedaPay invalide.');
    return payload as Record<string, unknown>;
  }

  async createSession(input: Parameters<FedaPayGateway['createSession']>[0]) {
    const names = input.customer.name.trim().split(/\s+/);
    const created = await this.request('/transactions', {
      method: 'POST',
      body: JSON.stringify({
        description: 'ShopHub commande ' + input.reference,
        amount: input.amountXof,
        currency: { iso: 'XOF' },
        customer: {
          firstname: names[0],
          lastname: names.slice(1).join(' ') || names[0],
          email: input.customer.email,
          phone_number: { number: input.customer.phone.replace(/^\+?229/, ''), country: 'BJ' },
        },
        custom_metadata: { shophub_payment_id: input.reference },
      }),
    });
    const transaction = this.entity(created, 'v1/transaction', 'transaction');
    const transactionId = String(transaction.id ?? '');
    if (!transactionId) throw new ApplicationError('UPSTREAM', 'Identifiant FedaPay manquant.');
    const tokenResponse = await this.request('/transactions/' + encodeURIComponent(transactionId) + '/token', { method: 'POST', body: '{}' });
    const token = this.entity(tokenResponse, 'v1/token', 'token');
    const checkoutUrl = String(token.url ?? token.payment_url ?? '');
    if (!checkoutUrl.startsWith('https://')) throw new ApplicationError('UPSTREAM', 'Lien de paiement FedaPay invalide.');
    return { transactionId, checkoutUrl };
  }

  async getStatus(transactionId: string) {
    const response = await this.request('/transactions/' + encodeURIComponent(transactionId));
    const transaction = this.entity(response, 'v1/transaction', 'transaction');
    switch (String(transaction.status ?? '').toLowerCase()) {
      case 'approved': case 'transferred': return 'paid' as const;
      case 'declined': case 'canceled': return 'failed' as const;
      case 'refunded': case 'approved_partially_refunded': case 'transferred_partially_refunded': return 'refunded' as const;
      default: return 'pending' as const;
    }
  }

  private entity(payload: Record<string, unknown>, ...keys: string[]) {
    for (const key of keys) {
      const value = payload[key];
      if (value && typeof value === 'object') return value as Record<string, unknown>;
    }
    return payload;
  }
}
