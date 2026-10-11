import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/payment/moyasar_payment_manager.dart';
import '../auth/auth_provider.dart';
import '../experiences/experience_details_screen.dart';
import 'data/booking_draft.dart';
import 'data/booking_repository.dart';
import 'data/payment_gateways_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String experienceId;
  final BookingDraft? draft;

  const CheckoutScreen({
    super.key,
    required this.experienceId,
    this.draft,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late int _ticketCount;
  late DateTime _selectedDate;
  String _selectedPaymentMethod = 'moyasar';
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  double _discountAmount = 0.0;
  String? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.draft?.date ?? DateTime.now().add(const Duration(days: 1));
    _ticketCount = widget.draft?.totalGuests ?? 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.userName != null && auth.userName!.isNotEmpty) {
        _nameController.text = auth.userName!;
      }
      if (auth.userEmail != null && auth.userEmail!.isNotEmpty) {
        _emailController.text = auth.userEmail!;
      }
      if (auth.user?.phone != null && auth.user!.phone!.isNotEmpty) {
        _phoneController.text = auth.user!.phone!;
      } else {
        _phoneController.text = '0555123456';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(bool isAr) {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'MODEEFE' ||
        code == 'KSA2030' ||
        code == 'GOLD' ||
        code == 'MOFEEF') {
      setState(() {
        _discountAmount = 50.0;
        _appliedCoupon = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'تم تطبيق خصم بقيمة ٥٠ ﷼ بنجاح! 🎉'
                      : 'Coupon applied successfully (-50 ﷼)! 🎉',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (code.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'رمز الكوبون غير صالح أو منتهي الصلاحية'
                : 'Invalid or expired coupon code',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _removeCoupon(bool isAr) {
    setState(() {
      _discountAmount = 0.0;
      _appliedCoupon = null;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم إلغاء الكوبون' : 'Coupon removed',
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleConfirmBooking({
    required int serviceId,
    required String serviceType,
    required String title,
    required int guests,
    required double finalTotal,
    required bool isAr,
    required bool isDark,
    String? imageUrl,
    String? location,
  }) async {
    // Validation
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى إدخال الاسم ورقم الجوال للمتابعة'
                : 'Please enter your name and phone number to continue',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Step 0: Require a real Moyasar payment before confirming the booking if selected.
      final visibleGateways = ref.read(visiblePaymentGatewaysProvider);
      final selectedGateway = visibleGateways.firstWhere(
        (g) => g.id == _selectedPaymentMethod,
        orElse: () => visibleGateways.first,
      );
      String? moyasarPaymentId;
      if (selectedGateway.isMoyasar && finalTotal > 0) {
        final payment = await ref
            .read(moyasarPaymentManagerProvider)
            .start(context: context, amount: finalTotal, isAr: isAr);
        if (!mounted) return;
        if (!payment.isPaid) {
          if (payment.status == MoyasarPaymentStatus.failed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr
                      ? 'لم يكتمل الدفع. لم يتم تأكيد الحجز.'
                      : 'Payment was not completed. Booking was not confirmed.',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          return;
        }
        moyasarPaymentId = payment.paymentId;
      }

      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final bookingCode =
          'MDF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final newBooking = BookingItemModel(
        id: DateTime.now().millisecondsSinceEpoch % 1000000,
        code: bookingCode,
        serviceTitle: title,
        serviceType: serviceType,
        startDate: dateStr,
        total: finalTotal,
        status: 'confirmed',
        totalGuests: guests,
        image: imageUrl,
        location: location,
      );

      // 1. Immediately persist locally
      await ref.read(bookingRepositoryProvider).saveBookingLocally(newBooking);

      // 2. Call backend API
      try {
        await ref.read(bookingRepositoryProvider).addToCart(
          serviceId: serviceId,
          serviceType: serviceType,
          startDate: dateStr,
          guests: guests,
          extraData: {
            'booking_code': bookingCode,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'notes': _notesController.text.trim(),
            'payment_gateway': selectedGateway.id,
            'moyasar_payment_id': moyasarPaymentId,
          },
        );
      } catch (_) {}

      // 3. Invalidate booking history so the new booking immediately appears
      ref.invalidate(bookingHistoryProvider(''));
      ref.invalidate(bookingHistoryProvider('upcoming'));
      ref.invalidate(bookingHistoryProvider('completed'));
      ref.invalidate(myTicketsProvider);

      if (mounted) {
        _showBookingSuccessDialog(
          context: context,
          booking: newBooking,
          bookingCode: bookingCode,
          dateStr: dateStr,
          guests: guests,
          finalTotal: finalTotal,
          isAr: isAr,
          isDark: isDark,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'حدث خطأ أثناء الحجز: $e' : 'Booking error: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showBookingSuccessDialog({
    required BuildContext context,
    required BookingItemModel booking,
    required String bookingCode,
    required String dateStr,
    required int guests,
    required double finalTotal,
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
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: cardBorder, width: 1.2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Checkmark Header
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.15),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isAr ? 'تم تأكيد الحجز بنجاح! 🎉' : 'Booking Confirmed! 🎉',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'تم استلام طلبك وتأكيد حجز التذكرة فورياً'
                  : 'Your reservation has been placed and confirmed instantly',
              style: GoogleFonts.cairo(fontSize: 13, color: textSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Booking Code Card with Copy Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF140F1B) : const Color(0xFFF7F4F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'رقم الحجز المرجعي' : 'Booking Reference',
                        style: GoogleFonts.cairo(fontSize: 11, color: textSub),
                      ),
                      Text(
                        bookingCode,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        size: 20, color: AppColors.primaryMauve),
                    tooltip: isAr ? 'نسخ رقم الحجز' : 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: bookingCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr ? 'تم نسخ رقم الحجز' : 'Booking code copied',
                            style: GoogleFonts.cairo(),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Item Details Breakdown
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF140F1B) : const Color(0xFFF7F4F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildReceiptRow(
                    label: isAr ? 'الخدمة:' : 'Service:',
                    value: booking.serviceTitle,
                    isDark: isDark,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    label: isAr ? 'الموعد:' : 'Date:',
                    value: dateStr,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    label: isAr ? 'التذاكر / الضيوف:' : 'Guests:',
                    value: '$guests ${isAr ? 'تذاكر' : 'tickets'}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  Divider(color: cardBorder, height: 1),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    label: isAr ? 'المبلغ المسدد:' : 'Amount Paid:',
                    value: '${finalTotal.toStringAsFixed(0)} ﷼',
                    isDark: isDark,
                    isGold: true,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Code Scan Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      size: 68, color: Color(0xFF161220)),
                  Text(
                    isAr
                        ? 'امسح التذكرة عند الدخول'
                        : 'Scan ticket upon arrival',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF736980),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Primary Navigation: My Bookings
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMauve,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                label: Text(
                  isAr ? 'عرض التذكرة في حجوزاتي' : 'View in My Bookings',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/reservations');
                },
              ),
            ),
            const SizedBox(height: 6),

            // Secondary Navigation: Return Home
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/');
              },
              child: Text(
                isAr ? 'العودة للرئيسية' : 'Back to Home',
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

  Widget _buildReceiptRow({
    required String label,
    required String value,
    required bool isDark,
    bool isBold = false,
    bool isGold = false,
  }) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isGold ? AppColors.accentGold : textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceBg =
        isDark ? const Color(0xFF161220) : const Color(0xFFFAF7FC);

    final visibleGateways = ref.watch(visiblePaymentGatewaysProvider);
    final gatewaysAsync = ref.watch(paymentGatewaysProvider);

    // If draft is passed from any service sheet (car, tour, museum, event), use it directly!
    if (widget.draft != null) {
      final draft = widget.draft!;
      final subtotal = draft.subtotal;
      final finalTotal =
          (subtotal - _discountAmount).clamp(0.0, double.infinity);

      return _buildCheckoutScaffold(
        context: context,
        isAr: isAr,
        isDark: isDark,
        bg: bg,
        cardBg: cardBg,
        cardBorder: cardBorder,
        textPrimary: textPrimary,
        textSub: textSub,
        textMuted: textMuted,
        surfaceBg: surfaceBg,
        title: draft.title,
        serviceType: draft.serviceType,
        serviceId: draft.serviceId,
        imageUrl: draft.imageUrl,
        location: draft.location,
        guestsCount: draft.totalGuests,
        personItems: draft.personItems,
        extraItems: draft.extraItems,
        subtotal: subtotal,
        finalTotal: finalTotal,
        canChangeGuests: false,
        visibleGateways: visibleGateways,
        gatewaysAsync: gatewaysAsync,
      );
    }

    // Fallback: Fetch from tourDetailProvider if no draft was passed
    final tourAsync = ref.watch(tourDetailProvider(widget.experienceId));

    return tourAsync.when(
      data: (tour) {
        final unitPrice = tour.salePrice ?? tour.price;
        final subtotal = unitPrice * _ticketCount;
        final finalTotal =
            (subtotal - _discountAmount).clamp(0.0, double.infinity);

        return _buildCheckoutScaffold(
          context: context,
          isAr: isAr,
          isDark: isDark,
          bg: bg,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          textSub: textSub,
          textMuted: textMuted,
          surfaceBg: surfaceBg,
          title: tour.title,
          serviceType: 'tour',
          serviceId: int.tryParse(widget.experienceId) ?? 1,
          imageUrl: tour.imageUrl,
          location: tour.locationName ?? tour.address,
          guestsCount: _ticketCount,
          personItems: const [],
          extraItems: const [],
          subtotal: subtotal,
          finalTotal: finalTotal,
          canChangeGuests: true,
          visibleGateways: visibleGateways,
          gatewaysAsync: gatewaysAsync,
        );
      },
      loading: () => Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(
            context, isAr, isDark, textPrimary, cardBorder, cardBg),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accentGold),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'جاري تجهيز تفاصيل الحجز...'
                    : 'Preparing booking details...',
                style: GoogleFonts.cairo(color: textSub),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(
            context, isAr, isDark, textPrimary, cardBorder, cardBg),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? 'تعذر تحميل بيانات التجربة للحجز'
                      : 'Failed to load booking details',
                  style: GoogleFonts.cairo(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMauve,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.pop(),
                  child: Text(
                    isAr ? 'الرجوع' : 'Go Back',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isAr,
    bool isDark,
    Color textPrimary,
    Color cardBorder,
    Color cardBg,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        isAr ? 'إتمام الحجز والدفع' : 'Checkout & Payment',
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: textPrimary,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder),
            ),
            child: Icon(
              isAr
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: textPrimary,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsetsDirectional.only(end: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 14, color: AppColors.accentGold),
              const SizedBox(width: 4),
              Text(
                isAr ? 'دفع آمن' : 'Secure',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutScaffold({
    required BuildContext context,
    required bool isAr,
    required bool isDark,
    required Color bg,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required Color textMuted,
    required Color surfaceBg,
    required String title,
    required String serviceType,
    required int serviceId,
    required String? imageUrl,
    required String? location,
    required int guestsCount,
    required List<BookingPersonItem> personItems,
    required List<BookingExtraItem> extraItems,
    required double subtotal,
    required double finalTotal,
    required bool canChangeGuests,
    required List<PaymentGatewayItem> visibleGateways,
    required AsyncValue<List<PaymentGatewayItem>> gatewaysAsync,
  }) {
    return Scaffold(
      backgroundColor: bg,
      appBar:
          _buildAppBar(context, isAr, isDark, textPrimary, cardBorder, cardBg),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Stepper Indicator
            _buildStepperHeader(
                isAr, isDark, cardBg, cardBorder, textPrimary, textSub),
            const SizedBox(height: 16),

            // 1. Service Summary Card
            _buildServiceSummaryCard(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSub: textSub,
              title: title,
              serviceType: serviceType,
              imageUrl: imageUrl,
              location: location,
            ),
            const SizedBox(height: 16),

            // 2. Selected Visit Date Card
            _buildDateSelectionCard(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            const SizedBox(height: 16),

            // 3. Tickets / Guests Breakdown Card
            _buildTicketsBreakdownCard(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSub: textSub,
              guestsCount: guestsCount,
              personItems: personItems,
              extraItems: extraItems,
              subtotal: subtotal,
              canChangeGuests: canChangeGuests,
            ),
            const SizedBox(height: 16),

            // 4. Lead Traveler Information Form
            _buildTravelerInfoCard(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              surfaceBg: surfaceBg,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            const SizedBox(height: 16),

            // 5. Coupon Section
            _buildCouponCard(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              surfaceBg: surfaceBg,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            const SizedBox(height: 16),

            // 6. Payment Gateways Section
            _buildPaymentGatewaysSection(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSub: textSub,
              visibleGateways: visibleGateways,
              gatewaysAsync: gatewaysAsync,
            ),
            const SizedBox(height: 16),

            // 7. Total Receipt Breakdown Card
            _buildReceiptSummaryCard(
              isAr: isAr,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSub: textSub,
              subtotal: subtotal,
              finalTotal: finalTotal,
            ),
            const SizedBox(height: 16),

            // 8. Trust Badges
            _buildTrustBadges(isAr, isDark, cardBg, cardBorder, textSub),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyBottomBar(
        context: context,
        isAr: isAr,
        isDark: isDark,
        cardBg: cardBg,
        cardBorder: cardBorder,
        textPrimary: textPrimary,
        textSub: textSub,
        finalTotal: finalTotal,
        serviceId: serviceId,
        serviceType: serviceType,
        title: title,
        guests: guestsCount,
        imageUrl: imageUrl,
        location: location,
      ),
    );
  }

  // --- Step Indicator ---
  Widget _buildStepperHeader(
    bool isAr,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSub,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          // Step 1: Selected
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Text(
            isAr ? 'الخدمة' : 'Service',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textSub,
            ),
          ),
          const SizedBox(width: 8),

          // Connector line
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primaryMauve,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Step 2: Payment & Confirm (Active)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryMauve, AppColors.primaryMauveDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMauve.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '2',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isAr ? 'الدفع والتأكيد' : 'Pay & Confirm',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Service Summary Card ---
  Widget _buildServiceSummaryCard({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required String title,
    required String serviceType,
    required String? imageUrl,
    required String? location,
  }) {
    String typeLabel;
    IconData typeIcon;
    switch (serviceType) {
      case 'car':
        typeLabel = isAr ? 'تأجير سيارة' : 'Car Rental';
        typeIcon = Icons.directions_car_outlined;
        break;
      case 'event':
        typeLabel = isAr ? 'فعالية ترفيهية' : 'Event';
        typeIcon = Icons.confirmation_number_outlined;
        break;
      case 'museum':
        typeLabel = isAr ? 'معلم ومتحف' : 'Museum';
        typeIcon = Icons.museum_outlined;
        break;
      case 'guide':
        typeLabel = isAr ? 'مرشد سياحي' : 'Tour Guide';
        typeIcon = Icons.person_pin_circle_outlined;
        break;
      default:
        typeLabel = isAr ? 'مسار وتجربة سياحية' : 'Tour & Experience';
        typeIcon = Icons.explore_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl ??
                  'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 84,
                height: 84,
                color:
                    isDark ? const Color(0xFF282035) : const Color(0xFFE9E2EE),
                child: const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accentGold),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 84,
                height: 84,
                color:
                    isDark ? const Color(0xFF282035) : const Color(0xFFE9E2EE),
                child: const Icon(Icons.image_not_supported_outlined,
                    color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Type Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMauve.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primaryMauve.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 12, color: AppColors.primaryMauve),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryMauve,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // Location Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.accentGold),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location ??
                            (isAr
                                ? 'المملكة العربية السعودية'
                                : 'Saudi Arabia'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 11, color: textSub),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Date Selection Card ---
  Widget _buildDateSelectionCard({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
  }) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', isAr ? 'ar' : 'en')
        .format(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'موعد الزيارة المحدد' : 'Selected Visit Date',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? const ColorScheme.dark(
                                  primary: AppColors.accentGold,
                                  surface: AppColors.darkCard,
                                  onSurface: AppColors.darkTextPrimary,
                                )
                              : const ColorScheme.light(
                                  primary: AppColors.primaryMauve,
                                  surface: AppColors.lightCard,
                                  onSurface: AppColors.lightTextPrimary,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    isAr ? 'تغيير الموعد' : 'Change Date',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMauve,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF140F1B) : const Color(0xFFF7F4F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded,
                    size: 18, color: AppColors.primaryMauve),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Tickets Breakdown Card ---
  Widget _buildTicketsBreakdownCard({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required int guestsCount,
    required List<BookingPersonItem> personItems,
    required List<BookingExtraItem> extraItems,
    required double subtotal,
    required bool canChangeGuests,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  color: AppColors.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'تفاصيل التذاكر والضيوف' : 'Guests & Tickets Details',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // If person items passed in draft
          if (personItems.isNotEmpty) ...[
            ...personItems.where((p) => p.quantity > 0).map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p.quantity} × ${p.name}',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: textPrimary),
                        ),
                        Text(
                          '${p.total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ] else if (canChangeGuests) ...[
            // Counter widget when no fixed draft
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF140F1B) : const Color(0xFFF7F4F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'تذاكر الدخول (بالغين)' : 'General Tickets (Adults)',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: cardBorder),
                          ),
                        ),
                        icon: const Icon(Icons.remove,
                            size: 16, color: AppColors.primaryMauve),
                        onPressed: _ticketCount > 1
                            ? () => setState(() => _ticketCount--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_ticketCount',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: cardBorder),
                          ),
                        ),
                        icon: const Icon(Icons.add,
                            size: 16, color: AppColors.primaryMauve),
                        onPressed: () => setState(() => _ticketCount++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$guestsCount × ${isAr ? 'تذكرة دخول عامة' : 'General Ticket'}',
                    style: GoogleFonts.cairo(fontSize: 13, color: textPrimary),
                  ),
                  Text(
                    '${subtotal.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Extra items add-ons if any
          if (extraItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: cardBorder, height: 1),
            const SizedBox(height: 8),
            ...extraItems.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+ ${e.name}',
                      style: GoogleFonts.cairo(fontSize: 13, color: textSub),
                    ),
                    Text(
                      '+${e.price.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. Traveler Info Form Card ---
  Widget _buildTravelerInfoCard({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color surfaceBg,
    required Color textPrimary,
    required Color textSub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined,
                  color: AppColors.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'بيانات المسافر الرئيسي' : 'Lead Traveler Information',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'ستُرسل التذكرة وتفاصيل الحجز إلى هذه البيانات'
                : 'Your ticket and confirmation details will be sent here',
            style: GoogleFonts.cairo(fontSize: 11, color: textSub),
          ),
          const SizedBox(height: 14),

          // Name Field
          _buildInputField(
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            label: isAr ? 'الاسم الكامل' : 'Full Name',
            hint: isAr ? 'أدخل اسمك كما في الهوية' : 'Enter your full name',
            isDark: isDark,
            surfaceBg: surfaceBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
          const SizedBox(height: 12),

          // Email Field
          _buildInputField(
            controller: _emailController,
            icon: Icons.alternate_email_rounded,
            label: isAr ? 'البريد الإلكتروني' : 'Email Address',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            surfaceBg: surfaceBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
          const SizedBox(height: 12),

          // Phone Field
          _buildInputField(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            label: isAr ? 'رقم الجوال' : 'Phone Number',
            hint: '05xxxxxxxx',
            keyboardType: TextInputType.phone,
            isDark: isDark,
            surfaceBg: surfaceBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
          const SizedBox(height: 12),

          // Notes / Special Requests Field (Optional)
          _buildInputField(
            controller: _notesController,
            icon: Icons.edit_note_rounded,
            label: isAr
                ? 'ملاحظات أو طلبات خاصة (اختياري)'
                : 'Special Requests (Optional)',
            hint: isAr
                ? 'أي ملاحظات تود إبلاغ المنظم بها...'
                : 'Any special notes for the host...',
            isDark: isDark,
            surfaceBg: surfaceBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required bool isDark,
    required Color surfaceBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(fontSize: 13, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: textSub),
        hintStyle: GoogleFonts.cairo(
            fontSize: 12, color: textSub.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: AppColors.primaryMauve, size: 20),
        filled: true,
        fillColor: surfaceBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryMauve, width: 1.5),
        ),
      ),
    );
  }

  // --- 5. Coupon Card ---
  Widget _buildCouponCard({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color surfaceBg,
    required Color textPrimary,
    required Color textSub,
  }) {
    final hasCoupon = _discountAmount > 0 && _appliedCoupon != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              hasCoupon ? AppColors.success.withValues(alpha: 0.5) : cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.discount_outlined,
                  color: AppColors.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'كوبون الخصم' : 'Discount Coupon',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasCoupon) ...[
            // Applied Coupon State
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isAr ? 'تم تطبيق الكوبون:' : 'Applied Code:'} $_appliedCoupon',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          isAr
                              ? 'خصم ٥٠ ﷼ من المجموع النهائي'
                              : '50 SAR discount deducted from total',
                          style:
                              GoogleFonts.cairo(fontSize: 11, color: textSub),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.error),
                    tooltip: isAr ? 'إلغاء الكوبون' : 'Remove coupon',
                    onPressed: () => _removeCoupon(isAr),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Input code row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.cairo(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? 'أدخل الرمز (مثال: MODEEFE)'
                          : 'Enter promo code (e.g. MODEEFE)',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 12, color: textSub.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.local_offer_outlined,
                          color: AppColors.primaryMauve, size: 18),
                      filled: true,
                      fillColor: surfaceBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primaryMauve, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMauve,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _applyCoupon(isAr),
                  child: Text(
                    isAr ? 'تطبيق' : 'Apply',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 6),
            // Text(
            //   isAr ? '💡 جرب كود: MODEEFE أو KSA2030 لخصم ٥٠ ﷼' : '💡 Try promo code: MODEEFE or KSA2030 for 50 SAR discount',
            //   style: GoogleFonts.cairo(fontSize: 11, color: textSub),
            // ),
          ],
        ],
      ),
    );
  }

  // --- 6. Payment Gateways Section ---
  Widget _buildPaymentGatewaysSection({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required List<PaymentGatewayItem> visibleGateways,
    required AsyncValue<List<PaymentGatewayItem>> gatewaysAsync,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment_rounded,
                      color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'طريقة وبوابة الدفع' : 'Payment Method',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAr ? 'مشفر 100%' : '100% Encrypted',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'اختر بوابتك المفضلة لإتمام الحجز بأمان'
                : 'Select your preferred gateway to complete booking safely',
            style: GoogleFonts.cairo(fontSize: 11, color: textSub),
          ),
          const SizedBox(height: 14),
          gatewaysAsync.when(
            data: (gateways) {
              return Column(
                children: gateways
                    .map((gw) => _buildGatewayTile(gw, isAr, isDark, cardBg,
                        cardBorder, textPrimary, textSub))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
            ),
            error: (_, __) => Column(
              children: visibleGateways
                  .map((gw) => _buildGatewayTile(gw, isAr, isDark, cardBg,
                      cardBorder, textPrimary, textSub))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayTile(
    PaymentGatewayItem gateway,
    bool isAr,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSub,
  ) {
    final visibleGateways = ref.read(visiblePaymentGatewaysProvider);
    final effectiveSelection =
        visibleGateways.any((g) => g.id == _selectedPaymentMethod)
            ? _selectedPaymentMethod
            : visibleGateways.first.id;
    final isSelected = effectiveSelection == gateway.id;

    IconData iconData = Icons.credit_card_rounded;
    if (gateway.iconType == 'apple_pay') {
      iconData = Icons.phone_iphone;
    } else if (gateway.iconType == 'wallet') {
      iconData = Icons.account_balance_wallet_outlined;
    } else if (gateway.iconType == 'offline') {
      iconData = Icons.handshake_outlined;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = gateway.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? const Color(0xFF140F1B) : const Color(0xFFF7F4F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio Indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accentGold : cardBorder,
                      width: 2,
                    ),
                    color:
                        isSelected ? AppColors.accentGold : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),

                // Gateway Icon
                Icon(
                  iconData,
                  color: isSelected
                      ? AppColors.accentGold
                      : AppColors.primaryMauve,
                  size: 22,
                ),
                const SizedBox(width: 10),

                // Gateway Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? gateway.nameAr : gateway.name,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        isAr ? gateway.descAr : gateway.desc,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Supported Card Logos Chips for Moyasar
            if (gateway.isMoyasar) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 32),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildPaymentBadge('مدى Mada', const Color(0xFF007E33)),
                    _buildPaymentBadge(
                        'Apple Pay', isDark ? Colors.white : Colors.black),
                    _buildPaymentBadge('Visa / MC', const Color(0xFF1A1F71)),
                    _buildPaymentBadge('STC Pay', const Color(0xFF4F008C)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --- 7. Total Receipt Breakdown Card ---
  Widget _buildReceiptSummaryCard({
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required double subtotal,
    required double finalTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'ملخص الفاتورة والمجموع' : 'Bill Breakdown & Summary',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildReceiptRow(
            label: isAr ? 'المجموع الفرعي:' : 'Subtotal:',
            value: '${subtotal.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
            isDark: isDark,
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isAr ? 'خصم الكوبون' : 'Coupon Discount'} ($_appliedCoupon):',
                  style:
                      GoogleFonts.cairo(fontSize: 12, color: AppColors.success),
                ),
                Text(
                  '-${_discountAmount.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _buildReceiptRow(
            label: isAr ? 'ضريبة القيمة المضافة (١٥٪):' : 'VAT (15%):',
            value: isAr ? 'مشمولة في السعر' : 'Included in price',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'المجموع النهائي المطلوب' : 'Grand Total Due',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    isAr
                        ? 'شامل كافة الرسوم والضرائب'
                        : 'All taxes and fees included',
                    style: GoogleFonts.cairo(fontSize: 10, color: textSub),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    finalTotal.toStringAsFixed(0),
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAr ? '﷼' : 'SAR',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 8. Trust Badges ---
  Widget _buildTrustBadges(
    bool isAr,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textSub,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF140F1B) : const Color(0xFFF7F4F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustBadgeItem(
            icon: Icons.lock_outline_rounded,
            label: isAr ? 'دفع مشفر 256-bit' : '256-bit Secure',
            textSub: textSub,
          ),
          Container(width: 1, height: 20, color: cardBorder),
          _buildTrustBadgeItem(
            icon: Icons.bolt_rounded,
            label: isAr ? 'تأكيد فوري' : 'Instant Confirmation',
            textSub: textSub,
          ),
          Container(width: 1, height: 20, color: cardBorder),
          _buildTrustBadgeItem(
            icon: Icons.verified_user_outlined,
            label: isAr ? 'ضمان ضيف' : 'Modeefe Guarantee',
            textSub: textSub,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadgeItem({
    required IconData icon,
    required String label,
    required Color textSub,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.accentGold),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
              fontSize: 10, fontWeight: FontWeight.w600, color: textSub),
        ),
      ],
    );
  }

  // --- Sticky Bottom Action Bar ---
  Widget _buildStickyBottomBar({
    required BuildContext context,
    required bool isAr,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required double finalTotal,
    required int serviceId,
    required String serviceType,
    required String title,
    required int guests,
    String? imageUrl,
    String? location,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Amount Info
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'الإجمالي المطلوب' : 'Total Due',
                  style: GoogleFonts.cairo(fontSize: 11, color: textSub),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      finalTotal.toStringAsFixed(0),
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAr ? '﷼' : 'SAR',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Confirm & Pay Primary Button
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMauve,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _handleConfirmBooking(
                          serviceId: serviceId,
                          serviceType: serviceType,
                          title: title,
                          guests: guests,
                          finalTotal: finalTotal,
                          isAr: isAr,
                          isDark: isDark,
                          imageUrl: imageUrl,
                          location: location,
                        ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'تأكيد الحجز والدفع' : 'Confirm & Pay',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
