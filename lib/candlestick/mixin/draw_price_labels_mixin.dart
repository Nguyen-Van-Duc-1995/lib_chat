import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:chart/utils/format.dart';
import '../../utils/colors.dart' show AppColors;

mixin DrawPriceLabelsMixin {
  void drawPriceLabels({
    required Canvas canvas,
    required Size size,
    required double chartHeight,
    required double maxPrice,
    required double minPrice,
    required double maxVolume,
  }) {
    final textStyle = TextStyle(color: AppColors.textSecondary, fontSize: 10);
    const int numLabels = 5;

    for (int i = 0; i <= numLabels; i++) {
      final price = maxPrice - ((maxPrice - minPrice) / numLabels) * i;
      final y = (chartHeight / numLabels) * i;

      final textSpan = TextSpan(
        text: FormatUtils.formatPrice(
          price,
          decimalPlaces: (maxPrice - minPrice) < 10
              ? 2
              : ((maxPrice - minPrice) < 1 ? 4 : 0),
        ),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final double textX = size.width + 5;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = AppColors.gridLine.withOpacity(0.2)
          ..strokeWidth = 0.5,
      );

      textPainter.paint(canvas, Offset(textX, y - textPainter.height / 2));
    }
  }
}
