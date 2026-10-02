import 'dotenv/config';

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`La variable d'environnement ${name} est obligatoire.`);
  return value;
}

const fedapayEnvironment = process.env.FEDAPAY_ENVIRONMENT ?? 'sandbox';

export const env = {
  port: Number(process.env.PORT ?? 3000),
  databaseUrl: process.env.DATABASE_URL,
  accessSecret: required('JWT_ACCESS_SECRET'),
  refreshSecret: required('JWT_REFRESH_SECRET'),
  accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '7d',
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  mailServer: process.env.MAIL_SERVER,
  mailPort: Number(process.env.MAIL_PORT ?? 587),
  mailUsername: process.env.MAIL_USERNAME,
  mailPassword: process.env.MAIL_PASSWORD,
  mailFrom: process.env.MAIL_FROM,
  mailSecure: /^(1|true|yes)$/i.test(process.env.MAIL_SSL_TLS ?? process.env.MAIL_SSL ?? ''),
  mailStartTls: /^(1|true|yes)$/i.test(process.env.MAIL_STARTTLS ?? ''),
  fedapaySecretKey: fedapayEnvironment === 'live'
    ? process.env.FEDAPAY_LIVE_SECRET_KEY ?? process.env.FEDAPAY_SECRET_KEY
    : process.env.FEDAPAY_SANDBOX_SECRET_KEY ?? process.env.FEDAPAY_SECRET_KEY,
  fedapayEnvironment,
  fedapayWebhookSecret: process.env.FEDAPAY_WEBHOOK_SECRET,
};
