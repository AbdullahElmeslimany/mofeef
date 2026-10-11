import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../tours/data/repositories/tour_repository.dart';
import '../events/data/event_repository.dart';
import '../museums/data/museum_repository.dart';
import '../cart/data/cart_repository.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bannerIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    final authState = ref.watch(authProvider);
    final toursAsync = ref.watch(toursListProvider(null));
    final museumsAsync = ref.watch(museumsListProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final cartState = ref.watch(cartNotifierProvider);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Greeting & Actions (From Figma 02 · الرئيسية)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Greeting & Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? (authState.userName != null
                                  ? 'مرحباً، ${authState.userName}'
                                  : 'مرحباً بك')
                              : (authState.userName != null
                                  ? 'Welcome, ${authState.userName}'
                                  : 'Welcome'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSub,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr ? 'إلى أين وجهتك اليوم؟' : 'Where to today?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Actions: Search & Notifications (& Cart if items)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cart Icon (if has items)
                      if (cartState.items.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => context.push('/cart'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardBg,
                              border: Border.all(color: cardBorder),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 19, color: textPrimary),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${cartState.items.length}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Search Button
                      GestureDetector(
                        onTap: () => context.go('/discover'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBg,
                            border: Border.all(color: cardBorder),
                          ),
                          child: Icon(Icons.search_rounded,
                              size: 19, color: textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Notification Button
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBg,
                            border: Border.all(color: cardBorder),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 19, color: textPrimary),
                              Positioned(
                                top: 8,
                                right: 9,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Featured Hero Banner (Matching Figma)
              _buildHeroBanner(context, isAr: isAr),
              const SizedBox(height: 10),

              // Banner Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = _bannerIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accentGold
                          : (isDark
                              ? const Color(0xFF2E243B)
                              : const Color(0xFFDCD2E3)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 3. Categories Grid (الأقسام - 6 Items matching Figma)
              Text(
                isAr ? 'الأقسام' : 'Categories',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoriesGrid(context, isAr: isAr),
              const SizedBox(height: 28),

              // 4. Featured Museums Section (متاحف مميزة)
              _buildSectionHeader(
                title: isAr ? 'متاحف مميزة' : 'Featured Museums',
                onSeeAll: () => context.push('/museums'),
                isAr: isAr,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              museumsAsync.when(
                data: (museums) =>
                    _buildMuseumsRow(context, museums, isAr: isAr),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: AppColors.primaryMauve),
                  ),
                ),
                error: (_, __) => _buildMuseumsRow(context, [], isAr: isAr),
              ),
              const SizedBox(height: 28),

              // 5. Handpicked Experiences Section (تجارب مختارة)
              _buildSectionHeader(
                title: isAr ? 'تجارب مختارة' : 'Handpicked Experiences',
                onSeeAll: () => context.push('/trails'),
                isAr: isAr,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              toursAsync.when(
                data: (tours) =>
                    _buildExperiencesList(context, tours, isAr: isAr),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: AppColors.primaryMauve),
                  ),
                ),
                error: (_, __) =>
                    _buildExperiencesList(context, [], isAr: isAr),
              ),
              const SizedBox(height: 28),

              // 6. Upcoming Events Section (فعاليات قادمة)
              _buildSectionHeader(
                title: isAr ? 'فعاليات قادمة' : 'Upcoming Events',
                onSeeAll: () => context.push('/events'),
                isAr: isAr,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              eventsAsync.when(
                data: (events) => _buildEventsCard(context, events, isAr: isAr),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: AppColors.primaryMauve),
                  ),
                ),
                error: (_, __) => _buildEventsCard(context, [], isAr: isAr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Featured Banner Widget
  Widget _buildHeroBanner(BuildContext context, {required bool isAr}) {
    final banners = [
      {
        'title':
            isAr ? 'المتحف الوطني السعودي' : 'National Museum of Saudi Arabia',
        'subtitle': isAr
            ? 'الرياض · 8 قاعات عرض تاريخية وإسلامية'
            : 'Riyadh · 8 Historical & Islamic Halls',
        'image':
            'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=1200&q=80',
        'route': '/museum/1',
      },
      {
        'title': isAr ? 'متحف قصر المصمك' : 'Al Masmak Fortress Museum',
        'subtitle': isAr
            ? 'الرياض · شاهد انطلاقة توحيد المملكة'
            : 'Riyadh · Witness the founding of the Kingdom',
        'image':
            'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=1200&q=80',
        'route': '/museum/2',
      },
      {
        'title':
            isAr ? 'ليلة لرصد النجوم في العلا' : 'Stargazing Night in AlUla',
        'subtitle': isAr
            ? 'العلا · تجربة فريدة بين جبال وتراث العلا'
            : 'AlUla · Unique experience among starry skies',
        'image':
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&q=80',
        'route': '/experience/17',
      },
    ];

    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: PageView.builder(
          controller: _pageController,
          itemCount: banners.length,
          onPageChanged: (idx) => setState(() => _bannerIndex = idx),
          itemBuilder: (context, index) {
            final b = banners[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: b['image']!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF1B1424)),
                ),

                // Dark Plum Vignette Gradient
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Top "مميز" Badge
                Positioned(
                  top: 14,
                  right: isAr ? 14 : null,
                  left: isAr ? null : 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAr ? 'مميز' : 'Featured',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Content Bottom
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              b['title']!,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              b['subtitle']!,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => context.push(b['route']!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMauve,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAr ? 'احجز تذكرتك' : 'Book Ticket',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 2. Categories Grid (6 Cards from Figma)
  Widget _buildCategoriesGrid(BuildContext context, {required bool isAr}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final categories = [
      {
        'label': isAr ? 'المتاحف' : 'Museums',
        'icon': Icons.account_balance_outlined,
        'route': '/museums',
      },
      {
        'label': isAr ? 'التجارب' : 'Experiences',
        'icon': Icons.auto_awesome_outlined,
        'route': '/trails',
      },
      {
        'label': isAr ? 'الفعاليات' : 'Events',
        'icon': Icons.calendar_today_outlined,
        'route': '/events',
      },
      {
        'label': isAr ? 'السيارات' : 'Cars',
        'icon': Icons.directions_car_outlined,
        'route': '/cars',
      },
      {
        'label': isAr ? 'المرشدين' : 'Guides',
        'icon': Icons.person_pin_outlined,
        'route': '/guides',
      },
      {
        'label': isAr ? 'المتجر' : 'Shop',
        'icon': Icons.shopping_bag_outlined,
        'route': '/store',
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return GestureDetector(
          onTap: () => context.push(cat['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 26,
                  color:
                      isDark ? const Color(0xFFC4B3D4) : AppColors.primaryMauve,
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Featured Museums Row (Side by Side)
  Widget _buildMuseumsRow(BuildContext context, List<dynamic> museums,
      {required bool isAr}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final fallbackItems = [
      {
        'id': '1',
        'title': isAr ? 'المتحف الوطني السعودي' : 'Saudi National Museum',
        'location': isAr ? 'الرياض' : 'Riyadh',
        'rating': 4.9,
        'price': isAr ? 'من 10 ر.س' : 'From 10 SAR',
        'image':
            'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
      },
      {
        'id': '2',
        'title': isAr ? 'متحف قصر المصمك' : 'Al Masmak Fortress',
        'location': isAr ? 'الرياض' : 'Riyadh',
        'rating': 4.8,
        'price': isAr ? 'مجاني' : 'Free',
        'image':
            'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
      },
    ];

    final displayItems = museums.isNotEmpty
        ? museums.take(2).map((m) {
            final double ratingVal = (m is MuseumModel)
                ? m.rating
                : (double.tryParse((m as dynamic).rating?.toString() ??
                        (m as dynamic).ratingAverage?.toString() ??
                        '') ??
                    4.8);
            final bool isFreeVal = (m is MuseumModel)
                ? (m.price <= 0)
                : ((m as dynamic).isFree == true || (m as dynamic).price == 0);
            final dynamic priceVal =
                (m is MuseumModel) ? m.price : (m as dynamic).price;
            return {
              'id': m.id.toString(),
              'title': m.title.toString(),
              'location':
                  m.locationName?.toString() ?? (isAr ? 'المملكة' : 'KSA'),
              'rating': ratingVal,
              'price': isFreeVal
                  ? (isAr ? 'مجاني' : 'Free')
                  : '${priceVal ?? 10} ${isAr ? 'ر.س' : 'SAR'}',
              'image': m.imageUrl ?? fallbackItems.first['image']!,
            };
          }).toList()
        : fallbackItems;

    return Row(
      children: displayItems.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.push('/museum/${item['id']}'),
            child: Container(
              margin: EdgeInsets.only(
                  left: displayItems.first == item ? 8 : 0,
                  right: displayItems.last == item ? 8 : 0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: item['image'] as String,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: textSub),
                            const SizedBox(width: 4),
                            Text(
                              item['location'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 16, color: AppColors.accentGold),
                                const SizedBox(width: 2),
                                Text(
                                  '${item['rating']}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              item['price'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
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
          ),
        );
      }).toList(),
    );
  }

  // 4. Handpicked Experiences List
  Widget _buildExperiencesList(BuildContext context, List<dynamic> tours,
      {required bool isAr}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final defaultExperiences = [
      {
        'id': '17',
        'title':
            isAr ? 'جولة تاريخية في الدرعية' : 'Historical Tour in Diriyah',
        'guide':
            isAr ? 'مع سعد الدوسري · الرياض' : 'With Saad Al-Dossari · Riyadh',
        'image':
            'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
      },
      {
        'id': '18',
        'title':
            isAr ? 'ليلة لرصد النجوم في العلا' : 'Stargazing Night in AlUla',
        'guide':
            isAr ? 'مع نور الغامدي · العلا' : 'With Nour Al-Ghamdi · AlUla',
        'image':
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80',
      },
      {
        'id': '19',
        'title': isAr
            ? 'غوص وتراث بحري في جدة'
            : 'Diving & Marine Heritage in Jeddah',
        'guide':
            isAr ? 'مع خالد الزهراني · البحر الأحمر' : 'With Khaled · Red Sea',
        'image':
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80',
      },
    ];

    final items = tours.isNotEmpty
        ? tours.take(3).map((t) {
            return {
              'id': t.id.toString(),
              'title': t.title.toString(),
              'guide': t.locationName != null
                  ? '${isAr ? 'الوجهة: ' : 'Location: '}${t.locationName}'
                  : (isAr ? 'المملكة العربية السعودية' : 'Saudi Arabia'),
              'image': t.imageUrl ?? defaultExperiences.first['image']!,
            };
          }).toList()
        : defaultExperiences;

    return Column(
      children: items.map((item) {
        return GestureDetector(
          onTap: () => context.push('/experience/${item['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                // Chevron icon
                Icon(
                  isAr
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: textSub,
                  size: 22,
                ),
                const SizedBox(width: 8),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['guide']!,
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF261D30)
                              : const Color(0xFFF1E9F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAr ? 'تجربة' : 'Experience',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFC7B5D6)
                                : AppColors.primaryMauve,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: item['image']!,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Upcoming Events Card
  Widget _buildEventsCard(BuildContext context, List<dynamic> events,
      {required bool isAr}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final firstEvent = events.isNotEmpty ? events.first : null;
    final title = firstEvent?.title ??
        (isAr ? 'موسم الرياض التراثي' : 'Riyadh Heritage Season');
    final loc = firstEvent?.locationName ??
        (isAr ? 'الرياض · قريباً' : 'Riyadh · Soon');
    final id = firstEvent?.id?.toString() ?? '12';

    return GestureDetector(
      onTap: () => context.push('/event/$id'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 14, color: AppColors.accentGold),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? 'تذاكر متاحة' : 'Tickets Available',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Date Badge Block
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF261D32) : const Color(0xFFEDE4F4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '--',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    isAr ? 'الشهر' : 'Month',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header with "عرض الكل >"
  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onSeeAll,
    required bool isAr,
    required Color textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text(
                isAr ? 'عرض الكل' : 'View All',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
              Icon(
                isAr ? Icons.chevron_left : Icons.chevron_right,
                size: 16,
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
