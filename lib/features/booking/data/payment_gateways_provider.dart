import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentGatewayItem {
  final String id;
  final String name;
  final String nameAr;
  final String desc;
  final String descAr;
  final bool isOffline;
  final String iconType;

  const PaymentGatewayItem({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.desc,
    required this.descAr,
    this.isOffline = false,
    required this.iconType,
  });

  bool get isMoyasar => id.startsWith('moyasar');
}

const _moyasarGateway = PaymentGatewayItem(
  id: 'moyasar',
  name: 'Online Payment via Moyasar',
  nameAr: 'الدفع الإلكتروني',
  desc: 'Secure payment via Mada, Visa, MasterCard, Apple Pay & STC Pay',
  descAr: 'دفع آمن ومشفر عبر مدى وفيزا وماستركارد وApple Pay وSTC Pay',
  iconType: 'card',
);

const _codGateway = PaymentGatewayItem(
  id: 'offline',
  name: 'Offline Payment',
  nameAr: 'الدفع عند الوصول',
  desc: 'Pay in cash when the service is delivered',
  descAr: 'ادفع نقدًا عند استلام الخدمة',
  isOffline: true,
  iconType: 'offline',
);

const appPaymentGateways = <PaymentGatewayItem>[_moyasarGateway, _codGateway];

enum PaymentGatewaysMode {
  both,
  moyasarOnly,
  codOnly,
}

const defaultPaymentGatewaysMode = PaymentGatewaysMode.both;

class PaymentGatewaysManager extends StateNotifier<PaymentGatewaysMode> {
  PaymentGatewaysManager(
      {PaymentGatewaysMode initialMode = defaultPaymentGatewaysMode})
      : super(initialMode);

  Set<String>? _allowedIds;

  void setMode(PaymentGatewaysMode mode) {
    _allowedIds = null;
    state = mode;
  }

  void showBoth() => setMode(PaymentGatewaysMode.both);

  void showMoyasarOnly() => setMode(PaymentGatewaysMode.moyasarOnly);

  void showCodOnly() => setMode(PaymentGatewaysMode.codOnly);

  void showOnly(Set<String> gatewayIds) {
    _allowedIds = gatewayIds;
    state = PaymentGatewaysMode.both;
  }

  void resetToDefault() => setMode(defaultPaymentGatewaysMode);

  List<PaymentGatewayItem> get visibleGateways {
    final pool = _allowedIds == null
        ? appPaymentGateways
        : appPaymentGateways.where((g) => _allowedIds!.contains(g.id)).toList();
    return switch (state) {
      PaymentGatewaysMode.both => pool,
      PaymentGatewaysMode.moyasarOnly =>
        pool.where((g) => g.isMoyasar).toList(),
      PaymentGatewaysMode.codOnly => pool.where((g) => g.isOffline).toList(),
    };
  }
}

final paymentGatewaysManagerProvider =
    StateNotifierProvider<PaymentGatewaysManager, PaymentGatewaysMode>(
  (ref) => PaymentGatewaysManager(),
);

final visiblePaymentGatewaysProvider =
    Provider<List<PaymentGatewayItem>>((ref) {
  ref.watch(paymentGatewaysManagerProvider);
  return ref.read(paymentGatewaysManagerProvider.notifier).visibleGateways;
});

final paymentGatewaysProvider =
    FutureProvider<List<PaymentGatewayItem>>((ref) async {
  return ref.watch(visiblePaymentGatewaysProvider);
});
