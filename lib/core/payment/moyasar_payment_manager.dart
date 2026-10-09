import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moyasar/moyasar.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

/// Outcome of a Moyasar payment attempt.
enum MoyasarPaymentStatus {
  /// Payment was charged successfully.
  paid,

  /// A payment was attempted but ended in a failed/non-paid state.
  failed,

  /// The sheet was dismissed by the user without completing a payment.
  cancelled,

  /// No Moyasar API key is configured; payment could not start.
  notConfigured,
}

class MoyasarPaymentResult {
  final MoyasarPaymentStatus status;
  final String? paymentId;
  final String? errorMessage;

  const MoyasarPaymentResult(
    this.status, {
    this.paymentId,
    this.errorMessage,
  });

  bool get isPaid => status == MoyasarPaymentStatus.paid;
}

/// Opens the Moyasar card payment sheet and returns the payment outcome.
///
/// Example:
/// ```dart
/// final payment = await ref.read(moyasarPaymentManagerProvider).start(
///   context: context,
///   amount: total,
///   isAr: isAr,
/// );
/// if (payment.isPaid) { /* confirm order */ }
/// ```
class MoyasarPaymentManager {
  const MoyasarPaymentManager();

  Future<MoyasarPaymentResult> start({
    required BuildContext context,
    required double amount,
    required bool isAr,
    String? description,
  }) async {
    if (AppConfig.moyasarApiKey.isEmpty) {
      return const MoyasarPaymentResult(
        MoyasarPaymentStatus.notConfigured,
        errorMessage: 'Moyasar API key is not configured.',
      );
    }

    final config = PaymentConfig(
      publishableApiKey: AppConfig.moyasarApiKey,
      amount: (amount * 100).round(),
      givenID: const Uuid().v4(),
      description:
          description ?? (isAr ? 'دفع عبر تطبيق مديف' : 'Modeef payment'),
      creditCard: CreditCardConfig(saveCard: false, manual: false),
    );

    final result = await showModalBottomSheet<MoyasarPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MoyasarPaymentSheet(
        config: config,
        locale: isAr ? const Localization.ar() : const Localization.en(),
      ),
    );

    return result ?? const MoyasarPaymentResult(MoyasarPaymentStatus.cancelled);
  }
}

final moyasarPaymentManagerProvider = Provider<MoyasarPaymentManager>((ref) {
  return const MoyasarPaymentManager();
});

class _MoyasarPaymentSheet extends StatefulWidget {
  final PaymentConfig config;
  final Localization locale;

  const _MoyasarPaymentSheet({
    required this.config,
    required this.locale,
  });

  @override
  State<_MoyasarPaymentSheet> createState() => _MoyasarPaymentSheetState();
}

class _MoyasarPaymentSheetState extends State<_MoyasarPaymentSheet> {
  void _handleResult(dynamic result) {
    if (result is PaymentResponse) {
      final paid = result.status == PaymentStatus.paid;
      Navigator.of(context).pop(
        MoyasarPaymentResult(
          paid ? MoyasarPaymentStatus.paid : MoyasarPaymentStatus.failed,
          paymentId: result.id,
          errorMessage: paid ? null : _failureMessage(result),
        ),
      );
      return;
    }

    final message = result is ApiError
        ? result.message
        : (widget.locale.languageCode == 'ar'
            ? 'فشل الدفع. حاول مرة أخرى'
            : 'Payment failed. Please try again.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _failureMessage(PaymentResponse result) {
    final source = result.source;
    final message = source is CardPaymentResponseSource ? source.message : null;
    return message?.isNotEmpty == true
        ? message!
        : (widget.locale.languageCode == 'ar'
            ? 'لم يكتمل الدفع'
            : 'Payment was not completed');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Theme(
              data: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: Colors.white,
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black87),
                  hintStyle: TextStyle(color: Colors.black38),
                ),
              ),
              child: CreditCard(
                config: widget.config,
                onPaymentResult: _handleResult,
                locale: widget.locale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
