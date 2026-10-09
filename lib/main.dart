import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/booking/data/payment_gateways_provider.dart';

const initialPaymentGatewaysMode =
    PaymentGatewaysMode.both; //todo (both - moyasarOnly - codOnly)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        paymentGatewaysManagerProvider.overrideWith(
          (ref) =>
              PaymentGatewaysManager(initialMode: initialPaymentGatewaysMode),
        ),
      ],
      child: const ModeefApp(),
    ),
  );
}

class ModeefApp extends ConsumerWidget {
  const ModeefApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'مُضيف',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
