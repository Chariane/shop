import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'mocks/products_mock.dart';
import 'mocks/vendors_mock.dart';
import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/storage/api_cache_store.dart';
import '../mappers/product_mapper.dart';
import '../mappers/user_mapper.dart';
import 'package:shophub/domain/entities/app_user.dart';
import 'package:shophub/domain/entities/product.dart';

class MarketplaceApi {
  final Dio _dio;
  final ApiCacheStore _cache;

  const MarketplaceApi(this._dio, this._cache);

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products');
      final rows = (response.data?['products'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      await _cache.writeList('products', rows);
      return rows.map(productFromJson).toList();
    } on DioException {
      final cached = await _cache.readList('products');
      if (cached != null && cached.isNotEmpty) {
        return cached.map(productFromJson).toList();
      }
      return ProductsMock.generate();
    }
  }

  Future<List<String>> uploadProductImages(List<XFile> files) async {
    if (files.isEmpty) return const [];
    final images = <Map<String, String>>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const AppException("Chaque image doit faire 5 Mo maximum.");
      }
      images.add({'name': file.name, 'data': base64Encode(bytes)});
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>('/uploads/images',
          data: {'images': images});
      return (response.data?['images'] as List<dynamic>? ?? const [])
          .cast<String>();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<String> uploadProfileImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const AppException('La photo doit faire 5 Mo maximum.');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/uploads/profile-image',
        data: {
          'image': {'name': file.name, 'data': base64Encode(bytes)}
        },
      );
      final image = response.data?['image'];
      if (image is! String) throw const AppException('Réponse image invalide.');
      return image;
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<Product> saveProduct(Product product, {required bool isNew}) async {
    final data = {
      'name': product.name,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'gallery': product.gallery,
      'category': product.category,
      'shortDescription': product.shortDescription,
      'longDescription': product.longDescription,
      'originalPrice': product.originalPrice,
      'stock': product.stock,
      'freeShipping': product.freeShipping,
      'warrantyMonths': product.warrantyMonths,
      'isActive': product.isActive,
      'tags': product.tags,
      'specifications': product.specifications,
    };
    try {
      final response = isNew
          ? await _dio.post<Map<String, dynamic>>('/products', data: data)
          : await _dio.patch<Map<String, dynamic>>('/products/${product.id}',
              data: data);
      final rawProduct = response.data?['product'];
      if (rawProduct is! Map)
        throw const AppException('Réponse produit invalide.');
      final saved = productFromJson(Map<String, dynamic>.from(rawProduct));
      final rows =
          await _cache.readList('products') ?? const <Map<String, dynamic>>[];
      final next = [
        productToJson(saved),
        ...rows.where((row) => row['id'] != saved.id)
      ];
      await _cache.writeList('products', next);
      return saved;
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<List<AppUser>> fetchVendors() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/vendors');
      final rows = (response.data?['vendors'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      await _cache.writeList('vendors', rows);
      return rows.map(userFromJson).toList();
    } on DioException {
      final cached = await _cache.readList('vendors');
      if (cached != null && cached.isNotEmpty) {
        return cached.map(userFromJson).toList();
      }
      return VendorsMock.all;
    }
  }
}
