import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';

import { ApplicationError } from '../domain/errors';
import type { AuthRepository, EmailVerificationSender, PasswordHasher, RefreshTokenCodec, AccessTokenService } from '../domain/repositories';
import type { UserProfile } from '../domain/models';

export interface Session {
  accessToken: string;
  refreshToken: string;
  user: UserProfile;
}

export class AuthUseCases {
  constructor(
    private readonly users: AuthRepository,
    private readonly passwords: PasswordHasher,
    private readonly tokens: AccessTokenService & RefreshTokenCodec,
    private readonly emailSender: EmailVerificationSender,
    private readonly verificationSecret: string,
  ) {}

  private static readonly verificationMinutes = 10;
  private static readonly resendCooldownMs = 60_000;
  private static readonly maxVerificationAttempts = 5;

  async register(input: {
    name: string;
    email: string;
    password: string;
    role: 'client' | 'vendor';
    shopName?: string;
    shopTagline?: string;
    shopDescription?: string;
    shopCity?: string;
    shopCountry?: string;
    shopCategories?: string[];
    avatarUrl?: string;
  }): Promise<{ email: string; verificationRequired: true }> {
    if (!input.name.trim() || !this.isEmail(input.email) || input.password.length < 8) {
      throw new ApplicationError('VALIDATION', 'Nom, email valide et mot de passe de 8 caractères minimum requis.');
    }
    const email = input.email.trim().toLowerCase();
    if (input.role === 'vendor' && !input.shopName?.trim()) {
      throw new ApplicationError('VALIDATION', 'Le nom de la boutique est requis pour un vendeur.');
    }
    if (!this.emailSender.isConfigured()) {
      throw new ApplicationError('SERVICE_UNAVAILABLE', 'La vérification email n’est pas configurée sur le serveur.');
    }

    const existing = await this.users.findUserByEmail(email);
    if (existing?.emailVerified) {
      throw new ApplicationError('CONFLICT', 'Un compte utilise déjà cet email.');
    }
    if (existing) {
      await this.sendVerificationCode(email);
      return { email, verificationRequired: true };
    }

    await this.users.createUser({
      name: input.name.trim(),
      email,
      passwordHash: await this.passwords.hash(input.password),
      role: input.role,
      avatarUrl: input.avatarUrl?.trim() || null,
      vendor: input.role === 'vendor'
        ? {
            shopName: input.shopName!.trim(),
            shopTagline: input.shopTagline,
            shopDescription: input.shopDescription,
            shopCity: input.shopCity?.trim() || 'Cotonou',
            shopCountry: input.shopCountry?.trim() || 'Bénin',
            categories: input.shopCategories ?? [],
          }
        : undefined,
    });
    await this.sendVerificationCode(email);
    return { email, verificationRequired: true };
  }

  async resendVerification(emailInput: string): Promise<void> {
    const email = emailInput.trim().toLowerCase();
    if (!this.isEmail(email)) return;
    const user = await this.users.findUserByEmail(email);
    if (!user || user.emailVerified) return;
    if (!this.emailSender.isConfigured()) {
      throw new ApplicationError('SERVICE_UNAVAILABLE', 'La vérification email n’est pas configurée sur le serveur.');
    }
    await this.sendVerificationCode(email);
  }

  async verifyEmail(emailInput: string, code: string): Promise<Session> {
    const email = emailInput.trim().toLowerCase();
    if (!this.isEmail(email) || !/^\d{6}$/.test(code)) {
      throw new ApplicationError('VALIDATION', 'Adresse email ou code invalide.');
    }
    const challenge = await this.users.findEmailVerification(email);
    const now = new Date();
    if (!challenge || challenge.expiresAt <= now || challenge.attempts >= AuthUseCases.maxVerificationAttempts) {
      throw new ApplicationError('VALIDATION', 'Code invalide ou expiré. Demandez un nouveau code.');
    }
    const codeHash = this.hashVerificationCode(email, code);
    if (!timingSafeEqual(Buffer.from(codeHash), Buffer.from(challenge.codeHash))) {
      await this.users.incrementEmailVerificationAttempts(email);
      throw new ApplicationError('VALIDATION', 'Code incorrect. Vérifiez le message reçu et réessayez.');
    }
    if (!await this.users.completeEmailVerification(email, codeHash, now)) {
      throw new ApplicationError('VALIDATION', 'Code invalide ou expiré. Demandez un nouveau code.');
    }
    const user = await this.users.findUserByEmail(email);
    if (!user) throw new ApplicationError('UNAUTHORIZED', 'Compte introuvable.');
    return this.issueSession(user.profile);
  }

  private async sendVerificationCode(email: string): Promise<void> {
    const now = new Date();
    const current = await this.users.findEmailVerification(email);
    if (current && now.getTime() - current.sentAt.getTime() < AuthUseCases.resendCooldownMs) return;

    const code = String(randomInt(100_000, 1_000_000));
    await this.users.saveEmailVerification({
      email,
      codeHash: this.hashVerificationCode(email, code),
      expiresAt: new Date(now.getTime() + AuthUseCases.verificationMinutes * 60_000),
      sentAt: now,
    });
    try {
      await this.emailSender.sendVerificationCode(email, code, AuthUseCases.verificationMinutes);
    } catch {
      await this.users.deleteEmailVerification(email);
      throw new ApplicationError('SERVICE_UNAVAILABLE', 'Impossible d’envoyer le code pour le moment. Vérifiez la configuration email puis réessayez.');
    }
  }

  private hashVerificationCode(email: string, code: string): string {
    return createHmac('sha256', this.verificationSecret).update(email + ':' + code).digest('hex');
  }

  async login(emailInput: string, password: string): Promise<Session> {
    const email = emailInput.trim().toLowerCase();
    const found = await this.users.findUserByEmail(email);
    if (!found || !(await this.passwords.verify(password, found.passwordHash))) {
      throw new ApplicationError('UNAUTHORIZED', 'Email ou mot de passe incorrect.');
    }
    if (!found.emailVerified) {
      throw new ApplicationError('FORBIDDEN', 'Confirmez votre adresse email avant de vous connecter.');
    }
    return this.issueSession(found.profile);
  }

  async refresh(refreshToken: string): Promise<Session> {
    if (!refreshToken) throw new ApplicationError('UNAUTHORIZED', 'Refresh token requis.');
    let payload: { userId: string; role: string };
    try {
      payload = this.tokens.verifyRefreshToken(refreshToken);
    } catch {
      throw new ApplicationError('UNAUTHORIZED', 'Refresh token invalide ou expiré.');
    }

    const tokenHash = this.tokens.hash(refreshToken);
    const stored = await this.users.findRefreshToken(tokenHash);
    if (
      !stored ||
      stored.userId !== payload.userId ||
      stored.revokedAt ||
      stored.expiresAt <= new Date()
    ) {
      throw new ApplicationError('UNAUTHORIZED', 'Refresh token révoqué ou expiré.');
    }

    await this.users.revokeRefreshToken(tokenHash, new Date());
    const user = await this.users.findUserById(payload.userId);
    if (!user) throw new ApplicationError('UNAUTHORIZED', 'Utilisateur introuvable.');
    return this.issueSession(user);
  }

  async logout(refreshToken?: string): Promise<void> {
    if (refreshToken) {
      await this.users.revokeRefreshToken(this.tokens.hash(refreshToken), new Date());
    }
  }

  async getCurrentUser(userId: string): Promise<UserProfile> {
    const user = await this.users.findUserById(userId);
    if (!user) throw new ApplicationError('UNAUTHORIZED', 'Utilisateur introuvable.');
    return user;
  }

  async updateProfile(userId: string, input: {
    name: string;
    email: string;
    avatarUrl: string | null;
  }): Promise<UserProfile> {
    const name = input.name.trim();
    const email = input.email.trim().toLowerCase();
    if (!name || !this.isEmail(email)) {
      throw new ApplicationError('VALIDATION', 'Nom et adresse email valides requis.');
    }
    const current = await this.users.findUserById(userId);
    if (current && current.email !== email) {
      throw new ApplicationError('VALIDATION', 'La modification de l’email nécessite une nouvelle vérification.');
    }
    const existing = await this.users.findUserByEmail(email);
    if (existing && existing.profile.id !== userId) {
      throw new ApplicationError('CONFLICT', 'Un compte utilise déjà cet email.');
    }
    return this.users.updateUserProfile(userId, {
      name,
      email,
      avatarUrl: input.avatarUrl?.trim() || null,
    });
  }

  async updateVendorProfile(userId: string, input: {
    shopName: string;
    shopTagline: string | null;
    shopDescription: string | null;
    shopBannerUrl: string | null;
    shopCity: string | null;
    shopCountry: string | null;
    categories: string[];
  }): Promise<UserProfile> {
    if (!input.shopName.trim()) {
      throw new ApplicationError('VALIDATION', 'Le nom de la boutique est obligatoire.');
    }
    const user = await this.users.findUserById(userId);
    if (!user || user.role !== 'vendor') {
      throw new ApplicationError('FORBIDDEN', 'Profil vendeur introuvable.');
    }
    return this.users.updateVendorProfile(userId, {
      ...input,
      shopName: input.shopName.trim(),
      shopTagline: input.shopTagline?.trim() || null,
      shopDescription: input.shopDescription?.trim() || null,
      shopBannerUrl: input.shopBannerUrl?.trim() || null,
      shopCity: input.shopCity?.trim() || null,
      shopCountry: input.shopCountry?.trim() || null,
      categories: input.categories.map((value) => value.trim()).filter(Boolean),
    });
  }

  private async issueSession(user: UserProfile): Promise<Session> {
    const accessToken = this.tokens.issueAccessToken(user);
    const refreshToken = this.tokens.issueRefreshToken(user);
    await this.users.createRefreshToken({
      tokenHash: this.tokens.hash(refreshToken),
      userId: user.id,
      expiresAt: this.tokens.expiresAt(),
    });
    return { accessToken, refreshToken, user };
  }

  private isEmail(value: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  }
}
