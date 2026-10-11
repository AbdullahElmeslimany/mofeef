import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/custom_button.dart';
import '../auth/auth_provider.dart';
import '../auth/data/models/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cityController = TextEditingController(text: isArLocale ? 'الرياض' : 'Riyadh');
  }

  bool get isArLocale => ref.read(localeProvider).languageCode == 'ar';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentUser = ref.read(authProvider).user;
      final updatedUser = UserModel(
        id: currentUser?.id ?? 1,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: currentUser?.avatarUrl,
        token: currentUser?.token,
      );

      ref.read(authProvider.notifier).updateUserState(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'تم حفظ بيانات الملف الشخصي بنجاح' : 'Profile updated successfully',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'حدث خطأ أثناء الحفظ' : 'Failed to save changes',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    // If NOT authenticated, enforce login required screen!
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
              color: textPrimary,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isAr ? 'البيانات الشخصية' : 'Personal Details',
            style: GoogleFonts.cairo(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon Ring
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryMauve.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.primaryMauve.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 46,
                    color: AppColors.primaryMauve,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isAr ? 'تسجيل الدخول مطلوب' : 'Sign In Required',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  isAr
                      ? 'أنت تتصفح التطبيق حالياً كحساب ضيف. لا يمكن تعديل أو حفظ بيانات الملف الشخصي إلا بعد تسجيل الدخول إلى حسابك.'
                      : 'You are currently browsing as a guest. Profile details can only be viewed and edited after signing in.',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    color: textMuted,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Primary Button: Login
                SizedBox(
                  width: double.infinity,
                  height: 52,
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
                        fontSize: 14.5,
                      ),
                    ),
                    onPressed: () => context.push('/login'),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary Button: Back
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    isAr ? 'الرجوع إلى حسابي' : 'Back to Profile',
                    style: GoogleFonts.cairo(
                      color: textMuted,
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

    // Authenticated: Normal Edit Form
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryMauve, width: 2.5),
                        color: isDark ? const Color(0xFF281C30) : const Color(0xFFECE7EF),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 52, color: AppColors.primaryMauve),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Inputs Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: isAr ? 'الاسم الكامل' : 'Full Name',
                      icon: Icons.person_outline_rounded,
                      inputBg: inputBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      validator: (v) => v == null || v.trim().isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _emailController,
                      label: isAr ? 'البريد الإلكتروني' : 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      inputBg: inputBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      validator: (v) => v == null || !v.contains('@') ? (isAr ? 'بريد غير صحيح' : 'Invalid email') : null,
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _phoneController,
                      label: isAr ? 'رقم الجوال' : 'Phone Number',
                      icon: Icons.phone_android_rounded,
                      inputBg: inputBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _cityController,
                      label: isAr ? 'المدينة' : 'City',
                      icon: Icons.location_city_outlined,
                      inputBg: inputBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              CustomButton(
                text: isAr ? 'حفظ التعديلات' : 'Save Changes',
                isLoading: _isSaving,
                onPressed: () => _handleSave(isAr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color inputBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textMuted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          cursorColor: AppColors.primaryMauve,
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            prefixIcon: Icon(icon, color: AppColors.primaryMauve, size: 20),
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
          ),
        ),
      ],
    );
  }
}
