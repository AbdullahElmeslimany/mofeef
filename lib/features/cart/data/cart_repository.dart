import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../shop/models/product_model.dart';

class CartStateModel {
  final List<ProductModel> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? couponCode;

  int get itemCount => items.length;
  int get totalPieces => items.fold<int>(0, (sum, i) => sum + (i.quantity > 0 ? i.quantity : 1));

  const CartStateModel({
    this.items = const [],
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.couponCode,
  });

  CartStateModel copyWith({
    List<ProductModel>? items,
    double? subtotal,
    double? discount,
    double? total,
    String? couponCode,
  }) {
    return CartStateModel(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      couponCode: couponCode ?? this.couponCode,
    );
  }
}

class CartNotifier extends StateNotifier<CartStateModel> {
  final Dio _dio;

  CartNotifier(this._dio) : super(const CartStateModel()) {
    fetchCart();
  }

  Future<void> fetchCart() async {
    try {
      final response = await _dio.get(ApiEndpoints.cart);
      final data = response.data;
      if (data is Map && data['items'] is List) {
        final list = (data['items'] as List).map((e) {
          final m = e as Map<String, dynamic>;
          return ProductModel(
            id: m['id']?.toString() ?? '0',
            title: m['name']?.toString() ?? '',
            category: 'هدايا وتذكارات',
            storeName: 'متجر الهدايا',
            price: '${m['price'] ?? 0} ﷼',
            priceNumeric: double.tryParse(m['price']?.toString() ?? '0') ?? 0.0,
            originalPrice: '${m['price'] ?? 0} ﷼',
            rating: 5.0,
            reviewsCount: 10,
            imageUrl: m['image_url']?.toString() ?? '',
            description: '',
          );
        }).toList();

        final subtotal = double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0.0;
        final discount = double.tryParse(data['discount']?.toString() ?? '0') ?? 0.0;
        final total = double.tryParse(data['total']?.toString() ?? '0') ?? subtotal - discount;

        state = CartStateModel(
          items: list,
          subtotal: subtotal,
          discount: discount,
          total: total,
        );
      }
    } catch (_) {
      // Keep local state if server is offline
    }
  }

  Future<void> addItem(ProductModel product) async {
    final updated = [...state.items, product];
    final subtotal = updated.fold<double>(0, (sum, i) => sum + i.priceNumeric);
    final total = subtotal - state.discount;
    state = state.copyWith(items: updated, subtotal: subtotal, total: total);

    try {
      await _dio.post(
        ApiEndpoints.cart,
        data: {'id': product.id, 'qty': 1},
      );
    } catch (_) {}
  }

  Future<void> removeItem(int index) async {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    final updated = List<ProductModel>.from(state.items)..removeAt(index);
    final subtotal = updated.fold<double>(0, (sum, i) => sum + (i.priceNumeric * (i.quantity > 0 ? i.quantity : 1)));
    final total = (subtotal - state.discount).clamp(0.0, double.infinity);
    state = state.copyWith(items: updated, subtotal: subtotal, total: total);

    try {
      await _dio.post(
        ApiEndpoints.removeCartItem,
        data: {'id': item.id},
      );
    } catch (_) {}
  }

  void updateQuantity(int index, int delta) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    final currentQty = item.quantity > 0 ? item.quantity : 1;
    final newQty = currentQty + delta;
    if (newQty <= 0) {
      removeItem(index);
      return;
    }
    final updatedItem = item.copyWith(quantity: newQty);
    final updated = List<ProductModel>.from(state.items);
    updated[index] = updatedItem;
    final subtotal = updated.fold<double>(0, (sum, i) => sum + (i.priceNumeric * (i.quantity > 0 ? i.quantity : 1)));
    final total = (subtotal - state.discount).clamp(0.0, double.infinity);
    state = state.copyWith(items: updated, subtotal: subtotal, total: total);
  }

  Future<bool> applyCoupon(String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.applyCoupon,
        data: {'coupon_code': code},
      );
      final discount = double.tryParse(response.data['discount']?.toString() ?? '0') ?? (state.subtotal * 0.1);
      final total = state.subtotal - discount;
      state = state.copyWith(couponCode: code, discount: discount, total: total);
      return true;
    } catch (e) {
      // Fallback 10% coupon validation
      final discount = state.subtotal * 0.1;
      final total = state.subtotal - discount;
      state = state.copyWith(couponCode: code, discount: discount, total: total);
      return true;
    }
  }

  void clearCart() {
    state = const CartStateModel();
  }
}

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartStateModel>((ref) {
  return CartNotifier(ref.watch(dioProvider));
});
