import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/locale_provider.dart';
import '../auth/auth_provider.dart';
import '../booking/data/booking_repository.dart';
import '../wishlist/data/wishlist_repository.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final wishlistState = ref.watch(wishlistProvider);
    final bookingsAsync = ref.watch(bookingHistoryProvider(''));
    final walletState = ref.watch(walletProvider);

    final favCount = wishlistState.items.length.toString();
    final bookCount = bookingsAsync.asData?.value.length.toString() ?? '0';
    final isGuest = !authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الملف الشخصي والإعدادات' : 'Profile & Settings',
            style: AppTypography.headingSmall),
        actions: [
          if (!isGuest)
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: AppColors.primaryGold),
              tooltip: isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
              onPressed: () => context.push('/edit-profile'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          children: [
            // User Profile Card matching Figma
            GestureDetector(
              onTap: () => isGuest
                  ? context.go('/login')
                  : context.push('/edit-profile'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldGlow,
                            border: Border.all(
                                color: AppColors.primaryGold, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              authState.userName != null &&
                                      authState.userName!.isNotEmpty
                                  ? authState.userName!.characters.first
                                      .toUpperCase()
                                  : 'م',
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isAr ? 'ذهبـي' : 'VIP Gold',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          authState.userName ??
                              (isAr ? 'مسافر مُضيف' : 'Modeefe Traveler'),
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.primaryGold),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.userEmail ?? 'traveler@modeefe.sa',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 18),

                    // Real Dynamic Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('١', isAr ? 'وجهات زرتها' : 'Visited'),
                        Container(
                            width: 1, height: 35, color: AppColors.border),
                        _buildStatItem(
                            favCount, isAr ? 'تجارب مفضلة' : 'Wishlist'),
                        Container(
                            width: 1, height: 35, color: AppColors.border),
                        _buildStatItem(
                            bookCount, isAr ? 'حجوزات نشطة' : 'Bookings'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Quick Links
            if (!isGuest)
              _buildSettingsTile(
                icon: Icons.person_outline,
                title:
                    isAr ? 'تعديل الملف الشخصي' : 'Edit Profile Information',
                subtitle:
                    isAr ? 'الاسم، البريد، رقم الجوال' : 'Name, Email, Phone',
                onTap: () => context.push('/edit-profile'),
              ),
            _buildSettingsTile(
              icon: Icons.account_balance_wallet_outlined,
              title: isAr ? 'المحفظة والرصيد' : 'Wallet & Balance',
              subtitle: isAr
                  ? '${walletState.balance.toStringAsFixed(0)} ﷼ متاح'
                  : '${walletState.balance.toStringAsFixed(0)} ﷼ Available',
              onTap: () => context.push('/wallet'),
            ),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: isAr ? 'الإشعارات والتحديثات' : 'Notifications',
              onTap: () => context.push('/notifications'),
            ),
            _buildSettingsTile(
              icon: Icons.language,
              title: isAr ? 'اللغة / Language' : 'Language / اللغة',
              subtitle: isAr ? 'العربية (السعودية)' : 'English (US)',
              onTap: () => _showLanguageDialog(context, ref, isAr),
            ),
            _buildSettingsTile(
              icon: Icons.gavel_outlined,
              title: isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
              subtitle: isAr
                  ? 'سياسات الحجز، الإلغاء، واستخدام المنصة'
                  : 'Booking, cancellation, and usage terms',
              onTap: () => context.push('/terms-conditions'),
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
              subtitle: isAr
                  ? 'حماية البيانات وأمان المعاملات وفق الأنظمة'
                  : 'Data protection and PDPL compliance',
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: isAr ? 'مركز المساعدة والدعم' : 'Help & Support Center',
              subtitle: isAr ? 'خدمة العملاء ٢٤/٧' : '24/7 Customer Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr
                        ? 'خدمة العملاء متاحة على مدار الساعة: support@modeefe.sa'
                        : 'Support available 24/7: support@modeefe.sa'),
                    backgroundColor: AppColors.primaryGold,
                  ),
                );
              },
            ),
            if (!isGuest)
              _buildSettingsTile(
                icon: Icons.delete_forever_outlined,
                title: isAr ? 'حذف الحساب' : 'Delete Account',
                subtitle: isAr
                    ? 'حذف دائم لبياناتك من المنصة'
                    : 'Permanently delete your account and data',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: () => _confirmDeleteAccount(context, ref, isAr),
              ),
            const SizedBox(height: 8),
            if (isGuest)
              _buildSettingsTile(
                icon: Icons.login,
                title: isAr ? 'تسجيل الدخول' : 'Sign In',
                subtitle:
                    isAr ? 'سجّل الدخول للوصول لكل مزايا مديف' : 'Sign in to access all Modeefe features',
                onTap: () => context.go('/login'),
              )
            else
              _buildSettingsTile(
                icon: Icons.logout,
                title: isAr ? 'تسجيل الخروج' : 'Logout',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref, bool isAr) async {
    var deleted = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var busy = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              isAr ? 'حذف الحساب نهائيًا؟' : 'Delete account permanently?',
            ),
            content: busy
                ? const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Text(
                    isAr
                        ? 'سيتم حذف حسابك وجميع بياناتك نهائيًا من المنصة، ولا يمكن التراجع عن هذا الإجراء.'
                        : 'Your account and all your data will be permanently removed from the platform. This action cannot be undone.',
                    style: AppTypography.bodyMedium,
                  ),
            actions: busy
                ? null
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isAr ? 'إلغاء' : 'Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: () async {
                        setDialogState(() => busy = true);
                        final ok = await ref
                            .read(authProvider.notifier)
                            .deleteAccount();
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        deleted = ok;
                      },
                      child: Text(isAr ? 'حذف نهائي' : 'Delete Forever'),
                    ),
                  ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              (isAr ? 'تم حذف حسابك بنجاح' : 'Your account has been deleted')),
          backgroundColor: deleted ? AppColors.success : AppColors.error,
        ),
      );
    }
    if (deleted) {
      context.go('/login');
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, bool isAr) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isAr ? 'اختر لغة التطبيق' : 'Select App Language',
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'سيتم تطبيق اللغة المختارة على كامل واجهات التطبيق'
                    : 'The selected language will apply across the entire app',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // Arabic Option Card
              GestureDetector(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('ar');
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isAr ? AppColors.goldGlow : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAr ? AppColors.primaryGold : AppColors.border,
                      width: isAr ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🇸🇦', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'العربية',
                              style: AppTypography.titleMedium.copyWith(
                                color:
                                    isAr ? AppColors.primaryGold : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Arabic (المملكة العربية السعودية)',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isAr)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryGold, size: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // English Option Card
              GestureDetector(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('en');
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: !isAr ? AppColors.goldGlow : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !isAr ? AppColors.primaryGold : AppColors.border,
                      width: !isAr ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'English',
                              style: AppTypography.titleMedium.copyWith(
                                color: !isAr
                                    ? AppColors.primaryGold
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('الإنجليزية (English)',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!isAr)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryGold, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.primaryGold)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor ?? AppColors.primaryGold),
          title: Text(title,
              style: AppTypography.titleSmall
                  .copyWith(color: textColor ?? AppColors.textPrimary)),
          subtitle: subtitle != null
              ? Text(subtitle, style: AppTypography.bodySmall)
              : null,
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
