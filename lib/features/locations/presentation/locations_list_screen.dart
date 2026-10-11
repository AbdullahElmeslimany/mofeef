import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../discovery/data/models/discovery_models.dart';
import '../../discovery/data/repositories/discovery_repository.dart';

class LocationsListScreen extends ConsumerStatefulWidget {
  const LocationsListScreen({super.key});

  @override
  ConsumerState<LocationsListScreen> createState() =>
      _LocationsListScreenState();
}

class _LocationsListScreenState extends ConsumerState<LocationsListScreen> {
  final _searchController = TextEditingController();

  final List<LocationModel> _featuredLocations = const [
    LocationModel(
      id: 1,
      name: 'مكة المكرمة',
      slug: 'تراث وإسلامي',
      imageUrl:
          'https://staging.modeef-e.com/uploads/0000/6/2026/06/03/1395849838834267800-jpg-webp.jpg',
      bannerUrl:
          'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
    ),
    LocationModel(
      id: 2,
      name: 'المدينة المنورة',
      slug: 'تراث وإسلامي',
      imageUrl:
          'https://staging.modeef-e.com/uploads/0000/6/2026/06/03/almzarat-aldyny.jpg',
      bannerUrl:
          'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
    ),
    LocationModel(
      id: 3,
      name: 'العُلا',
      slug: 'تراث عالمي',
      imageUrl:
          'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
    ),
    LocationModel(
      id: 4,
      name: 'الدرعية',
      slug: 'تاريخ وأصالة',
      imageUrl:
          'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
    ),
    LocationModel(
      id: 5,
      name: 'جدة التاريخية (البلد)',
      slug: 'ثقافة وحضارة',
      imageUrl:
          'https://images.unsplash.com/photo-1578895101407-28d8442e61df?w=800&q=80',
    ),
    LocationModel(
      id: 6,
      name: 'الرياض',
      slug: 'عاصمة الثقافة',
      imageUrl:
          'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80',
    ),
    LocationModel(
      id: 7,
      name: 'عسير ورجال ألمع',
      slug: 'طبيعة وتراث',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
    ),
    LocationModel(
      id: 8,
      name: 'البحر الأحمر',
      slug: 'طبيعة وسياحة ساحلية',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
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
    final inputBg = isDark ? const Color(0xFF191222) : const Color(0xFFF7F4F9);

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
          isAr ? 'الوجهات السياحية السعودية' : 'Saudi Destinations',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Box
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
                style: GoogleFonts.cairo(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'ابحث عن وجهة أو مدينة (العلا، الرياض...)'
                      : 'Search destinations (AlUla, Riyadh)...',
                  hintStyle: GoogleFonts.cairo(
                      color: textMuted.withValues(alpha: 0.7), fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.primaryMauve, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textMuted, size: 18),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Grid of Destinations
          Expanded(
            child: locationsAsync.when(
              data: (apiLocations) {
                final allLocations =
                    apiLocations.isNotEmpty ? apiLocations : _featuredLocations;
                final query = _searchController.text.toLowerCase();
                final filtered = allLocations.where((loc) {
                  return query.isEmpty ||
                      loc.name.toLowerCase().contains(query) ||
                      (loc.slug?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined,
                            color: textMuted, size: 54),
                        const SizedBox(height: 14),
                        Text(
                          isAr
                              ? 'لا توجد وجهات مطابقة للبحث'
                              : 'No destinations found',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final loc = filtered[index];
                    return GestureDetector(
                      onTap: () => context.push(
                          '/location/${loc.id}?name=${Uri.encodeComponent(loc.name)}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: loc.imageUrl ??
                                  'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? const Color(0xFF221A2A)
                                    : const Color(0xFFECE7EF),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark
                                    ? const Color(0xFF221A2A)
                                    : const Color(0xFFECE7EF),
                                child: Icon(Icons.landscape_outlined,
                                    color: textMuted, size: 36),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                  stops: const [0.3, 0.6, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              left: 14,
                              right: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    loc.name,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (loc.slug != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      loc.slug!,
                                      style: GoogleFonts.cairo(
                                        color: AppColors.accentGold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
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
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr
                          ? 'تعذر تحميل الوجهات'
                          : 'Failed to load destinations',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => ref.refresh(locationsProvider),
                      child: Text(
                        isAr ? 'إعادة المحاولة' : 'Retry',
                        style: GoogleFonts.cairo(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold),
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
