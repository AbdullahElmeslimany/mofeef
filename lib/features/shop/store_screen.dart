import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import 'data/shop_repository.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  final List<String> _categoriesAr = ['الكل', 'أغذية ومأكولات', 'عطور وبخور', 'مقتنيات وتحف', 'حِرَف يدوية'];
  final List<String> _categoriesEn = ['All', 'Food & Sweets', 'Perfumes & Incense', 'Collectibles', 'Handicrafts'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? const Color(0xFF191222) : const Color(0xFFF7F4F9);

    final categories = isAr ? _categoriesAr : _categoriesEn;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'بازار مُضيف التراثي' : 'Modeef Heritage Bazaar',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231A2D) : const Color(0xFFF0EAF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentGold, size: 20),
            ),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder, width: 1.2),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.primaryMauve,
                style: GoogleFonts.cairo(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث عن مقتنيات، تمور، عطور، تحف...' : 'Search items, dates, perfume...',
                  hintStyle: GoogleFonts.cairo(
                    color: textMuted.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryMauve, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textMuted, size: 18),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // 2. Categories Horizontal Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = (_selectedCategory == cat) ||
                    (_selectedCategory == 'الكل' && cat == (isAr ? 'الكل' : 'All'));

                final pillBg = isSelected
                    ? AppColors.primaryMauve
                    : (isDark ? const Color(0xFF1E1624) : const Color(0xFFEBE6EE));
                final pillText = isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFA59BAE) : const Color(0xFF6B6274));

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: GoogleFonts.cairo(
                        color: pillText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // 3. Products Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final query = _searchController.text.toLowerCase();
                final filtered = products.where((prod) {
                  final matchesCat = _selectedCategory == 'الكل' ||
                      _selectedCategory == 'All' ||
                      prod.category.contains(_selectedCategory);
                  final matchesSearch = query.isEmpty ||
                      prod.title.toLowerCase().contains(query) ||
                      prod.description.toLowerCase().contains(query);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, color: textMuted, size: 54),
                        const SizedBox(height: 14),
                        Text(
                          isAr ? 'لا توجد منتجات مطابقة للبحث' : 'No products found',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final prod = filtered[index];
                    return GestureDetector(
                      onTap: () => context.push('/product/${prod.id}'),
                      child: Container(
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
                            // Product Image
                            Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: prod.imageUrl,
                                  height: 118,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    height: 118,
                                    color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    height: 118,
                                    color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
                                    child: Icon(Icons.image_not_supported_outlined, color: textMuted),
                                  ),
                                ),
                                if (prod.discountPercent != null && prod.discountPercent!.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    right: isAr ? 8 : null,
                                    left: isAr ? null : 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        prod.discountPercent!,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // Details
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
                                        Text(
                                          prod.category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                            color: AppColors.accentGold,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          prod.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prod.price,
                                                style: GoogleFonts.cairo(
                                                  color: AppColors.accentGold,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              if (prod.originalPrice != prod.price)
                                                Text(
                                                  prod.originalPrice,
                                                  style: GoogleFonts.cairo(
                                                    decoration: TextDecoration.lineThrough,
                                                    color: textMuted,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2B2034) : const Color(0xFFEDE7F2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 16,
                                            color: AppColors.primaryMauve,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryMauve),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'تعذر تحميل منتجات البازار' : 'Failed to load products',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.refresh(productsListProvider),
                      child: Text(
                        isAr ? 'إعادة المحاولة' : 'Retry',
                        style: GoogleFonts.cairo(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
