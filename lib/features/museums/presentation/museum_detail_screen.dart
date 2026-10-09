import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
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
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
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

    return Scaffold(
      body: museumAsync.when(
        data: (museum) {
          final cleanContent = HtmlUtils.stripHtml(museum.content);
          final img = museum.imageUrl ??
              'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 320,
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
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: Icon(
                              ref
                                      .watch(wishlistProvider)
                                      .isFavorite(museumId, 'museum')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref
                                      .watch(wishlistProvider)
                                      .isFavorite(museumId, 'museum')
                                  ? AppColors.error
                                  : AppColors.primaryGold,
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(wishlistProvider.notifier)
                                  .toggleFavorite(
                                    WishlistItemModel(
                                      id: int.tryParse(museumId.toString()) ??
                                          0,
                                      objectId:
                                          int.tryParse(museumId.toString()) ??
                                              0,
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
                                    content: Text(added
                                        ? (isAr
                                            ? 'تمت إضافة المعلم إلى المفضلة ❤️'
                                            : 'Added landmark to favorites ❤️')
                                        : (isAr
                                            ? 'تمت إزالة المعلم من المفضلة'
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.white),
                            onPressed: () => ShareHelper.shareItem(
                              context: context,
                              title: museum.title,
                              category:
                                  isAr ? 'متحف ومعلم' : 'Museum & Landmark',
                              id: museumId.toString(),
                              price: museum.formattedPrice,
                              location: museum.locationName,
                              type: 'museum',
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: GestureDetector(
                        onTap: () =>
                            ImageViewerDialog.show(context, images: [img]),
                        child: CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.museum_outlined,
                                color: AppColors.primaryGold, size: 60),
                          ),
                        ),
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
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldGlow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAr
                                      ? 'متحف ومعلم ثقافي'
                                      : 'Museum & Cultural Landmark',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: AppColors.primaryGold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${museum.rating} (${museum.reviewsCount} ${isAr ? 'تقييم' : 'reviews'})',
                                    style: AppTypography.titleSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(museum.title,
                              style: AppTypography.headingMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.primaryGold, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                    museum.locationName ??
                                        (isAr
                                            ? 'المملكة العربية السعودية'
                                            : 'Saudi Arabia'),
                                    style: AppTypography.bodyMedium),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                    Icons.access_time,
                                    isAr ? 'أوقات العمل' : 'Opening Hours',
                                    museum.workingHours ??
                                        (isAr ? '٩ص — ٩م' : '9 AM - 9 PM')),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: AppColors.border),
                                _buildInfoItem(
                                    Icons.confirmation_number_outlined,
                                    isAr ? 'رسوم الدخول' : 'Entry Fee',
                                    museum.formattedPrice),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                              isAr
                                  ? 'نبذة عن المتحف والمعلم'
                                  : 'About Museum & Landmark',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            cleanContent.isNotEmpty
                                ? cleanContent
                                : (isAr
                                    ? 'صرح تراثي وثقافي عريق يروي تاريخ وأصالة المملكة العربية السعودية.'
                                    : 'An authentic cultural landmark reflecting rich Saudi heritage.'),
                            style:
                                AppTypography.bodyLarge.copyWith(height: 1.6),
                          ),
                          const SizedBox(height: 24),

                          // Interactive Google Map Section
                          Text(
                              isAr
                                  ? 'الموقع الجغرافي والوصول'
                                  : 'Location & Directions',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _openMap(museum),
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
                                          museum.address ??
                                              museum.locationName ??
                                              (isAr
                                                  ? 'موقع المتحف والمعلم'
                                                  : 'Museum Location'),
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isAr ? 'سعر الدخول' : 'Ticket Price',
                                style: AppTypography.bodySmall),
                            Text(museum.formattedPrice,
                                style: AppTypography.price),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: CustomButton(
                            text:
                                isAr ? 'حجز تذكرة الدخول' : 'Book Entry Ticket',
                            onPressed: () {
                              final draft = BookingDraft(
                                title: museum.title,
                                imageUrl: museum.imageUrl,
                                location: museum.locationName,
                                date:
                                    DateTime.now().add(const Duration(days: 1)),
                                serviceType: 'museum',
                                serviceId:
                                    int.tryParse(museum.id.toString()) ?? 1,
                                personItems: [
                                  BookingPersonItem(
                                    name: isAr
                                        ? 'تذكرة دخول متحف'
                                        : 'Museum Ticket',
                                    price: museum.price,
                                    quantity: 1,
                                  ),
                                ],
                                totalAmount: museum.price,
                              );
                              context.push('/checkout/${museum.id}',
                                  extra: draft);
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
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  isAr
                      ? 'تعذر تحميل تفاصيل المتحف'
                      : 'Failed to load museum details',
                  style: AppTypography.titleLarge),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(museumDetailProvider(museumId)),
                child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
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
