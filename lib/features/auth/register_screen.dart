import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/custom_button.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _passwordController.text,
      'term': 1,
      'term_conditions': 1,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'مرحباً بك في مُضيف! تم إنشاء حسابك بنجاح.'
                : 'Welcome to Modeef! Your account has been created.',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? (isAr ? 'فشل إنشاء الحساب' : 'Registration failed'),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? const Color(0xFF191222) : const Color(0xFFF7F4F9);

    return Scaffold(
      backgroundColor: bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Header Banner matching Login Figma
              Stack(
                children: [
                  SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/login_hero_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF281C30), Color(0xFF130E18)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Mauve & Dark Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF654D71).withValues(alpha: 0.65),
                            const Color(0xFF23162C).withValues(alpha: 0.85),
                            bg,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Bar & Title
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.language, color: Colors.white, size: 14),
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
                          const SizedBox(height: 20),
                          Text(
                            isAr ? 'إنشاء حساب جديد' : 'Create New Account',
                            style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'انضم إلى مجتمع مسافري مُضيف لتستمتع بأفضل التجارب'
                                : 'Join the Modeef travelers community for the best experiences',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Auth Card matching Figma 01
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
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
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
                                  onTap: () => context.go('/login'),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Text(
                                      isAr ? 'تسجيل الدخول' : 'Sign In',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Sign Up Tab (Active)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMauve,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'حساب جديد' : 'New Account',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // First Name & Last Name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _firstNameController,
                                label: isAr ? 'الاسم الأول' : 'First Name',
                                hint: isAr ? 'سعود' : 'Saud',
                                icon: Icons.person_outline_rounded,
                                isDark: isDark,
                                cardBorder: cardBorder,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                validator: (v) => v == null || v.trim().isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                controller: _lastNameController,
                                label: isAr ? 'اسم العائلة' : 'Last Name',
                                hint: isAr ? 'العتيبي' : 'Alotaibi',
                                icon: Icons.person_outline_rounded,
                                isDark: isDark,
                                cardBorder: cardBorder,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                validator: (v) => v == null || v.trim().isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _buildInputField(
                          controller: _emailController,
                          label: isAr ? 'البريد الإلكتروني' : 'Email Address',
                          hint: 'name@example.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                          cardBorder: cardBorder,
                          inputBg: inputBg,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          validator: (v) => v == null || !v.contains('@') ? (isAr ? 'بريد غير صحيح' : 'Invalid email') : null,
                        ),
                        const SizedBox(height: 14),

                        // Phone
                        _buildInputField(
                          controller: _phoneController,
                          label: isAr ? 'رقم الجوال' : 'Phone Number',
                          hint: '05XXXXXXXX',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                          cardBorder: cardBorder,
                          inputBg: inputBg,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _buildInputField(
                          controller: _passwordController,
                          label: isAr ? 'كلمة المرور' : 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                          isDark: isDark,
                          cardBorder: cardBorder,
                          inputBg: inputBg,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          validator: (v) => v == null || v.length < 6 ? (isAr ? '٦ خانات على الأقل' : 'Min 6 characters') : null,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleRegister(isAr),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        CustomButton(
                          text: isAr ? 'إنشاء الحساب' : 'Create Account',
                          isLoading: authState.isLoading,
                          onPressed: () => _handleRegister(isAr),
                        ),

                        const SizedBox(height: 18),

                        // Back to login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isAr ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                              style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(
                                isAr ? 'تسجيل الدخول' : 'Sign In',
                                style: GoogleFonts.cairo(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color cardBorder,
    required Color inputBg,
    required Color textPrimary,
    required Color textMuted,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          cursorColor: AppColors.primaryMauve,
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              color: textMuted.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: AppColors.primaryMauve, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textMuted,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cardBorder, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cardBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryMauve, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
