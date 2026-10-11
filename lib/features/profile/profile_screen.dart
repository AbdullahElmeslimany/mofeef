import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';
import '../booking/data/booking_repository.dart';
import '../wishlist/data/wishlist_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final wishlistState = ref.watch(wishlistProvider);
    final bookingsAsync = ref.watch(bookingHistoryProvider(''));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isGuest = !authState.isAuthenticated;
    final realBookings = bookingsAsync.asData?.value ?? [];

    // Guest vs Authenticated User Information
    final userName = isGuest
        ? (isAr ? 'حساب ضيف' : 'Guest Account')
        : (authState.userName != null && authState.userName!.isNotEmpty
            ? authState.userName!
            : (isAr ? 'مستخدم ضيف' : 'Modeefe User'));

    final userEmail = isGuest
        ? (isAr ? 'غير مسجل الدخول' : 'Not signed in')
        : (authState.userEmail != null && authState.userEmail!.isNotEmpty
            ? authState.userEmail!
            : '');

    final userStatus = isGuest
        ? (isAr
            ? 'تصفح كزائر · الميزات محدودة'
            : 'Browsing as guest · Limited features')
        : (isAr ? 'عضو مسجل · موثق' : 'Verified Member');

    final tripCount = isGuest ? '0' : realBookings.length.toString();
    final bookCount = isGuest ? '0' : realBookings.length.toString();
    final favCount = wishlistState.items.length.toString();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Title & Theme Switcher Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'حسابي' : 'My Account',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  // Sun/Moon Circular Toggle Button
                  GestureDetector(
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).toggleTheme(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. User Profile Card (Enhanced for Guest / Authenticated)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isGuest
                        ? AppColors.accentGold.withValues(alpha: 0.35)
                        : cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    // Top: User Info & Avatar
                    Row(
                      children: [
                        // User Info (Name, Email / Status)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge (حساب ضيف أو عضو موثق)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isGuest
                                      ? AppColors.accentGold
                                          .withValues(alpha: 0.15)
                                      : AppColors.success
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isGuest
                                        ? AppColors.accentGold
                                            .withValues(alpha: 0.4)
                                        : AppColors.success
                                            .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGuest
                                          ? Icons.person_outline_rounded
                                          : Icons.verified_rounded,
                                      size: 13,
                                      color: isGuest
                                          ? AppColors.accentGold
                                          : AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isGuest
                                          ? (isAr
                                              ? 'حساب ضيف (زائر)'
                                              : 'Guest Account')
                                          : (isAr
                                              ? 'عضو موثق'
                                              : 'Verified Member'),
                                      style: GoogleFonts.cairo(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isGuest
                                            ? AppColors.accentGold
                                            : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Name
                              Text(
                                userName,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Email or prompt
                              Text(
                                userEmail,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  color: textSub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Status note
                              Text(
                                userStatus,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Avatar with Ring
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E1728)
                                : const Color(0xFFF3EEF7),
                            border: Border.all(
                              color: isGuest
                                  ? AppColors.accentGold
                                  : AppColors.primaryMauve,
                              width: 2.2,
                            ),
                          ),
                          child: Icon(
                            isGuest
                                ? Icons.person_outline_rounded
                                : Icons.person_rounded,
                            size: 38,
                            color: isGuest ? AppColors.accentGold : textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // If Guest: Prominent Sign In Banner inside Card
                    if (isGuest) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF140F1B)
                              : const Color(0xFFFAF7FC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.primaryMauve,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'سجل دخولك لتعديل بياناتك والوصول إلى كافة الخدمات'
                                    : 'Sign in to edit your profile and access all services',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: textSub,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryMauve,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => context.push('/login'),
                              child: Text(
                                isAr ? 'دخول' : 'Login',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Divider before Stats
                    Divider(color: cardBorder, height: 1),
                    const SizedBox(height: 14),

                    // Bottom Stats Row: رحلات | تذاكر | المفضلة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(tripCount, isAr ? 'رحلات' : 'Trips',
                            textPrimary, textSub),
                        Container(width: 1, height: 30, color: cardBorder),
                        _buildStatColumn(bookCount, isAr ? 'تذاكر' : 'Tickets',
                            textPrimary, textSub),
                        Container(width: 1, height: 30, color: cardBorder),
                        _buildStatColumn(
                            favCount,
                            isAr ? 'المفضلة' : 'Favorites',
                            textPrimary,
                            textSub),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Section 1: التفضيلات (Preferences)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  isAr ? 'التفضيلات' : 'Preferences',
                  style: GoogleFonts.cairo(
                    color: textSub,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cardBorder, width: 1.2),
                ),
                child: Column(
                  children: [
                    // المظهر (Theme)
                    _buildSectionTile(
                      icon: Icons.dark_mode_outlined,
                      title: isAr ? 'المظهر' : 'Appearance',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSub: textSub,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isDark
                                ? (isAr ? 'داكن' : 'Dark')
                                : (isAr ? 'فاتح' : 'Light'),
                            style:
                                GoogleFonts.cairo(fontSize: 13, color: textSub),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: isDark,
                            activeTrackColor: AppColors.primaryMauve,
                            activeThumbColor: Colors.white,
                            onChanged: (_) => ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(),
                          ),
                        ],
                      ),
                      onTap: () =>
                          ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                    Divider(color: cardBorder, height: 1),

                    // اللغة (Language)
                    _buildSectionTile(
                      icon: Icons.language_rounded,
                      title: isAr ? 'اللغة' : 'Language',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSub: textSub,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr ? 'العربية' : 'English',
                            style:
                                GoogleFonts.cairo(fontSize: 13, color: textSub),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isAr
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 18,
                            color: textSub,
                          ),
                        ],
                      ),
                      onTap: () => _showLanguageModal(context, isAr),
                    ),
                    Divider(color: cardBorder, height: 1),

                    // الإشعارات (Notifications)
                    _buildSectionTile(
                      icon: Icons.notifications_none_rounded,
                      title: isAr ? 'الإشعارات' : 'Notifications',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSub: textSub,
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeTrackColor: AppColors.primaryMauve,
                        activeThumbColor: Colors.white,
                        onChanged: (val) =>
                            setState(() => _notificationsEnabled = val),
                      ),
                      onTap: () => setState(
                          () => _notificationsEnabled = !_notificationsEnabled),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Section 2: الحساب (Account)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  isAr ? 'الحساب' : 'Account',
                  style: GoogleFonts.cairo(
                    color: textSub,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cardBorder, width: 1.2),
                ),
                child: Column(
                  children: [
                    // طلباتي (My Orders)
                    _buildSectionTile(
                      icon: Icons.description_outlined,
                      title: isAr ? 'طلباتي وحجوزاتي' : 'My Bookings & Orders',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSub: textSub,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isGuest
                                ? (isAr ? 'تصفح' : 'View')
                                : '${realBookings.length} ${isAr ? 'حجز' : 'bookings'}',
                            style: GoogleFonts.cairo(
                                fontSize: 12.5, color: textSub),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isAr
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 18,
                            color: textSub,
                          ),
                        ],
                      ),
                      onTap: () => context.go('/reservations'),
                    ),
                    Divider(color: cardBorder, height: 1),

                    // البيانات الشخصية (Personal Info - LOCKED FOR GUESTS)
                    _buildSectionTile(
                      icon: isGuest
                          ? Icons.lock_outline_rounded
                          : Icons.person_outline_rounded,
                      title: isAr ? 'البيانات الشخصية' : 'Personal Details',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSub: textSub,
                      trailing: isGuest
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF231B2A)
                                    : const Color(0xFFEFE8F4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded,
                                      size: 12, color: textSub),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr ? 'يتطلب الدخول' : 'Login required',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: textSub,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Icon(
                              isAr
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              size: 18,
                              color: textSub,
                            ),
                      onTap: () {
                        if (isGuest) {
                          _showGuestLoginPrompt(
                            context: context,
                            isAr: isAr,
                            isDark: isDark,
                            title: isAr
                                ? 'تعديل البيانات الشخصية'
                                : 'Edit Personal Details',
                            message: isAr
                                ? 'أنت تتصفح حالياً كحساب ضيف. لا يمكن تعديل بيانات الملف الشخصي إلا بعد تسجيل الدخول إلى حسابك.'
                                : 'You are currently browsing as a guest. Please sign in to edit and manage your personal details.',
                          );
                        } else {
                          context.push('/edit-profile');
                        }
                      },
                    ),
                    Divider(color: cardBorder, height: 1),

                    // لوحة الإدارة (Admin Panel) with gold badge
                    _buildSectionTile(
                      icon: Icons.shield_outlined,
                      title: isAr ? 'لوحة الإدارة' : 'Admin Dashboard',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSub: textSub,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAr ? 'للمشرفين' : 'Admin',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF1A1220),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isAr
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 18,
                            color: textSub,
                          ),
                        ],
                      ),
                      onTap: () {
                        if (isGuest) {
                          _showGuestLoginPrompt(
                            context: context,
                            isAr: isAr,
                            isDark: isDark,
                            title: isAr ? 'لوحة المشرفين' : 'Admin Access',
                            message: isAr
                                ? 'يتطلب الدخول إلى لوحة الإدارة تسجيل الدخول بحساب مشرف معتمد.'
                                : 'Admin dashboard requires logging in with authorized admin credentials.',
                          );
                        } else {
                          context.push('/admin');
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Login / Logout Action Button
              GestureDetector(
                onTap: () {
                  if (isGuest) {
                    context.push('/login');
                  } else {
                    _showLogoutDialog(
                        context: context, isAr: isAr, isDark: isDark);
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isGuest ? AppColors.primaryMauve : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isGuest ? AppColors.primaryMauve : cardBorder,
                      width: 1.2,
                    ),
                    boxShadow: isGuest
                        ? [
                            BoxShadow(
                              color: AppColors.primaryMauve
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isGuest ? Icons.login_rounded : Icons.logout_rounded,
                        size: 20,
                        color: isGuest ? Colors.white : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGuest
                            ? (isAr
                                ? 'تسجيل الدخول / إنشاء حساب'
                                : 'Sign In / Register')
                            : (isAr ? 'تسجيل الخروج' : 'Logout'),
                        style: GoogleFonts.cairo(
                          color: isGuest ? Colors.white : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuestLoginPrompt({
    required BuildContext context,
    required bool isAr,
    required bool isDark,
    required String title,
    required String message,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMauve.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.primaryMauve.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 34,
                  color: AppColors.primaryMauve,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: textSub,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMauve,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(
                    isAr ? 'تسجيل الدخول الآن' : 'Sign In Now',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/login');
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'المتابعة كضيف' : 'Continue as Guest',
                  style: GoogleFonts.cairo(
                    color: textSub,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog({
    required BuildContext context,
    required bool isAr,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cardBorder),
        ),
        title: Text(
          isAr ? 'تسجيل الخروج' : 'Logout',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟'
              : 'Are you sure you want to sign out of your account?',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: textSub,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.cairo(
                  color: textSub, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
            },
            child: Text(
              isAr ? 'تسجيل الخروج' : 'Logout',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String count, String label, Color textPrimary, Color textSub) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color textPrimary,
    required Color textSub,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rounded Icon Box in Mauve tint
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF261D2E) : const Color(0xFFF1ECF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    isDark ? const Color(0xFFD2C5DF) : AppColors.primaryMauve,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context, bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'اختر لغة التطبيق' : 'Choose App Language',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
                title: Text(
                  'العربية',
                  style: GoogleFonts.cairo(
                    fontWeight: isAr ? FontWeight.bold : FontWeight.normal,
                    color: isAr ? AppColors.primaryMauve : textPrimary,
                  ),
                ),
                trailing: isAr
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primaryMauve)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('ar');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(
                  'English',
                  style: GoogleFonts.cairo(
                    fontWeight: !isAr ? FontWeight.bold : FontWeight.normal,
                    color: !isAr ? AppColors.primaryMauve : textPrimary,
                  ),
                ),
                trailing: !isAr
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primaryMauve)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('en');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
