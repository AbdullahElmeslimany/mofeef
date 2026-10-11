import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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
          isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
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
                  const Icon(Icons.security, color: AppColors.accentGold, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'نلتزم في منصة "مُضيف" بحماية بياناتكم وخصوصيتكم وفقاً لنظام حماية البيانات الشخصية في المملكة العربية السعودية.'
                          : 'Modeef is committed to protecting your data and privacy in full compliance with Saudi PDPL regulations.',
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
              title: isAr ? '١. جمع واستخدام البيانات الشخصية' : '1. Data Collection & Use',
              content: isAr
                  ? 'نقوم بجمع البيانات الضرورية لتقديم الخدمات السياحية وحجوزات المسارات والفعاليات، وتشمل: الاسم، رقم الجوال، البريد الإلكتروني، وبيانات الحجز، وذلك لغرض إصدار التذاكر وتأكيد العمليات والتواصل معكم.'
                  : 'We collect essential information to facilitate tourist bookings, tickets, and seasonal experiences including your name, email, phone number, and booking preferences.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٢. أمان وسرية المعاملات المالية' : '2. Payment & Transaction Security',
              content: isAr
                  ? 'تتم جميع العمليات المالية وعمليات الدفع عبر بوابات دفع إلكترونية معتمدة من البنك المركزي السعودي (ساما) وتخضع لأعلى معايير التشفير والأمان العالمية (PCI-DSS).'
                  : 'All electronic payments are processed through secure gateways certified by the Saudi Central Bank (SAMA) with top-tier PCI-DSS encryption standards.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٣. الموقع الجغرافي والخرائط' : '3. Location & Navigation Services',
              content: isAr
                  ? 'يتم استخدام إحداثيات الموقع الجغرافي فقط عند طلب المسافر للوصول إلى محطات المسارات السياحية والمتاحف والفعاليات عبر تطبيقات الخرائط المعتمدة.'
                  : 'Location data is only accessed when requesting navigation directions to trail stages, museums, or live event venues.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٤. مشاركة البيانات مع الشركاء' : '4. Third-Party Sharing',
              content: isAr
                  ? 'لا نقوم ببيع أو تأجير بياناتكم لأي طرف ثالث. تتم مشاركة بيانات الحجز الأساسية فقط مع مزودي التجارب والمرشدين السياحيين المعتمدين لضمان تنفيذ خدمتكم بنجاح.'
                  : 'We do not sell or rent user data. Necessary booking details are shared exclusively with certified guides and experience hosts to execute your tour.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            _buildSection(
              title: isAr ? '٥. حقوق المستخدم والتحكم بالبيانات' : '5. User Rights & Data Control',
              content: isAr
                  ? 'يحق لكم في أي وقت مراجعة بياناتكم الشخصية، تحديثها من خلال صفحة تعديل الملف الشخصي، أو طلب حذف الحساب والتواصل مع فريق الخصوصية عبر: privacy@modeefe.sa'
                  : 'You maintain the right to review, update, or request deletion of your personal data at any time by contacting privacy@modeefe.sa.',
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
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
    required Color textPrimary,
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
