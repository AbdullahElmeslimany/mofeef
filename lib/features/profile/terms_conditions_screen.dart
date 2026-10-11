import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';

class TermsConditionsScreen extends ConsumerWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF281C30) : const Color(0xFFF3EDF7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryMauve.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_outlined, color: AppColors.accentGold, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'مرحباً بك في منصة "مُضيف". يُعد استخدامك للتطبيق وحجز الخدمات موافقة صريحة على الشروط والأحكام الموضحة أدناه.'
                          : 'Welcome to Modeef. Your use of the application and bookings signifies your agreement to these terms and conditions.',
                      style: GoogleFonts.cairo(
                        color: textPrimary,
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: isAr ? '١. سياسة الحجز وإصدار التذاكر' : '1. Bookings & Ticketing',
              content: isAr
                  ? 'يتم إصدار التذاكر الرقمية فور إتمام عملية الدفع بنجاح. تعتبر التذكرة وثيقة إلكترونية صالحة للاستخدام في الموعد والمكان المحددين ولا يجوز استخدامها لغير المستفيد المسجل.'
                  : 'Digital tickets are issued instantly upon successful payment completion. Each ticket is non-transferable and valid solely for the scheduled date and venue.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٢. سياسة الإلغاء والاسترداد' : '2. Cancellation & Refunds',
              content: isAr
                  ? 'يمكن إلغاء الحجز واسترداد القيمة وفقاً لسياسة كل تجربة ومسار سياحي، وذلك بحد أقصى ٢٤ إلى ٤٨ ساعة قبل موعد الانطلاق. يتم استرداد المبالغ إلى نفس وسيلة الدفع أو رصيد المحفظة.'
                  : 'Cancellations and refunds are subject to individual experience policies, typically allowable 24 to 48 hours prior to start time.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٣. التزامات وسلوك المسافرين' : '3. Traveler Obligations & Conduct',
              content: isAr
                  ? 'يلتزم المسافرون باحترام تعليمات المرشدين السياحيين والأنظمة المعمول بها في الأماكن التراثية والمقدسة، والالتزام بالذوق العام والأزياء المناسبة لثقافة المملكة.'
                  : 'Travelers must adhere to tour guide instructions, local venue guidelines, and public decorum regulations in accordance with Saudi heritage traditions.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٤. مسؤولية المنصة والشركاء' : '4. Platform & Host Responsibility',
              content: isAr
                  ? 'تعمل منصة "مُضيف" كوسيط رقمي يربط المسافرين بمقدمي التجارب والمرشدين المعتمدين من وزارة السياحة، ونحرص على أعلى معايير الجودة وسلامة الزوار.'
                  : 'Modeef acts as a licensed digital marketplace connecting travelers with certified Ministry of Tourism hosts and verified service providers.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٥. تعديل الشروط والأحكام' : '5. Amendments to Terms',
              content: isAr
                  ? 'تحتفظ المنصة بحق تعديل أو تحديث هذه الشروط عند الحاجة، ويسري التعديل من تاريخ نشره على التطبيق.'
                  : 'Modeef reserves the right to modify these terms as required. Changes become effective upon publication in the application.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textMuted: textMuted,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                isAr ? 'آخر تحديث: ٢٠٢٦ — منصة مُضيف للسياحة والتراث' : 'Last updated: 2026 — Modeef Platform',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color cardBg,
    required Color cardBorder,
    required Color textMuted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
