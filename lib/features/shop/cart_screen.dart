import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/payment/moyasar_payment_manager.dart';
import '../../core/widgets/empty_state_view.dart';
import '../booking/data/payment_gateways_provider.dart';
import '../cart/data/cart_repository.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  String _paymentMethod = 'moyasar';
  bool _isProcessing = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    final cartState = ref.read(cartNotifierProvider);
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    final amount = cartState.total;
    if (amount <= 0) return;

    // Show sleek payment method selection sheet
    final chosenGatewayId = await _showPaymentMethodSheet(isAr: isAr);
    if (!mounted || chosenGatewayId == null) return;

    final visibleGateways = ref.read(visiblePaymentGatewaysProvider);
    final selectedGateway = visibleGateways.firstWhere(
      (g) => g.id == chosenGatewayId,
      orElse: () => visibleGateways.first,
    );

    if (!selectedGateway.isOffline) {
      setState(() => _isProcessing = true);
      final payment = await ref
          .read(moyasarPaymentManagerProvider)
          .start(context: context, amount: amount, isAr: isAr);
      setState(() => _isProcessing = false);
      if (!mounted) return;

      if (!payment.isPaid) {
        if (payment.status == MoyasarPaymentStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'لم يكتمل الدفع. لم يتم تأكيد الطلب.'
                    : 'Payment was not completed. Order was not confirmed.',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    _showOrderPlacedDialog(isAr: isAr);
  }

  Future<String?> _showPaymentMethodSheet({required bool isAr}) {
    final visibleGateways = ref.read(visiblePaymentGatewaysProvider);
    String tempSelected = _paymentMethod;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'اختر طريقة الدفع' : 'Choose Payment Method',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'اختر طريقة الدفع المفضلة لديك لتأكيد الطلب'
                      : 'Select your preferred payment method to complete order',
                  style: GoogleFonts.cairo(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 16),
                ...visibleGateways.map((gw) {
                  final isSel = tempSelected == gw.id;
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempSelected = gw.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.accentGold.withValues(alpha: 0.12)
                            : (isDark
                                ? const Color(0xFF16111C)
                                : const Color(0xFFFAF8FB)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel ? AppColors.accentGold : cardBorder,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            gw.isOffline
                                ? Icons.handshake_outlined
                                : Icons.credit_card_outlined,
                            color:
                                isSel ? AppColors.accentGold : textPrimary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? gw.nameAr : gw.name,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAr ? gw.descAr : gw.desc,
                                  style: GoogleFonts.cairo(
                                    color: textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSel
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color:
                                isSel ? AppColors.accentGold : textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _paymentMethod = tempSelected);
                      Navigator.pop(ctx, tempSelected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMauve,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isAr ? 'تأكيد ومتابعة الدفع' : 'Confirm & Pay',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderPlacedDialog({required bool isAr}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.check_circle_rounded,
            color: AppColors.accentGold, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr ? 'تم استلام طلبك بنجاح!' : 'Order Placed Successfully!',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'شكراً لتسوقك من بازار مُضيف الأصيل.\nرقم الطلب: #ORD-98431'
                  : 'Thank you for shopping from Modeefe Bazaar.\nOrder ID: #ORD-98431',
              style: GoogleFonts.cairo(
                fontSize: 13,
                height: 1.6,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(cartNotifierProvider.notifier).clearCart();
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMauve,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isAr ? 'العودة للرئيسية' : 'Back to Home',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (cartState.items.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            isAr ? 'السلة' : 'Shopping Cart',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        body: EmptyStateView(
          icon: Icons.shopping_bag_outlined,
          title: isAr ? 'سلتك فارغة' : 'Your cart is empty',
          message: isAr
              ? 'اكتشف منتجات وتحف سعودية أصيلة من بازار مُضيف.'
              : 'Explore authentic Saudi handicrafts and gifts in Modeefe Bazaar.',
          buttonText: isAr ? 'تسوّق الآن' : 'Shop Now',
          onButtonPressed: () => context.go('/store'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1625) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: cardBorder),
              ),
              child: Icon(
                isAr
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: textPrimary,
              ),
            ),
          ),
        ),
        title: Text(
          isAr ? 'السلة' : 'Cart',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        actions: [
          // Items badge (e.g. 4 قطع)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF261C30)
                    : const Color(0xFFEADFF2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                isAr
                    ? '${cartState.totalPieces} قطع'
                    : '${cartState.totalPieces} items',
                style: GoogleFonts.cairo(
                  color: isDark
                      ? const Color(0xFFD4C7DF)
                      : const Color(0xFF533C5E),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Products List
                ...cartState.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final qty = item.quantity > 0 ? item.quantity : 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        // Delete trash button
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 22, color: textMuted),
                          onPressed: () => ref
                              .read(cartNotifierProvider.notifier)
                              .removeItem(index),
                          tooltip: isAr ? 'حذف' : 'Remove',
                        ),
                        // Counter Stepper [- qty +]
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF231A2D)
                                : const Color(0xFFF3EEF7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => ref
                                    .read(cartNotifierProvider.notifier)
                                    .updateQuantity(index, -1),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.remove,
                                      size: 16, color: textPrimary),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '$qty',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref
                                    .read(cartNotifierProvider.notifier)
                                    .updateQuantity(index, 1),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.add,
                                      size: 16, color: AppColors.accentGold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product Title and Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.priceNumeric.toStringAsFixed(0)} ${isAr ? "ر.س" : "SAR"}',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl.isNotEmpty
                                ? item.imageUrl
                                : 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800&q=80',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 76,
                              height: 76,
                              color: cardBg,
                              child: Icon(Icons.inventory_2_outlined,
                                  color: textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Coupon Box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Apply Button
                      ElevatedButton(
                        onPressed: () async {
                          if (_couponController.text.trim().isNotEmpty) {
                            final success = await ref
                                .read(cartNotifierProvider.notifier)
                                .applyCoupon(_couponController.text.trim());
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr
                                        ? 'تم تطبيق كود الخصم بنجاح!'
                                        : 'Coupon applied successfully!',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primaryMauve,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF382944)
                              : const Color(0xFFEADFF2),
                          foregroundColor: isDark
                              ? Colors.white
                              : const Color(0xFF533C5E),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isAr ? 'تطبيق' : 'Apply',
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF533C5E),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          style: GoogleFonts.cairo(
                            color: textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: isAr
                                ? 'لديك كود خصم؟'
                                : 'Have a discount coupon?',
                            hintStyle: GoogleFonts.cairo(
                              color: textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Order Summary Card ("ملخص الطلب")
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'ملخص الطلب' : 'Order Summary',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'المجموع الفرعي' : 'Subtotal',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          Text(
                            '${cartState.subtotal.toStringAsFixed(0)} ${isAr ? "ر.س" : "SAR"}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (cartState.discount > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'خصم الكوبون' : 'Coupon Discount',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '-${cartState.discount.toStringAsFixed(0)} ${isAr ? "ر.س" : "SAR"}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Delivery / Shipping
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'التوصيل' : 'Delivery',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          Text(
                            isAr ? 'يُحسب عند الدفع' : 'Calculated at checkout',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: cardBorder, height: 1),
                      ),
                      // Final Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'الإجمالي' : 'Total',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${cartState.total.toStringAsFixed(0)} ${isAr ? "ر.س" : "SAR"}',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar matching Figma
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(top: BorderSide(color: cardBorder)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Action Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMauve,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isAr ? 'إتمام الطلب' : 'Complete Order',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Total Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr ? 'الإجمالي' : 'Total',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cartState.total.toStringAsFixed(0)} ${isAr ? "ر.س" : "SAR"}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
