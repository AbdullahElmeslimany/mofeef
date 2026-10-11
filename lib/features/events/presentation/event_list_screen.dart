import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/widgets/unified_item_card.dart';
import '../data/event_repository.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
          isAr ? 'الفعاليات والمواسم السعودية' : 'Saudi Events & Seasons',
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
          // Search Bar
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
                      ? 'ابحث عن فعالية (اليوم الوطني، شتاء مكة)...'
                      : 'Search events (National Day, Winter)...',
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

          // Events List
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                final query = _searchController.text.toLowerCase();
                final filtered = events.where((ev) {
                  return query.isEmpty ||
                      ev.title.toLowerCase().contains(query) ||
                      ev.location.toLowerCase().contains(query) ||
                      ev.description.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_outlined, color: textMuted, size: 54),
                        const SizedBox(height: 14),
                        Text(
                          isAr ? 'لا توجد فعاليات مطابقة للبحث' : 'No events found',
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ev = filtered[index];
                    return UnifiedItemCard(
                      title: ev.title,
                      imageUrl: ev.imageUrl,
                      locationName: ev.location,
                      rating: ev.rating,
                      price: ev.price,
                      accentColor: AppColors.primaryMauve,
                      onTap: () => context.push('/event/${ev.id}'),
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
                      isAr ? 'تعذر تحميل الفعاليات' : 'Failed to load events',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => ref.refresh(eventsListProvider),
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
