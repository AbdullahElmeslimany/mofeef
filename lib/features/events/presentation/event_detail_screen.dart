import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/image_viewer_dialog.dart';
import '../../booking/data/booking_draft.dart';
import '../../wishlist/data/wishlist_repository.dart';
import '../data/event_repository.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final dynamic eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  int _currentGalleryIndex = 0;

  Future<void> _openMap(EventItemModel event) async {
    final lat = event.mapLat ?? 24.7136;
    final lng = event.mapLng ?? 46.6753;
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    return Scaffold(
      body: eventAsync.when(
        data: (event) {
          final images =
              event.gallery.isNotEmpty ? event.gallery : [event.imageUrl];

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 340,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.55),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: Icon(
                              ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.eventId, 'event')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: ref
                                      .watch(wishlistProvider)
                                      .isFavorite(widget.eventId, 'event')
                                  ? AppColors.error
                                  : AppColors.primaryGold,
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(wishlistProvider.notifier)
                                  .toggleFavorite(
                                    WishlistItemModel(
                                      id: int.tryParse(
                                              widget.eventId.toString()) ??
                                          0,
                                      objectId: int.tryParse(
                                              widget.eventId.toString()) ??
                                          0,
                                      objectModel: 'event',
                                      title: event.title,
                                      imageUrl: event.imageUrl,
                                      price: event.priceNum,
                                      location: event.location,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(added
                                        ? (isAr
                                            ? 'تمت إضافة الفعالية إلى المفضلة ❤️'
                                            : 'Added event to favorites ❤️')
                                        : (isAr
                                            ? 'تمت إزالة الفعالية من المفضلة'
                                            : 'Removed from favorites')),
                                    backgroundColor: added
                                        ? AppColors.primaryGold
                                        : AppColors.card,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.55),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.white),
                            onPressed: () => ShareHelper.shareItem(
                              context: context,
                              title: event.title,
                              category:
                                  isAr ? 'فعالية وتجربة' : 'Event & Experience',
                              id: widget.eventId.toString(),
                              price: event.price,
                              location: event.location,
                              type: 'event',
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (idx) =>
                                setState(() => _currentGalleryIndex = idx),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => ImageViewerDialog.show(context,
                                    images: images, initialIndex: index),
                                child: CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surface,
                                    child: const Icon(Icons.festival_outlined,
                                        color: AppColors.primaryGold, size: 80),
                                  ),
                                ),
                              );
                            },
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                  AppColors.background.withOpacity(0.95),
                                  AppColors.background,
                                ],
                                stops: const [0.0, 0.4, 0.85, 1.0],
                              ),
                            ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: isAr ? 16 : null,
                              right: isAr ? null : 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  '📸 ${_currentGalleryIndex + 1} / ${images.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldGlow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primaryGold
                                          .withOpacity(0.4)),
                                ),
                                child: Text(
                                  isAr
                                      ? 'فعالية وموسم سعودي'
                                      : 'Saudi Event & Season',
                                  style: const TextStyle(
                                      color: AppColors.primaryGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: AppColors.primaryGold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr ? '4.9 (مميز)' : '4.9 (Featured)',
                                    style: AppTypography.titleSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(event.title, style: AppTypography.headingMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.primaryGold, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(event.location,
                                    style: AppTypography.bodyMedium),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfo(Icons.calendar_today,
                                    isAr ? 'التاريخ' : 'Date', event.date),
                                Container(
                                    width: 1,
                                    height: 30,
                                    color: AppColors.border),
                                _buildInfo(
                                    Icons.schedule,
                                    isAr ? 'المدة' : 'Duration',
                                    event.duration),
                                Container(
                                    width: 1,
                                    height: 30,
                                    color: AppColors.border),
                                _buildInfo(
                                    Icons.access_time,
                                    isAr ? 'وقت البدء' : 'Start Time',
                                    event.startTime ??
                                        (isAr ? '٥:٠٠ م' : '5:00 PM')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(isAr ? 'عن الفعالية' : 'About Event',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style:
                                AppTypography.bodyLarge.copyWith(height: 1.7),
                          ),
                          const SizedBox(height: 24),

                          // Ticket Types Available
                          if (event.ticketTypes.isNotEmpty) ...[
                            Text(
                                isAr
                                    ? 'فئات التذاكر المتاحة'
                                    : 'Available Ticket Categories',
                                style: AppTypography.titleLarge),
                            const SizedBox(height: 12),
                            ...event.ticketTypes.map((t) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons
                                                  .confirmation_number_outlined,
                                              color: AppColors.primaryGold,
                                              size: 20),
                                          const SizedBox(width: 10),
                                          Text(t.getDisplayName(isAr),
                                              style: AppTypography.titleSmall),
                                        ],
                                      ),
                                      Text('${t.price.toStringAsFixed(0)} ﷼',
                                          style: AppTypography.price
                                              .copyWith(fontSize: 15)),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 20),
                          ],

                          // Interactive Google Map Section
                          Text(
                              isAr
                                  ? 'الموقع الجغرافي والوصول'
                                  : 'Location & Directions',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _openMap(event),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color:
                                        AppColors.primaryGold.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldGlow,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.directions_outlined,
                                        color: AppColors.primaryGold, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.location,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isAr
                                              ? 'انقر لفتح الاتجاهات المباشرة عبر خرائط Google'
                                              : 'Tap to open directions in Google Maps',
                                          style: const TextStyle(
                                              color: AppColors.primaryGold,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new,
                                      color: AppColors.primaryGold, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border:
                        const Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                isAr
                                    ? 'يبدأ سعر التذكرة من'
                                    : 'Tickets start from',
                                style: AppTypography.bodySmall),
                            Text(event.price, style: AppTypography.price),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: CustomButton(
                            text: isAr
                                ? 'احجز تذكرتك وموعدك'
                                : 'Book Tickets & Date',
                            onPressed: () =>
                                _showEventBookingModal(context, event, isAr),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold)),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                    isAr
                        ? 'تعذر تحميل تفاصيل الفعالية'
                        : 'Failed to load event details',
                    style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(eventDetailProvider(widget.eventId)),
                  child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventBookingModal(
      BuildContext context, EventItemModel event, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _EventBookingBottomSheet(event: event, isAr: isAr),
    );
  }

  Widget _buildInfo(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20),
        const SizedBox(height: 4),
        Text(title, style: AppTypography.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleSmall.copyWith(fontSize: 12)),
      ],
    );
  }
}

class _EventBookingBottomSheet extends StatefulWidget {
  final EventItemModel event;
  final bool isAr;

  const _EventBookingBottomSheet({required this.event, required this.isAr});

  @override
  State<_EventBookingBottomSheet> createState() =>
      _EventBookingBottomSheetState();
}

class _EventBookingBottomSheetState extends State<_EventBookingBottomSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final Map<String, int> _ticketQuantities = {};
  final Set<String> _selectedExtras = {};

  @override
  void initState() {
    super.initState();
    if (widget.event.ticketTypes.isNotEmpty) {
      for (var t in widget.event.ticketTypes) {
        _ticketQuantities[t.name] =
            (t.name.toLowerCase().contains('standard') ||
                    t.name.toLowerCase().contains('regular') ||
                    t.nameAr?.contains('عادية') == true)
                ? 1
                : 0;
      }
      if (_ticketQuantities.values.every((v) => v == 0)) {
        _ticketQuantities[widget.event.ticketTypes.first.name] = 1;
      }
    } else {
      _ticketQuantities['default'] = 1;
    }
  }

  double _calculateTotal() {
    double total = 0;
    if (widget.event.ticketTypes.isNotEmpty) {
      for (var t in widget.event.ticketTypes) {
        final q = _ticketQuantities[t.name] ?? 0;
        total += (q * t.price);
      }
    } else {
      final unit = widget.event.priceNum;
      total += (unit * (_ticketQuantities['default'] ?? 1));
    }

    for (var extra in widget.event.extraPrices) {
      if (_selectedExtras.contains(extra.name)) {
        total += extra.price;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final total = _calculateTotal();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'خيارات وتذاكر الفعالية' : 'Event Booking Options',
                    style: AppTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.event.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.event.title,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(widget.event.location,
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 28),

            // Date Selector
            Text(isAr ? 'تاريخ الحضور' : 'Event Date',
                style: AppTypography.titleSmall),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryGold,
                          surface: AppColors.card,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                    Text(isAr ? 'تغيير التاريخ' : 'Change Date',
                        style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ticket Options
            Text(isAr ? 'خيارات وفئات التذاكر' : 'Ticket Categories',
                style: AppTypography.titleSmall),
            const SizedBox(height: 10),

            if (widget.event.ticketTypes.isNotEmpty)
              ...widget.event.ticketTypes.map((t) {
                final q = _ticketQuantities[t.name] ?? 0;
                final name = t.getDisplayName(isAr);
                final desc = t.getDisplayDesc(isAr);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: q > 0
                            ? AppColors.primaryGold.withOpacity(0.5)
                            : AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: AppTypography.titleSmall
                                    .copyWith(fontSize: 14)),
                            if (desc != null && desc.isNotEmpty)
                              Text(desc,
                                  style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            Text('${t.price.toStringAsFixed(0)} ﷼',
                                style:
                                    AppTypography.price.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.primaryGold, size: 22),
                            onPressed: q > 0
                                ? () => setState(
                                    () => _ticketQuantities[t.name] = q - 1)
                                : null,
                          ),
                          Text('$q', style: AppTypography.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.primaryGold, size: 22),
                            onPressed: q < t.max
                                ? () => setState(
                                    () => _ticketQuantities[t.name] = q + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'عدد التذاكر' : 'Tickets',
                        style: AppTypography.titleSmall),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.primaryGold),
                          onPressed: (_ticketQuantities['default'] ?? 1) > 1
                              ? () => setState(() =>
                                  _ticketQuantities['default'] =
                                      (_ticketQuantities['default'] ?? 1) - 1)
                              : null,
                        ),
                        Text('${_ticketQuantities['default'] ?? 1}',
                            style: AppTypography.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.primaryGold),
                          onPressed: () => setState(() =>
                              _ticketQuantities['default'] =
                                  (_ticketQuantities['default'] ?? 1) + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Extra Services
            if (widget.event.extraPrices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(isAr ? 'خدمات إضافية اختيارية' : 'Optional Extra Services',
                  style: AppTypography.titleSmall),
              const SizedBox(height: 10),
              ...widget.event.extraPrices.map((extra) {
                final isSelected = _selectedExtras.contains(extra.name);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CheckboxListTile(
                    activeColor: AppColors.primaryGold,
                    checkColor: AppColors.textDark,
                    title: Text(extra.getDisplayName(isAr),
                        style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    subtitle: Text('+ ${extra.price.toStringAsFixed(0)} ﷼',
                        style: AppTypography.price.copyWith(fontSize: 12)),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedExtras.add(extra.name);
                        } else {
                          _selectedExtras.remove(extra.name);
                        }
                      });
                    },
                  ),
                ),
              );
            }),
            ],

            const SizedBox(height: 24),

            // Total & Checkout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'المجموع الإجمالي' : 'Total Amount',
                        style: AppTypography.bodySmall),
                    Text('${total.toStringAsFixed(0)} ﷼',
                        style: AppTypography.price.copyWith(fontSize: 22)),
                  ],
                ),
                CustomButton(
                  text: isAr ? 'متابعة للدفع والتأكيد' : 'Proceed to Checkout',
                  width: 190,
                  onPressed: () {
                    final personItems = <BookingPersonItem>[];
                    if (widget.event.ticketTypes.isNotEmpty) {
                      for (var t in widget.event.ticketTypes) {
                        final q = _ticketQuantities[t.name] ?? 0;
                        if (q > 0) {
                          personItems.add(BookingPersonItem(
                            name: t.getDisplayName(isAr),
                            price: t.price,
                            quantity: q,
                          ));
                        }
                      }
                    } else {
                      personItems.add(BookingPersonItem(
                        name: isAr ? 'تذكرة فعالية' : 'Event Ticket',
                        price: widget.event.priceNum,
                        quantity: _ticketQuantities['default'] ?? 1,
                      ));
                    }

                    final extraItems = widget.event.extraPrices
                        .where((e) => _selectedExtras.contains(e.name))
                        .map((e) => BookingExtraItem(
                            name: e.getDisplayName(isAr), price: e.price))
                        .toList();

                    final draft = BookingDraft(
                      title: widget.event.title,
                      imageUrl: widget.event.imageUrl,
                      location: widget.event.location,
                      date: _selectedDate,
                      serviceType: 'event',
                      serviceId: int.tryParse(widget.event.id.toString()) ?? 1,
                      personItems: personItems,
                      extraItems: extraItems,
                      totalAmount: total,
                    );

                    Navigator.pop(context);
                    context.push('/checkout/${widget.event.id}', extra: draft);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
