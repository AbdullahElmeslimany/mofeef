import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/widgets/unified_item_card.dart';
import '../data/museum_repository.dart';

class MuseumListScreen extends ConsumerStatefulWidget {
  const MuseumListScreen({super.key});

  @override
  ConsumerState<MuseumListScreen> createState() => _MuseumListScreenState();
}

class _MuseumListScreenState extends ConsumerState<MuseumListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCity = 'الكل';
  RangeValues _priceRange = const RangeValues(0, 500);
  double _minRating = 0.0;

  final List<String> _citiesAr = ['الكل', 'الرياض', 'العُلا', 'جدة التاريخية', 'الدرعية', 'مكة المكرمة', 'المدينة المنورة', 'عسير'];
  final List<String> _citiesEn = ['All', 'Riyadh', 'AlUla', 'Historic Jeddah', 'Diriyah', 'Makkah', 'Madinah', 'Asir'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context, bool isAr, bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final cities = isAr ? _citiesAr : _citiesEn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'تصفية المتاحف والمعالم' : 'Filter Museums & Heritage',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCity = isAr ? 'الكل' : 'All';
                            _priceRange = const RangeValues(0, 500);
                            _minRating = 0.0;
                          });
                          setState(() {});
                        },
                        child: Text(
                          isAr ? 'إعادة ضبط' : 'Reset',
                          style: GoogleFonts.cairo(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // City Filter
                  Text(
                    isAr ? 'المدينة / الوجهة' : 'City / Destination',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cities.map((city) {
                      final isSel = _selectedCity == city || (_selectedCity == 'الكل' && city == (isAr ? 'الكل' : 'All'));
                      return ChoiceChip(
                        label: Text(city),
                        selected: isSel,
                        onSelected: (val) {
                          setModalState(() => _selectedCity = city);
                          setState(() {});
                        },
                        selectedColor: AppColors.primaryMauve,
                        backgroundColor: isDark ? const Color(0xFF1E1624) : const Color(0xFFECE7EF),
                        labelStyle: GoogleFonts.cairo(
                          color: isSel ? Colors.white : textMuted,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'نطاق السعر' : 'Price Range',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Text(
                        '${_priceRange.start.round()} — ${_priceRange.end.round()} ${isAr ? 'ر.س' : 'SAR'}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 500,
                    divisions: 10,
                    activeColor: AppColors.primaryMauve,
                    inactiveColor: cardBorder,
                    onChanged: (val) {
                      setModalState(() => _priceRange = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Minimum Rating
                  Text(
                    isAr ? 'الحد الأدنى للتقييم' : 'Minimum Rating',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [0.0, 3.0, 4.0, 4.5].map((r) {
                      final isSel = _minRating == r;
                      final label = r == 0.0 ? (isAr ? 'الكل' : 'All') : '$r+ ⭐';
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _minRating = r);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primaryMauve : (isDark ? const Color(0xFF1E1624) : const Color(0xFFECE7EF)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.cairo(
                              color: isSel ? Colors.white : textMuted,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        isAr ? 'تطبيق الفلاتر' : 'Apply Filters',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final museumsAsync = ref.watch(museumsListProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? const Color(0xFF191222) : const Color(0xFFF7F4F9);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'المتاحف والمعالم التراثية' : 'Museums & Heritage Sites',
          style: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder, width: 1.2),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      cursorColor: AppColors.primaryMauve,
                      style: GoogleFonts.cairo(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isAr ? 'ابحث عن متحف أو معلم تراثي...' : 'Search museum or heritage site...',
                        hintStyle: GoogleFonts.cairo(color: textMuted.withValues(alpha: 0.7), fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryMauve, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showFilterSheet(context, isAr, isDark, cardBg, cardBorder, textPrimary, textMuted),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF281C30) : const Color(0xFFEDE6F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryMauve.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primaryMauve, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Museum List
          Expanded(
            child: museumsAsync.when(
              data: (museums) {
                final filtered = museums.where((m) {
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matches = m.title.toLowerCase().contains(q) || (m.locationName?.toLowerCase().contains(q) ?? false);
                    if (!matches) return false;
                  }
                  if (m.price < _priceRange.start || m.price > _priceRange.end) return false;
                  if (m.rating < _minRating) return false;
                  if (_selectedCity != 'الكل' && _selectedCity != 'All') {
                    if (m.locationName != null && !m.locationName!.contains(_selectedCity)) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.museum_outlined, color: textMuted, size: 54),
                        const SizedBox(height: 14),
                        Text(
                          isAr ? 'لا توجد متاحف مطابقة للبحث' : 'No museums matching your search',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final museum = filtered[index];
                    return UnifiedItemCard(
                      title: museum.title,
                      imageUrl: museum.imageUrl,
                      locationName: museum.locationName ?? (isAr ? 'المملكة العربية السعودية' : 'Saudi Arabia'),
                      rating: museum.rating,
                      price: museum.formattedPrice,
                      accentColor: AppColors.primaryMauve,
                      onTap: () => context.push('/museum/${museum.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryMauve),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'تعذر تحميل قائمة المتاحف' : 'Failed to load museums',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => ref.refresh(museumsListProvider),
                      child: Text(
                        isAr ? 'إعادة المحاولة' : 'Retry',
                        style: GoogleFonts.cairo(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
