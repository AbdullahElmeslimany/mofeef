import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/payment/moyasar_payment_manager.dart';
import '../../core/widgets/custom_button.dart';
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
      if (auth.userName != null) _nameController.text = auth.userName!;
      if (auth.userEmail != null) _emailController.text = auth.userEmail!;
      if (auth.user?.phone != null) {
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
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(bool isAr) {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'MODEEFE' || code == 'KSA2030' || code == 'GOLD') {
      setState(() {
        _discountAmount = 50.0;
        _appliedCoupon = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? 'تم تطبيق خصم بقيمة ٥٠ ﷼ بنجاح! 🎉'
              : 'Coupon applied successfully (-50 ﷼)! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (code.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'رمز الكوبون غير صالح' : 'Invalid coupon code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleConfirmBooking({
    required int serviceId,
    required String serviceType,
    required String title,
    required int guests,
    required double finalTotal,
    required bool isAr,
    String? imageUrl,
    String? location,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      // Step 0: Require a real Moyasar payment before confirming the booking.
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
                ),
                backgroundColor: AppColors.error,
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 64),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'تم تأكيد الحجز بنجاح!' : 'Booking Confirmed!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'رقم الحجز:' : 'Booking #:',
                              style: AppTypography.bodySmall),
                          Text(bookingCode,
                              style: AppTypography.titleSmall
                                  .copyWith(color: AppColors.primaryGold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'الموعد:' : 'Date:',
                              style: AppTypography.bodySmall),
                          Text(dateStr, style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'التذاكر / الضيوف:' : 'Guests:',
                              style: AppTypography.bodySmall),
                          Text('$guests ${isAr ? 'تذاكر' : 'tickets'}',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'المبلغ المدفوع:' : 'Paid Amount:',
                              style: AppTypography.bodySmall),
                          Text('${finalTotal.toStringAsFixed(0)} ﷼',
                              style: AppTypography.titleSmall
                                  .copyWith(color: AppColors.primaryGold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.qr_code_2,
                      size: 100, color: Colors.black),
                ),
              ],
            ),
            actions: [
              Center(
                child: CustomButton(
                  text: isAr ? 'عرض التذكرة في حجوزاتي' : 'View in My Bookings',
                  width: 220,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/reservations');
                  },
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isAr ? 'حدث خطأ أثناء الحجز: $e' : 'Booking error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final gatewaysAsync = ref.watch(paymentGatewaysProvider);
    final visibleGateways = ref.watch(visiblePaymentGatewaysProvider);

    // If draft is passed from booking sheet, render with exact parameters!
    if (widget.draft != null) {
      final draft = widget.draft!;
      final subtotal = draft.subtotal;
      final total = (subtotal - _discountAmount).clamp(0.0, double.infinity);

      return Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إتمام الحجز والدفع' : 'Checkout & Payment',
              style: AppTypography.headingSmall),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: isAr ? 'رجوع' : 'Back',
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Item Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: draft.imageUrl ??
                            'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(draft.title, style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                              draft.location ??
                                  (isAr
                                      ? 'المملكة العربية السعودية'
                                      : 'Saudi Arabia'),
                              style: AppTypography.bodySmall),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.goldGlow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              draft.serviceType == 'tour'
                                  ? (isAr ? 'مسار سياحي' : 'Tourist Trail')
                                  : draft.serviceType == 'event'
                                      ? (isAr ? 'فعالية' : 'Event')
                                      : (isAr ? 'معلم ومتحف' : 'Museum'),
                              style: const TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Booking Date
              Text(isAr ? 'موعد الزيارة المحدد' : 'Selected Visit Date',
                  style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: AppColors.primaryGold, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: AppTypography.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Exact Ticket Breakdown
              Text(
                  isAr
                      ? 'تفاصيل التذاكر والخدمات'
                      : 'Tickets & Services Breakdown',
                  style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (draft.personItems.isNotEmpty)
                      ...draft.personItems.where((p) => p.quantity > 0).map(
                            (p) => _buildPriceRow(
                              '${p.quantity} × ${p.name}',
                              '${p.total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                            ),
                          )
                    else
                      _buildPriceRow(
                        '${draft.totalGuests} × ${isAr ? 'تذكرة دخول' : 'General Ticket'}',
                        '${draft.subtotal.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                      ),
                    if (draft.extraItems.isNotEmpty) ...[
                      const Divider(color: AppColors.border, height: 16),
                      ...draft.extraItems.map(
                        (e) => _buildPriceRow(
                          '+ ${e.name}',
                          '${e.price.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Guest Details
              Text(
                  isAr ? 'بيانات المسافر الرئيسي' : 'Lead Traveler Information',
                  style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isAr ? 'الاسم الكامل' : 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.primaryGold),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText:
                      isAr ? 'البريد الإلكتروني لتأكيد الحجز' : 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.primaryGold),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAr ? 'رقم الجوال للتواصل' : 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.primaryGold),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Coupon Code
              Text(isAr ? 'كوبون الخصم' : 'Discount Coupon',
                  style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'أدخل رمز القسيمة (مثال: MODEEFE10)'
                            : 'Enter coupon code',
                        prefixIcon: const Icon(Icons.discount_outlined,
                            color: AppColors.primaryGold),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _applyCoupon(isAr),
                    child: Text(isAr ? 'تطبيق' : 'Apply',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Payment Gateways
              Text(isAr ? 'طريقة وبوابة الدفع' : 'Payment Method',
                  style: AppTypography.titleLarge),
              const SizedBox(height: 10),

              gatewaysAsync.when(
                data: (gateways) {
                  return Column(
                    children: gateways
                        .map((gw) => _buildGatewayTile(gw, isAr))
                        .toList(),
                  );
                },
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: AppColors.primaryGold))),
                error: (_, __) => Column(
                  children: visibleGateways
                      .map((gw) => _buildGatewayTile(gw, isAr))
                      .toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 7. Total Calculation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(isAr ? 'المجموع الفرعي' : 'Subtotal',
                        '${subtotal.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}'),
                    if (_discountAmount > 0)
                      _buildPriceRow(
                        '${isAr ? 'خصم الكوبون' : 'Discount'} ($_appliedCoupon)',
                        '-${_discountAmount.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                      ),
                    _buildPriceRow(
                        isAr ? 'ضريبة القيمة المضافة (١٥٪)' : 'VAT (15%)',
                        isAr ? 'مشمولة' : 'Included'),
                    const Divider(color: AppColors.border, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'المجموع النهائي' : 'Total Amount',
                            style: AppTypography.titleMedium),
                        Text(
                            '${total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                            style: AppTypography.price),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 8. Confirm Button
              CustomButton(
                text:
                    '${isAr ? 'تأكيد ودفع' : 'Confirm & Pay'} ${total.toStringAsFixed(0)} ﷼',
                isLoading: _isSubmitting,
                onPressed: () => _handleConfirmBooking(
                  serviceId: draft.serviceId,
                  serviceType: draft.serviceType,
                  title: draft.title,
                  guests: draft.totalGuests,
                  finalTotal: total,
                  isAr: isAr,
                  imageUrl: draft.imageUrl,
                ),
              ),
              const SizedBox(height: 12),

              // Cancel and Return Button
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back,
                      size: 16, color: AppColors.textSecondary),
                  label: Text(
                    isAr
                        ? 'إلغاء والرجوع للتفاصيل'
                        : 'Cancel and Return to Details',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    // Fallback: Fetch from tourDetailProvider if no draft was passed
    final tourAsync = ref.watch(tourDetailProvider(widget.experienceId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إتمام الحجز والدفع' : 'Checkout & Payment',
            style: AppTypography.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: isAr ? 'رجوع' : 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: tourAsync.when(
        data: (tour) {
          final unitPrice = tour.salePrice ?? tour.price;
          final subtotal = unitPrice * _ticketCount;
          final total =
              (subtotal - _discountAmount).clamp(0.0, double.infinity);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: tour.imageUrl ??
                              'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tour.title, style: AppTypography.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                                tour.locationName ?? (isAr ? 'المملكة' : 'KSA'),
                                style: AppTypography.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                                '${tour.formattedPrice} / ${isAr ? 'للتذكرة' : 'per ticket'}',
                                style:
                                    AppTypography.price.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Date Picker Section
                Text(isAr ? 'موعد الزيارة' : 'Visit Date',
                    style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primaryGold,
                              surface: AppColors.card,
                              onSurface: AppColors.textPrimary,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: AppColors.primaryGold, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                              style: AppTypography.titleSmall,
                            ),
                          ],
                        ),
                        Text(isAr ? 'تغيير الموعد' : 'Change Date',
                            style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tickets Counter
                Text(isAr ? 'عدد التذاكر' : 'Number of Tickets',
                    style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isAr ? 'التذاكر (بالغين)' : 'Tickets (Adults)',
                          style: AppTypography.titleSmall),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.primaryGold),
                            onPressed: _ticketCount > 1
                                ? () => setState(() => _ticketCount--)
                                : null,
                          ),
                          Text('$_ticketCount',
                              style: AppTypography.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.primaryGold),
                            onPressed: () => setState(() => _ticketCount++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Guest Details
                Text(
                    isAr
                        ? 'بيانات المسافر الرئيسي'
                        : 'Lead Traveler Information',
                    style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الاسم الكامل' : 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'البريد الإلكتروني لتأكيد الحجز'
                        : 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رقم الجوال' : 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),

                // Coupon Section
                Text(isAr ? 'كوبون الخصم' : 'Discount Coupon',
                    style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'أدخل الرمز (مثال: MODEEFE)'
                              : 'Enter promo code (e.g. MODEEFE)',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _applyCoupon(isAr),
                      child: Text(isAr ? 'تطبيق' : 'Apply',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Methods
                Text(isAr ? 'طريقة وبوابة الدفع' : 'Payment Method',
                    style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                ...visibleGateways.map((gw) => _buildGatewayTile(gw, isAr)),

                const SizedBox(height: 24),

                // Price Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                          '${isAr ? 'التذاكر' : 'Tickets'} ($_ticketCount)',
                          '${subtotal.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}'),
                      if (_discountAmount > 0)
                        _buildPriceRow(
                            '${isAr ? 'خصم الكوبون' : 'Discount'} ($_appliedCoupon)',
                            '-${_discountAmount.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}'),
                      _buildPriceRow(
                          isAr ? 'ضريبة القيمة المضافة (١٥٪)' : 'VAT (15%)',
                          isAr ? 'مشمولة' : 'Included'),
                      const Divider(color: AppColors.border, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'المجموع الكلي' : 'Total Amount',
                              style: AppTypography.titleMedium),
                          Text(
                              '${total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                              style: AppTypography.price),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm Button
                CustomButton(
                  text:
                      '${isAr ? 'تأكيد ودفع' : 'Confirm & Pay'} ${total.toStringAsFixed(0)} ${isAr ? '﷼' : 'SAR'}',
                  isLoading: _isSubmitting,
                  onPressed: () => _handleConfirmBooking(
                    serviceId: int.tryParse(widget.experienceId) ?? 1,
                    serviceType: 'tour',
                    title: tour.title,
                    guests: _ticketCount,
                    finalTotal: total,
                    isAr: isAr,
                    imageUrl: tour.imageUrl,
                    location: tour.locationName ?? tour.address,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_back,
                        size: 16, color: AppColors.textSecondary),
                    label: Text(
                      isAr
                          ? 'إلغاء والرجوع للتفاصيل'
                          : 'Cancel and Return to Details',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (_, __) => Center(
          child: Text(
              isAr
                  ? 'تعذر تحميل بيانات التجربة للحجز'
                  : 'Failed to load booking details',
              style: AppTypography.titleMedium),
        ),
      ),
    );
  }

  Widget _buildGatewayTile(PaymentGatewayItem gateway, bool isAr) {
    final visibleGateways = ref.read(visiblePaymentGatewaysProvider);
    final effectiveSelection = visibleGateways.any(
            (g) => g.id == _selectedPaymentMethod)
        ? _selectedPaymentMethod
        : visibleGateways.first.id;
    final isSelected = effectiveSelection == gateway.id;
    IconData iconData = Icons.payment;
    if (gateway.iconType == 'apple_pay') iconData = Icons.phone_iphone;
    if (gateway.iconType == 'mada' || gateway.iconType == 'card') {
      iconData = Icons.credit_card;
    }
    if (gateway.iconType == 'wallet') {
      iconData = Icons.account_balance_wallet_outlined;
    }
    if (gateway.iconType == 'stc_pay') iconData = Icons.phone_android;
    if (gateway.iconType == 'offline') iconData = Icons.handshake_outlined;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = gateway.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldGlow : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(iconData,
                color: isSelected
                    ? AppColors.primaryGold
                    : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? gateway.nameAr : gateway.name,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr ? gateway.descAr : gateway.desc,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primaryGold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(value, style: AppTypography.titleSmall),
        ],
      ),
    );
  }
}
