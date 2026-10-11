import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/image_viewer_dialog.dart';
import '../../booking/data/booking_draft.dart';
import '../data/car_repository.dart';
import '../../wishlist/data/wishlist_repository.dart';

class CarDetailScreen extends ConsumerStatefulWidget {
  final dynamic carId;

  const CarDetailScreen({super.key, required this.carId});

  @override
  ConsumerState<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends ConsumerState<CarDetailScreen> {
  int _selectedImageIndex = 0;

  void _openBookingSheet(BuildContext context, CarModel car) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CarBookingBottomSheet(car: car),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final carAsync = ref.watch(carDetailProvider(widget.carId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: carAsync.when(
        data: (car) {
          final images = car.gallery.isNotEmpty ? car.gallery : [car.imageUrl];
          final currentImage = _selectedImageIndex < images.length
              ? images[_selectedImageIndex]
              : car.imageUrl;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    backgroundColor: bg,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                          child: IconButton(
                            icon: Icon(
                              ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.carId, 'car')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.carId, 'car')
                                  ? AppColors.error
                                  : AppColors.accentGold,
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(wishlistProvider.notifier)
                                  .toggleFavorite(
                                    WishlistItemModel(
                                      id: int.tryParse(
                                              widget.carId.toString()) ??
                                          0,
                                      objectId: int.tryParse(
                                              widget.carId.toString()) ??
                                          0,
                                      objectModel: 'car',
                                      title: car.title,
                                      imageUrl: car.imageUrl,
                                      price: car.price,
                                      location: car.locationName,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? (isAr
                                              ? 'تمت إضافة السيارة إلى المفضلة ❤️'
                                              : 'Added car to favorites ❤️')
                                          : (isAr
                                              ? 'تمت إزالة السيارة من المفضلة'
                                              : 'Removed from favorites'),
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: added
                                        ? AppColors.accentGold
                                        : (isDark
                                            ? AppColors.darkCard
                                            : const Color(0xFF333333)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.white, size: 20),
                            onPressed: () => ShareHelper.shareItem(
                              context: context,
                              title: car.title,
                              category: isAr
                                  ? 'تأجير سيارات فارهة'
                                  : 'Luxury Car Rental',
                              id: widget.carId.toString(),
                              price: '${car.price} ر.س / يوم',
                              location: car.locationName,
                              type: 'car',
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen,
                                color: Colors.white, size: 20),
                            onPressed: () => ImageViewerDialog.show(
                              context,
                              images: images,
                              initialIndex: _selectedImageIndex,
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: GestureDetector(
                        onTap: () => ImageViewerDialog.show(
                          context,
                          images: images,
                          initialIndex: _selectedImageIndex,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: currentImage,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: cardBg,
                                child: Icon(Icons.directions_car,
                                    color: AppColors.accentGold, size: 80),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.transparent,
                                    bg.withValues(alpha: 0.95),
                                    bg,
                                  ],
                                  stops: const [0.0, 0.4, 0.85, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: isAr ? 16 : null,
                              left: isAr ? null : 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library_outlined,
                                        size: 14, color: AppColors.accentGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_selectedImageIndex + 1}/${images.length}',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnails row if multiple images
                          if (images.length > 1) ...[
                            SizedBox(
                              height: 60,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final isSel = idx == _selectedImageIndex;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedImageIndex = idx),
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSel
                                              ? AppColors.accentGold
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        imageUrl: images[idx],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Category & Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accentGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentGold
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  car.category,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: AppColors.accentGold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${car.rating}',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr
                                        ? '(${car.reviewsCount} تقييم)'
                                        : '(${car.reviewsCount} reviews)',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            car.title,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.accentGold),
                              const SizedBox(width: 4),
                              Text(
                                car.locationName ??
                                    (isAr
                                        ? 'المملكة العربية السعودية'
                                        : 'Saudi Arabia'),
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Specs Grid
                          Text(
                            isAr ? 'المواصفات الأساسية' : 'Key Specifications',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSpecBox(
                                        Icons.people_outline,
                                        isAr ? 'السعة' : 'Capacity',
                                        isAr
                                            ? '${car.passengerCount} ركاب'
                                            : '${car.passengerCount} Seats',
                                        textPrimary,
                                        textMuted,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 45,
                                        color: cardBorder),
                                    Expanded(
                                      child: _buildSpecBox(
                                        Icons.meeting_room_outlined,
                                        isAr ? 'الأبواب' : 'Doors',
                                        isAr
                                            ? '${car.doors} أبواب'
                                            : '${car.doors} Doors',
                                        textPrimary,
                                        textMuted,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 45,
                                        color: cardBorder),
                                    Expanded(
                                      child: _buildSpecBox(
                                        Icons.luggage_outlined,
                                        isAr ? 'الحقائب' : 'Baggage',
                                        isAr
                                            ? '${car.baggage} حقائب'
                                            : '${car.baggage} Bags',
                                        textPrimary,
                                        textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24, color: cardBorder),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSpecBox(
                                        Icons.settings_outlined,
                                        isAr ? 'ناقل الحركة' : 'Transmission',
                                        car.transmission,
                                        textPrimary,
                                        textMuted,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 45,
                                        color: cardBorder),
                                    Expanded(
                                      child: _buildSpecBox(
                                        Icons.local_gas_station_outlined,
                                        isAr ? 'الوقود' : 'Fuel',
                                        isAr ? 'بنزين 95' : 'Petrol 95',
                                        textPrimary,
                                        textMuted,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 45,
                                        color: cardBorder),
                                    Expanded(
                                      child: _buildSpecBox(
                                        Icons.ac_unit_outlined,
                                        isAr ? 'التكييف' : 'A/C',
                                        isAr ? 'مركزي حديث' : 'Climate Control',
                                        textPrimary,
                                        textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            isAr ? 'نبذة عن السيارة' : 'About Vehicle',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            car.description,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.7,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Features & Inclusions
                          Text(
                            isAr
                                ? 'المميزات والخدمات المشمولة'
                                : 'Features & Included Services',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            Icons.verified_outlined,
                            isAr
                                ? 'تأمين شامل ضد الحوادث والمسؤولية'
                                : 'Comprehensive insurance included',
                            textPrimary,
                          ),
                          const SizedBox(height: 10),
                          _buildFeatureRow(
                            Icons.gps_fixed,
                            isAr
                                ? 'نظام ملاحة وخرائط ذكي ومحدث'
                                : 'Smart updated GPS navigation system',
                            textPrimary,
                          ),
                          const SizedBox(height: 10),
                          _buildFeatureRow(
                            Icons.clean_hands_outlined,
                            isAr
                                ? 'استلام وتسليم معقم بالكامل مع باقة ضيافة'
                                : 'Fully sanitized delivery with hospitality pack',
                            textPrimary,
                          ),
                          const SizedBox(height: 10),
                          _buildFeatureRow(
                            Icons.support_agent_outlined,
                            isAr
                                ? 'دعم ومساعدة على الطريق على مدار 24 ساعة'
                                : '24/7 roadside assistance support',
                            textPrimary,
                          ),
                          const SizedBox(height: 10),
                          _buildFeatureRow(
                            Icons.person_pin,
                            isAr
                                ? 'خيار إضافة سائق خاص محترف مرخص'
                                : 'Optional licensed private chauffeur service',
                            textPrimary,
                          ),

                          if (car.features.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: car.features.map((f) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check,
                                          size: 14,
                                          color: AppColors.accentGold),
                                      const SizedBox(width: 6),
                                      Text(
                                        f.title,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Sticky Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    border: Border(top: BorderSide(color: cardBorder)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'سعر الإيجار اليومي' : 'Daily Rental Rate',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              car.pricePerDay,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openBookingSheet(context, car),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMauve,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isAr
                                  ? 'حجز واستئجار السيارة'
                                  : 'Book & Rent Vehicle',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Scaffold(
          backgroundColor: bg,
          body: const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold)),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              isAr ? 'تفاصيل السيارة' : 'Car Details',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'تعذر تحميل تفاصيل السيارة'
                      : 'Failed to load car details',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(carDetailProvider(widget.carId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMauve,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isAr ? 'إعادة المحاولة' : 'Retry',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecBox(IconData icon, String title, String value,
      Color textPrimary, Color textMuted) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 22),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.cairo(fontSize: 11, color: textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color textPrimary) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline,
            color: AppColors.accentGold, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(fontSize: 13, color: textPrimary),
          ),
        ),
      ],
    );
  }
}

class _CarBookingBottomSheet extends StatefulWidget {
  final CarModel car;

  const _CarBookingBottomSheet({required this.car});

  @override
  State<_CarBookingBottomSheet> createState() => _CarBookingBottomSheetState();
}

class _CarBookingBottomSheetState extends State<_CarBookingBottomSheet> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));
  bool _includeDriver = false;
  String _pickupLocation = 'مطار الملك خالد الدولي (الرياض)';

  int get _daysCount {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _baseDailyRate {
    return widget.car.salePrice != null && widget.car.salePrice! > 0
        ? widget.car.salePrice!
        : widget.car.price;
  }

  double get _driverDailyRate => 200.0;

  double get _totalPrice {
    final daily = _baseDailyRate + (_includeDriver ? _driverDailyRate : 0.0);
    return daily * _daysCount;
  }

  Future<void> _selectStartDate(bool isDark, Color textPrimary) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.primaryMauve,
              onPrimary: Colors.white,
              secondary: AppColors.accentGold,
              onSecondary: Colors.black,
              surface: isDark ? AppColors.darkCard : Colors.white,
              onSurface: textPrimary,
              error: AppColors.error,
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate(bool isDark, Color textPrimary) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate)
          ? _endDate
          : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.primaryMauve,
              onPrimary: Colors.white,
              secondary: AppColors.accentGold,
              onSecondary: Colors.black,
              surface: isDark ? AppColors.darkCard : Colors.white,
              onSurface: textPrimary,
              error: AppColors.error,
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _proceedToCheckout() {
    Navigator.pop(context);

    final draft = BookingDraft(
      title: widget.car.title,
      serviceId: int.tryParse(widget.car.id) ?? 1,
      serviceType: 'car',
      imageUrl: widget.car.imageUrl,
      location: widget.car.locationName ?? _pickupLocation,
      date: _startDate,
      unitPrice: _baseDailyRate,
      personItems: [
        BookingPersonItem(
          name: 'أيام الاستئجار ($_daysCount أيام)',
          price: _baseDailyRate,
          quantity: _daysCount,
        ),
      ],
      extraItems: [
        if (_includeDriver)
          BookingExtraItem(
            name: 'سائق خاص محترف ($_daysCount أيام)',
            price: _driverDailyRate * _daysCount,
          ),
      ],
      totalAmount: _totalPrice,
    );

    context.push('/checkout/${widget.car.id}', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Handle bar & Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تحديد تفاصيل استئجار السيارة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: cardBorder),
            const SizedBox(height: 12),

            // Date Range Selection
            Text(
              'مدة الاستئجار',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectStartDate(isDark, textPrimary),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الاستلام',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: textMuted),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: AppColors.accentGold),
                              const SizedBox(width: 6),
                              Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectEndDate(isDark, textPrimary),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ التسليم',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: textMuted),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 16, color: AppColors.accentGold),
                              const SizedBox(width: 6),
                              Text(
                                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'المدة الإجمالية: $_daysCount أيام',
                  style: GoogleFonts.cairo(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pick-up location
            Text(
              'موقع الاستلام والتسليم',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _pickupLocation,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                  items: [
                    'مطار الملك خالد الدولي (الرياض)',
                    'مطار الملك عبدالعزيز الدولي (جدة)',
                    'مطار الأمير محمد بن عبدالعزيز (المدينة)',
                    'مطار العلا الدولي',
                    'التسليم عند مقر إقامة العميل (الفندق)',
                  ]
                      .map((loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(
                              loc,
                              style: GoogleFonts.cairo(
                                  fontSize: 13, color: textPrimary),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _pickupLocation = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver Option Switch
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin,
                      color: AppColors.accentGold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب سائق خاص محترف',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'خدمة سائق مرافق مع السيارة (+200 ﷼/يوم)',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeDriver,
                    activeThumbColor: AppColors.accentGold,
                    onChanged: (val) => setState(() => _includeDriver = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pricing Breakdown Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF130F1A)
                    : const Color(0xFFF7F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سعر الإيجار الأساسي ($_daysCount أيام):',
                        style:
                            GoogleFonts.cairo(fontSize: 12, color: textMuted),
                      ),
                      Text(
                        '${(_baseDailyRate * _daysCount).toStringAsFixed(0)} ﷼',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_includeDriver) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'خدمة السائق الخاص ($_daysCount أيام):',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: textMuted),
                        ),
                        Text(
                          '${(_driverDailyRate * _daysCount).toStringAsFixed(0)} ﷼',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 16, color: cardBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي المستحق:',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(0)} ﷼',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMauve,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'متابعة إلى إتمام الحجز والدفع',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
