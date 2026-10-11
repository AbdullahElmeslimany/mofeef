import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/booking/my_reservations_screen.dart';
import '../../features/booking/checkout_screen.dart';
import '../../features/booking/data/booking_draft.dart';
import '../../features/profile/favorites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/privacy_policy_screen.dart';
import '../../features/profile/terms_conditions_screen.dart';
import '../../features/profile/notifications_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/shop/store_screen.dart';
import '../../features/shop/product_details_screen.dart';
import '../../features/shop/cart_screen.dart';
import '../../features/experiences/experience_details_screen.dart';
import '../../features/locations/presentation/locations_list_screen.dart';
import '../../features/locations/presentation/destination_detail_screen.dart';
import '../../features/tours/presentation/tourist_trails_screen.dart';
import '../../features/museums/presentation/museum_list_screen.dart';
import '../../features/museums/presentation/museum_detail_screen.dart';
import '../../features/guides/presentation/guide_list_screen.dart';
import '../../features/guides/presentation/guide_detail_screen.dart';
import '../../features/cars/presentation/car_list_screen.dart';
import '../../features/cars/presentation/car_detail_screen.dart';
import '../../features/events/presentation/event_list_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../localization/locale_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => const NoTransitionPage(child: DiscoveryScreen()),
          ),
          GoRoute(
            path: '/reservations',
            pageBuilder: (context, state) => const NoTransitionPage(child: MyReservationsScreen()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => const NoTransitionPage(child: FavoritesScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/experience/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          return ExperienceDetailsScreen(experienceId: id);
        },
      ),
      GoRoute(
        path: '/tour/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          return ExperienceDetailsScreen(experienceId: id);
        },
      ),
      GoRoute(
        path: '/ar/tour/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          return ExperienceDetailsScreen(experienceId: id);
        },
      ),
      GoRoute(
        path: '/en/tour/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          return ExperienceDetailsScreen(experienceId: id);
        },
      ),
      GoRoute(
        path: '/ar/experience/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          return ExperienceDetailsScreen(experienceId: id);
        },
      ),
      GoRoute(
        path: '/en/experience/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          return ExperienceDetailsScreen(experienceId: id);
        },
      ),
      GoRoute(
        path: '/checkout/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '17';
          final draft = state.extra is BookingDraft ? state.extra as BookingDraft : null;
          return CheckoutScreen(experienceId: id, draft: draft);
        },
      ),
      GoRoute(
        path: '/store',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StoreScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '11';
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/shop/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '11';
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/ar/shop/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '11';
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/en/shop/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '11';
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/ar/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '11';
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/en/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '11';
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/wallet',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-conditions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: '/trails',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TouristTrailsScreen(),
      ),
      GoRoute(
        path: '/locations',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LocationsListScreen(),
      ),
      GoRoute(
        path: '/location/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final name = state.uri.queryParameters['name'];
          return DestinationDetailScreen(locationId: id, initialName: name);
        },
      ),
      GoRoute(
        path: '/destination/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final name = state.uri.queryParameters['name'];
          return DestinationDetailScreen(locationId: id, initialName: name);
        },
      ),
      GoRoute(
        path: '/ar/location/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final name = state.uri.queryParameters['name'];
          return DestinationDetailScreen(locationId: id, initialName: name);
        },
      ),
      GoRoute(
        path: '/en/location/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final name = state.uri.queryParameters['name'];
          return DestinationDetailScreen(locationId: id, initialName: name);
        },
      ),
      GoRoute(
        path: '/museums',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MuseumListScreen(),
      ),
      GoRoute(
        path: '/museum/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          return MuseumDetailScreen(museumId: id);
        },
      ),
      GoRoute(
        path: '/ar/museum/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          return MuseumDetailScreen(museumId: id);
        },
      ),
      GoRoute(
        path: '/en/museum/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          return MuseumDetailScreen(museumId: id);
        },
      ),
      GoRoute(
        path: '/guides',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GuideListScreen(),
      ),
      GoRoute(
        path: '/guide/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '61';
          return GuideDetailScreen(guideId: id);
        },
      ),
      GoRoute(
        path: '/ar/guide/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '61';
          return GuideDetailScreen(guideId: id);
        },
      ),
      GoRoute(
        path: '/en/guide/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '61';
          return GuideDetailScreen(guideId: id);
        },
      ),
      GoRoute(
        path: '/cars',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CarListScreen(),
      ),
      GoRoute(
        path: '/car/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '3';
          return CarDetailScreen(carId: id);
        },
      ),
      GoRoute(
        path: '/ar/car/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '3';
          return CarDetailScreen(carId: id);
        },
      ),
      GoRoute(
        path: '/en/car/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '3';
          return CarDetailScreen(carId: id);
        },
      ),
      GoRoute(
        path: '/events',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EventListScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '12';
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/ar/event/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '12';
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/en/event/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '12';
          return EventDetailScreen(eventId: id);
        },
      ),
    ],
  );
});


class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/reservations')) return 2;
    if (location.startsWith('/favorites')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/discover');
        break;
      case 2:
        context.go('/reservations');
        break;
      case 3:
        context.go('/favorites');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      _NavItemData(
        label: isAr ? 'الرئيسية' : 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _NavItemData(
        label: isAr ? 'استكشف' : 'Discover',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
      ),
      _NavItemData(
        label: isAr ? 'رحلاتي' : 'Trips',
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
      ),
      _NavItemData(
        label: isAr ? 'المفضلة' : 'Favorites',
        icon: Icons.favorite_outline_rounded,
        activeIcon: Icons.favorite_rounded,
      ),
      _NavItemData(
        label: isAr ? 'حسابي' : 'Account',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    final navBg = isDark ? const Color(0xFF0E0B12) : Colors.white;
    final navBorder = isDark ? const Color(0xFF231A2E) : const Color(0xFFEBE3F0);
    final inactiveColor =
        isDark ? const Color(0xFF786D85) : const Color(0xFF8E839B);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder, width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index, context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Active Gold Line Indicator (matching Figma)
                        Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF5A623)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(3),
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Icon
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? const Color(0xFFF5A623)
                              : inactiveColor,
                          size: 22,
                        ),
                        const SizedBox(height: 3),

                        // Label in Cairo font
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isSelected
                                ? const Color(0xFFF5A623)
                                : inactiveColor,
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
