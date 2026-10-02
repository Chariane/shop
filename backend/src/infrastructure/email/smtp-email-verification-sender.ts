import nodemailer from 'nodemailer';

import { env } from '../config/environment';
import type { EmailVerificationSender } from '../../domain/repositories';

export class SmtpEmailVerificationSender implements EmailVerificationSender {
  isConfigured(): boolean {
    return Boolean(env.mailServer && env.mailPort && env.mailUsername && env.mailPassword && env.mailFrom);
  }

  async sendVerificationCode(email: string, code: string, expiresInMinutes: number): Promise<void> {
    if (!this.isConfigured()) throw new Error('Configuration SMTP incomplète.');

    const transporter = nodemailer.createTransport({
      host: env.mailServer,
      port: env.mailPort,
      secure: env.mailSecure || env.mailPort === 465,
      requireTLS: env.mailStartTls,
      auth: { user: env.mailUsername!, pass: env.mailPassword! },
    });

    try {
      await transporter.sendMail({
        from: env.mailFrom,
        to: email,
        subject: 'Votre code de vérification ShopHub',
        text: `Votre code ShopHub est ${code}. Il expire dans ${expiresInMinutes} minutes. Si vous n’êtes pas à l’origine de cette demande, ignorez ce message.`,
        html: `<div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;color:#17202a"><h1>Vérifiez votre adresse email</h1><p>Saisissez ce code dans ShopHub pour confirmer que cette adresse vous appartient :</p><p style="font-size:32px;font-weight:700;letter-spacing:8px;padding:16px;background:#f2f5f4;display:inline-block">${code}</p><p>Ce code expire dans ${expiresInMinutes} minutes. Si vous n’êtes pas à l’origine de cette demande, ignorez ce message.</p></div>`,
      });
    } finally {
      transporter.close();
    }
  }
}
