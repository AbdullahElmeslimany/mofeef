import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/html_utils.dart';
import '../../../core/utils/share_helper.dart';
import '../../wishlist/data/wishlist_repository.dart';
import '../data/guide_repository.dart';

class GuideDetailScreen extends ConsumerWidget {
  final dynamic guideId;

  const GuideDetailScreen({super.key, required this.guideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final guideAsync = ref.watch(guideDetailProvider(guideId));

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
      body: guideAsync.when(
        data: (guide) {
          final cleanBio = HtmlUtils.stripHtml(guide.title);

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
                                      .isFavorite(guideId, 'guide')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref
                                      .watch(wishlistProvider)
                                      .isFavorite(guideId, 'guide')
                                  ? AppColors.error
                                  : AppColors.accentGold,
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(wishlistProvider.notifier)
                                  .toggleFavorite(
                                    WishlistItemModel(
                                      id: guide.intId ??
                                          int.tryParse(guideId.toString()) ??
                                          0,
                                      objectId: guide.intId ??
                                          int.tryParse(guideId.toString()) ??
                                          0,
                                      objectModel: 'guide',
                                      title: guide.name,
                                      imageUrl: guide.imageUrl,
                                      price: double.tryParse(guide.hourlyRate
                                              .replaceAll(
                                                  RegExp(r'[^0-9.]'), '')) ??
                                          0.0,
                                      location: guide.languages.join(' • '),
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? (isAr
                                              ? 'تمت إضافة المرشد إلى المفضلة ❤️'
                                              : 'Added guide to favorites ❤️')
                                          : (isAr
                                              ? 'تمت إزالة المرشد من المفضلة'
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
                              title: guide.name,
                              category: isAr
                                  ? 'مرشد سياحي معتمد'
                                  : 'Certified Tour Guide',
                              id: guideId.toString(),
                              price: guide.hourlyRate,
                              location: guide.languages.join(' • '),
                              type: 'guide',
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: guide.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: cardBg,
                              child: Icon(Icons.person,
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
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  isAr
                                      ? 'مرشد سياحي معتمد'
                                      : 'Certified Tour Guide',
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
                                    '${guide.rating}',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            guide.name,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildChip(
                                guide.isAvailable
                                    ? (isAr ? 'متاح الآن' : 'Available Now')
                                    : (isAr ? 'غير متاح حالياً' : 'Unavailable'),
                                guide.isAvailable
                                    ? const Color(0xFF2E7D32)
                                    : AppColors.error,
                              ),
                              if (guide.hasDiscount) ...[
                                const SizedBox(width: 8),
                                _buildChip(
                                  isAr ? 'خصم متاح' : 'Discount Available',
                                  AppColors.accentGold,
                                ),
                              ],
                              if (guide.freeConsultation) ...[
                                const SizedBox(width: 8),
                                _buildChip(
                                  isAr
                                      ? 'استشارة مجانية'
                                      : 'Free Consultation',
                                  AppColors.accentGold,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            cleanBio.isNotEmpty
                                ? cleanBio
                                : (isAr
                                    ? 'مرشد سياحي مرخص معتمد يقدم جولات واستشارات ثقافية غنية ومعلومات تاريخية موثقة.'
                                    : 'Certified professional tour guide offering rich cultural tours and verified historical insights.'),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.7,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                  Icons.translate,
                                  isAr ? 'اللغات' : 'Languages',
                                  guide.languages.join('، '),
                                  textPrimary,
                                  textMuted,
                                ),
                                Container(
                                    width: 1, height: 40, color: cardBorder),
                                _buildInfoItem(
                                  Icons.tour_outlined,
                                  isAr ? 'الجولات' : 'Tours',
                                  '${guide.toursCount} ${isAr ? "جولة" : "tours"}',
                                  textPrimary,
                                  textMuted,
                                ),
                                Container(
                                    width: 1, height: 40, color: cardBorder),
                                _buildInfoItem(
                                  Icons.payments_outlined,
                                  isAr ? 'سعر الساعة' : 'Rate/hr',
                                  guide.hourlyRate,
                                  textPrimary,
                                  textMuted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isAr
                                ? 'خدمات الإرشاد السياحي'
                                : 'Guide Services & Expertise',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildServiceTile(
                            Icons.directions_walk,
                            isAr ? 'جولات ميدانية خاصة' : 'Private Field Tours',
                            isAr
                                ? 'مرافقة حية للمواقع الأثرية وشرح تاريخي موثق.'
                                : 'Live accompanying to archaeological sites with verified historical narratives.',
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textMuted,
                          ),
                          const SizedBox(height: 10),
                          _buildServiceTile(
                            Icons.support_agent,
                            isAr
                                ? 'استشارات تخطيط المسارات'
                                : 'Itinerary & Route Planning',
                            isAr
                                ? 'مساعدتك في تصميم جدول سياحي متكامل في المملكة.'
                                : 'Expert guidance in tailoring comprehensive travel schedules across Saudi Arabia.',
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textMuted,
                          ),
                          if (guide.museums.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              isAr
                                  ? 'جولات ومتاحف المرشد'
                                  : 'Associated Museums & Tours',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 190,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: guide.museums.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) =>
                                    _buildHomeStyleCard(
                                  context,
                                  guide.museums[index],
                                  'متحف',
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textMuted,
                                ),
                              ),
                            ),
                          ],
                          if (guide.events.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              isAr ? 'فعاليات المرشد' : 'Associated Events',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: guide.events.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) =>
                                    _buildHomeStyleCard(
                                  context,
                                  guide.events[index],
                                  'فعالية',
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textMuted,
                                ),
                              ),
                            ),
                          ],
                          if (guide.relatedGuides.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              isAr ? 'مرشدون آخرون' : 'Other Certified Guides',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 190,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: guide.relatedGuides.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) =>
                                    _buildHomeStyleCard(
                                  context,
                                  guide.relatedGuides[index],
                                  'مرشد',
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textMuted,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Bottom Sticky Bar matching Figma
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
                              isAr ? 'التكلفة التقريبية' : 'Estimated Rate',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              guide.hourlyRate,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr
                                        ? 'تم إرسال طلب الحجز للمرشد ${guide.name} بنجاح!'
                                        : 'Booking request sent to guide ${guide.name} successfully!',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primaryMauve,
                                ),
                              );
                            },
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
                                  ? 'حجز واستشارة المرشد'
                                  : 'Book & Consult Guide',
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
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'تعذر تحميل تفاصيل المرشد' : 'Failed to load guide details',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (err.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      err.toString(),
                      style: GoogleFonts.cairo(fontSize: 12, color: textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(guideDetailProvider(guideId)),
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

  Widget _buildInfoItem(IconData icon, String title, String value,
      Color textPrimary, Color textMuted) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentGold, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 11, color: textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
      IconData icon,
      String title,
      String desc,
      Color cardBg,
      Color cardBorder,
      Color textPrimary,
      Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accentGold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.cairo(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHomeStyleCard(
      BuildContext context,
      Map<String, dynamic> item,
      String type,
      Color cardBg,
      Color cardBorder,
      Color textPrimary,
      Color textMuted) {
    final title =
        item['title']?.toString() ?? item['name']?.toString() ?? type;
    final rawPrice = item['sale_price']?.toString() ??
        item['price']?.toString() ??
        item['price_per_hour']?.toString();
    final numVal = double.tryParse(rawPrice ?? '');
    final priceText = numVal != null
        ? '${numVal.toStringAsFixed(0)} ﷼'
        : (rawPrice != null && rawPrice.isNotEmpty ? rawPrice : type);
    final imageUrl = item['image']?.toString() ??
        item['image_url']?.toString() ??
        item['avatar_url']?.toString();
    final location = _locationName(item['location']);
    final hasImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null';

    return GestureDetector(
      onTap: () => _openLinkedItem(context, item, type),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 110,
                        color: cardBg,
                        child: Icon(_iconFor(type),
                            color: AppColors.accentGold, size: 36),
                      ),
                    )
                  : Container(
                      height: 110,
                      color: cardBg,
                      child: Icon(_iconFor(type),
                          color: AppColors.accentGold, size: 36),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          location != null && location.isNotEmpty
                              ? location
                              : type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              GoogleFonts.cairo(fontSize: 11, color: textMuted),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        priceText,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLinkedItem(
      BuildContext context, Map<String, dynamic> item, String type) {
    if (type == 'متحف') {
      context.push('/museum/${item['id']}');
    } else if (type == 'فعالية') {
      context.push('/event/${item['id']}');
    } else {
      final id = item['uuid']?.toString() ??
          item['id']?.toString() ??
          (item['id'] ?? '').toString();
      context.push('/guide/$id');
    }
  }

  IconData _iconFor(String type) {
    if (type == 'فعالية') return Icons.event;
    if (type == 'مرشد') return Icons.person;
    return Icons.museum_outlined;
  }

  String? _locationName(dynamic location) {
    if (location == null) return null;
    if (location is Map) {
      return location['name']?.toString();
    }
    final s = location.toString();
    return s.isNotEmpty && s != 'null' ? s : null;
  }
}
