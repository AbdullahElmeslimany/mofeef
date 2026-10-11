import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/payment/moyasar_payment_manager.dart';
import '../../core/widgets/custom_button.dart';
import '../auth/auth_provider.dart';

class WalletTransaction {
  final String id;
  final String title;
  final String date;
  final double amount;
  final bool isCredit;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
  });
}

class WalletState {
  final double balance;
  final List<WalletTransaction> transactions;

  const WalletState({
    this.balance = 0.0,
    this.transactions = const [],
  });

  WalletState copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState(balance: 0.0, transactions: []));

  void addFunds(double amount, String paymentMethod, bool isAr) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final newTx = WalletTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      title: isAr
          ? 'شحن رصيد المحفظة ($paymentMethod)'
          : 'Wallet Top-up ($paymentMethod)',
      date: dateStr,
      amount: amount,
      isCredit: true,
    );

    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [newTx, ...state.transactions],
    );
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _showTopUpModal(BuildContext context, WidgetRef ref, bool isAr, bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    double selectedAmount = 100.0;
    String selectedMethod = 'Moyasar';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final amounts = [50.0, 100.0, 250.0, 500.0, 1000.0];
          final methods = ['Moyasar'];

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'شحن رصيد المحفظة' : 'Top Up Wallet Balance',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Selection
                Text(
                  isAr ? 'اختر المبلغ' : 'Select Amount',
                  style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: amounts.map((amt) {
                    final isSel = selectedAmount == amt;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedAmount = amt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryMauve : (isDark ? const Color(0xFF1E1624) : const Color(0xFFECE7EF)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSel ? AppColors.primaryMauve : cardBorder),
                        ),
                        child: Text(
                          '${amt.toInt()} ${isAr ? 'ر.س' : 'SAR'}',
                          style: GoogleFonts.cairo(
                            color: isSel ? Colors.white : textMuted,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Payment Method
                Text(
                  isAr ? 'بوابة الدفع الآمنة' : 'Payment Gateway',
                  style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 10),
                ...methods.map((method) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1624) : const Color(0xFFF7F4F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryMauve, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: AppColors.accentGold, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          isAr ? 'ميسر (مدى / فيزا / ماستركارد)' : 'Moyasar (Mada / Visa / MC)',
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.check_circle_rounded, color: AppColors.primaryMauve, size: 20),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Confirm button
                CustomButton(
                  text: isAr
                      ? 'تأكيد وشحن (${selectedAmount.toInt()} ر.س)'
                      : 'Confirm & Top Up (${selectedAmount.toInt()} SAR)',
                  isLoading: isProcessing,
                  onPressed: () async {
                    setModalState(() => isProcessing = true);
                    final payment =
                        await ref.read(moyasarPaymentManagerProvider).start(
                              context: context,
                              amount: selectedAmount,
                              isAr: isAr,
                              description: isAr
                                  ? 'شحن رصيد محفظة مضيف'
                                  : 'Modeef wallet top-up',
                            );
                    if (!context.mounted) return;
                    setModalState(() => isProcessing = false);

                    if (payment.isPaid) {
                      ref.read(walletProvider.notifier).addFunds(
                            selectedAmount,
                            selectedMethod,
                            isAr,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تم شحن المحفظة بنجاح بمبلغ ${selectedAmount.toInt()} ر.س'
                                : 'Successfully added ${selectedAmount.toInt()} SAR to wallet',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else if (payment.status == MoyasarPaymentStatus.failed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'لم يكتمل الدفع. لم يتم شحن المحفظة.'
                                : 'Payment was not completed. Wallet was not topped up.',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final userName =
        authState.user?.displayName ?? (isAr ? 'سعود العتيبي' : 'Saud Alotaibi');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'المحفظة الرقمية' : 'Digital Wallet',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Royal Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF654D71), Color(0xFF281C30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF654D71).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.cairo(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentGold, size: 26),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isAr ? 'الرصيد المتاح' : 'Available Balance',
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        walletState.balance.toStringAsFixed(2),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'ر.س' : 'SAR',
                        style: GoogleFonts.cairo(
                          color: AppColors.accentGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showTopUpModal(context, ref, isAr, isDark, cardBg, cardBorder, textPrimary, textMuted),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            isAr ? 'إضافة رصيد' : 'Top Up',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr
                                      ? 'يمكنك استخدام رصيد المحفظة مباشرة عند إتمام الحجز'
                                      : 'You can use wallet balance directly at checkout',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            isAr ? 'استخدام بالحجز' : 'Use in Booking',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Transactions Header
            Text(
              isAr ? 'سجل العمليات والتحويلات' : 'Transaction History',
              style: GoogleFonts.cairo(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (walletState.transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cardBorder, width: 1.2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isAr ? 'لا توجد عمليات سابقة في المحفظة' : 'No previous transactions found',
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'ستظهر هنا كافة عمليات الشحن والمدفوعات فور إجرائها'
                          : 'All top-ups and booking payments will appear here',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...walletState.transactions.map(
                (tx) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tx.isCredit
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.primaryMauve.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: tx.isCredit ? AppColors.success : AppColors.accentGold,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.date,
                                style: GoogleFonts.cairo(fontSize: 11, color: textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${tx.isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}',
                        style: GoogleFonts.cairo(
                          color: tx.isCredit ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
