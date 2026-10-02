export type UserRole = 'client' | 'vendor';
export type OrderStatus = 'pending' | 'confirmed' | 'shipped' | 'delivered';

export interface VendorProfile {
  id: string;
  userId: string;
  shopName: string;
  shopTagline: string | null;
  shopDescription: string | null;
  shopBannerUrl: string | null;
  shopCity: string | null;
  shopCountry: string | null;
  shopCategoriesJson: string;
  isVerified: boolean;
  shopSales: number;
  shopRating: number;
  shopReviewCount: number;
  shopResponseMinutes: number;
  shopFoundedYear: number | null;
  productCount: number;
}

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatarUrl: string | null;
  createdAt: Date;
  vendorProfile: VendorProfile | null;
}

export interface ProductView {
  id: string;
  vendorId: string;
  vendorName: string;
  name: string;
  shortDescription: string;
  longDescription: string;
  price: number;
  originalPrice: number | null;
  imageUrl: string;
  gallery: string[];
  category: string;
  tagsJson: string;
  specificationsJson: string;
  rating: number;
  reviewCount: number;
  stock: number;
  isActive: boolean;
  freeShipping: boolean;
  warrantyMonths: number;
  createdAt: Date;
}

export interface VendorView extends UserProfile {
  vendorProfile: VendorProfile;
}

export interface OrderItemView {
  productId: string;
  productName: string;
  imageUrl: string;
  unitPrice: number;
  quantity: number;
  stock: number;
  productCreatedAt: Date;
}

export interface ShopReviewView {
  id: string;
  orderId: string;
  vendorId: string;
  clientName: string;
  rating: number;
  comment: string | null;
  createdAt: Date;
}

export interface OrderView {
  id: string;
  clientId: string;
  clientName: string;
  vendorId: string;
  vendorName: string;
  status: OrderStatus;
  paymentStatus: 'pending' | 'paid' | 'failed' | 'refunded' | 'not_required';
  paymentId: string | null;
  total: number;
  deliveryMethod: string;
  deliveryFee: number;
  shopReview: { rating: number; comment: string | null } | null;
  deliveryAddress: {
    fullName: string;
    phone: string;
    street: string;
    city: string;
    country: string;
  };
  items: OrderItemView[];
  createdAt: Date;
}

export interface ProductFilter {
  category?: string;
  query?: string;
}

export interface NewVendorProfile {
  shopName: string;
  shopTagline?: string | null;
  shopDescription?: string | null;
  shopCity: string;
  shopCountry: string;
  categories: string[];
}

export interface NewProduct {
  name: string;
  price: number;
  imageUrl: string;
  gallery: string[];
  category: string;
  shortDescription: string;
  longDescription: string;
  originalPrice?: number | null;
  stock: number;
  freeShipping: boolean;
  warrantyMonths: number;
  isActive?: boolean;
  tags: string[];
  specifications: Record<string, string>;
}

export interface DeliveryAddress {
  fullName: string;
  phone: string;
  street: string;
  city: string;
  country: string;
}

export interface CartLine {
  productId: string;
  quantity: number;
}
