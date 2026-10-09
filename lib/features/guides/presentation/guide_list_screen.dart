import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('المرشدون السياحيون المعتمدون',
            style: AppTypography.headingSmall),
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return Center(
              child: Text('لا يوجد مرشدون متاحون حالياً',
                  style: AppTypography.bodyMedium),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: guides.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final guide = guides[index];
              return GestureDetector(
                onTap: () => context.push('/guide/${guide.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: guide.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.surface,
                            child: const Icon(Icons.person,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
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
                                    style: AppTypography.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        color: AppColors.primaryGold, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${guide.rating}',
                                        style: AppTypography.bodySmall.copyWith(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(guide.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    guide.hourlyRate,
                                    style: AppTypography.price
                                        .copyWith(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CustomButton(
                                  text: 'طلب إرشاد',
                                  width: 95,
                                  height: 36,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'تم إرسال طلب استشارة للمرشد ${guide.name}!'),
                                          backgroundColor: AppColors.success),
                                    );
                                  },
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
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('تعذر تحميل بيانات الأدلاء',
                  style: AppTypography.bodyMedium),
              TextButton(
                onPressed: () => ref.refresh(guidesListProvider),
                child: const Text('إعادة المحاولة',
                    style: TextStyle(color: AppColors.primaryGold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
