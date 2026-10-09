import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/utils/share_helper.dart';
import '../../core/widgets/custom_button.dart';
import '../cart/data/cart_repository.dart';
import 'data/shop_repository.dart';
import '../wishlist/data/wishlist_repository.dart';
import 'models/product_model.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedTab = 0; // 0: Description, 1: Specifications, 2: Shipping
  int _currentGalleryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final prodAsync = ref.watch(productDetailProvider(widget.productId));
    final cartState = ref.watch(cartNotifierProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    return Scaffold(
      body: prodAsync.when(
        data: (prod) {
          final images =
              prod.gallery.isNotEmpty ? prod.gallery : [prod.imageUrl];

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Top Hero Image / Gallery with Glass Controls
                  SliverAppBar(
                    expandedHeight: 360,
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
                                      .isFavorite(widget.productId, 'product')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.productId, 'product')
                                  ? AppColors.error
                                  : AppColors.primaryGold,
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(wishlistProvider.notifier)
                                  .toggleFavorite(
                                    WishlistItemModel(
                                      id: int.tryParse(
                                              widget.productId.toString()) ??
                                          0,
                                      objectId: int.tryParse(
                                              widget.productId.toString()) ??
                                          0,
                                      objectModel: 'product',
                                      title: prod.title,
                                      imageUrl: prod.imageUrl,
                                      price: prod.priceNumeric,
                                      location: isAr
                                          ? 'المتجر التراثي'
                                          : 'Heritage Shop',
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(added
                                        ? (isAr
                                            ? 'تمت إضافة المنتج إلى المفضلة ❤️'
                                            : 'Added product to favorites ❤️')
                                        : (isAr
                                            ? 'تمت إزالة المنتج من المفضلة'
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
                              title: prod.title,
                              category: 'متجر مضيف',
                              id: widget.productId,
                              price: prod.price,
                              type: 'product',
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.55),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_bag_outlined,
                                    color: Colors.white),
                                onPressed: () => context.push('/cart'),
                              ),
                            ),
                            if (cartState.itemCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${cartState.itemCount}',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (idx) =>
                                setState(() => _currentGalleryIndex = idx),
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.image_not_supported,
                                      color: AppColors.textMuted),
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
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                  AppColors.background.withOpacity(0.9),
                                  AppColors.background,
                                ],
                                stops: const [0.0, 0.4, 0.85, 1.0],
                              ),
                            ),
                          ),
                          // Image counter badge if multiple images
                          if (images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: isAr ? 16 : null,
                              right: isAr ? null : 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  '📸 ${_currentGalleryIndex + 1} / ${images.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Glass Badge "بازار مُضيف للمقتنيات"
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.storefront,
                                        color: AppColors.primaryGold, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      prod.storeName,
                                      style: const TextStyle(
                                          color: AppColors.primaryGold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  prod.category,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Product Title
                          Text(prod.title, style: AppTypography.headingMedium),

                          const SizedBox(height: 8),

                          // Rating & SKU
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.primaryGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${prod.rating} (${prod.reviewsCount} ${isAr ? 'تقييم' : 'reviews'})',
                                style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (prod.sku != null && prod.sku!.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'SKU: ${prod.sku}',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Price & Quantity Card matching Figma
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(isAr ? 'السعر' : 'Price',
                                            style: AppTypography.bodySmall),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(prod.price,
                                                style: AppTypography.price
                                                    .copyWith(fontSize: 24)),
                                            if (prod.originalPrice !=
                                                prod.price) ...[
                                              const SizedBox(width: 10),
                                              Text(
                                                prod.originalPrice,
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: AppColors.textMuted,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Quantity Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                size: 18,
                                                color: AppColors.textPrimary),
                                            onPressed: _quantity > 1
                                                ? () =>
                                                    setState(() => _quantity--)
                                                : null,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text('$_quantity',
                                                style:
                                                    AppTypography.titleMedium),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                size: 18,
                                                color: AppColors.primaryGold),
                                            onPressed: () =>
                                                setState(() => _quantity++),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 8),

                                // Stock Status Row
                                Row(
                                  children: [
                                    Icon(
                                      prod.inStock
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      color: prod.inStock
                                          ? AppColors.success
                                          : AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      prod.inStock
                                          ? (isAr
                                              ? 'متوفر في المخزون (${prod.quantity} قطعة)'
                                              : 'In Stock (${prod.quantity} items)')
                                          : (isAr
                                              ? 'نفذت الكمية'
                                              : 'Out of stock'),
                                      style: TextStyle(
                                        color: prod.inStock
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (prod.discountPercent != null &&
                                        prod.discountPercent!.isNotEmpty) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.error.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.error
                                                  .withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          'خصم ${prod.discountPercent}',
                                          style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Segmented Tabs matching Figma: [الوصف, التفاصيل والمواصفات, الشحن والضمان]
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                _buildTabButton(
                                    0, isAr ? 'الوصف' : 'Description'),
                                _buildTabButton(
                                    1, isAr ? 'المواصفات' : 'Specifications'),
                                _buildTabButton(
                                    2, isAr ? 'الشحن والضمان' : 'Shipping'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tab Content
                          _buildTabContent(prod, isAr),

                          const SizedBox(height: 28),

                          // Related Products Section matching Figma ("منتجات مشابهة")
                          if (prod.related.isNotEmpty) ...[
                            Text(isAr ? 'منتجات مشابهة' : 'Related Products',
                                style: AppTypography.titleLarge),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 190,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: prod.related.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, idx) {
                                  final rel = prod.related[idx];
                                  return GestureDetector(
                                    onTap: () =>
                                        context.push('/product/${rel.id}'),
                                    child: Container(
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(16)),
                                            child: CachedNetworkImage(
                                              imageUrl: rel.imageUrl,
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rel.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography
                                                      .titleSmall
                                                      .copyWith(fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(rel.price,
                                                    style: AppTypography.price
                                                        .copyWith(
                                                            fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

              // Bottom Action Bar matching Figma ("أضف للسلة" + "اشتر الآن")
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border:
                        const Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primaryGold, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              for (int i = 0; i < _quantity; i++) {
                                ref
                                    .read(cartNotifierProvider.notifier)
                                    .addItem(prod);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr
                                      ? 'تمت إضافة $_quantity إلى السلة بنجاح!'
                                      : 'Added $_quantity item(s) to cart!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_bag_outlined,
                                    color: AppColors.primaryGold, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isAr ? 'أضف للسلة' : 'Add to Cart',
                                  style: const TextStyle(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: isAr ? 'اشتر الآن' : 'Buy Now',
                            icon: Icons.flash_on,
                            onPressed: () {
                              for (int i = 0; i < _quantity; i++) {
                                ref
                                    .read(cartNotifierProvider.notifier)
                                    .addItem(prod);
                              }
                              context.push('/cart');
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
        loading: () => const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold)),
        ),
        error: (err, __) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                    isAr
                        ? 'تعذر تحميل تفاصيل المنتج'
                        : 'Failed to load product details',
                    style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(productDetailProvider(widget.productId)),
                  child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.textDark : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ProductModel prod, bool isAr) {
    switch (_selectedTab) {
      case 0:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            prod.description,
            style: AppTypography.bodyLarge.copyWith(height: 1.7),
          ),
        );
      case 1:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (prod.specifications.isNotEmpty)
                ...prod.specifications.map((spec) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(spec.title,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textMuted)),
                          Text(spec.content,
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ))
              else ...[
                _buildSpecRow(isAr ? 'النوع' : 'Type', prod.category),
                _buildSpecRow(isAr ? 'المصدر' : 'Source',
                    isAr ? 'المملكة العربية السعودية' : 'Saudi Arabia'),
                _buildSpecRow(isAr ? 'الضمان' : 'Authenticity',
                    isAr ? 'أصلي ١٠٠٪ معتمد' : '100% Authentic'),
              ],
            ],
          ),
        );
      case 2:
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildTrustRow(
                  Icons.local_shipping_outlined,
                  isAr ? 'شحن سريع ومبرد' : 'Express Delivery',
                  isAr
                      ? 'توصيل مبرد لكافة مناطق المملكة خلال ٢-٤ أيام عمل'
                      : 'Fast temperature-controlled shipping 2-4 days'),
              const SizedBox(height: 12),
              _buildTrustRow(
                  Icons.verified_outlined,
                  isAr ? 'ضمان الأصالة والجودة' : 'Quality Guaranteed',
                  isAr
                      ? 'منتجات حصرية موثوقة من أفضل مزارع وحرفيي المملكة'
                      : '100% genuine products directly from local artisans'),
              const SizedBox(height: 12),
              _buildTrustRow(
                  Icons.assignment_return_outlined,
                  isAr ? 'سياسة استرجاع مرنة' : 'Easy Returns',
                  isAr
                      ? 'إمكانية الاسترجاع أو الاستبدال خلال ٧ أيام'
                      : 'Hassle-free return policy within 7 days'),
            ],
          ),
        );
    }
  }

  Widget _buildSpecRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted)),
          Text(val,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrustRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.goldGlow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
