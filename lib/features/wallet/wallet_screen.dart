import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
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

  void _showTopUpModal(BuildContext context, WidgetRef ref, bool isAr) {
    double selectedAmount = 100.0;
    String selectedMethod = 'Moyasar';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final amounts = [50.0, 100.0, 250.0, 500.0, 1000.0];
          final methods = [
            'Moyasar'
            // , 'Apple Pay'
          ];

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'شحن رصيد المحفظة' : 'Top Up Wallet Balance',
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: 16),

                // Amount Selection
                Text(isAr ? 'اختر المبلغ (﷼)' : 'Select Amount (﷼)',
                    style: AppTypography.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: amounts.map((amt) {
                    final isSel = selectedAmount == amt;
                    return ChoiceChip(
                      label: Text('${amt.toInt()} ﷼'),
                      selected: isSel,
                      onSelected: (val) =>
                          setModalState(() => selectedAmount = amt),
                      selectedColor: AppColors.primaryGold,
                      backgroundColor: AppColors.card,
                      labelStyle: TextStyle(
                        color:
                            isSel ? AppColors.textDark : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Payment Method
                Text(isAr ? 'طريقة الدفع' : 'Payment Method',
                    style: AppTypography.titleSmall),
                const SizedBox(height: 10),
                ...methods.map((method) {
                  final isSel = selectedMethod == method;
                  return Material(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color:
                              isSel ? AppColors.primaryGold : AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioListTile<String>(
                      title: Text(method,
                          style:
                              AppTypography.titleSmall.copyWith(fontSize: 14)),
                      value: method,
                      groupValue: selectedMethod,
                      activeColor: AppColors.primaryGold,
                      onChanged: (val) =>
                          setModalState(() => selectedMethod = val!),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Confirm button
                CustomButton(
                  text: isAr ? 'تأكيد وشحن الرصيد' : 'Confirm & Top Up',
                  isLoading: isProcessing,
                  onPressed: () async {
                    setModalState(() => isProcessing = true);
                    final payment =
                        await ref.read(moyasarPaymentManagerProvider).start(
                              context: context,
                              amount: selectedAmount,
                              isAr: isAr,
                              description: isAr
                                  ? 'شحن رصيد محفظة مديف'
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
                                ? 'تم شحن المحفظة بنجاح بمبلغ ${selectedAmount.toInt()} ﷼'
                                : 'Successfully added ${selectedAmount.toInt()} ﷼ to wallet',
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

    final userName =
        authState.user?.displayName ?? (isAr ? 'ضيف مُضيف' : 'Modeefe Guest');

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المحفظة الرقمية' : 'Digital Wallet',
            style: AppTypography.headingSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF273844), Color(0xFF101C25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.goldGlow,
                      blurRadius: 20,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(userName,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.primaryGold)),
                      const Icon(Icons.account_balance_wallet,
                          color: AppColors.primaryGold, size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(isAr ? 'الرصيد المتاح' : 'Available Balance',
                      style: AppTypography.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${walletState.balance.toStringAsFixed(2)} ﷼',
                    style: AppTypography.headingLarge
                        .copyWith(color: AppColors.primaryGold, fontSize: 32),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: isAr ? 'إضافة رصيد' : 'Top Up',
                          icon: Icons.add,
                          height: 44,
                          onPressed: () => _showTopUpModal(context, ref, isAr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: isAr ? 'استخدام في الحجز' : 'Use in Bookings',
                          isOutlined: true,
                          height: 44,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr
                                    ? 'يمكنك اختيار الدفع عبر المحفظة مباشرة في شاشات الحجز'
                                    : 'You can choose Wallet Payment at checkout'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Transactions Header
            Text(isAr ? 'سجل العمليات والتحويلات' : 'Transaction History',
                style: AppTypography.titleLarge),
            const SizedBox(height: 12),

            if (walletState.transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'لا توجد عمليات سابقة في المحفظة'
                          : 'No previous transactions found',
                      style: AppTypography.titleSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'ستظهر هنا كافة عمليات الشحن والمدفوعات فور إجرائها'
                          : 'All top-ups and booking payments will appear here',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...walletState.transactions.map((tx) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
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
                                    ? AppColors.success.withOpacity(0.15)
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tx.isCredit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx.isCredit
                                    ? AppColors.success
                                    : AppColors.primaryGold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.title, style: AppTypography.titleSmall),
                                const SizedBox(height: 2),
                                Text(tx.date,
                                    style: AppTypography.bodySmall
                                        .copyWith(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${tx.isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(0)} ﷼',
                          style: TextStyle(
                            color: tx.isCredit
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
