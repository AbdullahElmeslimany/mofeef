import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';

class WishlistItemModel {
  final int id;
  final int objectId;
  final String objectModel;
  final String title;
  final String? imageUrl;
  final double price;
  final String? location;

  const WishlistItemModel({
    required this.id,
    required this.objectId,
    required this.objectModel,
    required this.title,
    this.imageUrl,
    required this.price,
    this.location,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] is Map ? json['service'] as Map<String, dynamic> : json;
    return WishlistItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      objectId: json['object_id'] is int
          ? json['object_id']
          : int.tryParse(json['object_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      objectModel: json['object_model']?.toString() ?? json['service_type']?.toString() ?? 'tour',
      title: json['title']?.toString() ?? service['title']?.toString() ?? service['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString() ?? service['image_url']?.toString() ?? service['image']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? service['price']?.toString() ?? '0') ?? 0.0,
      location: json['location'] is Map
          ? json['location']['name']?.toString()
          : json['location']?.toString() ?? (service['location'] is Map ? service['location']['name']?.toString() : service['location']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'object_id': objectId,
    'object_model': objectModel,
    'title': title,
    'image_url': imageUrl,
    'price': price,
    'location': location,
  };
}

abstract class WishlistRepository {
  Future<List<WishlistItemModel>> getWishlist();
  Future<void> addToWishlist(String serviceType, dynamic id, {WishlistItemModel? item});
  Future<void> removeFromWishlist(String serviceType, dynamic id);
}

class WishlistRepositoryImpl implements WishlistRepository {
  final Dio _dio;
  static const String _wishlistStorageKey = 'user_saved_wishlist_v2';

  WishlistRepositoryImpl(this._dio);

  @override
  Future<List<WishlistItemModel>> getWishlist() async {
    // 1. Get locally saved wishlist
    List<WishlistItemModel> localItems = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_wishlistStorageKey);
      if (savedString != null && savedString.isNotEmpty) {
        final list = jsonDecode(savedString) as List<dynamic>;
        localItems = list.map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // 2. Fetch from remote API if available
    List<WishlistItemModel> remoteItems = [];
    try {
      final response = await _dio.get(ApiEndpoints.wishlist);
      final list = ApiResponseHandler.extractList(response.data);
      remoteItems = list.map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}

    // 3. Merge & deduplicate
    final Map<String, WishlistItemModel> combined = {};
    for (final item in remoteItems) {
      combined['${item.objectModel}_${item.objectId}'] = item;
    }
    for (final item in localItems) {
      combined['${item.objectModel}_${item.objectId}'] = item;
    }

    return combined.values.toList();
  }

  @override
  Future<void> addToWishlist(String serviceType, dynamic id, {WishlistItemModel? item}) async {
    try {
      if (item != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedString = prefs.getString(_wishlistStorageKey);
        List<dynamic> list = [];
        if (savedString != null && savedString.isNotEmpty) {
          try {
            list = jsonDecode(savedString) as List<dynamic>;
          } catch (_) {}
        }
        list.removeWhere((i) => i['object_id'] == item.objectId && i['object_model'] == item.objectModel);
        list.insert(0, item.toJson());
        await prefs.setString(_wishlistStorageKey, jsonEncode(list));
      }
      await _dio.post(ApiEndpoints.addToWishlist(serviceType, id));
    } catch (_) {}
  }

  @override
  Future<void> removeFromWishlist(String serviceType, dynamic id) async {
    try {
      final idInt = int.tryParse(id.toString()) ?? 0;
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_wishlistStorageKey);
      if (savedString != null && savedString.isNotEmpty) {
        List<dynamic> list = [];
        try {
          list = jsonDecode(savedString) as List<dynamic>;
        } catch (_) {}
        list.removeWhere((i) => (i['object_id'] == idInt || i['id'] == idInt) && (serviceType.isEmpty || i['object_model'] == serviceType));
        await prefs.setString(_wishlistStorageKey, jsonEncode(list));
      }
      await _dio.delete(ApiEndpoints.removeFromWishlist(serviceType, id));
    } catch (_) {}
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepositoryImpl(ref.watch(dioProvider));
});

class WishlistState {
  final List<WishlistItemModel> items;
  final bool isLoading;

  const WishlistState({this.items = const [], this.isLoading = false});

  bool isFavorite(dynamic objectId, [String? objectModel]) {
    final idInt = int.tryParse(objectId.toString()) ?? 0;
    return items.any((i) => (i.objectId == idInt || i.id == idInt) && (objectModel == null || i.objectModel == objectModel));
  }

  WishlistState copyWith({List<WishlistItemModel>? items, bool? isLoading}) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repo;

  WishlistNotifier(this._repo) : super(const WishlistState()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true);
    final items = await _repo.getWishlist();
    state = WishlistState(items: items, isLoading: false);
  }

  Future<bool> toggleFavorite(WishlistItemModel item) async {
    final exists = state.isFavorite(item.objectId, item.objectModel);
    List<WishlistItemModel> updatedList = List.from(state.items);
    if (exists) {
      updatedList.removeWhere((i) => (i.objectId == item.objectId || i.id == item.objectId) && i.objectModel == item.objectModel);
      state = state.copyWith(items: updatedList);
      await _repo.removeFromWishlist(item.objectModel, item.objectId);
      return false; // Removed
    } else {
      updatedList.removeWhere((i) => (i.objectId == item.objectId || i.id == item.objectId) && i.objectModel == item.objectModel);
      updatedList.insert(0, item);
      state = state.copyWith(items: updatedList);
      await _repo.addToWishlist(item.objectModel, item.objectId, item: item);
      return true; // Added
    }
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
});

final wishlistItemsProvider = FutureProvider<List<WishlistItemModel>>((ref) async {
  final state = ref.watch(wishlistProvider);
  return state.items;
});
