import '../../../../core/utils/html_utils.dart';

class ProductSpecification {
  final String title;
  final String content;

  const ProductSpecification({
    required this.title,
    required this.content,
  });

  factory ProductSpecification.fromJson(Map<String, dynamic> json) {
    return ProductSpecification(
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}

class ProductModel {
  final String id;
  final String title;
  final String category;
  final String storeName;
  final String price;
  final double priceNumeric;
  final String originalPrice;
  final String? discountPercent;
  final double rating;
  final int reviewsCount;
  final String imageUrl;
  final String description;
  final String? sku;
  final String? stockStatus;
  final bool inStock;
  final int quantity;
  final List<String> gallery;
  final List<ProductSpecification> specifications;
  final List<ProductModel> related;

  const ProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.storeName,
    required this.price,
    required this.priceNumeric,
    required this.originalPrice,
    this.discountPercent,
    required this.rating,
    required this.reviewsCount,
    required this.imageUrl,
    required this.description,
    this.sku,
    this.stockStatus,
    this.inStock = true,
    this.quantity = 10,
    this.gallery = const [],
    this.specifications = const [],
    this.related = const [],
  });

  ProductModel copyWith({
    String? id,
    String? title,
    String? category,
    String? storeName,
    String? price,
    double? priceNumeric,
    String? originalPrice,
    String? discountPercent,
    double? rating,
    int? reviewsCount,
    String? imageUrl,
    String? description,
    String? sku,
    String? stockStatus,
    bool? inStock,
    int? quantity,
    List<String>? gallery,
    List<ProductSpecification>? specifications,
    List<ProductModel>? related,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      priceNumeric: priceNumeric ?? this.priceNumeric,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      stockStatus: stockStatus ?? this.stockStatus,
      inStock: inStock ?? this.inStock,
      quantity: quantity ?? this.quantity,
      gallery: gallery ?? this.gallery,
      specifications: specifications ?? this.specifications,
      related: related ?? this.related,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['sale_price'] ?? json['price'] ?? 0;
    final rawOriginPrice = json['price'] ?? json['origin_price'] ?? rawPrice;
    final numPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    final numOrigin = double.tryParse(rawOriginPrice.toString()) ?? numPrice;

    final displayPrice =
        json['display_price']?.toString() ?? '${numPrice.toStringAsFixed(0)} ﷼';
    final displayOrigin = json['display_regular_price']?.toString() ??
        '${numOrigin.toStringAsFixed(0)} ﷼';

    // Parse specifications
    List<ProductSpecification> specs = [];
    if (json['specifications'] is List) {
      specs = (json['specifications'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductSpecification.fromJson(e))
          .toList();
    }

    // Parse gallery
    List<String> gal = [];
    if (json['gallery'] is List) {
      gal = (json['gallery'] as List)
          .map((e) => e is Map
              ? e['large']?.toString() ?? e['thumb']?.toString()
              : e.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Parse related
    List<ProductModel> rel = [];
    if (json['related'] is List) {
      rel = (json['related'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductModel.fromJson(e))
          .toList();
    }

    // Rating
    double parsedRating = 5.0;
    int parsedReviews = 10;
    if (json['review_score'] is Map) {
      parsedRating = double.tryParse(
              json['review_score']['score_total']?.toString() ?? '5') ??
          5.0;
      parsedReviews = int.tryParse(
              json['review_score']['total_review']?.toString() ?? '0') ??
          0;
      if (parsedRating == 0) parsedRating = 5.0;
    } else if (json['review_score'] != null) {
      parsedRating = double.tryParse(json['review_score'].toString()) ?? 5.0;
    }

    final titleStr =
        json['title']?.toString() ?? json['name']?.toString() ?? '';
    String? rawImg = json['image_url']?.toString() ?? json['image']?.toString();
    if (rawImg != null &&
        (rawImg.isEmpty || rawImg.contains('127.0.0.1') || rawImg == 'null')) {
      rawImg = null;
    }

    String chosenImg;
    if (rawImg != null &&
        rawImg.isNotEmpty &&
        !rawImg.contains('via.placeholder')) {
      chosenImg = rawImg;
    } else if (gal.isNotEmpty) {
      chosenImg = gal.first;
    } else if (titleStr.contains('تمر') || titleStr.contains('عجوة')) {
      chosenImg =
          'https://staging.modeef-e.com/uploads/0000/6/2026/06/13/59d5a114-b797-46a0-ab4b-105e3d06f637.jpg';
    } else if (titleStr.contains('عسل') || titleStr.contains('سدرة')) {
      chosenImg =
          'https://staging.modeef-e.com/uploads/0000/6/2026/06/13/e1cca3ea-806b-4c5b-8cd4-fd5ce5135344.jpg';
    } else if (titleStr.contains('مبخرة') || titleStr.contains('بخور')) {
      chosenImg =
          'https://img-1.kwcdn.com/product/open/5cd147b6fecf4561bbaf3b0ca50ea400-goods.jpeg?imageView2/2/w/500/q/80/format/avif';
    } else if (titleStr.contains('مسك') || titleStr.contains('عطر')) {
      chosenImg =
          'https://elghazawy.b-cdn.net/158392/AL-FARES-MUSK-ABIYEDH-EDP-100ML.webp';
    } else if (titleStr.contains('تيشرت') || titleStr.contains('قميص')) {
      chosenImg = 'https://i.postimg.cc/VNwWgdkz/tshert.png';
    } else if (titleStr.contains('مجسم') ||
        titleStr.contains('الواجهه') ||
        titleStr.contains('الواجهة')) {
      chosenImg =
          'https://www.gazzaz.com.sa/cdn/shop/files/422514727043_2.jpg?v=1692605588&width=1780';
    } else if (titleStr.contains('باب الكعب') ||
        titleStr.contains('باب الكعبة')) {
      chosenImg =
          'https://www.gazzaz.com.sa/cdn/shop/products/422514727022.jpg?v=1671706104&width=1100';
    } else if (titleStr.contains('مفتاح') ||
        titleStr.contains('مفتاح الكعبة')) {
      chosenImg =
          'https://www.gazzaz.com.sa/cdn/shop/products/422514727012.jpg?v=1671706024&width=1100';
    } else if (titleStr.contains('كوب') || titleStr.contains('حراري')) {
      chosenImg =
          'https://img-1.kwcdn.com/product/Fancyalgo/VirtualModelMatting/49c6aca159729d39580c9c44587a94e0.jpg?imageView2/2/w/500/q/80/format/avif';
    } else if (titleStr.contains('سجاد') || titleStr.contains('صلاة')) {
      chosenImg =
          'https://m.media-amazon.com/images/I/71pt72EQ8wL._AC_SX522_.jpg';
    } else if (titleStr.contains('شماغ') || titleStr.contains('غترة')) {
      chosenImg =
          'https://m.media-amazon.com/images/I/61XZajcEtGL._AC_SX679_.jpg';
    } else {
      chosenImg =
          'https://staging.modeefe.com/uploads/0000/6/2026/06/13/59d5a114-b797-46a0-ab4b-105e3d06f637.jpg';
    }

    final rawDesc =
        json['content']?.toString() ?? json['desc']?.toString() ?? '';
    final cleanDesc = HtmlUtils.stripHtml(rawDesc);

    return ProductModel(
      id: json['id']?.toString() ?? '0',
      title: titleStr.isNotEmpty ? titleStr : 'منتج تراثي فاخر',
      category: json['category'] is Map
          ? json['category']['name']?.toString() ?? 'هدايا وتذكارات'
          : (json['category']?.toString() ?? 'هدايا وتذكارات'),
      storeName: json['store'] is Map
          ? json['store']['name']?.toString() ?? 'متجر الهدايا والتذكارات'
          : 'متجر الهدايا والتذكارات',
      price: displayPrice.contains('﷼')
          ? displayPrice
          : (displayPrice.contains('ر.س')
              ? displayPrice.replaceAll('ر.س', '﷼')
              : '$displayPrice ﷼'),
      priceNumeric: numPrice,
      originalPrice: displayOrigin.contains('﷼')
          ? displayOrigin
          : (displayOrigin.contains('ر.س')
              ? displayOrigin.replaceAll('ر.س', '﷼')
              : '$displayOrigin ﷼'),
      discountPercent: json['discount_percent']?.toString(),
      rating: parsedRating,
      reviewsCount: parsedReviews > 0 ? parsedReviews : 10,
      imageUrl: chosenImg,
      description: cleanDesc.isNotEmpty
          ? cleanDesc
          : 'منتج سعودي أصيل من بازار مُضيف، منتقى بعناية ليعكس عراقة الهوية الوطنية.',
      sku: json['sku']?.toString(),
      stockStatus: json['stock_status']?.toString() ?? 'in',
      inStock: json['in_stock'] == true ||
          json['stock_status'] == 'in' ||
          (json['quantity'] is int && (json['quantity'] as int) > 0),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '10') ?? 10,
      gallery: gal.isNotEmpty ? gal : [chosenImg],
      specifications: specs,
      related: rel,
    );
  }
}
