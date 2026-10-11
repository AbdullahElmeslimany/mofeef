import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../data/car_repository.dart';

class CarListScreen extends ConsumerWidget {
  const CarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(carsListProvider);
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
          isAr ? 'تأجير السيارات الفاخرة' : 'Luxury Car Rentals',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: carsAsync.when(
        data: (cars) {
          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, color: textMuted, size: 54),
                  const SizedBox(height: 14),
                  Text(
                    isAr ? 'لا توجد سيارات متاحة حالياً' : 'No cars currently available',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
            itemCount: cars.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final car = cars[index];
              return GestureDetector(
                onTap: () => context.push('/car/${car.id}'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Image
                      CachedNetworkImage(
                        imageUrl: car.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 160,
                          color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
                          child: Icon(Icons.directions_car, size: 48, color: textMuted),
                        ),
                      ),

                      // Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car.category,
                              style: GoogleFonts.cairo(
                                color: AppColors.accentGold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              car.title,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Meta specs
                            Row(
                              children: [
                                Icon(Icons.people_outline, size: 16, color: textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '${car.passengerCount} ${isAr ? 'ركاب' : 'Passengers'}',
                                  style: GoogleFonts.cairo(fontSize: 12.5, color: textMuted),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.settings_outlined, size: 16, color: textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  car.transmission,
                                  style: GoogleFonts.cairo(fontSize: 12.5, color: textMuted),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Price & Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.pricePerDay,
                                      style: GoogleFonts.cairo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentGold,
                                      ),
                                    ),
                                    Text(
                                      isAr ? 'شامل التأمين والضريبة' : 'Inc. insurance & VAT',
                                      style: GoogleFonts.cairo(fontSize: 10.5, color: textMuted),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryMauve,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => context.push('/car/${car.id}'),
                                    child: Text(
                                      isAr ? 'احجز الآن' : 'Book Now',
                                      style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
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
            isAr ? 'تعذر تحميل قائمة السيارات' : 'Failed to load cars',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
