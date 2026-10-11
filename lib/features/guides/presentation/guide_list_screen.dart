import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../data/guide_repository.dart';

class GuideModel {
  final String id;
  final int? intId;
  final String name;
  final String title;
  final List<String> languages;
  final double rating;
  final int toursCount;
  final String hourlyRate;
  final String imageUrl;
  final String? city;
  final String? yearStarted;
  final bool isAvailable;
  final bool freeConsultation;
  final bool hasDiscount;
  final List<Map<String, dynamic>> museums;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> relatedGuides;

  const GuideModel({
    required this.id,
    this.intId,
    required this.name,
    required this.title,
    required this.languages,
    required this.rating,
    required this.toursCount,
    required this.hourlyRate,
    required this.imageUrl,
    this.city,
    this.yearStarted,
    this.isAvailable = true,
    this.freeConsultation = false,
    this.hasDiscount = false,
    this.museums = const [],
    this.events = const [],
    this.relatedGuides = const [],
  });
}

class GuideListScreen extends ConsumerWidget {
  const GuideListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(guidesListProvider);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'المرشدون السياحيون المعتمدون' : 'Certified Tour Guides',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, color: textMuted, size: 54),
                  const SizedBox(height: 14),
                  Text(
                    isAr ? 'لا يوجد مرشدون متاحون حالياً' : 'No guides currently available',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
            itemCount: guides.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final guide = guides[index];
              return GestureDetector(
                onTap: () => context.push('/guide/${guide.id}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder, width: 1.2),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: guide.imageUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 84,
                            height: 84,
                            color: isDark ? const Color(0xFF231B2A) : const Color(0xFFF0EBF3),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 84,
                            height: 84,
                            color: isDark ? const Color(0xFF231B2A) : const Color(0xFFF0EBF3),
                            child: const Icon(Icons.person, color: AppColors.primaryMauve, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    guide.name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${guide.rating}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              guide.title,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  guide.hourlyRate,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentGold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF281C30) : const Color(0xFFEDE7F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isAr ? 'عرض الملف' : 'View Profile',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryMauve,
                                    ),
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
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryMauve),
        ),
        error: (err, _) => Center(
          child: Text(
            isAr ? 'تعذر تحميل المرشدين' : 'Failed to load guides',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
