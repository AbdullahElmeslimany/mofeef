import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/unified_item_card.dart';
import '../tours/data/repositories/tour_repository.dart';
import '../museums/data/museum_repository.dart';
import '../events/data/event_repository.dart';
import '../guides/data/guide_repository.dart';
import '../cars/data/car_repository.dart';
import '../shop/data/shop_repository.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0; // 0: الكل, 1: المتاحف, 2: التجارب, 3: الفعاليات, 4: المرشدون, 5: السيارات, 6: المتجر
  String _selectedSort = 'rating'; // 'rating', 'price_low', 'price_high', 'newest'

  // Global / General Filters
  String _selectedCity = 'الكل';
  RangeValues _globalPriceRange = const RangeValues(0, 3000);
  double _minRating = 0.0;

  // 1. Museums Specific Filters
  String _museumEntryType = 'الكل'; // 'الكل', 'دخول مجاني فقط', 'تذاكر مدفوعة'
  RangeValues _museumPriceRange = const RangeValues(0, 500);

  // 2. Tours Specific Filters
  String _tourCategoryFilter = 'الكل';
  String _tourThemeFilter = 'الكل';
  RangeValues _tourPriceRange = const RangeValues(50, 1500);

  // 3. Events Specific Filters
  String _eventTypeFilter = 'الكل';
  String _eventEntryType = 'الكل';
  RangeValues _eventPriceRange = const RangeValues(0, 2000);

  // 4. Guides Specific Filters
  bool _guideOnlyAvailable = false;
  bool _guideFreeConsultation = false;
  String _guideTourType = 'الكل';
  String _guideLanguageFilter = 'الكل';
  RangeValues _guideHourlyRange = const RangeValues(0, 1000);

  // 5. Cars Specific Filters
  String _carCategoryFilter = 'الكل';
  String _carPassengerFilter = 'الكل';
  String _carTransmissionFilter = 'الكل';
  RangeValues _carPriceRange = const RangeValues(100, 2500);

  // 6. Shop Specific Filters
  String _productCategoryFilter = 'الكل';
  bool _productOnlyInStock = false;
  bool _productOnlyOnSale = false;
  RangeValues _productPriceRange = const RangeValues(0, 1500);

  // Categories exactly as designed in Figma 03 · استكشف
  final List<String> _categoriesAr = [
    'الكل',
    'المتاحف',
    'التجارب',
    'الفعاليات',
    'المرشدون',
    'السيارات',
    'المتجر',
  ];

  final List<String> _categoriesEn = [
    'All',
    'Museums',
    'Experiences',
    'Events',
    'Guides',
    'Cars',
    'Shop',
  ];

  final List<String> _citiesAr = [
    'الكل',
    'الرياض',
    'جدة',
    'مكة المكرمة',
    'المدينة المنورة',
    'العُلا',
    'الدرعية',
    'عسير',
    'أبها',
    'الدمام',
  ];

  final List<String> _citiesEn = [
    'All',
    'Riyadh',
    'Jeddah',
    'Makkah',
    'Madinah',
    'AlUla',
    'Diriyah',
    'Asir',
    'Abha',
    'Dammam',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCity = 'الكل';
      _globalPriceRange = const RangeValues(0, 3000);
      _minRating = 0.0;
      _museumEntryType = 'الكل';
      _museumPriceRange = const RangeValues(0, 500);
      _tourCategoryFilter = 'الكل';
      _tourThemeFilter = 'الكل';
      _tourPriceRange = const RangeValues(50, 1500);
      _eventTypeFilter = 'الكل';
      _eventEntryType = 'الكل';
      _eventPriceRange = const RangeValues(0, 2000);
      _guideOnlyAvailable = false;
      _guideFreeConsultation = false;
      _guideTourType = 'الكل';
      _guideLanguageFilter = 'الكل';
      _guideHourlyRange = const RangeValues(0, 1000);
      _carCategoryFilter = 'الكل';
      _carPassengerFilter = 'الكل';
      _carTransmissionFilter = 'الكل';
      _carPriceRange = const RangeValues(100, 2500);
      _productCategoryFilter = 'الكل';
      _productOnlyInStock = false;
      _productOnlyOnSale = false;
      _productPriceRange = const RangeValues(0, 1500);
    });
  }

  bool _isAnyFilterActive() {
    if (_selectedCity != 'الكل') return true;
    if (_minRating > 0.0) return true;
    if (_selectedCategoryIndex == 1 && (_museumEntryType != 'الكل' || _museumPriceRange.end < 500)) return true;
    if (_selectedCategoryIndex == 2 && (_tourCategoryFilter != 'الكل' || _tourThemeFilter != 'الكل' || _tourPriceRange.end < 1500)) return true;
    if (_selectedCategoryIndex == 3 && (_eventTypeFilter != 'الكل' || _eventEntryType != 'الكل' || _eventPriceRange.end < 2000)) return true;
    if (_selectedCategoryIndex == 4 && (_guideOnlyAvailable || _guideFreeConsultation || _guideTourType != 'الكل' || _guideLanguageFilter != 'الكل' || _guideHourlyRange.end < 1000)) return true;
    if (_selectedCategoryIndex == 5 && (_carCategoryFilter != 'الكل' || _carPassengerFilter != 'الكل' || _carTransmissionFilter != 'الكل' || _carPriceRange.end < 2500)) return true;
    if (_selectedCategoryIndex == 6 && (_productCategoryFilter != 'الكل' || _productOnlyInStock || _productOnlyOnSale || _productPriceRange.end < 1500)) return true;
    return false;
  }

  void _showSortModal(bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final sortOptions = [
      {'key': 'rating', 'label': isAr ? 'الأعلى تقييماً' : 'Highest Rated'},
      {'key': 'price_low', 'label': isAr ? 'الأقل سعراً' : 'Price: Low to High'},
      {'key': 'price_high', 'label': isAr ? 'الأعلى سعراً' : 'Price: High to Low'},
      {'key': 'newest', 'label': isAr ? 'الأحدث' : 'Newest'},
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'ترتيب النتائج حسب' : 'Sort Results By',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...sortOptions.map((opt) {
                  final isSelected = _selectedSort == opt['key'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opt['label']!,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primaryMauve : textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryMauve, size: 20)
                        : null,
                    onTap: () {
                      setState(() => _selectedSort = opt['key']!);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final categories = isAr ? _categoriesAr : _categoriesEn;
          final cities = isAr ? _citiesAr : _citiesEn;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.primaryMauve, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isAr
                              ? 'فلاتر ${categories[_selectedCategoryIndex]}'
                              : 'Filter ${categories[_selectedCategoryIndex]}',
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _resetAllFilters();
                        setModalState(() {});
                      },
                      child: Text(
                        isAr ? 'إعادة ضبط' : 'Reset',
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryMauve,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // City filter
                      _buildCityFilter(setModalState, isAr, cities, isDark),
                      const SizedBox(height: 18),

                      // Category-specific filters
                      if (_selectedCategoryIndex == 1)
                        _buildMuseumFilters(setModalState, isAr, isDark)
                      else if (_selectedCategoryIndex == 2)
                        _buildTourFilters(setModalState, isAr, isDark)
                      else if (_selectedCategoryIndex == 3)
                        _buildEventFilters(setModalState, isAr, isDark)
                      else if (_selectedCategoryIndex == 4)
                        _buildGuideFilters(setModalState, isAr, isDark)
                      else if (_selectedCategoryIndex == 5)
                        _buildCarFilters(setModalState, isAr, isDark)
                      else if (_selectedCategoryIndex == 6)
                        _buildShopFilters(setModalState, isAr, isDark)
                      else
                        _buildGlobalPriceFilter(setModalState, isAr, isDark),

                      const SizedBox(height: 18),
                      _buildRatingFilter(setModalState, isAr, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMauve,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isAr ? 'تطبيق الفلاتر' : 'Apply Filters',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Filter Helper Widgets ---
  Widget _buildCityFilter(StateSetter setModalState, bool isAr, List<String> cities, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final unselectedBg = isDark ? const Color(0xFF1E1624) : const Color(0xFFF1EDF3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الوجهة / المدينة' : 'City / Destination',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cities.map((city) {
            final isSel = _selectedCity == city;
            return ChoiceChip(
              label: Text(city),
              selected: isSel,
              onSelected: (_) => setModalState(() => _selectedCity = city),
              selectedColor: AppColors.primaryMauve,
              backgroundColor: unselectedBg,
              labelStyle: GoogleFonts.cairo(
                color: isSel ? Colors.white : textSub,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGlobalPriceFilter(StateSetter setModalState, bool isAr, bool isDark) {
    return _buildPriceRangeWidget(
      title: isAr ? 'نطاق السعر (﷼)' : 'Price Range (SAR)',
      values: _globalPriceRange,
      max: 3000,
      divisions: 30,
      onChanged: (val) => setModalState(() => _globalPriceRange = val),
      isDark: isDark,
    );
  }

  Widget _buildMuseumFilters(StateSetter setModalState, bool isAr, bool isDark) {
    final entryTypes = isAr ? ['الكل', 'دخول مجاني فقط', 'تذاكر مدفوعة'] : ['All', 'Free Only', 'Paid'];
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final unselectedBg = isDark ? const Color(0xFF1E1624) : const Color(0xFFF1EDF3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'نوع تذكرة المتحف' : 'Museum Entry Type',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: entryTypes.map((t) {
            final isSel = _museumEntryType == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSel,
              onSelected: (_) => setModalState(() => _museumEntryType = t),
              selectedColor: AppColors.primaryMauve,
              backgroundColor: unselectedBg,
              labelStyle: GoogleFonts.cairo(
                color: isSel ? Colors.white : textSub,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildPriceRangeWidget(
          title: isAr ? 'سعر التذكرة (﷼)' : 'Ticket Price (SAR)',
          values: _museumPriceRange,
          max: 500,
          divisions: 10,
          onChanged: (val) => setModalState(() => _museumPriceRange = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTourFilters(StateSetter setModalState, bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRangeWidget(
          title: isAr ? 'سعر التجربة (﷼)' : 'Experience Price (SAR)',
          values: _tourPriceRange,
          max: 1500,
          divisions: 15,
          onChanged: (val) => setModalState(() => _tourPriceRange = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildEventFilters(StateSetter setModalState, bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRangeWidget(
          title: isAr ? 'سعر تذكرة الفعالية (﷼)' : 'Event Ticket (SAR)',
          values: _eventPriceRange,
          max: 2000,
          divisions: 20,
          onChanged: (val) => setModalState(() => _eventPriceRange = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildGuideFilters(StateSetter setModalState, bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRangeWidget(
          title: isAr ? 'سعر الساعة للإرشاد (﷼)' : 'Hourly Rate (SAR)',
          values: _guideHourlyRange,
          max: 1000,
          divisions: 20,
          onChanged: (val) => setModalState(() => _guideHourlyRange = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCarFilters(StateSetter setModalState, bool isAr, bool isDark) {
    final categories = isAr ? ['الكل', 'فاخرة', 'دفع رباعي SUV', 'سيدان', 'عائلية VIP'] : ['All', 'Luxury', 'SUV 4x4', 'Sedan', 'VIP Family'];
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final unselectedBg = isDark ? const Color(0xFF1E1624) : const Color(0xFFF1EDF3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'فئة السيارة' : 'Car Category',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSel = _carCategoryFilter == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSel,
              onSelected: (_) => setModalState(() => _carCategoryFilter = cat),
              selectedColor: AppColors.primaryMauve,
              backgroundColor: unselectedBg,
              labelStyle: GoogleFonts.cairo(
                color: isSel ? Colors.white : textSub,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildPriceRangeWidget(
          title: isAr ? 'السعر اليومي (﷼)' : 'Daily Rate (SAR)',
          values: _carPriceRange,
          max: 2500,
          divisions: 25,
          onChanged: (val) => setModalState(() => _carPriceRange = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildShopFilters(StateSetter setModalState, bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRangeWidget(
          title: isAr ? 'سعر المنتج (﷼)' : 'Product Price (SAR)',
          values: _productPriceRange,
          max: 1500,
          divisions: 15,
          onChanged: (val) => setModalState(() => _productPriceRange = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildRatingFilter(StateSetter setModalState, bool isAr, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final unselectedBg = isDark ? const Color(0xFF1E1624) : const Color(0xFFF1EDF3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الحد الأدنى للتقييم' : 'Minimum Rating',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0.0, 3.0, 4.0, 4.5, 4.8].map((r) {
            final isSel = _minRating == r;
            return GestureDetector(
              onTap: () => setModalState(() => _minRating = r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primaryMauve : unselectedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? AppColors.primaryMauve : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: isSel ? Colors.white : AppColors.accentGold),
                    const SizedBox(width: 4),
                    Text(
                      r == 0.0 ? (isAr ? 'الكل' : 'All') : '$r+',
                      style: GoogleFonts.cairo(
                        color: isSel ? Colors.white : textSub,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeWidget({
    required String title,
    required RangeValues values,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
    required bool isDark,
  }) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Text(
              '${values.start.round()} — ${values.end.round()} ﷼',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: 0,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primaryMauve,
          inactiveColor: isDark ? const Color(0xFF2A2132) : const Color(0xFFDDD7E3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final categories = isAr ? _categoriesAr : _categoriesEn;
    final search = _searchController.text.trim();
    final isFilterActive = _isAnyFilterActive();

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (استكشف + متاحف وتجارب وفعاليات في مكان واحد)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'استكشف' : 'Explore',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAr
                        ? 'متاحف وتجارب وفعاليات في مكان واحد'
                        : 'Museums, experiences & events in one place',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search & Filter Bar (Matching Figma 03 · استكشف)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Filter Button (on leading edge in RTL/LTR)
                  GestureDetector(
                    onTap: () => _showFilterSheet(isAr),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFilterActive ? AppColors.accentGold : cardBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: isFilterActive ? AppColors.accentGold : textPrimary,
                            size: 22,
                          ),
                        ),
                        if (isFilterActive)
                          Positioned(
                            top: -2,
                            right: isAr ? null : -2,
                            left: isAr ? -2 : null,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.accentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Search Text Input
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'ابحث عن متحف أو تجربة أو منتج'
                              : 'Search museum, experience, product...',
                          hintStyle: GoogleFonts.cairo(
                            fontSize: 13,
                            color: textSub,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: textSub,
                            size: 21,
                          ),
                          prefixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  child: Icon(Icons.close_rounded, size: 18, color: textSub),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Category Horizontal Pills (Figma exact styling)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryIndex == index;

                  final pillBg = isSelected
                      ? AppColors.primaryMauve
                      : (isDark ? const Color(0xFF1E1624) : const Color(0xFFEBE6EE));
                  final pillText = isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFA59BAE) : const Color(0xFF6B6274));

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: GoogleFonts.cairo(
                          color: pillText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 4. Content Area with Header Counter & Sort
            Expanded(
              child: _buildCategoryContent(isAr, search, isDark, textPrimary, textSub),
            ),
          ],
        ),
      ),
    );
  }

  // --- Category Switcher ---
  Widget _buildCategoryContent(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    switch (_selectedCategoryIndex) {
      case 1: // المتاحف (Museums)
        return _buildMuseumsList(isAr, search, isDark, textPrimary, textSub);
      case 2: // التجارب (Experiences / Trails)
        return _buildToursList(isAr, search, isDark, textPrimary, textSub);
      case 3: // الفعاليات (Events)
        return _buildEventsList(isAr, search, isDark, textPrimary, textSub);
      case 4: // المرشدون (Guides)
        return _buildGuidesList(isAr, search, isDark, textPrimary, textSub);
      case 5: // السيارات (Cars)
        return _buildCarsList(isAr, search, isDark, textPrimary, textSub);
      case 6: // المتجر (Shop)
        return _buildProductsList(isAr, search, isDark, textPrimary, textSub);
      case 0: // الكل (All Combined)
      default:
        return _buildAllCombinedList(isAr, search, isDark, textPrimary, textSub);
    }
  }

  // --- Sub-Header: Count + Sort Option ---
  Widget _buildListHeaderRow({
    required int count,
    required String labelPlural,
    required bool isAr,
    required Color textPrimary,
    required Color textSub,
  }) {
    final sortLabel = _getSortLabel(isAr);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Count e.g. "6 متاحف"
          Text(
            isAr ? '$count $labelPlural' : '$count $labelPlural',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),

          // Sort action: "الأعلى تقييماً <"
          GestureDetector(
            onTap: () => _showSortModal(isAr),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sortLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textSub,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: textSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(bool isAr) {
    switch (_selectedSort) {
      case 'price_low':
        return isAr ? 'الأقل سعراً' : 'Price: Low';
      case 'price_high':
        return isAr ? 'الأعلى سعراً' : 'Price: High';
      case 'newest':
        return isAr ? 'الأحدث' : 'Newest';
      case 'rating':
      default:
        return isAr ? 'الأعلى تقييماً' : 'Top Rated';
    }
  }

  // --- 1. Museums List (Figma 03 Primary View) ---
  Widget _buildMuseumsList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final museumsAsync = ref.watch(museumsListProvider);

    // Fallback items exactly as represented in Figma 03 · استكشف
    final figmaMuseums = [
      {
        'id': '1',
        'title': isAr ? 'المتحف الوطني السعودي' : 'Saudi National Museum',
        'location': isAr ? 'الرياض' : 'Riyadh',
        'desc': isAr ? '8 قاعات عرض تاريخية وإسلامية' : '8 historical & Islamic exhibition halls',
        'rating': 4.9,
        'price': isAr ? 'من 10 ر.س' : 'From 10 SAR',
        'image': 'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
      },
      {
        'id': '2',
        'title': isAr ? 'متحف قصر المصمك' : 'Al Masmak Fortress',
        'location': isAr ? 'الرياض' : 'Riyadh',
        'desc': isAr ? 'ملحمة توحيد المملكة' : 'Epic of Saudi unification',
        'rating': 4.8,
        'price': isAr ? 'مجاني' : 'Free',
        'image': 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
      },
      {
        'id': '3',
        'title': isAr ? 'متحف قصر خزام' : 'Khuzam Palace Museum',
        'location': isAr ? 'جدة' : 'Jeddah',
        'desc': isAr ? 'بوابة تاريخ جدة الحديث' : 'Gateway to modern Jeddah history',
        'rating': 4.7,
        'price': isAr ? '15 ر.س' : '15 SAR',
        'image': 'https://images.unsplash.com/photo-1565552684305-7e861397b24f?w=800&q=80',
      },
      {
        'id': '4',
        'title': isAr ? 'متحف دار الفنون الإسلامية' : 'Islamic Arts Museum',
        'location': isAr ? 'جدة' : 'Jeddah',
        'desc': isAr ? 'أكثر من 1000 قطعة أثرية نادرة' : 'Over 1,000 rare antique artifacts',
        'rating': 4.9,
        'price': isAr ? '35 ر.س' : '35 SAR',
        'image': 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800&q=80',
      },
      {
        'id': '5',
        'title': isAr ? 'متحف العلا بين الجبال' : 'AlUla Museum in the Mountains',
        'location': isAr ? 'العلا' : 'AlUla',
        'desc': isAr ? 'آثار دادان والحجر ومملكة لحيان' : 'Dadan, Hegra and Lihyanite kingdom relics',
        'rating': 4.9,
        'price': isAr ? '75 ر.س' : '75 SAR',
        'image': 'https://images.unsplash.com/photo-1578895101408-1a36b834405b?w=800&q=80',
      },
      {
        'id': '6',
        'title': isAr ? 'متحف رجال ألمع التراثي' : 'Rijal Almaa Heritage Village',
        'location': isAr ? 'عسير' : 'Asir',
        'desc': isAr ? 'عمارة حجرية وفن القط العسيري' : 'Stone architecture & Al-Qatt art',
        'rating': 4.8,
        'price': isAr ? '20 ر.س' : '20 SAR',
        'image': 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=800&q=80',
      },
    ];

    return museumsAsync.when(
      data: (museums) {
        var items = museums.where((m) {
          if (search.isNotEmpty && !m.title.toLowerCase().contains(search.toLowerCase())) return false;
          if (m.price < _museumPriceRange.start || m.price > _museumPriceRange.end) return false;
          if (_selectedCity != 'الكل' && _selectedCity != 'All') {
            if (m.locationName != null && !m.locationName!.contains(_selectedCity)) return false;
          }
          if (_museumEntryType.contains('مجاني') && m.price > 0) return false;
          if (_museumEntryType.contains('مدفوع') && m.price == 0) return false;
          if (m.rating < _minRating) return false;
          return true;
        }).toList();

        // Apply sorting
        if (_selectedSort == 'price_low') {
          items.sort((a, b) => a.price.compareTo(b.price));
        } else if (_selectedSort == 'price_high') {
          items.sort((a, b) => b.price.compareTo(a.price));
        } else if (_selectedSort == 'rating') {
          items.sort((a, b) => b.rating.compareTo(a.rating));
        }

        // Use fallback if API returns empty list or offline
        if (items.isEmpty && search.isEmpty && !_isAnyFilterActive()) {
          return Column(
            children: [
              _buildListHeaderRow(
                count: figmaMuseums.length,
                labelPlural: isAr ? 'متاحف' : 'Museums',
                isAr: isAr,
                textPrimary: textPrimary,
                textSub: textSub,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: figmaMuseums.length,
                  itemBuilder: (context, index) {
                    final item = figmaMuseums[index];
                    return UnifiedItemCard(
                      title: item['title'] as String,
                      imageUrl: item['image'] as String,
                      locationName: item['location'] as String,
                      rating: item['rating'] as double,
                      subtitle: item['desc'] as String,
                      price: item['price'] as String,
                      onTap: () => context.push('/museum/${item['id']}'),
                    );
                  },
                ),
              ),
            ],
          );
        }

        if (items.isEmpty) return _buildEmptyState(isAr);

        return Column(
          children: [
            _buildListHeaderRow(
              count: items.length,
              labelPlural: isAr ? 'متاحف' : 'Museums',
              isAr: isAr,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final museum = items[index];
                  final priceLabel = museum.price <= 0
                      ? (isAr ? 'مجاني' : 'Free')
                      : '${museum.price.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}';

                  return UnifiedItemCard(
                    title: museum.title,
                    imageUrl: museum.imageUrl,
                    locationName: museum.locationName ?? (isAr ? 'المملكة' : 'KSA'),
                    rating: museum.rating,
                    subtitle: museum.workingHours ?? (isAr ? 'متحف ومعلم ثقافي' : 'Cultural Landmark'),
                    price: priceLabel,
                    onTap: () => context.push('/museum/${museum.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMauve),
      ),
      error: (_, __) => Column(
        children: [
          _buildListHeaderRow(
            count: figmaMuseums.length,
            labelPlural: isAr ? 'متاحف' : 'Museums',
            isAr: isAr,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: figmaMuseums.length,
              itemBuilder: (context, index) {
                final item = figmaMuseums[index];
                return UnifiedItemCard(
                  title: item['title'] as String,
                  imageUrl: item['image'] as String,
                  locationName: item['location'] as String,
                  rating: item['rating'] as double,
                  subtitle: item['desc'] as String,
                  price: item['price'] as String,
                  onTap: () => context.push('/museum/${item['id']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Experiences / Tours List ---
  Widget _buildToursList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final toursAsync = ref.watch(toursListProvider(search.isEmpty ? null : search));

    return toursAsync.when(
      data: (tours) {
        var filtered = tours.where((t) {
          final price = t.salePrice ?? t.price;
          if (price < _tourPriceRange.start || price > _tourPriceRange.end) return false;
          if (t.rating < _minRating) return false;
          if (_selectedCity != 'الكل' && _selectedCity != 'All') {
            if (t.locationName != null && !t.locationName!.contains(_selectedCity)) return false;
          }
          return true;
        }).toList();

        if (_selectedSort == 'price_low') {
          filtered.sort((a, b) => (a.salePrice ?? a.price).compareTo(b.salePrice ?? b.price));
        } else if (_selectedSort == 'price_high') {
          filtered.sort((a, b) => (b.salePrice ?? b.price).compareTo(a.salePrice ?? a.price));
        } else if (_selectedSort == 'rating') {
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
        }

        if (filtered.isEmpty) return _buildEmptyState(isAr);

        return Column(
          children: [
            _buildListHeaderRow(
              count: filtered.length,
              labelPlural: isAr ? 'تجارب' : 'Experiences',
              isAr: isAr,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final tour = filtered[index];
                  return UnifiedItemCard(
                    title: tour.title,
                    imageUrl: tour.imageUrl,
                    locationName: tour.locationName ?? (isAr ? 'المملكة' : 'KSA'),
                    rating: tour.rating,
                    subtitle: tour.duration ?? (isAr ? 'جولة مميزة' : 'Featured Tour'),
                    price: tour.formattedPrice,
                    onTap: () => context.push('/experience/${tour.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMauve),
      ),
      error: (_, __) => _buildErrorState(isAr, () => ref.refresh(toursListProvider(search.isEmpty ? null : search))),
    );
  }

  // --- 3. Events List ---
  Widget _buildEventsList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final eventsAsync = ref.watch(eventsListProvider);

    return eventsAsync.when(
      data: (events) {
        var filtered = events.where((e) {
          if (search.isNotEmpty && !e.title.toLowerCase().contains(search.toLowerCase())) return false;
          if (e.priceNum < _eventPriceRange.start || e.priceNum > _eventPriceRange.end) return false;
          if (_selectedCity != 'الكل' && _selectedCity != 'All') {
            if (!e.location.contains(_selectedCity)) return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState(isAr);

        return Column(
          children: [
            _buildListHeaderRow(
              count: filtered.length,
              labelPlural: isAr ? 'فعاليات' : 'Events',
              isAr: isAr,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final event = filtered[index];
                  return UnifiedItemCard(
                    title: event.title,
                    imageUrl: event.imageUrl,
                    locationName: event.location,
                    rating: 4.8,
                    subtitle: event.duration,
                    price: event.price,
                    onTap: () => context.push('/event/${event.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMauve),
      ),
      error: (_, __) => _buildErrorState(isAr, () => ref.refresh(eventsListProvider)),
    );
  }

  // --- 4. Guides List ---
  Widget _buildGuidesList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final guidesAsync = ref.watch(guidesListProvider);

    return guidesAsync.when(
      data: (guides) {
        var filtered = guides.where((g) {
          if (search.isNotEmpty && !g.name.toLowerCase().contains(search.toLowerCase())) return false;
          if (g.rating < _minRating) return false;
          return true;
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState(isAr);

        return Column(
          children: [
            _buildListHeaderRow(
              count: filtered.length,
              labelPlural: isAr ? 'مرشدين' : 'Guides',
              isAr: isAr,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final guide = filtered[index];
                  return UnifiedItemCard(
                    title: guide.name,
                    imageUrl: guide.imageUrl,
                    locationName: guide.title,
                    rating: guide.rating,
                    subtitle: guide.languages.join(' • '),
                    price: guide.hourlyRate,
                    onTap: () => context.push('/guide/${guide.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMauve),
      ),
      error: (_, __) => _buildErrorState(isAr, () => ref.refresh(guidesListProvider)),
    );
  }

  // --- 5. Cars List ---
  Widget _buildCarsList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final carsAsync = ref.watch(carsListProvider);

    return carsAsync.when(
      data: (cars) {
        var filtered = cars.where((c) {
          if (search.isNotEmpty && !c.title.toLowerCase().contains(search.toLowerCase())) return false;
          if (c.price < _carPriceRange.start || c.price > _carPriceRange.end) return false;
          return true;
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState(isAr);

        return Column(
          children: [
            _buildListHeaderRow(
              count: filtered.length,
              labelPlural: isAr ? 'سيارات' : 'Cars',
              isAr: isAr,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final car = filtered[index];
                  return UnifiedItemCard(
                    title: car.title,
                    imageUrl: car.imageUrl,
                    locationName: car.locationName ?? (isAr ? 'الرياض' : 'Riyadh'),
                    rating: car.rating,
                    subtitle: '${car.passengerCount} ${isAr ? 'ركاب' : 'passengers'} • ${car.transmission}',
                    price: car.pricePerDay,
                    onTap: () => context.push('/car/${car.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMauve),
      ),
      error: (_, __) => _buildErrorState(isAr, () => ref.refresh(carsListProvider)),
    );
  }

  // --- 6. Shop Products List ---
  Widget _buildProductsList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final productsAsync = ref.watch(productsListProvider);

    return productsAsync.when(
      data: (products) {
        var list = products.where((p) {
          if (search.isNotEmpty && !p.title.toLowerCase().contains(search.toLowerCase())) return false;
          if (p.priceNumeric < _productPriceRange.start || p.priceNumeric > _productPriceRange.end) return false;
          if (_productOnlyInStock && !p.inStock) return false;
          if (_productOnlyOnSale && (p.discountPercent == null || p.discountPercent!.isEmpty)) return false;
          return true;
        }).toList();

        if (list.isEmpty) return _buildEmptyState(isAr);

        return Column(
          children: [
            _buildListHeaderRow(
              count: list.length,
              labelPlural: isAr ? 'منتجات' : 'Products',
              isAr: isAr,
              textPrimary: textPrimary,
              textSub: textSub,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final product = list[index];
                  return UnifiedItemCard(
                    title: product.title,
                    imageUrl: product.imageUrl,
                    locationName: product.category,
                    rating: product.rating,
                    subtitle: product.discountPercent != null && product.discountPercent!.isNotEmpty
                        ? 'خصم ${product.discountPercent}'
                        : (isAr ? 'أصلي 100%' : 'Original'),
                    price: product.price,
                    onTap: () => context.push('/product/${product.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMauve),
      ),
      error: (_, __) => _buildErrorState(isAr, () => ref.refresh(productsListProvider)),
    );
  }

  // --- 0. Combined All Content ---
  Widget _buildAllCombinedList(
    bool isAr,
    String search,
    bool isDark,
    Color textPrimary,
    Color textSub,
  ) {
    final toursAsync = ref.watch(toursListProvider(search.isEmpty ? null : search));
    final museumsAsync = ref.watch(museumsListProvider);
    final eventsAsync = ref.watch(eventsListProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
      children: [
        // Section 1: Featured Museums
        _buildSectionHeader(
          title: isAr ? 'أبرز المتاحف والمعالم' : 'Featured Museums',
          onTapMore: () => setState(() => _selectedCategoryIndex = 1),
          isAr: isAr,
          textPrimary: textPrimary,
        ),
        museumsAsync.when(
          data: (museums) {
            final list = museums.take(3).toList();
            return Column(
              children: list.map((m) {
                final priceStr = m.price <= 0
                    ? (isAr ? 'مجاني' : 'Free')
                    : '${m.price.toStringAsFixed(0)} ${isAr ? 'ر.س' : 'SAR'}';

                return UnifiedItemCard(
                  title: m.title,
                  imageUrl: m.imageUrl,
                  locationName: m.locationName ?? (isAr ? 'المملكة' : 'KSA'),
                  rating: m.rating,
                  subtitle: m.workingHours ?? (isAr ? 'متحف ومعلم ثقافي' : 'Cultural Landmark'),
                  price: priceStr,
                  onTap: () => context.push('/museum/${m.id}'),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        // Section 2: Experiences
        _buildSectionHeader(
          title: isAr ? 'أبرز التجارب والمسارات' : 'Top Experiences & Trails',
          onTapMore: () => setState(() => _selectedCategoryIndex = 2),
          isAr: isAr,
          textPrimary: textPrimary,
        ),
        toursAsync.when(
          data: (tours) {
            final list = tours.take(3).toList();
            return Column(
              children: list.map((tour) {
                return UnifiedItemCard(
                  title: tour.title,
                  imageUrl: tour.imageUrl,
                  locationName: tour.locationName ?? (isAr ? 'المملكة' : 'KSA'),
                  rating: tour.rating,
                  subtitle: tour.duration ?? (isAr ? 'جولة سياحية' : 'Tour'),
                  price: tour.formattedPrice,
                  onTap: () => context.push('/experience/${tour.id}'),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        // Section 3: Events
        _buildSectionHeader(
          title: isAr ? 'الفعاليات والمواسم' : 'Events & Seasons',
          onTapMore: () => setState(() => _selectedCategoryIndex = 3),
          isAr: isAr,
          textPrimary: textPrimary,
        ),
        eventsAsync.when(
          data: (events) {
            final list = events.take(2).toList();
            return Column(
              children: list.map((event) {
                return UnifiedItemCard(
                  title: event.title,
                  imageUrl: event.imageUrl,
                  locationName: event.location,
                  rating: 4.8,
                  subtitle: event.duration,
                  price: event.price,
                  onTap: () => context.push('/event/${event.id}'),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onTapMore,
    required bool isAr,
    required Color textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
              color: textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onTapMore,
            child: Row(
              children: [
                Text(
                  isAr ? 'عرض الكل' : 'View All',
                  style: GoogleFonts.cairo(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.accentGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_off_outlined, size: 54, color: AppColors.primaryMauve),
            const SizedBox(height: 16),
            Text(
              isAr ? 'لا توجد نتائج مطابقة لبحثك' : 'No results match your filters',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? 'جرب تعديل الفلاتر أو البحث بكلمات أخرى' : 'Try adjusting your filter options or search query',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _resetAllFilters();
                _searchController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMauve,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(isAr ? 'إعادة ضبط الفلاتر' : 'Reset Filters', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isAr, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            isAr ? 'تعذر تحميل البيانات' : 'Failed to load data',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMauve,
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? 'إعادة المحاولة' : 'Retry', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
