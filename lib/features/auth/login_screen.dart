import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/custom_button.dart';
import 'auth_provider.dart';
import '../booking/data/booking_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthSubmit(bool isAr) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور'
                : 'Please enter your email and password',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final success = await ref.read(authProvider.notifier).register({
        'first_name': name.isNotEmpty ? name.split(' ').first : 'مسافر',
        'last_name': name.split(' ').length > 1
            ? name.split(' ').sublist(1).join(' ')
            : 'مُضيف',
        'email': email,
        'password': password,
        'phone': phone,
      });

      if (success && mounted) {
        ref.invalidate(bookingHistoryProvider(''));
        ref.invalidate(myTicketsProvider);
        context.go('/home');
      } else if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                error ?? (isAr ? 'فشل إنشاء الحساب' : 'Registration failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      final success =
          await ref.read(authProvider.notifier).login(email, password);
      if (success && mounted) {
        ref.invalidate(bookingHistoryProvider(''));
        ref.invalidate(myTicketsProvider);
        context.go('/home');
      } else if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        final isEmailNotVerified = error != null &&
            (error.contains('التحقق') ||
                error.toLowerCase().contains('verify'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ??
                (isAr
                    ? 'فشل تسجيل الدخول، يرجى التأكد من البيانات'
                    : 'Login failed, please verify your credentials')),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: isEmailNotVerified ? 8 : 4),
            action: isEmailNotVerified
                ? SnackBarAction(
                    label: isAr ? 'إعادة الإرسال' : 'Resend',
                    textColor: Colors.white,
                    onPressed: () async {
                      final msg = await ref
                          .read(authProvider.notifier)
                          .resendVerificationEmail(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg ??
                                (isAr
                                    ? 'تم إرسال رابط التحقق'
                                    : 'Verification link sent')),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final authState = ref.watch(authProvider);

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? const Color(0xFF120E1A) : const Color(0xFFF7F3FB);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Heritage Photo Hero Section (From Figma 01 · تسجيل الدخول)
              Stack(
                children: [
                  // Diriyah At-Turaif Background Image
                  SizedBox(
                    height: 290,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/home_hero_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(
                        'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=1200&q=85',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Dark / Violet Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.20),
                            const Color(0xFF0E0B12).withOpacity(0.55),
                            (isDark
                                    ? const Color(0xFF0E0B12)
                                    : const Color(0xFFF1ECF5))
                                .withOpacity(0.98),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Hero Text & Rosette Gem Logo
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Gemstone Logo
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  'assets/images/modeef_gem_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.diamond_outlined,
                                    color: AppColors.accentGold,
                                    size: 24,
                                  ),
                                ),
                              ),

                              // Language toggle pill
                              GestureDetector(
                                onTap: () => ref
                                    .read(localeProvider.notifier)
                                    .toggleLocale(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.language,
                                          color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        isAr ? 'English' : 'العربية',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Headline
                          Text(
                            isAr
                                ? 'أهلاً بك في مضـيـفي'
                                : 'Welcome to Modeef-e',
                            style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            isAr
                                ? 'سجّل دخولك لتحفظ رحلاتك وتذاكرك في مكان واحد.'
                                : 'Sign in to keep all your trips and tickets in one place.',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Auth Card (matching Figma)
              Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Segmented Switch [تسجيل الدخول | حساب جديد]
                      Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            // Sign In Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = false),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: !_isSignUp
                                        ? AppColors.primaryMauve
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'تسجيل الدخول' : 'Sign In',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !_isSignUp
                                            ? Colors.white
                                            : textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Sign Up Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = true),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: _isSignUp
                                        ? AppColors.primaryMauve
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'حساب جديد' : 'New Account',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _isSignUp
                                            ? Colors.white
                                            : textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Sign Up Fields (Name & Phone)
                      if (_isSignUp) ...[
                        _buildInputField(
                          context: context,
                          controller: _nameController,
                          label: isAr ? 'الاسم الكامل' : 'Full Name',
                          hint: isAr ? 'أدخل اسمك الكامل' : 'Enter your name',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildInputField(
                          context: context,
                          controller: _phoneController,
                          label: isAr ? 'رقم الجوال' : 'Phone Number',
                          hint: '05xxxxxxxx',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Email Field
                      _buildInputField(
                        context: context,
                        controller: _emailController,
                        label: isAr ? 'البريد الإلكتروني' : 'Email Address',
                        hint: 'name@example.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      _buildInputField(
                        context: context,
                        controller: _passwordController,
                        label: isAr ? 'كلمة المرور' : 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),

                      // Forgot Password Link
                      if (!_isSignUp) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: isAr
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text(
                              isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                              style: GoogleFonts.cairo(
                                color: AppColors.accentGold,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Primary Submit Button
                      CustomButton(
                        text: _isSignUp
                            ? (isAr ? 'إنشاء حساب جديد' : 'Create Account')
                            : (isAr ? 'تسجيل الدخول' : 'Sign In'),
                        isLoading: authState.isLoading,
                        onPressed: () => _handleAuthSubmit(isAr),
                      ),
                      const SizedBox(height: 20),

                      // Divider "أو"
                      //   Row(
                      //     children: [
                      //       Expanded(child: Divider(color: cardBorder)),
                      //       Padding(
                      //         padding: const EdgeInsets.symmetric(horizontal: 14),
                      //         child: Text(
                      //           isAr ? 'أو' : 'OR',
                      //           style: GoogleFonts.cairo(
                      //             color: textMuted,
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.bold,
                      //           ),
                      //         ),
                      //       ),
                      //       Expanded(child: Divider(color: cardBorder)),
                      //     ],
                      //   ),
                      //   const SizedBox(height: 18),

                      //   // Social Sign-In Buttons (Google & Apple)
                      //   Row(
                      //     children: [
                      //       Expanded(
                      //         child: _buildSocialButton(
                      //           context: context,
                      //           label: 'Google',
                      //           icon: Icons.g_mobiledata_rounded,
                      //           iconColor: const Color(0xFFEA4335),
                      //           onTap: () {
                      //             _emailController.text = 'traveler@modeefe.sa';
                      //             _passwordController.text = 'password123';
                      //             _handleAuthSubmit(isAr);
                      //           },
                      //         ),
                      //       ),
                      //       const SizedBox(width: 12),
                      //       Expanded(
                      //         child: _buildSocialButton(
                      //           context: context,
                      //           label: 'Apple',
                      //           icon: Icons.apple,
                      //           iconColor: textPrimary,
                      //           onTap: () {
                      //             _emailController.text = 'traveler@modeefe.sa';
                      //             _passwordController.text = 'password123';
                      //             _handleAuthSubmit(isAr);
                      //           },
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                    ],
                  ),
                ),
              ),

              // 3. Continue as Guest Link
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: Icon(
                      isAr
                          ? Icons.arrow_back_ios_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: textMuted,
                    ),
                    label: Text(
                      isAr ? 'المتابعة كزائر' : 'Continue as Guest',
                      style: GoogleFonts.cairo(
                        color: textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? const Color(0xFF120E1A) : const Color(0xFFF7F3FB);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.cairo(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(color: textMuted, fontSize: 13),
              prefixIcon: Icon(icon, color: textMuted, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: textMuted,
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primaryMauve, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? const Color(0xFF120E1A) : const Color(0xFFF7F3FB);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
