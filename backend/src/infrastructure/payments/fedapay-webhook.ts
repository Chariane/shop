import { createHmac, timingSafeEqual } from 'node:crypto';

export function verifyFedaPayWebhook(
  payload: Buffer,
  signatureHeader: string | undefined,
  secret: string | undefined,
  now = Date.now(),
): boolean {
  if (!secret || !signatureHeader) return false;
  const entries = new Map(signatureHeader.split(',').map((part) => {
    const separator = part.indexOf('=');
    return separator < 0 ? ['', ''] : [part.slice(0, separator).trim(), part.slice(separator + 1).trim()];
  }));
  const timestamp = Number(entries.get('t'));
  const signature = entries.get('s') ?? '';
  if (!Number.isInteger(timestamp) || Math.abs(Math.floor(now / 1000) - timestamp) > 300) return false;
  if (!/^[a-f0-9]{64}$/i.test(signature)) return false;
  const expected = createHmac('sha256', secret)
    .update(String(timestamp) + '.' + payload.toString('utf8'))
    .digest();
  const received = Buffer.from(signature, 'hex');
  return received.length === expected.length && timingSafeEqual(received, expected);
}

export function getFedaPayTransactionEvent(event: unknown): { name: string; transactionId: string } | null {
  if (!event || typeof event !== 'object' || Array.isArray(event)) return null;
  const record = event as Record<string, unknown>;
  const name = typeof record.name === 'string' ? record.name : typeof record.type === 'string' ? record.type : '';
  if (!name.startsWith('transaction.')) return null;

  const entity = record.entity && typeof record.entity === 'object' ? record.entity as Record<string, unknown> : null;
  const object = record.object && typeof record.object === 'object' ? record.object as Record<string, unknown> : null;
  const data = record.data && typeof record.data === 'object' ? record.data as Record<string, unknown> : null;
  const dataObject = data?.object && typeof data.object === 'object' ? data.object as Record<string, unknown> : null;
  const candidates = [record.object_id, entity?.id, object?.id, data?.object_id, dataObject?.id];
  const id = candidates.find((candidate) => typeof candidate === 'string' || typeof candidate === 'number');
  return id === undefined ? null : { name, transactionId: String(id) };
}
