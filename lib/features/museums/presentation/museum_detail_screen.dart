import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/html_utils.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/image_viewer_dialog.dart';
import '../../booking/data/booking_draft.dart';
import '../../wishlist/data/wishlist_repository.dart';
import '../data/museum_repository.dart';

class MuseumDetailScreen extends ConsumerWidget {
  final dynamic museumId;

  const MuseumDetailScreen({super.key, required this.museumId});

  Future<void> _openMap(MuseumModel museum) async {
    final lat = museum.mapLat ?? 24.7136;
    final lng = museum.mapLng ?? 46.6753;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final museumAsync = ref.watch(museumDetailProvider(museumId));
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: museumAsync.when(
        data: (museum) {
          final cleanContent = HtmlUtils.stripHtml(museum.content);
          final img = museum.imageUrl ??
              'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 1. Sliver AppBar with Hero Image
                  SliverAppBar(
                    expandedHeight: 340,
                    pinned: true,
                    backgroundColor: isDark ? const Color(0xFF140E1B) : AppColors.primaryMauve,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: GestureDetector(
                          onTap: () async {
                            final added = await ref.read(wishlistProvider.notifier).toggleFavorite(
                              WishlistItemModel(
                                id: int.tryParse(museumId.toString()) ?? 0,
                                objectId: int.tryParse(museumId.toString()) ?? 0,
                                objectModel: 'museum',
                                title: museum.title,
                                imageUrl: img,
                                price: museum.price,
                                location: museum.locationName,
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? (isAr ? 'تمت إضافة المعلم إلى المفضلة ❤️' : 'Added to favorites ❤️')
                                        : (isAr ? 'تمت إزالة المعلم من المفضلة' : 'Removed from favorites'),
                                    style: GoogleFonts.cairo(),
                                  ),
                                  backgroundColor: added ? AppColors.primaryMauve : cardBg,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ref.watch(wishlistProvider).isFavorite(museumId, 'museum')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref.watch(wishlistProvider).isFavorite(museumId, 'museum')
                                  ? AppColors.error
                                  : Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                        child: GestureDetector(
                          onTap: () => ShareHelper.shareItem(
                            context: context,
                            title: museum.title,
                            category: isAr ? 'متحف ومعلم' : 'Museum & Landmark',
                            id: museumId.toString(),
                            price: museum.formattedPrice,
                            location: museum.locationName,
                            type: 'museum',
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: GestureDetector(
                        onTap: () => ImageViewerDialog.show(context, images: [img]),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: img,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? const Color(0xFF231B2A) : const Color(0xFFECE7EF),
                                child: const Icon(Icons.museum_outlined, color: AppColors.primaryMauve, size: 60),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                    bg.withValues(alpha: 0.85),
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
                  ),

                  // 2. Museum Body Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag & Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMauve.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isAr ? 'متحف ومعلم ثقافي' : 'Museum & Cultural Landmark',
                                  style: GoogleFonts.cairo(
                                    color: isDark ? const Color(0xFFD6C4E6) : AppColors.primaryMauve,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${museum.rating}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${museum.reviewsCount} ${isAr ? 'تقييم' : 'reviews'})',
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

                          // Title
                          Text(
                            museum.title,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Location Pin
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.accentGold, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  museum.locationName ?? (isAr ? 'المملكة العربية السعودية' : 'Saudi Arabia'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.5,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Info Badges Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cardBorder, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                  Icons.access_time_rounded,
                                  isAr ? 'أوقات العمل' : 'Opening Hours',
                                  museum.workingHours ?? (isAr ? '٩ص — ٩م' : '9 AM - 9 PM'),
                                  textPrimary,
                                  textMuted,
                                ),
                                Container(width: 1, height: 40, color: cardBorder),
                                _buildInfoItem(
                                  Icons.confirmation_number_outlined,
                                  isAr ? 'رسوم الدخول' : 'Entry Fee',
                                  museum.formattedPrice,
                                  textPrimary,
                                  textMuted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            isAr ? 'نبذة عن المتحف والمعلم' : 'About Museum & Landmark',
                            style: GoogleFonts.cairo(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cleanContent.isNotEmpty
                                ? cleanContent
                                : (isAr
                                    ? 'صرح تراثي وثقافي عريق يروي تاريخ وأصالة المملكة العربية السعودية.'
                                    : 'An authentic cultural landmark reflecting rich Saudi heritage.'),
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              color: textMuted,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Interactive Google Map Card
                          Text(
                            isAr ? 'الموقع الجغرافي والوصول' : 'Location & Directions',
                            style: GoogleFonts.cairo(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _openMap(museum),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cardBorder, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryMauve.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.directions_outlined, color: AppColors.primaryMauve, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          museum.address ?? museum.locationName ?? (isAr ? 'موقع المتحف والمعلم' : 'Museum Location'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isAr ? 'انقر لفتح الاتجاهات المباشرة عبر خرائط Google' : 'Tap to open in Google Maps',
                                          style: GoogleFonts.cairo(
                                            color: AppColors.accentGold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, color: AppColors.accentGold, size: 18),
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

              // 3. Floating Bottom Booking Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(top: BorderSide(color: cardBorder, width: 1.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'رسوم الدخول' : 'Entry Fee',
                              style: GoogleFonts.cairo(fontSize: 11, color: textMuted),
                            ),
                            Text(
                              museum.formattedPrice,
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
                          child: CustomButton(
                            text: isAr ? 'حجز تذكرة الدخول' : 'Book Entry Ticket',
                            onPressed: () {
                              final draft = BookingDraft(
                                title: museum.title,
                                imageUrl: museum.imageUrl,
                                location: museum.locationName,
                                date: DateTime.now().add(const Duration(days: 1)),
                                serviceType: 'museum',
                                serviceId: int.tryParse(museum.id.toString()) ?? 1,
                                personItems: [
                                  BookingPersonItem(
                                    name: isAr ? 'تذكرة دخول متحف' : 'Museum Entry Ticket',
                                    price: museum.price,
                                    quantity: 1,
                                  ),
                                ],
                                totalAmount: museum.price,
                              );
                              context.push('/checkout/${museum.id}', extra: draft);
                            },
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryMauve),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isAr ? 'تعذر تحميل تفاصيل المتحف' : 'Failed to load museum details',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ref.refresh(museumDetailProvider(museumId)),
                child: Text(
                  isAr ? 'إعادة المحاولة' : 'Retry',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value, Color textPrimary, Color textMuted) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 22),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.cairo(fontSize: 11, color: textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
