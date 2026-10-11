import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/utils/html_utils.dart';
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
  int _selectedTab = 0; // 0: نظرة عامة, 1: التفاصيل, 2: المرشد, 3: التقييمات
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
                    backgroundColor: bg,
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
                                  : AppColors.accentGold,
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
                                    content: Text(
                                      added
                                          ? (isAr
                                              ? 'تمت إضافة المسار إلى المفضلة ❤️'
                                              : 'Added trail to favorites ❤️')
                                          : (isAr
                                              ? 'تمت إزالة المسار من المفضلة'
                                              : 'Removed from favorites'),
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: added
                                        ? AppColors.accentGold
                                        : (isDark ? AppColors.darkCard : const Color(0xFF333333)),
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
                                    color: cardBg,
                                    child: Icon(Icons.image_not_supported,
                                        color: textMuted),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Dark gradient overlay transitioning smoothly to bg
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                  bg.withOpacity(0.95),
                                  bg,
                                ],
                                stops: const [0.0, 0.4, 0.85, 1.0],
                              ),
                            ),
                          ),
                          // Dots indicator matching Figma
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length.clamp(1, 6), (i) {
                                final isAct = _currentGalleryIndex == i;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isAct ? 24 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isAct ? Colors.white : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
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

                          // Category Tags matching Figma
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF261C30)
                                      : const Color(0xFFEADFF2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAr ? 'تجربة' : 'Experience',
                                  style: GoogleFonts.cairo(
                                    color: isDark
                                        ? const Color(0xFFD4C7DF)
                                        : const Color(0xFF533C5E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF261C30)
                                      : const Color(0xFFEADFF2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tour.categoryName ??
                                      (isAr ? 'مغامرات ونجوم' : 'Adventures & Stars'),
                                  style: GoogleFonts.cairo(
                                    color: isDark
                                        ? const Color(0xFFD4C7DF)
                                        : const Color(0xFF533C5E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Title
                          Text(
                            tour.title,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Location and Guide Info Row
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.accentGold),
                              const SizedBox(width: 4),
                              Text(
                                tour.locationName ?? (isAr ? 'العلا' : 'AlUla'),
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: textMuted),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.verified,
                                  size: 16, color: AppColors.accentGold),
                              const SizedBox(width: 4),
                              Text(
                                tour.author != null && tour.author!.isNotEmpty
                                    ? (isAr ? 'مع ${tour.author}' : 'With ${tour.author}')
                                    : (isAr ? 'مع نور الغامدي' : 'With Certified Guide'),
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: textMuted),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons Row (احجز التجربة, أضف لرحلتي +, favorite)
                          Row(
                            children: [
                              // 1. احجز التجربة Button (Mauve)
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showBookingModal(context, tour, isAr),
                                  icon: const Icon(Icons.calendar_month_outlined,
                                      size: 18),
                                  label: Text(
                                    isAr ? 'احجز التجربة' : 'Book Experience',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryMauve,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // 2. أضف لرحلتي Outlined Button
                              Expanded(
                                flex: 3,
                                child: OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr
                                              ? 'تمت إضافة التجربة إلى جدول رحلتك'
                                              : 'Added to itinerary plan',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: AppColors.primaryMauve,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: cardBorder),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    isAr ? 'أضف لرحلتي +' : '+ Add to Trip',
                                    style: GoogleFonts.cairo(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // 3. Favorite Heart Button
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorder),
                                ),
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
                                        : textPrimary,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    await ref
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
                                            location: tour.locationName ??
                                                tour.address,
                                          ),
                                        );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Segmented Navigation Tabs Bar with Gold Active Indicator
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: cardBorder, width: 1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildNavTab(0, isAr ? 'نظرة عامة' : 'Overview',
                                    textPrimary, textMuted),
                                _buildNavTab(1, isAr ? 'التفاصيل' : 'Details',
                                    textPrimary, textMuted),
                                _buildNavTab(2, isAr ? 'المرشد' : 'Guide',
                                    textPrimary, textMuted),
                                _buildNavTab(3, isAr ? 'التقييمات' : 'Reviews',
                                    textPrimary, textMuted),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 3 Feature Cards in a Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildFeatureBox(
                                  icon: Icons.people_outline,
                                  title: tour.author != null &&
                                          tour.author!.isNotEmpty
                                      ? tour.author!
                                      : (isAr ? 'نور الغامدي' : 'Host'),
                                  subtitle: isAr ? 'المرشدة' : 'Guide',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textMuted: textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFeatureBox(
                                  icon: Icons.location_on_outlined,
                                  title: tour.locationName ??
                                      (isAr ? 'العلا' : 'AlUla'),
                                  subtitle: isAr ? 'الموقع' : 'Location',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textMuted: textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFeatureBox(
                                  icon: Icons.calendar_month_outlined,
                                  title: tour.duration ??
                                      (isAr ? 'حسب التوفر' : 'Flexible'),
                                  subtitle: isAr ? 'المواعيد' : 'Schedule',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textMuted: textMuted,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Description / About Tour
                          Text(
                            isAr ? 'عن التجربة' : 'About Experience',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            HtmlUtils.stripHtml(tour.content ?? ''),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.7,
                              color: textMuted,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // What's Included Section matching Figma
                          Text(
                            isAr ? 'ماذا تتضمّن التجربة' : "What's Included",
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInclusionItem(
                              isAr
                                  ? 'مرشدة معتمدة بخبرة 5 سنوات'
                                  : 'Certified guide with 5+ years experience',
                              isDark,
                              textPrimary),
                          const SizedBox(height: 10),
                          _buildInclusionItem(
                              isAr
                                  ? 'تأكيد موعد ومكان التجمّع بعد الحجز'
                                  : 'Confirmation of meeting point after booking',
                              isDark,
                              textPrimary),
                          const SizedBox(height: 10),
                          _buildInclusionItem(
                              isAr
                                  ? 'يمكن إضافتها إلى خطة رحلتك'
                                  : 'Can be added to your custom itinerary',
                              isDark,
                              textPrimary),
                          if (tour.includes.isNotEmpty) ...[
                            ...tour.includes.map((inc) => Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _buildInclusionItem(
                                      inc, isDark, textPrimary),
                                )),
                          ],

                          const SizedBox(height: 24),

                          // Itinerary / Timeline Stages
                          if (tour.itinerary.isNotEmpty) ...[
                            Text(
                              isAr
                                  ? 'محطات ومراحل المسار'
                                  : 'Itinerary & Route Stages',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
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
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGold
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: GoogleFonts.cairo(
                                            color: AppColors.accentGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              stageTitle,
                                              style: GoogleFonts.cairo(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                            if (stageDesc != null &&
                                                stageDesc.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                stageDesc,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: AppColors.accentGold,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                            if (stageContent != null &&
                                                stageContent.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                stageContent,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13,
                                                  height: 1.5,
                                                  color: textMuted,
                                                ),
                                              ),
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
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (tour.includes.isNotEmpty) ...[
                                    Text(
                                      isAr ? 'تشمل الرحلة:' : 'Includes:',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
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
                                              child: Text(
                                                inc,
                                                style: GoogleFonts.cairo(
                                                    fontSize: 13,
                                                    color: textPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (tour.excludes.isNotEmpty) ...[
                                    if (tour.includes.isNotEmpty)
                                      Divider(color: cardBorder, height: 20),
                                    Text(
                                      isAr ? 'لا تشمل الرحلة:' : 'Excludes:',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
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
                                              child: Text(
                                                exc,
                                                style: GoogleFonts.cairo(
                                                    fontSize: 13,
                                                    color: textPrimary),
                                              ),
                                            ),
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
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
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
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: ExpansionTile(
                                    iconColor: AppColors.accentGold,
                                    collapsedIconColor: textMuted,
                                    title: Text(
                                      faq.getDisplayTitle(isAr),
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 14),
                                        child: Text(
                                          HtmlUtils.stripHtml(
                                              faq.getDisplayContent(isAr)),
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            height: 1.6,
                                            color: textMuted,
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

                          // Interactive Google Map Section
                          Text(
                            isAr
                                ? 'الموقع الجغرافي والوصول'
                                : 'Location & Directions',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _openMap(tour),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color:
                                        AppColors.accentGold.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                        isDark ? 0.3 : 0.05),
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
                                      color: AppColors.accentGold
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.directions_outlined,
                                        color: AppColors.accentGold, size: 28),
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
                                          style: GoogleFonts.cairo(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isAr
                                              ? 'انقر لفتح الاتجاهات المباشرة عبر خرائط Google'
                                              : 'Tap to open directions in Google Maps',
                                          style: GoogleFonts.cairo(
                                            color: AppColors.accentGold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new,
                                      color: AppColors.accentGold, size: 20),
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

              // Bottom Sticky Booking Bar matching Figma
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    border: Border(top: BorderSide(color: cardBorder)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _showBookingModal(context, tour, isAr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMauve,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isAr ? 'احجز التجربة' : 'Book Experience',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'السعر للشخص' : 'Price per person',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tour.formattedPrice,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.accentGold,
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
          );
        },
        loading: () => Scaffold(
          backgroundColor: bg,
          body: const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold)),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: bg,
          appBar: AppBar(backgroundColor: Colors.transparent),
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
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(tourDetailProvider(widget.experienceId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMauve,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isAr ? 'إعادة المحاولة' : 'Retry',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingModal(BuildContext context, TourModel tour, bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
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

  Widget _buildNavTab(
      int index, String title, Color textPrimary, Color textMuted) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(
                color: isSelected ? textPrimary : textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGold : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentGold, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionItem(String text, bool isDark, Color textPrimary) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261C30) : const Color(0xFFEADFF2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.check,
            size: 16,
            color: isDark ? Colors.white : const Color(0xFF533C5E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: textPrimary,
            ),
          ),
        ),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'خيارات وتفاصيل الحجز' : 'Booking Options',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
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
                      Text(
                        widget.tour.title,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.tour.formattedPrice} / ${isAr ? 'للشخص' : 'per person'}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: cardBorder, height: 28),

            // 1. Date Selector
            Text(
              isAr ? 'تاريخ الحجز' : 'Booking Date',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
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
                        colorScheme: ColorScheme(
                          brightness:
                              isDark ? Brightness.dark : Brightness.light,
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
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: AppColors.accentGold, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isAr ? 'تغيير التاريخ' : 'Change Date',
                      style: GoogleFonts.cairo(
                        color: AppColors.accentGold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Person Types / Ticket Quantities
            Text(
              isAr ? 'خيارات التذاكر والزوار' : 'Ticket Options & Guests',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
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
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: q > 0 ? AppColors.accentGold : cardBorder,
                      width: q > 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            if (desc != null && desc.isNotEmpty)
                              Text(
                                desc,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            Text(
                              '${p.price.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.accentGold, size: 22),
                            onPressed: q > 0
                                ? () => setState(
                                    () => _personQuantities[p.name] = q - 1)
                                : null,
                          ),
                          Text(
                            '$q',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.accentGold, size: 22),
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
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'عدد الزوار' : 'Guests',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.accentGold),
                          onPressed: (_personQuantities['default'] ?? 1) > 1
                              ? () => setState(() =>
                                  _personQuantities['default'] =
                                      (_personQuantities['default'] ?? 1) - 1)
                              : null,
                        ),
                        Text(
                          '${_personQuantities['default'] ?? 1}',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.accentGold),
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
              Text(
                isAr ? 'خدمات إضافية اختيارية' : 'Optional Extra Services',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...widget.tour.extraPrices.map((extra) {
                final isSelected = _selectedExtras.contains(extra.name);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentGold : cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CheckboxListTile(
                      activeColor: AppColors.accentGold,
                      checkColor: Colors.black,
                      title: Text(
                        extra.getDisplayName(isAr),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '+ ${extra.price.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
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
                    Text(
                      isAr ? 'المجموع الإجمالي' : 'Total Amount',
                      style: GoogleFonts.cairo(fontSize: 12, color: textMuted),
                    ),
                    Text(
                      '${total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMauve,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isAr ? 'متابعة للدفع والتأكيد' : 'Proceed to Checkout',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
