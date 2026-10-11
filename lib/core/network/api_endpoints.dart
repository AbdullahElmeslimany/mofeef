class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (Laravel API)
  static const String baseUrl = 'https://staging.modeef-e.com/api';

  // ==================== 1. AUTH ====================
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/auth/email/verify';
  static const String resendVerification = '/auth/email/resend';

  // ==================== 2. ACCOUNT & MEDIA ====================
  static const String currentUser = '/user';
  static const String deleteAccount = '/user/permanently_delete';
  static const String uploadMedia = '/media/store';

  // ==================== 3. WISHLIST ====================
  static const String wishlist = '/user/wishlist';
  static String addToWishlist(String serviceType, dynamic id) =>
      '/user/wishlist/$serviceType/$id';
  static String removeFromWishlist(String serviceType, dynamic id) =>
      '/user/wishlist/$serviceType/$id';

  // ==================== 4. BOOKING HISTORY & TICKETS ====================
  static const String bookingHistory = '/user/booking-history';
  static const String myTickets = '/user/ticket';
  static String ticketQrImage(dynamic ticketId) =>
      '/user/ticket/qr-image/$ticketId';
  static const String manageTickets = '/user/booking/ticket';
  static String scanTicket(dynamic bookingId, dynamic ticketId) =>
      '/user/booking/ticket/scan/$bookingId/$ticketId';
  static const String generateQr = '/user/qr-code';

  // ==================== 5. CONTENT & DISCOVERY ====================
  static const String homeLayout = '/home-page';
  static const String services = '/services';
  static const String gateways = '/gateways';
  static const String locations = '/locations';
  static String locationDetail(dynamic id) => '/location/$id';
  static const String news = '/news';
  static const String newsCategories = '/news/category';
  static String newsDetail(dynamic id) => '/news/$id';
  static const String countries = '/configs/countries';

  // ==================== 6. TOURS ====================
  static const String tourSearch = '/tour/search';
  static const String tourFilters = '/tour/filters';
  static const String tourFormSearch = '/tour/form-search';
  static String tourDetail(dynamic id) => '/tour/detail/$id';
  static String tourAvailability(dynamic id) => '/tour/availability/$id';
  static String tourWriteReview(dynamic id) => '/tour/write-review/$id';

  // ==================== 7. GUIDES ====================
  static const String guideSearch = '/guide/search';
  static const String guideFilters = '/guide/filters';
  static String guideDetail(dynamic id) => '/guide/detail/$id';

  // ==================== 8. CARS ====================
  static const String carSearch = '/car/search';
  static const String carFilters = '/car/filters';
  static const String carFormSearch = '/car/form-search';
  static String carDetail(dynamic id) => '/car/detail/$id';
  static String carAvailability(dynamic id) => '/car/availability/$id';
  static String carWriteReview(dynamic id) => '/car/write-review/$id';

  // ==================== 9. EVENTS ====================
  static const String eventSearch = '/event/search';
  static const String eventFilters = '/event/filters';
  static const String eventFormSearch = '/event/form-search';
  static String eventDetail(dynamic id) => '/event/detail/$id';
  static String eventAvailability(dynamic id) => '/event/availability/$id';
  static String eventWriteReview(dynamic id) => '/event/write-review/$id';

  // ==================== 10. MUSEUMS ====================
  static const String museumSearch = '/museum/search';
  static const String museumFilters = '/museum/filters';
  static const String museumFormSearch = '/museum/form-search';
  static String museumDetail(dynamic id) => '/museum/detail/$id';
  static String museumAvailability(dynamic id) => '/museum/availability/$id';
  static String museumWriteReview(dynamic id) => '/museum/write-review/$id';

  // ==================== 11. SHOP (BAZAAR) ====================
  static const String productSearch = '/product/search';
  static const String productFilters = '/product/filters';
  static String productDetail(dynamic id) => '/product/detail/$id';
  static String productWriteReview(dynamic id) => '/product/write-review/$id';

  // ==================== 12. BOOKING SERVICE ====================
  static const String configs = '/configs';
  static const String paymentGateways = '/gateways';
  static const String addToCartBooking = '/booking/addToCart';
  static const String addEnquiry = '/booking/addEnquiry';
  static const String doCheckout = '/booking/doCheckout';
  static String bookingDetail(String code) => '/booking/$code';
  static String checkBookingStatus(String code) =>
      '/booking/$code/check-status';

  // ==================== 13. CART & SHOP ORDERS ====================
  static const String cart = '/cart';
  static const String applyCoupon = '/cart/coupon/apply';
  static const String updateCartItem = '/cart/update';
  static const String removeCartItem = '/cart/remove';
  static const String cartCheckout = '/cart/checkout';
  static String orderDetail(String id) => '/cart-order/$id';
  static const String myOrders = '/my-orders';
}
