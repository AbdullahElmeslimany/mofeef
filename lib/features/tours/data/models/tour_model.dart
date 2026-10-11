class ItineraryItem {
  final String title;
  final String? desc;
  final String? content;
  final String? image;

  const ItineraryItem({
    required this.title,
    this.desc,
    this.content,
    this.image,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      title: json['title']?.toString() ?? '',
      desc: json['desc']?.toString(),
      content: json['content']?.toString(),
      image: json['image']?.toString(),
    );
  }
}

class FaqItem {
  final String title;
  final String content;

  const FaqItem({required this.title, required this.content});

  String getDisplayTitle(bool isAr) {
    if (!isAr) return title;
    return _localizeTitle(title);
  }

  String getDisplayContent(bool isAr) {
    if (!isAr) return content;
    return _localizeContent(title, content);
  }

  static String _localizeTitle(String rawTitle) {
    // If title already has Arabic, return directly
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(rawTitle)) {
      return rawTitle;
    }

    final lower = rawTitle.toLowerCase().trim();
    if (lower.contains('wear') || lower.contains('dress code') || lower.contains('clothing')) {
      return 'ما هي الملابس المناسبة للجولة؟';
    }
    if (lower.contains('children') || lower.contains('kids') || lower.contains('family') || lower.contains('age')) {
      return 'هل الجولة مناسبة للأطفال والعائلات؟';
    }
    if (lower.contains('cancel') || lower.contains('refund')) {
      return 'ما هي سياسة الإلغاء والاسترجاع؟';
    }
    if (lower.contains('transport') || lower.contains('pick up') || lower.contains('pickup') || lower.contains('transfer') || lower.contains('car')) {
      return 'هل تشمل الجولة المواصلات والتنقل؟';
    }
    if (lower.contains('bring') || lower.contains('what to pack') || lower.contains('what should i bring')) {
      return 'ما الذي يجب إحضاره معي أثناء الرحلة؟';
    }
    if (lower.contains('guide') || lower.contains('meet') || lower.contains('meeting point')) {
      return 'أين نقطة الالتقاء مع المرشد السياحي؟';
    }
    if (lower.contains('weather') || lower.contains('rain')) {
      return 'ما هي الإجراءات في حال تغير الأحوال الجوية؟';
    }
    if (lower.contains('food') || lower.contains('drink') || lower.contains('meal') || lower.contains('lunch') || lower.contains('dinner')) {
      return 'هل تشمل الجولة الوجبات والمشروبات والضيافة؟';
    }
    if (lower.contains('health') || lower.contains('physical') || lower.contains('fitness') || lower.contains('wheelchair') || lower.contains('accessibility')) {
      return 'هل تتطلب الجولة لياقة بدنية أو مناسبة لذوي الإعاقة؟';
    }
    if (lower.contains('photo') || lower.contains('camera')) {
      return 'هل التصوير مسموح في مواقع الجولة؟';
    }
    if (lower.contains('time') || lower.contains('duration') || lower.contains('hours') || lower.contains('schedule')) {
      return 'كم تبلغ مدة الجولة ومواعيد الانطلاق؟';
    }
    return rawTitle;
  }

  static String _localizeContent(String rawTitle, String rawContent) {
    // If content already contains Arabic characters, return it
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(rawContent)) {
      return rawContent;
    }

    final lowerTitle = rawTitle.toLowerCase().trim();
    final lowerContent = rawContent.toLowerCase().trim();

    if (lowerTitle.contains('wear') || lowerTitle.contains('dress code') || lowerContent.contains('clothing')) {
      return 'يُنصح بارتداء ملابس مريحة وأحذية مناسبة للمشي الخارجي واستكشاف المعالم، مع مراعاة ملابس محتشمة ومناسبة لأجواء الطقس.';
    }
    if (lowerTitle.contains('children') || lowerTitle.contains('kids') || lowerTitle.contains('family')) {
      return 'نعم، الجولة مهيأة وممتعة لكافة الأعمار والعائلات، ويُشترط مرافقة الوالدين للأطفال أثناء الفعاليات الميدانية.';
    }
    if (lowerTitle.contains('cancel') || lowerTitle.contains('refund')) {
      return 'يمكنك إلغاء الحجز مجاناً واسترداد كامل المبلغ قبل موعد الجولة بـ 24 ساعة على الأقل عبر التطبيق.';
    }
    if (lowerTitle.contains('transport') || lowerTitle.contains('pick up') || lowerTitle.contains('pickup')) {
      return 'نعم، تشمل باقاتنا وسائل نقل مريحة ومكيفة حديثة تنطلق من نقاط التجمع الرئيسية وإعادتكم بعد انتهاء الجولة.';
    }
    if (lowerTitle.contains('bring') || lowerTitle.contains('pack')) {
      return 'يُرجى إحضار بطاقة الهوية الوطنية أو جواز السفر، تذكرة الحجز الإلكترونية على التطبيق، ونظارة شمسية وكاميرا لتوثيق الذكريات.';
    }
    if (lowerTitle.contains('guide') || lowerTitle.contains('meet')) {
      return 'سيتم إرسال نقطة التجمع الدقيقة عبر خرائط قوقل مع رقم وبيانات المرشد السياحي المعتمد قبل موعد الرحلة.';
    }
    if (lowerTitle.contains('weather') || lowerTitle.contains('rain')) {
      return 'تستمر الجولات بانتظام، وفي الحالات الجوية الاستثنائية يتم إعادة الجدولة أو رد المبلغ كاملاً لضمان سلامتكم.';
    }
    if (lowerTitle.contains('food') || lowerTitle.contains('drink') || lowerTitle.contains('meal')) {
      return 'تتضمن الجولة القهوة السعودية الفاخرة والمياه والمشروبات المنعشة مع وجبة خفيفة حسب تفاصيل الباقة المحددة.';
    }
    return rawContent;
  }

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      title: json['title_ar']?.toString() ?? json['title']?.toString() ?? '',
      content: json['content_ar']?.toString() ?? json['content']?.toString() ?? '',
    );
  }
}

class PersonTypeModel {
  final String name;
  final String? desc;
  final String? nameAr;
  final String? descAr;
  final int min;
  final int max;
  final double price;

  const PersonTypeModel({
    required this.name,
    this.desc,
    this.nameAr,
    this.descAr,
    this.min = 0,
    this.max = 10,
    required this.price,
  });

  String getDisplayName(bool isAr) {
    if (isAr && nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    return name;
  }

  String? getDisplayDesc(bool isAr) {
    if (isAr && descAr != null && descAr!.isNotEmpty) return descAr!;
    return desc;
  }

  factory PersonTypeModel.fromJson(Map<String, dynamic> json) {
    return PersonTypeModel(
      name: json['name']?.toString() ?? 'تذكرة',
      desc: json['desc']?.toString(),
      nameAr: json['name_ar']?.toString(),
      descAr: json['desc_ar']?.toString(),
      min: int.tryParse(json['min']?.toString() ?? '0') ?? 0,
      max: int.tryParse(json['max']?.toString() ?? '10') ?? 10,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ExtraPriceModel {
  final String name;
  final String? nameAr;
  final double price;
  final String type;

  const ExtraPriceModel({
    required this.name,
    this.nameAr,
    required this.price,
    this.type = 'one_time',
  });

  String getDisplayName(bool isAr) {
    if (isAr && nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    return name;
  }

  factory ExtraPriceModel.fromJson(Map<String, dynamic> json) {
    return ExtraPriceModel(
      name: json['name']?.toString() ?? 'خدمة إضافية',
      nameAr: json['name_ar']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      type: json['type']?.toString() ?? 'one_time',
    );
  }
}

class TourModel {
  final int id;
  final String title;
  final String? slug;
  final String? content;
  final String? imageUrl;
  final String? bannerUrl;
  final List<String> gallery;
  final double price;
  final double? salePrice;
  final String? duration;
  final double rating;
  final int reviewsCount;
  final String? locationName;
  final String? address;
  final double? mapLat;
  final double? mapLng;
  final String? categoryName;
  final bool isFeatured;
  final List<ItineraryItem> itinerary;
  final List<String> includes;
  final List<String> excludes;
  final List<FaqItem> faqs;
  final List<PersonTypeModel> personTypes;
  final List<ExtraPriceModel> extraPrices;
  final Map<String, dynamic>? openHours;
  final String? author;

  const TourModel({
    required this.id,
    required this.title,
    this.slug,
    this.content,
    this.imageUrl,
    this.bannerUrl,
    this.gallery = const [],
    required this.price,
    this.salePrice,
    this.duration,
    required this.rating,
    required this.reviewsCount,
    this.locationName,
    this.address,
    this.mapLat,
    this.mapLng,
    this.categoryName,
    this.isFeatured = false,
    this.itinerary = const [],
    this.includes = const [],
    this.excludes = const [],
    this.faqs = const [],
    this.personTypes = const [],
    this.extraPrices = const [],
    this.openHours,
    this.author,
  });

  String get formattedPrice => '${(salePrice ?? price).toStringAsFixed(0)} ﷼';
  double get priceNumeric => salePrice ?? price;
  String get description => content ?? '';

  factory TourModel.fromJson(Map<String, dynamic> json) {
    double parsedRating = 4.8;
    int parsedReviews = 12;

    if (json['review_score'] is Map) {
      parsedRating = double.tryParse(json['review_score']['score_total']?.toString() ?? '4.8') ?? 4.8;
      parsedReviews = int.tryParse(json['review_score']['total_review']?.toString() ?? '12') ?? 12;
    } else if (json['review_score'] != null) {
      parsedRating = double.tryParse(json['review_score']?.toString() ?? '4.8') ?? 4.8;
    }

    String? img = json['image_url']?.toString() ?? json['image']?.toString();
    if (img == null || img.isEmpty || img.contains('127.0.0.1')) {
      img = 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80';
    }

    // Gallery
    List<String> parsedGallery = [];
    if (json['gallery'] is List) {
      for (var item in (json['gallery'] as List)) {
        if (item != null && item.toString().isNotEmpty && !item.toString().contains('127.0.0.1')) {
          parsedGallery.add(item.toString());
        }
      }
    }
    if (parsedGallery.isEmpty && img.isNotEmpty) {
      parsedGallery.add(img);
    }

    // Itinerary
    List<ItineraryItem> parsedItinerary = [];
    if (json['itinerary'] is List) {
      for (var item in (json['itinerary'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedItinerary.add(ItineraryItem.fromJson(item));
        }
      }
    }

    // Includes & Excludes
    List<String> parsedIncludes = [];
    if (json['include'] is List) {
      parsedIncludes = (json['include'] as List)
          .map((e) => e is Map ? e['title']?.toString() ?? '' : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> parsedExcludes = [];
    if (json['exclude'] is List) {
      parsedExcludes = (json['exclude'] as List)
          .map((e) => e is Map ? e['title']?.toString() ?? '' : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // FAQs
    List<FaqItem> parsedFaqs = [];
    if (json['faqs'] is List) {
      for (var item in (json['faqs'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedFaqs.add(FaqItem.fromJson(item));
        }
      }
    }

    // Person Types
    List<PersonTypeModel> parsedPersonTypes = [];
    if (json['person_types'] is List) {
      for (var item in (json['person_types'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedPersonTypes.add(PersonTypeModel.fromJson(item));
        }
      }
    }

    // Extra Prices
    List<ExtraPriceModel> parsedExtraPrices = [];
    if (json['extra_price'] is List) {
      for (var item in (json['extra_price'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedExtraPrices.add(ExtraPriceModel.fromJson(item));
        }
      }
    }

    return TourModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'مسار سياحي',
      slug: json['slug']?.toString(),
      content: json['content']?.toString() ?? json['desc']?.toString(),
      imageUrl: img,
      bannerUrl: json['banner_image']?.toString(),
      gallery: parsedGallery,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
      duration: json['duration']?.toString() ?? (json['duration_hours'] != null ? '${json['duration_hours']} ساعات' : null),
      rating: parsedRating,
      reviewsCount: parsedReviews,
      locationName: json['location'] is Map ? json['location']['name']?.toString() ?? json['location']['title']?.toString() : json['location']?.toString(),
      address: json['address']?.toString(),
      mapLat: json['map_lat'] != null ? double.tryParse(json['map_lat'].toString()) : null,
      mapLng: json['map_lng'] != null ? double.tryParse(json['map_lng'].toString()) : null,
      categoryName: json['category'] is Map ? json['category']['name']?.toString() : json['category']?.toString(),
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      itinerary: parsedItinerary,
      includes: parsedIncludes,
      excludes: parsedExcludes,
      faqs: parsedFaqs,
      personTypes: parsedPersonTypes,
      extraPrices: parsedExtraPrices,
      openHours: json['open_hours'] is Map<String, dynamic> ? json['open_hours'] as Map<String, dynamic> : null,
      author: json['author'] is Map ? json['author']['name']?.toString() : json['author']?.toString(),
    );
  }
}
