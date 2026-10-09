import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/utils/html_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/image_viewer_dialog.dart';
import '../booking/data/booking_draft.dart';
import '../tours/data/models/tour_model.dart';
import '../tours/data/repositories/tour_repository.dart';
import '../../core/utils/share_helper.dart';
import '../wishlist/data/wishlist_repository.dart';

final tourDetailProvider =
    FutureProvider.family<TourModel, String>((ref, id) async {
  return ref.watch(tourRepositoryProvider).getTourDetail(id);
});

class ExperienceDetailsScreen extends ConsumerStatefulWidget {
  final String experienceId;

  const ExperienceDetailsScreen({super.key, required this.experienceId});

  @override
  ConsumerState<ExperienceDetailsScreen> createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState
    extends ConsumerState<ExperienceDetailsScreen> {
  int _currentGalleryIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openMap(TourModel tour) async {
    final lat = tour.mapLat ?? 21.4689868;
    final lng = tour.mapLng ?? 39.8279215;
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tourAsync = ref.watch(tourDetailProvider(widget.experienceId));
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    return Scaffold(
      body: tourAsync.when(
        data: (tour) {
          final images = tour.gallery.isNotEmpty
              ? tour.gallery
              : (tour.imageUrl != null
                  ? [tour.imageUrl!]
                  : [
                      'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80'
                    ]);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 1. Multi-Image Carousel Header with Back & Share Buttons
                  SliverAppBar(
                    expandedHeight: 380,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.55),
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
                            vertical: 8.0, horizontal: 4.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              ShareHelper.shareItem(
                                context: context,
                                title: tour.title,
                                category: isAr ? 'مسار سياحي' : 'Tourist Trail',
                                id: widget.experienceId,
                                price: tour.formattedPrice,
                                location: tour.locationName,
                                type: 'tour',
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: Icon(
                              ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.experienceId, 'tour')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.experienceId, 'tour')
                                  ? AppColors.error
                                  : AppColors.primaryGold,
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(wishlistProvider.notifier)
                                  .toggleFavorite(
                                    WishlistItemModel(
                                      id: int.tryParse(widget.experienceId) ??
                                          0,
                                      objectId:
                                          int.tryParse(widget.experienceId) ??
                                              0,
                                      objectModel: 'tour',
                                      title: tour.title,
                                      imageUrl: tour.imageUrl,
                                      price: tour.salePrice ?? tour.price,
                                      location:
                                          tour.locationName ?? tour.address,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(added
                                        ? (isAr
                                            ? 'تمت إضافة المسار إلى المفضلة ❤️'
                                            : 'Added trail to favorites ❤️')
                                        : (isAr
                                            ? 'تمت إزالة المسار من المفضلة'
                                            : 'Removed from favorites')),
                                    backgroundColor: added
                                        ? AppColors.primaryGold
                                        : AppColors.card,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (idx) =>
                                setState(() => _currentGalleryIndex = idx),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => ImageViewerDialog.show(context,
                                    images: images, initialIndex: index),
                                child: CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surface,
                                    child: const Icon(Icons.image_not_supported,
                                        color: AppColors.textMuted),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Dark gradient overlay
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                  AppColors.background.withOpacity(0.95),
                                  AppColors.background,
                                ],
                                stops: const [0.0, 0.4, 0.85, 1.0],
                              ),
                            ),
                          ),
                          // Image Counter Badge (📸 1/5)
                          Positioned(
                            bottom: 20,
                            left: isAr ? 20 : null,
                            right: isAr ? null : 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        AppColors.primaryGold.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_outlined,
                                      color: AppColors.primaryGold, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_currentGalleryIndex + 1} / ${images.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Content Details & Timeline Stages
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gallery Thumbnails Strip (if > 1 image)
                          if (images.length > 1) ...[
                            SizedBox(
                              height: 60,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final isSelected =
                                      _currentGalleryIndex == idx;
                                  return GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        idx,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryGold
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: images[idx],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Category and Location Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.goldGlow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primaryGold
                                          .withOpacity(0.4)),
                                ),
                                child: Text(
                                  tour.categoryName ??
                                      (isAr
                                          ? 'مسار سياحي وتراثي'
                                          : 'Tourist Trail'),
                                  style: const TextStyle(
                                      color: AppColors.primaryGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (tour.locationName != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          color: AppColors.textMuted, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        tour.locationName!,
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Title
                          Text(tour.title, style: AppTypography.headingMedium),

                          const SizedBox(height: 12),

                          // Rating and Duration Specs Grid
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                    Icons.star,
                                    isAr ? 'التقييم' : 'Rating',
                                    '${tour.rating} (${tour.reviewsCount})'),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.border),
                                _buildInfoItem(
                                    Icons.schedule,
                                    isAr ? 'المدة' : 'Duration',
                                    tour.duration ??
                                        (isAr ? '٤-٦ ساعات' : '4-6 hours')),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.border),
                                _buildInfoItem(
                                    Icons.groups_outlined,
                                    isAr ? 'المجموعة' : 'Group',
                                    isAr ? 'خاصة أو عائلية' : 'Private/Family'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Description / About Tour
                          Text(
                              isAr
                                  ? 'عن المسار والتجربة'
                                  : 'About the Trail & Experience',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            HtmlUtils.stripHtml(tour.content ?? ''),
                            style:
                                AppTypography.bodyLarge.copyWith(height: 1.7),
                          ),

                          const SizedBox(height: 24),

                          // Itinerary / Timeline Stages
                          if (tour.itinerary.isNotEmpty) ...[
                            Text(
                                isAr
                                    ? 'محطات ومراحل المسار'
                                    : 'Itinerary & Route Stages',
                                style: AppTypography.titleLarge),
                            const SizedBox(height: 14),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tour.itinerary.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final stage = tour.itinerary[index];
                                final stageTitle =
                                    _formatStageTitle(index, stage.title, isAr);
                                final stageDesc =
                                    _formatStageDesc(stage.desc, isAr);
                                final stageContent = _formatStageContent(
                                    index, stage.content, isAr);
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.goldGlow,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                              color: AppColors.primaryGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(stageTitle,
                                                style:
                                                    AppTypography.titleSmall),
                                            if (stageDesc != null &&
                                                stageDesc.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(stageDesc,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .primaryGold)),
                                            ],
                                            if (stageContent != null &&
                                                stageContent.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(stageContent,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(height: 1.5)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (stage.image != null &&
                                          stage.image!.isNotEmpty)
                                        GestureDetector(
                                          onTap: () => ImageViewerDialog.show(
                                              context,
                                              images: [stage.image!]),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: CachedNetworkImage(
                                              imageUrl: stage.image!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Includes & Excludes
                          if (tour.includes.isNotEmpty ||
                              tour.excludes.isNotEmpty) ...[
                            Text(
                                isAr
                                    ? 'تفاصيل باقة الحجز'
                                    : 'Package Inclusions & Exclusions',
                                style: AppTypography.titleLarge),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (tour.includes.isNotEmpty) ...[
                                    Text(isAr ? 'تشمل الرحلة:' : 'Includes:',
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                                color: AppColors.success)),
                                    const SizedBox(height: 8),
                                    ...tour.includes.map(
                                      (inc) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.check_circle_outline,
                                                color: AppColors.success,
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(inc,
                                                    style: AppTypography
                                                        .bodyMedium)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (tour.excludes.isNotEmpty) ...[
                                    if (tour.includes.isNotEmpty)
                                      const Divider(
                                          color: AppColors.border, height: 20),
                                    Text(isAr ? 'لا تشمل الرحلة:' : 'Excludes:',
                                        style: AppTypography.titleSmall
                                            .copyWith(color: AppColors.error)),
                                    const SizedBox(height: 8),
                                    ...tour.excludes.map(
                                      (exc) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.cancel_outlined,
                                                color: AppColors.error,
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(exc,
                                                    style: AppTypography
                                                        .bodyMedium)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // FAQs
                          if (tour.faqs.isNotEmpty) ...[
                            Text(
                                isAr
                                    ? 'الأسئلة الشائعة'
                                    : 'Frequently Asked Questions',
                                style: AppTypography.titleLarge),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tour.faqs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final faq = tour.faqs[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ExpansionTile(
                                    iconColor: AppColors.primaryGold,
                                    collapsedIconColor: AppColors.textSecondary,
                                    title: Text(faq.getDisplayTitle(isAr),
                                        style: AppTypography.titleSmall),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 14),
                                        child: Text(
                                            HtmlUtils.stripHtml(
                                                faq.getDisplayContent(isAr)),
                                            style: AppTypography.bodyMedium
                                                .copyWith(height: 1.5)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Interactive Google Map Section
                          Text(
                              isAr
                                  ? 'الموقع الجغرافي والوصول'
                                  : 'Location & Directions',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _openMap(tour),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color:
                                        AppColors.primaryGold.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldGlow,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.directions_outlined,
                                        color: AppColors.primaryGold, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tour.address ??
                                              tour.locationName ??
                                              (isAr
                                                  ? 'موقع المسار التاريخي'
                                                  : 'Trail Location'),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isAr
                                              ? 'انقر لفتح الاتجاهات المباشرة عبر خرائط Google'
                                              : 'Tap to open directions in Google Maps',
                                          style: const TextStyle(
                                              color: AppColors.primaryGold,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new,
                                      color: AppColors.primaryGold, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Sticky Booking Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border:
                        const Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isAr ? 'السعر يبدأ من' : 'Starts from',
                                style: AppTypography.bodySmall),
                            Text(tour.formattedPrice,
                                style: AppTypography.price),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CustomButton(
                            text: isAr
                                ? 'حجز التذكرة والموعد'
                                : 'Book Tickets & Date',
                            onPressed: () =>
                                _showBookingModal(context, tour, isAr),
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
        loading: () => const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold)),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 54, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                    isAr
                        ? 'تعذر تحميل تفاصيل المسار'
                        : 'Failed to load trail details',
                    style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(tourDetailProvider(widget.experienceId)),
                  child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingModal(BuildContext context, TourModel tour, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _BookingBottomSheet(tour: tour, isAr: isAr),
    );
  }

  String _formatStageTitle(int index, String? title, bool isAr) {
    if (!isAr) return title ?? 'Stage ${index + 1}';
    if (title == null || title.isEmpty) return 'المحطة ${index + 1}';
    final lower = title.toLowerCase().trim();
    if (lower.contains('mornning') || lower.contains('morning')) {
      return 'المحطة الأولى: انطلاق الجولة الصباحية';
    }
    if (lower.contains('hour 1') ||
        lower.contains('1 hour') ||
        lower.contains('stage 1') ||
        lower.contains('day 1')) {
      return 'المحطة الأولى: استكشاف الموقع التاريخي';
    }
    if (lower.contains('hour 2') ||
        lower.contains('2 hour') ||
        lower.contains('stage 2') ||
        lower.contains('day 2')) {
      return 'المحطة الثانية: الجولة الإرشادية والمعالم';
    }
    if (lower.contains('hour 3') ||
        lower.contains('3 hour') ||
        lower.contains('stage 3') ||
        lower.contains('day 3')) {
      return 'المحطة الثالثة: الاستراحة وتجربة الضيافة';
    }
    if (lower.contains('hour 4') ||
        lower.contains('4 hour') ||
        lower.contains('stage 4') ||
        lower.contains('day 4')) {
      return 'المحطة الرابعة: ختام الجولة والتصوير';
    }
    final ordinalsAr = [
      'الأولى',
      'الثانية',
      'الثالثة',
      'الرابعة',
      'الخامسة',
      'السادسة',
      'السابعة',
      'الثامنة'
    ];
    final ord = index < ordinalsAr.length ? ordinalsAr[index] : '${index + 1}';
    return 'المحطة $ord: ${HtmlUtils.stripHtml(title)}';
  }

  String? _formatStageDesc(String? desc, bool isAr) {
    if (desc == null || desc.isEmpty) return null;
    final clean = HtmlUtils.stripHtml(desc);
    if (isAr) {
      if (clean.toLowerCase().contains('hour')) {
        final numMatch = RegExp(r'\d+').firstMatch(clean);
        if (numMatch != null) {
          return 'المدة المتوقعة: ${numMatch.group(0)} ساعات';
        }
        return 'مدة المحطة: ساعة واحدة';
      }
    }
    return clean;
  }

  String? _formatStageContent(int index, String? content, bool isAr) {
    if (content == null || content.isEmpty) return null;
    final clean = HtmlUtils.stripHtml(content).trim();
    if (!isAr) return clean;

    final englishChars = RegExp(r'[a-zA-Z]').allMatches(clean).length;
    if (englishChars > clean.length * 0.3) {
      switch (index) {
        case 0:
          return 'انطلاق المسار السياحي واستكشاف المعالم التاريخية والشواهد التراثية مع المرشد السياحي المعتمد، والتعرف على تفاصيل المكان وأهميته التاريخية.';
        case 1:
          return 'جولة تفصيلية بين أروقة الموقع والمتاحف المجاورة، مع التقاط الصور التذكارية وتوثيق أبرز الزوايا التراثية.';
        case 2:
          return 'استراحة قصيرة وتجربة الضيافة السعودية الأصيلة (القهوة والتمر)، مع استعراض القصص والروايات المرتبطة بالمسار.';
        default:
          return 'المحطة الختامية للمسار، تلخيص أبرز محطات الرحلة، والتوديع بعد تجربة استكشافية متكاملة ومميزة.';
      }
    }
    return clean;
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20),
        const SizedBox(height: 4),
        Text(title, style: AppTypography.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleSmall),
      ],
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final TourModel tour;
  final bool isAr;

  const _BookingBottomSheet({required this.tour, required this.isAr});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final Map<String, int> _personQuantities = {};
  final Set<String> _selectedExtras = {};

  @override
  void initState() {
    super.initState();
    if (widget.tour.personTypes.isNotEmpty) {
      for (var p in widget.tour.personTypes) {
        _personQuantities[p.name] = (p.name.toLowerCase().contains('adult') ||
                p.nameAr?.contains('18') == true)
            ? 1
            : 0;
      }
    } else {
      _personQuantities['default'] = 1;
    }
  }

  double _calculateTotal() {
    double total = 0;
    if (widget.tour.personTypes.isNotEmpty) {
      for (var p in widget.tour.personTypes) {
        final q = _personQuantities[p.name] ?? 0;
        total += (q * p.price);
      }
    } else {
      final unit = widget.tour.salePrice ?? widget.tour.price;
      total += (unit * (_personQuantities['default'] ?? 1));
    }

    // Add extras
    for (var extra in widget.tour.extraPrices) {
      if (_selectedExtras.contains(extra.name)) {
        total += extra.price;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final total = _calculateTotal();

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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'خيارات وتفاصيل الحجز' : 'Booking Options',
                    style: AppTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.tour.imageUrl ??
                        'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tour.title,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                          '${widget.tour.formattedPrice} / ${isAr ? 'للشخص' : 'per person'}',
                          style: AppTypography.price.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 28),

            // 1. Date Selector
            Text(isAr ? 'تاريخ الحجز' : 'Booking Date',
                style: AppTypography.titleSmall),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryGold,
                          surface: AppColors.card,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                    Text(isAr ? 'تغيير التاريخ' : 'Change Date',
                        style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Person Types / Ticket Quantities
            Text(isAr ? 'خيارات التذاكر والزوار' : 'Ticket Options & Guests',
                style: AppTypography.titleSmall),
            const SizedBox(height: 10),

            if (widget.tour.personTypes.isNotEmpty)
              ...widget.tour.personTypes.map((p) {
                final q = _personQuantities[p.name] ?? 0;
                final name = p.getDisplayName(isAr);
                final desc = p.getDisplayDesc(isAr);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: q > 0
                            ? AppColors.primaryGold.withOpacity(0.5)
                            : AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: AppTypography.titleSmall
                                    .copyWith(fontSize: 14)),
                            if (desc != null && desc.isNotEmpty)
                              Text(desc,
                                  style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            Text(
                                '${p.price.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                                style:
                                    AppTypography.price.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.primaryGold, size: 22),
                            onPressed: q > 0
                                ? () => setState(
                                    () => _personQuantities[p.name] = q - 1)
                                : null,
                          ),
                          Text('$q', style: AppTypography.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.primaryGold, size: 22),
                            onPressed: q < p.max
                                ? () => setState(
                                    () => _personQuantities[p.name] = q + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'عدد الزوار' : 'Guests',
                        style: AppTypography.titleSmall),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.primaryGold),
                          onPressed: (_personQuantities['default'] ?? 1) > 1
                              ? () => setState(() =>
                                  _personQuantities['default'] =
                                      (_personQuantities['default'] ?? 1) - 1)
                              : null,
                        ),
                        Text('${_personQuantities['default'] ?? 1}',
                            style: AppTypography.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.primaryGold),
                          onPressed: () => setState(() =>
                              _personQuantities['default'] =
                                  (_personQuantities['default'] ?? 1) + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 3. Extra Services
            if (widget.tour.extraPrices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(isAr ? 'خدمات إضافية اختيارية' : 'Optional Extra Services',
                  style: AppTypography.titleSmall),
              const SizedBox(height: 10),
              ...widget.tour.extraPrices.map((extra) {
                final isSelected = _selectedExtras.contains(extra.name);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CheckboxListTile(
                    activeColor: AppColors.primaryGold,
                    checkColor: AppColors.textDark,
                    title: Text(extra.getDisplayName(isAr),
                        style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    subtitle: Text(
                        '+ ${extra.price.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                        style: AppTypography.price.copyWith(fontSize: 12)),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedExtras.add(extra.name);
                        } else {
                          _selectedExtras.remove(extra.name);
                        }
                      });
                    },
                  ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Total & Checkout Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'المجموع الإجمالي' : 'Total Amount',
                        style: AppTypography.bodySmall),
                    Text('${total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                        style: AppTypography.price.copyWith(fontSize: 22)),
                  ],
                ),
                CustomButton(
                  text: isAr ? 'متابعة للدفع والتأكيد' : 'Proceed to Checkout',
                  width: 190,
                  onPressed: () {
                    final personItems = <BookingPersonItem>[];
                    if (widget.tour.personTypes.isNotEmpty) {
                      for (var p in widget.tour.personTypes) {
                        final q = _personQuantities[p.name] ?? 0;
                        if (q > 0) {
                          personItems.add(BookingPersonItem(
                            name: p.getDisplayName(isAr),
                            price: p.price,
                            quantity: q,
                          ));
                        }
                      }
                    } else {
                      personItems.add(BookingPersonItem(
                        name: isAr ? 'تذكرة دخول عامة' : 'General Ticket',
                        price: widget.tour.salePrice ?? widget.tour.price,
                        quantity: _personQuantities['default'] ?? 1,
                      ));
                    }

                    final extraItems = widget.tour.extraPrices
                        .where((e) => _selectedExtras.contains(e.name))
                        .map((e) => BookingExtraItem(
                            name: e.getDisplayName(isAr), price: e.price))
                        .toList();

                    final draft = BookingDraft(
                      title: widget.tour.title,
                      imageUrl: widget.tour.imageUrl,
                      location: widget.tour.locationName,
                      date: _selectedDate,
                      serviceType: 'tour',
                      serviceId: widget.tour.id,
                      personItems: personItems,
                      extraItems: extraItems,
                      totalAmount: total,
                    );

                    Navigator.pop(context);
                    context.push('/checkout/${widget.tour.id}', extra: draft);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
