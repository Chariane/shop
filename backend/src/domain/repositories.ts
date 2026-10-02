import type {
  CartLine,
  DeliveryAddress,
  NewProduct,
  NewVendorProfile,
  OrderView,
  ProductFilter,
  ProductView,
  ShopReviewView,
  UserProfile,
  VendorView,
} from './models';

export interface EmailVerificationSender {
  isConfigured(): boolean;
  sendVerificationCode(email: string, code: string, expiresInMinutes: number): Promise<void>;
}

export interface AuthRepository {
  findUserByEmail(email: string): Promise<{ profile: UserProfile; passwordHash: string; emailVerified: boolean } | null>;
  findUserById(id: string): Promise<UserProfile | null>;
  updateUserProfile(id: string, input: { name: string; email: string; avatarUrl: string | null }): Promise<UserProfile>;
  updateVendorProfile(userId: string, input: {
    shopName: string; shopTagline: string | null; shopDescription: string | null;
    shopBannerUrl: string | null; shopCity: string | null; shopCountry: string | null; categories: string[];
  }): Promise<UserProfile>;
  createUser(input: {
    name: string;
    email: string;
    passwordHash: string;
    role: 'client' | 'vendor';
    avatarUrl: string | null;
    vendor?: NewVendorProfile;
  }): Promise<UserProfile>;
  saveEmailVerification(input: { email: string; codeHash: string; expiresAt: Date; sentAt: Date }): Promise<void>;
  findEmailVerification(email: string): Promise<{ codeHash: string; attempts: number; expiresAt: Date; sentAt: Date } | null>;
  incrementEmailVerificationAttempts(email: string): Promise<void>;
  completeEmailVerification(email: string, codeHash: string, now: Date): Promise<boolean>;
  deleteEmailVerification(email: string): Promise<void>;
  createRefreshToken(input: { tokenHash: string; userId: string; expiresAt: Date }): Promise<void>;
  findRefreshToken(tokenHash: string): Promise<{
    id: string;
    userId: string;
    expiresAt: Date;
    revokedAt: Date | null;
  } | null>;
  revokeRefreshToken(tokenHash: string, revokedAt: Date): Promise<void>;
}

export interface CheckoutPaymentRecord {
  id: string;
  clientId: string;
  orderIds: string[];
  amount: number;
  amountXof: number;
  status: 'pending' | 'paid' | 'failed' | 'refunded';
  providerTransactionId: string | null;
  checkoutUrl: string | null;
}

export interface CheckoutPaymentsRepository {
  createForOrders(clientId: string, orderIds: string[]): Promise<CheckoutPaymentRecord>;
  attachProviderSession(paymentId: string, providerTransactionId: string, checkoutUrl: string): Promise<CheckoutPaymentRecord>;
  getForClient(paymentId: string, clientId: string): Promise<CheckoutPaymentRecord>;
  getByProviderTransactionId(transactionId: string): Promise<CheckoutPaymentRecord | null>;
  syncProviderStatus(paymentId: string, status: 'pending' | 'paid' | 'failed' | 'refunded'): Promise<CheckoutPaymentRecord>;
}

export interface FedaPayGateway {
  createSession(input: { amountXof: number; reference: string; customer: { name: string; email: string; phone: string } }): Promise<{ transactionId: string; checkoutUrl: string }>;
  getStatus(transactionId: string): Promise<'pending' | 'paid' | 'failed' | 'refunded'>;
}

export interface ShopReviewRepository {
  rateDeliveredOrder(input: { orderId: string; clientId: string; rating: number; comment: string | null }): Promise<ShopReviewView>;
  listForVendor(vendorId: string): Promise<ShopReviewView[]>;
}

export interface CatalogRepository {
  listProducts(filter: ProductFilter): Promise<ProductView[]>;
  findProduct(id: string): Promise<ProductView | null>;
  listVendors(): Promise<VendorView[]>;
  findVendor(id: string): Promise<VendorView | null>;
  createProduct(userId: string, input: NewProduct): Promise<ProductView>;
  updateProduct(userId: string, productId: string, input: NewProduct): Promise<ProductView>;
}

export interface OrdersRepository {
  listForUser(userId: string, role: 'client' | 'vendor'): Promise<OrderView[]>;
  placeOrder(input: {
    clientId: string;
    items: CartLine[];
    deliveryMethod: string;
    deliveryFee: number;
    address: DeliveryAddress;
  }): Promise<OrderView[]>;
  updateVendorOrderStatus(input: {
    orderId: string;
    vendorUserId: string;
    status: 'pending' | 'confirmed' | 'shipped' | 'delivered';
  }): Promise<OrderView>;
  listNotifications(userId: string): Promise<Array<{ id: string; type: string; title: string; message: string; readAt: Date | null; createdAt: Date }>>;
  markNotificationRead(userId: string, id?: string): Promise<void>;
  loyaltyPoints(userId: string): Promise<number>;
}

export interface PasswordHasher {
  hash(password: string): Promise<string>;
  verify(password: string, hash: string): Promise<boolean>;
}

export interface RefreshTokenCodec {
  hash(token: string): string;
  expiresAt(): Date;
}

export interface AccessTokenService {
  issueAccessToken(user: Pick<UserProfile, 'id' | 'role'>): string;
  issueRefreshToken(user: Pick<UserProfile, 'id' | 'role'>): string;
  verifyRefreshToken(token: string): { userId: string; role: string };
}

