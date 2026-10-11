import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/unified_item_card.dart';
import '../../tours/data/models/tour_model.dart';
import '../../tours/data/repositories/tour_repository.dart';
import '../../events/data/event_repository.dart';
import '../../museums/data/museum_repository.dart';
import '../../guides/data/guide_repository.dart';
import '../../guides/presentation/guide_list_screen.dart';

final destinationToursProvider =
    FutureProvider.family<List<TourModel>, int>((ref, locationId) async {
  return ref.watch(tourRepositoryProvider).searchTours(locationId: locationId);
});

final destinationEventsProvider =
    FutureProvider.family<List<EventItemModel>, int>((ref, locationId) async {
  return ref
      .watch(eventRepositoryProvider)
      .searchEvents(locationId: locationId);
});

final destinationMuseumsProvider =
    FutureProvider.family<List<MuseumModel>, int>((ref, locationId) async {
  return ref
      .watch(museumRepositoryProvider)
      .searchMuseums(locationId: locationId);
});

final destinationGuidesProvider =
    FutureProvider.family<List<GuideModel>, int>((ref, locationId) async {
  return ref
      .watch(guideRepositoryProvider)
      .searchGuides(locationId: locationId);
});

class DestinationDetailScreen extends ConsumerStatefulWidget {
  final int locationId;
  final String? initialName;

  const DestinationDetailScreen({
    super.key,
    required this.locationId,
    this.initialName,
  });

  @override
  ConsumerState<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState
    extends ConsumerState<DestinationDetailScreen> {
  int _selectedTab = 0; // 0: Tours, 1: Events, 2: Museums, 3: Guides

  String _getCityBanner(int id) {
    switch (id) {
      case 1:
        return 'https://staging.modeef-e.com/uploads/0000/6/2026/06/03/1395849838834267800-jpg-webp.jpg';
      case 2:
        return 'https://staging.modeef-e.com/uploads/0000/6/2026/06/03/almzarat-aldyny.jpg';
      case 3:
        return 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80';
      case 4:
        return 'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80';
      default:
        return 'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80';
    }
  }

  String _getCityName(int id, bool isAr) {
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      return widget.initialName!;
    }
    switch (id) {
      case 1:
        return isAr ? 'مكة المكرمة' : 'Makkah';
      case 2:
        return isAr ? 'المدينة المنورة' : 'Madinah';
      case 3:
        return isAr ? 'العُلا' : 'AlUla';
      case 4:
        return isAr ? 'الدرعية' : 'Diriyah';
      default:
        return isAr ? 'الوجهة السياحية' : 'Destination';
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final cityName = _getCityName(widget.locationId, isAr);
    final bannerImg = _getCityBanner(widget.locationId);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // Hero Banner
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF140E1B) : AppColors.primaryMauve,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => ShareHelper.shareItem(
                    context: context,
                    title: cityName,
                    category: isAr ? 'وجهة سياحية' : 'Destination',
                    id: widget.locationId.toString(),
                    type: 'destination',
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_outlined,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                cityName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: bannerImg,
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          bg.withValues(alpha: 0.9),
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

          // Tabs & Filter Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? 'استكشف كافة المسارات والفعاليات والمتاحف في $cityName'
                        : 'Explore all trails, events, and museums in $cityName',
                    style: GoogleFonts.cairo(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Segmented Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab(
                            0,
                            isAr ? 'المسارات' : 'Trails',
                            Icons.alt_route,
                            isDark,
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textMuted),
                        const SizedBox(width: 8),
                        _buildTab(
                            1,
                            isAr ? 'الفعاليات' : 'Events',
                            Icons.festival_outlined,
                            isDark,
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textMuted),
                        const SizedBox(width: 8),
                        _buildTab(
                            2,
                            isAr ? 'المتاحف' : 'Museums',
                            Icons.account_balance_outlined,
                            isDark,
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textMuted),
                        const SizedBox(width: 8),
                        _buildTab(
                            3,
                            isAr ? 'المرشدون' : 'Guides',
                            Icons.person_pin_outlined,
                            isDark,
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          _buildActiveTabContent(isAr, cityName, textMuted),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon, bool isDark,
      Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryMauve
              : (isDark ? const Color(0xFF1E1624) : const Color(0xFFECE7EF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryMauve : cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isAr, String cityName, Color textMuted) {
    switch (_selectedTab) {
      case 0:
        final toursAsync =
            ref.watch(destinationToursProvider(widget.locationId));
        return toursAsync.when(
          data: (tours) {
            if (tours.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    isAr
                        ? 'لا توجد مسارات متاحة حالياً في هذه الوجهة'
                        : 'No trails available in this destination',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final t = tours[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UnifiedItemCard(
                        title: t.title,
                        imageUrl: t.imageUrl,
                        locationName: t.locationName ?? cityName,
                        rating: t.rating,
                        subtitle: t.duration,
                        price: t.formattedPrice,
                        accentColor: AppColors.primaryMauve,
                        onTap: () => context.push('/experience/${t.id}'),
                      ),
                    );
                  },
                  childCount: tours.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryMauve)),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                isAr ? 'تعذر تحميل المسارات' : 'Failed to load trails',
                style: GoogleFonts.cairo(color: textMuted),
              ),
            ),
          ),
        );

      case 1:
        final eventsAsync =
            ref.watch(destinationEventsProvider(widget.locationId));
        return eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    isAr
                        ? 'لا توجد فعاليات في هذه الوجهة'
                        : 'No events in this destination',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final ev = events[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UnifiedItemCard(
                        title: ev.title,
                        imageUrl: ev.imageUrl,
                        locationName:
                            ev.location.isNotEmpty ? ev.location : cityName,
                        rating: ev.rating,
                        subtitle: ev.duration,
                        price: ev.price,
                        accentColor: AppColors.primaryMauve,
                        onTap: () => context.push('/event/${ev.id}'),
                      ),
                    );
                  },
                  childCount: events.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryMauve)),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                isAr ? 'تعذر تحميل الفعاليات' : 'Failed to load events',
                style: GoogleFonts.cairo(color: textMuted),
              ),
            ),
          ),
        );

      case 2:
        final museumsAsync =
            ref.watch(destinationMuseumsProvider(widget.locationId));
        return museumsAsync.when(
          data: (museums) {
            if (museums.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    isAr
                        ? 'لا توجد متاحف في هذه الوجهة'
                        : 'No museums in this destination',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final m = museums[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UnifiedItemCard(
                        title: m.title,
                        imageUrl: m.imageUrl,
                        locationName: m.locationName ?? cityName,
                        rating: m.rating,
                        subtitle: m.workingHours,
                        price: m.formattedPrice,
                        accentColor: AppColors.primaryMauve,
                        onTap: () => context.push('/museum/${m.id}'),
                      ),
                    );
                  },
                  childCount: museums.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryMauve)),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                isAr ? 'تعذر تحميل المتاحف' : 'Failed to load museums',
                style: GoogleFonts.cairo(color: textMuted),
              ),
            ),
          ),
        );

      case 3:
      default:
        final guidesAsync =
            ref.watch(destinationGuidesProvider(widget.locationId));
        return guidesAsync.when(
          data: (guides) {
            if (guides.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    isAr
                        ? 'لا يوجد مرشدون سياحيون متاحون في هذه الوجهة'
                        : 'No guides in this destination',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final g = guides[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UnifiedItemCard(
                        title: g.name,
                        imageUrl: g.imageUrl,
                        locationName: g.title,
                        rating: g.rating,
                        subtitle: g.languages.join(' • '),
                        price: g.hourlyRate,
                        accentColor: AppColors.primaryMauve,
                        onTap: () => context.push('/guide/${g.id}'),
                      ),
                    );
                  },
                  childCount: guides.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryMauve)),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                isAr ? 'تعذر تحميل المرشدين' : 'Failed to load guides',
                style: GoogleFonts.cairo(color: textMuted),
              ),
            ),
          ),
        );
    }
  }
}
