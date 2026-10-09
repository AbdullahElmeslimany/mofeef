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

    final navItems = [
      _NavItemData(
        label: isAr ? 'الرئيسية' : 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _NavItemData(
        label: isAr ? 'اكتشف' : 'Discover',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
      ),
      _NavItemData(
        label: isAr ? 'الحجوزات' : 'Bookings',
        icon: Icons.event_available_outlined,
        activeIcon: Icons.event_available,
      ),
      _NavItemData(
        label: isAr ? 'المفضلات' : 'Favorites',
        icon: Icons.favorite_border,
        activeIcon: Icons.favorite,
      ),
      _NavItemData(
        label: isAr ? 'حسابي' : 'Account',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1926).withOpacity(0.96),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color(0xFF1E3246), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = currentIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index, context),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5A623),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66F5A623),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.activeIcon,
                            color: const Color(0xFF0C1926),
                            size: 20,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Icon(
                            item.icon,
                            color: const Color(0xFF8A9BB0),
                            size: 21,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFF5A623) : const Color(0xFF8A9BB0),
                          fontSize: 10,
                          height: 1.1,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
