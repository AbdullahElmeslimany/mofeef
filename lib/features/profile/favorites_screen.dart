import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../wishlist/data/wishlist_repository.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _selectedFilterIndex = 0; // 0: الكل, 1: المتاحف, 2: المتجر, 3: المرشدين

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final wishlistState = ref.watch(wishlistProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final filterTabs = isAr
        ? ['الكل', 'المتاحف', 'المتجر', 'المرشدين']
        : ['All', 'Museums', 'Shop', 'Guides'];



    // Map strictly from real user wishlist
    final liveItems = wishlistState.items;
    final List<Map<String, dynamic>> displayItems = liveItems.map((item) {
      String cat = isAr ? 'مسار سياحي' : 'Trail';
      String btn = isAr ? 'احجز' : 'Book';
      String route = '/experience/${item.objectId}';

      if (item.objectModel == 'museum') {
        cat = isAr ? 'متحف' : 'Museum';
        route = '/museum/${item.objectId}';
      } else if (item.objectModel == 'product') {
        cat = isAr ? 'المتجر' : 'Shop';
        btn = isAr ? 'أضف للسلة' : 'Add to Cart';
        route = '/product/${item.objectId}';
      } else if (item.objectModel == 'guide') {
        cat = isAr ? 'مرشد' : 'Guide';
        route = '/guide/${item.objectId}';
      } else if (item.objectModel == 'event') {
        cat = isAr ? 'فعالية' : 'Event';
        route = '/event/${item.objectId}';
      }

      return {
        'id': item.objectId.toString(),
        'type': item.objectModel,
        'category': cat,
        'title': item.title,
        'price': '${item.price.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}',
        'rating': 4.8,
        'meta': '${item.price.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}',
        'btnText': btn,
        'route': route,
        'image': item.imageUrl ?? 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
      };
    }).toList();

    // Filter by selected chip
    final filteredItems = displayItems.where((item) {
      if (_selectedFilterIndex == 0) return true;
      if (_selectedFilterIndex == 1) return item['type'] == 'museum';
      if (_selectedFilterIndex == 2) return item['type'] == 'shop' || item['type'] == 'product';
      if (_selectedFilterIndex == 3) return item['type'] == 'guide';
      return true;
    }).toList();

    final countText = isAr
        ? '${filteredItems.length} عناصر محفوظة'
        : '${filteredItems.length} saved items';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (المفضلة + عدد العناصر المحفوظة)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'المفضلة' : 'Favorites',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    countText,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Pills (الكل، المتاحف، المتجر، المرشدين)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: filterTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final title = filterTabs[index];
                  final isSelected = _selectedFilterIndex == index;

                  final pillBg = isSelected
                      ? AppColors.primaryMauve
                      : (isDark ? const Color(0xFF1E1624) : const Color(0xFFEBE6EE));
                  final pillText = isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFA59BAE) : const Color(0xFF6B6274));

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: pillText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // 3. 2-Column Grid of Favorite Cards (Figma 05 · المفضلة)
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState(isAr, isDark, textPrimary, textSub)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.58,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildFavoriteGridCard(
                          context,
                          item: item,
                          isDark: isDark,
                          isAr: isAr,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSub: textSub,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 2-Column Favorite Grid Card exactly matching Figma 05
  Widget _buildFavoriteGridCard(
    BuildContext context, {
    required Map<String, dynamic> item,
    required bool isDark,
    required bool isAr,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
  }) {
    final double rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    final String btnText = item['btnText'] as String;
    final String route = item['route'] as String;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Image
          CachedNetworkImage(
            imageUrl: item['image'] as String,
            height: 118,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 118,
              color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
            ),
          ),

          // 2. Body Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag (e.g. المتجر / متحف · جدة)
                      Text(
                        item['category'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSub,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Title
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Meta Row: Rating / Price / Experience
                      if (rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item['meta'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textSub,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          item['meta'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textSub,
                          ),
                        ),
                    ],
                  ),

                  // 3. Action Button (احجز / أضف للسلة)
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        if (btnText.contains('سلة') || btnText.contains('Cart')) {
                          context.push('/cart');
                        } else {
                          context.push(route);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2B2034)
                            : const Color(0xFFEDE7F2),
                        foregroundColor: isDark ? Colors.white : AppColors.primaryMauve,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        btnText,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isAr, bool isDark, Color textPrimary, Color textSub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231A2D) : const Color(0xFFF3EEF7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: isDark ? const Color(0xFFC7B8D6) : AppColors.primaryMauve,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'لا توجد عناصر محفوظة' : 'No saved items',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'احفظ معالمك وتجاربك المفضلة لتظهر هنا.'
                  : 'Bookmark your favorite places to find them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13, color: textSub),
            ),
          ],
        ),
      ),
    );
  }
}
