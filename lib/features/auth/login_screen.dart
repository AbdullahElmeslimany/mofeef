import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success =
        await ref.read(authProvider.notifier).login(email, password);
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'فشل تسجيل الدخول، يرجى التأكد من البيانات'),
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

    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with AlUla Background & Header
            Stack(
              children: [
                // Background Landscape Image
                SizedBox(
                  height: 310,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/home_hero_bg.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF0F1B26)),
                  ),
                ),

                // Gradient Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1B4E4A)
                              .withOpacity(0.70), // Turquoise top
                          const Color(0xFF09141D).withOpacity(0.60),
                          const Color(0xFF071018)
                              .withOpacity(0.98), // Solid bottom blend
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top Header Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        // Circular Logo Badge
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF131D26).withOpacity(0.85),
                              border: Border.all(
                                color:
                                    const Color(0xFFF5A623).withOpacity(0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.hotel_class_rounded,
                                color: Color(0xFFF5A623),
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Headline: "أهلاً بك في مُضيف"
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            children: [
                              TextSpan(
                                  text: isAr ? 'أهلاً بك في ' : 'Welcome to '),
                              TextSpan(
                                text: isAr ? 'مُضيف' : 'Modeefe',
                                style:
                                    const TextStyle(color: Color(0xFFF5A623)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle: "ابدأ رحلتك السعودية الفاخرة"
                        Text(
                          isAr
                              ? 'ابدأ رحلتك السعودية الفاخرة'
                              : 'Start your luxury Saudi journey',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFCBD5E1).withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Main Dark Auth Card matching Image 1
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B141E),
                  borderRadius: BorderRadius.circular(28),
                  border:
                      Border.all(color: const Color(0xFF1E3246), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented Switch [تسجيل الدخول | إنشاء حساب]
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070D14),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFF162534)),
                      ),
                      child: Row(
                        children: [
                          // Inactive: إنشاء حساب
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/register'),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Text(
                                  isAr ? 'إنشاء حساب' : 'Sign Up',
                                  style: const TextStyle(
                                    color: Color(0xFF8A9BB0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Active: تسجيل الدخول
                          Expanded(
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55F5A623),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? 'تسجيل الدخول' : 'Sign In',
                                  style: const TextStyle(
                                    color: Color(0xFF0B141E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Email Field with Label
                    _buildInputField(
                      controller: _emailController,
                      label: isAr ? 'البريد الإلكتروني' : 'Email Address',
                      hint: isAr ? 'أدخل بريدك الإلكتروني' : 'name@example.com',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    // Password Field with Label
                    _buildInputField(
                      controller: _passwordController,
                      label: isAr ? 'كلمة المرور' : 'Password',
                      hint: isAr ? '••••••••' : '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment:
                          isAr ? Alignment.centerRight : Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                          style: const TextStyle(
                            color: Color(0xFFF5A623),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Primary Login Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          foregroundColor: const Color(0xFF0B141E),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF0B141E),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isAr ? 'تسجيل الدخول' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_back,
                                    size: 18,
                                    color: Color(0xFF0B141E),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider: "— أو —"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              color: const Color(0xFF1E3246).withOpacity(0.8),
                              thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            isAr ? 'أو' : 'OR',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                              color: const Color(0xFF1E3246).withOpacity(0.8),
                              thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Google Login Button
                    // Container(
                    //   height: 50,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFF0E1A26),
                    //     borderRadius: BorderRadius.circular(25),
                    //     border: Border.all(color: const Color(0xFF1E3246)),
                    //   ),
                    //   child: InkWell(
                    //     onTap: () {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(
                    //           content: Text('تسجيل الدخول عبر Google متاح قريباً'),
                    //         ),
                    //       );
                    //     },
                    //     borderRadius: BorderRadius.circular(25),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Container(
                    //           width: 22,
                    //           height: 22,
                    //           decoration: const BoxDecoration(
                    //             shape: BoxShape.circle,
                    //             color: Colors.white,
                    //           ),
                    //           child: const Center(
                    //             child: Text(
                    //               'G',
                    //               style: TextStyle(
                    //                 color: Color(0xFFEA4335),
                    //                 fontWeight: FontWeight.w900,
                    //                 fontSize: 14,
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //         const SizedBox(width: 10),
                    //         Text(
                    //           isAr ? 'المتابعة عبر Google' : 'Continue with Google',
                    //           style: const TextStyle(
                    //             color: Color(0xFFE2E8F0),
                    //             fontSize: 13.5,
                    //             fontWeight: FontWeight.w600,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    const SizedBox(height: 16),

                    // Browse as Guest Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFF5A623),
                          size: 16,
                        ),
                        label: Text(
                          isAr ? 'تصفح كضيف' : 'Browse as Guest',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Text
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Tajawal',
                  ),
                  children: [
                    TextSpan(
                      text: isAr
                          ? 'بمواصلتك، فإنك توافق على '
                          : 'By continuing, you agree to the ',
                    ),
                    TextSpan(
                      text: isAr ? 'الشروط' : 'Terms',
                      style: const TextStyle(
                        color: Color(0xFFF5A623),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: isAr ? ' و' : ' and '),
                    TextSpan(
                      text: isAr ? 'الخصوصية' : 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFFF5A623),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBAC7D5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            cursorColor: const Color(0xFFF5A623),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Tajawal',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0D1722),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF5A6E82),
                fontSize: 13.5,
                fontFamily: 'Tajawal',
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: const Color(0xFFF5A623),
                  size: 20,
                ),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF8A9BB0),
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF1E3246), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFF5A623), width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
