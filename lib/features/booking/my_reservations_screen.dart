import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import 'data/booking_repository.dart';

class MyReservationsScreen extends ConsumerStatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  ConsumerState<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends ConsumerState<MyReservationsScreen> {
  int _selectedTabIndex = 0; // 0: القادمة (Upcoming), 1: السابقة (Past)

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final bookingsAsync = ref.watch(bookingHistoryProvider(''));
    final ticketsAsync = ref.watch(myTicketsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryMauve,
          onRefresh: () async {
            ref.invalidate(bookingHistoryProvider(''));
            ref.invalidate(myTicketsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (رحلاتي + خطة رحلتك وتذاكرك وحجوزاتك)
                Text(
                  isAr ? 'رحلاتي' : 'My Trips',
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr ? 'خطة رحلتك وتذاكرك وحجوزاتك الحقيقية' : 'Your trip plan, tickets & reservations',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Segmented Tabs (القادمة / السابقة)
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1624) : const Color(0xFFEBE6EE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Upcoming Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? AppColors.primaryMauve : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isAr ? 'القادمة' : 'Upcoming',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedTabIndex == 0 ? Colors.white : textSub,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Past Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 ? AppColors.primaryMauve : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isAr ? 'السابقة' : 'Past',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedTabIndex == 1 ? Colors.white : textSub,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Tab Content
                bookingsAsync.when(
                  data: (allBookings) {
                    final tickets = ticketsAsync.asData?.value ?? [];

                    // Filter upcoming vs past gracefully without dropping any booking
                    final now = DateTime.now();
                    final upcomingBookings = <BookingItemModel>[];
                    final pastBookings = <BookingItemModel>[];

                    for (final b in allBookings) {
                      final s = b.status.toLowerCase().trim();
                      final isExplicitPast = s == 'completed' ||
                          s == 'complete' ||
                          s == 'cancelled' ||
                          s == 'rejected' ||
                          s == 'finished';
                      final isExplicitUpcoming = s == 'confirmed' ||
                          s == 'pending' ||
                          s == 'paid' ||
                          s == 'processing' ||
                          s == 'publish' ||
                          s == 'active' ||
                          s == 'unpaid';

                      DateTime? bookingDate;
                      try {
                        final dStr = b.startDate.length >= 10
                            ? b.startDate.substring(0, 10)
                            : b.startDate;
                        bookingDate = DateTime.tryParse(dStr);
                      } catch (_) {}

                      if (isExplicitPast) {
                        pastBookings.add(b);
                      } else if (isExplicitUpcoming) {
                        upcomingBookings.add(b);
                      } else if (bookingDate != null && bookingDate.isBefore(now)) {
                        pastBookings.add(b);
                      } else {
                        // Default to upcoming so user never loses sight of their booking
                        upcomingBookings.add(b);
                      }
                    }

                    if (_selectedTabIndex == 0) {
                      return _buildRealUpcomingView(
                        context,
                        isDark: isDark,
                        isAr: isAr,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSub: textSub,
                        bookings: upcomingBookings,
                        tickets: tickets,
                      );
                    } else {
                      return _buildRealPastView(
                        context,
                        isDark: isDark,
                        isAr: isAr,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSub: textSub,
                        bookings: pastBookings,
                      );
                    }
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryMauve),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'تعذر تحميل سجل رحلاتك' : 'Failed to load trip history',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(bookingHistoryProvider('')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMauve,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(isAr ? 'إعادة المحاولة' : 'Retry', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          ),
                        ],
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

  // --- Real Upcoming Trips View ---
  Widget _buildRealUpcomingView(
    BuildContext context, {
    required bool isDark,
    required bool isAr,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required List<BookingItemModel> bookings,
    required List<TicketModel> tickets,
  }) {
    if (bookings.isEmpty) {
      return _buildEmptyState(
        context,
        isDark: isDark,
        isAr: isAr,
        cardBg: cardBg,
        textPrimary: textPrimary,
        textSub: textSub,
        title: isAr ? 'لا توجد رحلات قادمة حتى الآن' : 'No upcoming trips yet',
        subtitle: isAr
            ? 'احجز مسارك السياحي أو تذكرتك القادمة وستظهر جميع رحلاتك وتذاكرك هنا مباشرة.'
            : 'Book your next trail or attraction ticket and your bookings will appear here.',
      );
    }

    // The most recent/upcoming booking becomes the featured hero trip banner!
    final primaryBooking = bookings.first;
    final otherBookings = bookings.length > 1 ? bookings.sublist(1) : <BookingItemModel>[];

    final heroImg = primaryBooking.image ??
        'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=1000&q=80';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Hero Featured Trip Card (Figma Style with real booking data)
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Hero Banner
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: heroImg,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 170,
                      color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 170,
                      color: isDark ? const Color(0xFF221A2A) : const Color(0xFFECE7EF),
                      child: const Center(
                        child: Icon(Icons.terrain_rounded, size: 48, color: Colors.white54),
                      ),
                    ),
                  ),
                  // Dark Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Gold Status Badge
                  Positioned(
                    top: 14,
                    left: isAr ? 14 : null,
                    right: isAr ? null : 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(primaryBooking.status, isAr),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1220),
                        ),
                      ),
                    ),
                  ),
                  // Trip Title and Dates
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryBooking.serviceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 5),
                            Text(
                              '${primaryBooking.startDate} · ${primaryBooking.totalGuests} ${isAr ? 'ضيوف' : 'guests'}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Activity Rows of the real bookings
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildRealBookingRow(
                      context,
                      booking: primaryBooking,
                      isDark: isDark,
                      isAr: isAr,
                      textPrimary: textPrimary,
                      textSub: textSub,
                    ),
                    if (otherBookings.isNotEmpty)
                      ...otherBookings.map((b) => Column(
                            children: [
                              Divider(height: 1, indent: 64, endIndent: 20, color: cardBorder),
                              _buildRealBookingRow(
                                context,
                                booking: b,
                                isDark: isDark,
                                isAr: isAr,
                                textPrimary: textPrimary,
                                textSub: textSub,
                              ),
                            ],
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // B. "تذاكري" (My Tickets) Section
        Text(
          isAr ? 'تذاكري' : 'My Tickets',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Display Real E-Tickets from ticketsAsync / bookings
        if (tickets.isNotEmpty)
          ...tickets.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRealETicketCard(
                  context,
                  ticket: t,
                  isDark: isDark,
                  isAr: isAr,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSub: textSub,
                ),
              ))
        else
          // If no separate tickets, convert the bookings into tickets
          ...bookings.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRealETicketFromBooking(
                  context,
                  booking: b,
                  isDark: isDark,
                  isAr: isAr,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSub: textSub,
                ),
              )),

        const SizedBox(height: 16),

        // C. "+ أضف نشاطاً إلى الرحلة" Outline Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.go('/discover'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? const Color(0xFF382942) : const Color(0xFFD6C8DD),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: cardBg.withValues(alpha: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20, color: textPrimary),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'أضف نشاطاً إلى الرحلة' : 'Add Activity to Trip',
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Real Past Trips View ---
  Widget _buildRealPastView(
    BuildContext context, {
    required bool isDark,
    required bool isAr,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSub,
    required List<BookingItemModel> bookings,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF231A2D) : const Color(0xFFF3EEF7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 36,
                  color: isDark ? const Color(0xFFC7B8D6) : AppColors.primaryMauve,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'لا توجد رحلات سابقة' : 'No past trips',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'ستظهر هنا كافة رحلاتك وجولاتك المكتملة بعد إتمامها.'
                    : 'Your completed journeys and experiences will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13, color: textSub),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: bookings.map((b) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 1.2),
          ),
          child: _buildRealBookingRow(
            context,
            booking: b,
            isDark: isDark,
            isAr: isAr,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
        );
      }).toList(),
    );
  }

  // Real Booking Row Widget
  Widget _buildRealBookingRow(
    BuildContext context, {
    required BookingItemModel booking,
    required bool isDark,
    required bool isAr,
    required Color textPrimary,
    required Color textSub,
  }) {
    final icon = _getServiceIcon(booking.serviceType);
    final typeLabel = _getServiceTypeLabel(booking.serviceType, isAr);

    return InkWell(
      onTap: () => _navigateToService(context, booking),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rounded Icon Box in Mauve tint
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF281F30) : const Color(0xFFF1ECF4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDark ? const Color(0xFFD2C5DF) : AppColors.primaryMauve,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeLabel · ${booking.startDate} · ${booking.total.toStringAsFixed(0)} ﷼',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: textSub,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Real E-Ticket Card from TicketModel
  Widget _buildRealETicketCard(
    BuildContext context, {
    required TicketModel ticket,
    required bool isDark,
    required bool isAr,
    required Color cardBg,
    required Color textPrimary,
    required Color textSub,
  }) {
    return GestureDetector(
      onTap: () => _showTicketDetailsDialog(
        context,
        title: ticket.title,
        code: ticket.ticketCode,
        date: ticket.date,
        guests: ticket.totalGuests,
        total: ticket.total,
        status: ticket.status,
        isAr: isAr,
        isDark: isDark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.65),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 1. QR Code Box
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1725) : const Color(0xFFF3EEF6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 58,
                  color: isDark ? Colors.white : AppColors.primaryMauve,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Vertical Dotted Separator
            CustomPaint(
              size: const Size(1, 78),
              painter: _DottedLinePainter(color: AppColors.accentGold.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 14),

            // 3. Ticket Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.accentGold),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? 'تذكرة دخول إلكترونية' : 'Digital E-Ticket',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ticket.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isAr ? 'ضيوف' : 'Guests'} × ${ticket.totalGuests} · ${ticket.total.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ticket.date.isNotEmpty ? ticket.date : (isAr ? 'حجز مؤكد' : 'Confirmed'),
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Real E-Ticket Card from BookingItemModel
  Widget _buildRealETicketFromBooking(
    BuildContext context, {
    required BookingItemModel booking,
    required bool isDark,
    required bool isAr,
    required Color cardBg,
    required Color textPrimary,
    required Color textSub,
  }) {
    return GestureDetector(
      onTap: () => _showTicketDetailsDialog(
        context,
        title: booking.serviceTitle,
        code: booking.code,
        date: booking.startDate,
        guests: booking.totalGuests,
        total: booking.total,
        status: booking.status,
        isAr: isAr,
        isDark: isDark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.65),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 1. QR Code Box
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1725) : const Color(0xFFF3EEF6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 58,
                  color: isDark ? Colors.white : AppColors.primaryMauve,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Vertical Dotted Separator
            CustomPaint(
              size: const Size(1, 78),
              painter: _DottedLinePainter(color: AppColors.accentGold.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 14),

            // 3. Ticket Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.accentGold),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? 'تذكرة دخول إلكترونية' : 'Digital E-Ticket',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    booking.serviceTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isAr ? 'ضيوف' : 'Guests'} × ${booking.totalGuests} · ${booking.total.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    booking.startDate.isNotEmpty ? booking.startDate : (isAr ? 'حجز مؤكد' : 'Confirmed'),
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive Ticket Details Modal Sheet
  void _showTicketDetailsDialog(
    BuildContext context, {
    required String title,
    required String code,
    required String date,
    required int guests,
    required double total,
    required String status,
    required bool isAr,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // QR Code Visual
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF221A2A) : const Color(0xFFF3EEF7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.qr_code_2_rounded, size: 85, color: textPrimary),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isAr ? 'رمز الحجز: ' : 'Booking Code: '}$code',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(color: cardBorder),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'التاريخ' : 'Date',
                        style: GoogleFonts.cairo(color: textSub, fontSize: 13)),
                    Text(
                      date.isNotEmpty ? date : '-',
                      style: GoogleFonts.cairo(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'عدد الضيوف' : 'Guests',
                        style: GoogleFonts.cairo(color: textSub, fontSize: 13)),
                    Text(
                      '$guests ${isAr ? 'أشخاص' : 'persons'}',
                      style: GoogleFonts.cairo(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'المبلغ الإجمالي' : 'Total Paid',
                        style: GoogleFonts.cairo(color: textSub, fontSize: 13)),
                    Text(
                      '${total.toStringAsFixed(0)} ﷼',
                      style: GoogleFonts.cairo(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMauve,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isAr ? 'إغلاق' : 'Close',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
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

  // Helper: Empty State Widget
  Widget _buildEmptyState(
    BuildContext context, {
    required bool isDark,
    required bool isAr,
    required Color cardBg,
    required Color textPrimary,
    required Color textSub,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231A2D) : const Color(0xFFF3EEF7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 40,
                color: isDark ? const Color(0xFFC7B8D6) : AppColors.primaryMauve,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: textSub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/discover'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMauve,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  isAr ? 'استكشف واحجز الآن' : 'Explore & Book Now',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'museum':
        return Icons.account_balance_rounded;
      case 'event':
        return Icons.festival_outlined;
      case 'guide':
        return Icons.person_pin_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'tour':
      default:
        return Icons.alt_route_rounded;
    }
  }

  String _getServiceTypeLabel(String type, bool isAr) {
    switch (type.toLowerCase()) {
      case 'museum':
        return isAr ? 'متحف ومعلم' : 'Museum';
      case 'event':
        return isAr ? 'فعالية وموسم' : 'Event';
      case 'guide':
        return isAr ? 'مرشد سياحي' : 'Guide';
      case 'car':
        return isAr ? 'سيارة وتنقل' : 'Car';
      case 'tour':
      default:
        return isAr ? 'مسار سياحي' : 'Tour Trail';
    }
  }

  String _getStatusLabel(String status, bool isAr) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return isAr ? 'مؤكدة' : 'Confirmed';
      case 'pending':
        return isAr ? 'قيد التأكيد' : 'Pending';
      case 'completed':
        return isAr ? 'مكتملة' : 'Completed';
      case 'cancelled':
        return isAr ? 'ملغاة' : 'Cancelled';
      default:
        return isAr ? 'مؤكدة' : 'Confirmed';
    }
  }

  void _navigateToService(BuildContext context, BookingItemModel booking) {
    switch (booking.serviceType.toLowerCase()) {
      case 'museum':
        context.push('/museum/${booking.id}');
        break;
      case 'event':
        context.push('/event/${booking.id}');
        break;
      case 'guide':
        context.push('/guide/${booking.id}');
        break;
      case 'car':
        context.push('/car/${booking.id}');
        break;
      case 'tour':
      default:
        context.push('/experience/${booking.id}');
        break;
    }
  }
}

// Custom Painter for Vertical Dotted Line
class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
