import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> shareItem({
    BuildContext? context,
    required String title,
    required String category,
    required String id,
    String? price,
    String? location,
    String?
        type, // 'tour', 'museum', 'event', 'guide', 'car', 'shop', 'location'
  }) async {
    try {
      final typePath = switch (type) {
        'tour' => 'tour',
        'museum' => 'museum',
        'event' => 'event',
        'guide' => 'guide',
        'car' => 'car',
        'shop' || 'product' => 'shop',
        'location' || 'destination' => 'location',
        _ => 'tour',
      };

      final webUrl = 'https://staging.modeef-e.com/ar/$typePath/$id';
      final appDeepLink = 'modeef://$typePath/$id';

      final buffer = StringBuffer();
      buffer.writeln('✨ $title');
      if (category.isNotEmpty) buffer.writeln('🏷️ التصنيف: $category');
      if (location != null && location.isNotEmpty)
        buffer.writeln('📍 الموقع: $location');
      if (price != null && price.isNotEmpty) buffer.writeln('💰 السعر: $price');
      buffer.writeln();
      buffer.writeln('🔗 تفاصيل التجربة والحجز:');
      buffer.writeln(webUrl);
      buffer.writeln();
      buffer.writeln('📲 فتح في تطبيق مُضيف:');
      buffer.writeln(appDeepLink);

      Rect? origin;
      if (context != null && context.mounted) {
        try {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null &&
              box.hasSize &&
              box.size.width > 0 &&
              box.size.height > 0) {
            origin = box.localToGlobal(Offset.zero) & box.size;
          }
        } catch (_) {}
      }

      // ignore: deprecated_member_use
      await Share.share(
        buffer.toString(),
        subject: title,
        sharePositionOrigin: origin,
      );
    } catch (e, stack) {
      debugPrint('ShareHelper error: $e\n$stack');
    }
  }
}
