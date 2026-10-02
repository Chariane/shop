import { ApplicationError } from '../domain/errors';
import type { CatalogRepository } from '../domain/repositories';
import type { NewProduct, ProductFilter } from '../domain/models';

export class CatalogUseCases {
  constructor(private readonly catalog: CatalogRepository) {}

  listProducts(filter: ProductFilter) {
    return this.catalog.listProducts(filter);
  }

  async getProduct(id: string) {
    const product = await this.catalog.findProduct(id);
    if (!product || !product.isActive) throw new ApplicationError('NOT_FOUND', 'Produit introuvable.');
    return product;
  }

  listVendors() {
    return this.catalog.listVendors();
  }

  async getVendor(id: string) {
    const vendor = await this.catalog.findVendor(id);
    if (!vendor) throw new ApplicationError('NOT_FOUND', 'Boutique introuvable.');
    return vendor;
  }

  async updateProduct(userId: string, productId: string, input: NewProduct) {
    if (!input.name.trim() || !input.imageUrl.trim() || !input.category.trim() || input.price <= 0 || !Number.isInteger(input.price)) {
      throw new ApplicationError('VALIDATION', 'Nom, prix positif, image et catégorie sont requis.');
    }
    return this.catalog.updateProduct(userId, productId, input);
  }

  async createProduct(userId: string, input: NewProduct) {
    if (!input.name.trim() || !input.imageUrl.trim() || !input.category.trim() || input.price <= 0 || !Number.isInteger(input.price)) {
      throw new ApplicationError('VALIDATION', 'Nom, prix positif, image et catégorie sont requis.');
    }
    return this.catalog.createProduct(userId, input);
  }
}
