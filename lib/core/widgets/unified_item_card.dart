import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class UnifiedItemCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? locationName;
  final double? rating;
  final String? subtitle;
  final String price;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget? trailingBadge;

  const UnifiedItemCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.locationName,
    this.rating,
    this.subtitle,
    required this.price,
    this.accentColor = AppColors.primaryMauve,
    required this.onTap,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Thumbnail Image on Leading side (in RTL this is on the right)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imageUrl ??
                    'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 104,
                  height: 104,
                  color: isDark ? const Color(0xFF231B2A) : const Color(0xFFF0EBF3),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryMauve,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 104,
                  height: 104,
                  color: isDark ? const Color(0xFF231B2A) : const Color(0xFFF0EBF3),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: textSub,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and optional trailing badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (trailingBadge != null) trailingBadge!,
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Location Row
                  if (locationName != null && locationName!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: textSub,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            locationName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: textSub,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(height: 14),

                  // Subtitle / Brief Description
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: textSub,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Bottom Row: Price and Rating (Figma layout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        price,
                        style: GoogleFonts.cairo(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Rating with Gold Star
                      if (rating != null && rating! > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rating!.toStringAsFixed(1),
                              style: GoogleFonts.cairo(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.accentGold,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
