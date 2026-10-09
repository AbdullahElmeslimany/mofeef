import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/failure.dart';
import '../../core/localization/locale_provider.dart';
import 'data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني'),
          backgroundColor: Color(0xFFEA4335),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error;
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email);
    } on Failure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'تعذر إرسال رابط استعادة كلمة المرور، يرجى المحاولة لاحقاً';
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEA4335),
        ),
      );
      return;
    }

    final isAr = ref.read(localeProvider).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101C25),
        title: const Icon(Icons.mark_email_read_outlined,
            color: Color(0xFFF5A623), size: 56),
        content: Text(
          isAr
              ? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني. يرجى مراجعة صندوق الوارد أو الرسائل غير المرغوب فيها.'
              : 'A password reset link has been sent to your email. Please check your inbox or spam folder.',
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/login');
              },
              child: Text(
                isAr ? 'العودة لتسجيل الدخول' : 'Back to Login',
                style: const TextStyle(color: Color(0xFFF5A623)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071018),
        title: Text(
          isAr ? 'استعادة كلمة المرور' : 'Reset Password',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F1B26),
                  border: Border.all(
                    color: const Color(0xFFF5A623).withOpacity(0.35),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.key_rounded,
                    color: Color(0xFFF5A623),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isAr ? 'نسيت كلمة المرور؟' : 'Forgot your password?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لاستعادة كلمة المرور.'
                    : 'Enter your email address and we will send you a link to reset your password.',
                style: const TextStyle(
                  color: Color(0xFF8A9BB0),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _buildInputField(
                controller: _emailController,
                label: isAr ? 'البريد الإلكتروني' : 'Email Address',
                hint: isAr ? 'أدخل بريدك الإلكتروني' : 'name@example.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: const Color(0xFF0B141E),
                    elevation: 4,
                    disabledBackgroundColor: const Color(0xFF8A6D2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0B141E),
                          ),
                        )
                      : Text(
                          isAr ? 'إرسال رابط الاستعادة' : 'Send Reset Link',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
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
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: (_) => _handleSend(),
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
                child: Icon(icon, color: const Color(0xFFF5A623), size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1E3246)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1E3246)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}