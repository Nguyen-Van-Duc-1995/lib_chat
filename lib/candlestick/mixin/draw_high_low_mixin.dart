import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/format.dart';
import '../../utils/colors.dart';

mixin DrawHighLowMixin {
  // vẽ giá trị cao nhất và thấp nhất của screen các nến
  double _priceToY(
    double price,
    double chartHeight,
    double maxPrice,
    double minPrice,
  ) {
    if (maxPrice == minPrice) return chartHeight / 2;
    return ((maxPrice - price) / (maxPrice - minPrice)) * chartHeight;
  }

  void drawHighLowAnnotations({
    required Canvas canvas,
    required Size size,
    required double chartHeight,
    required double maxPrice,
    required double minPrice,
    required List<KlineData> klines,
    required double scrollX,
    required double candleWidth,
    required double spacing,
  }) {
    final double candleWidthWithSpacing = candleWidth + spacing;

    int? maxIndex;
    int? minIndex;
    double? maxValue;
    double? minValue;

    for (int i = 0; i < klines.length; i++) {
      final kline = klines[i];
      final double x = i * candleWidthWithSpacing - scrollX + spacing / 2;
      if (x + candleWidth < 0 || x > size.width) continue;

      if (maxValue == null || kline.high > maxValue) {
        maxValue = kline.high;
        maxIndex = i;
      }
      if (minValue == null || kline.low < minValue) {
        minValue = kline.low;
        minIndex = i;
      }
    }

    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    if (maxIndex != null && maxValue != null) {
      final double x =
          maxIndex * candleWidthWithSpacing - scrollX + spacing / 2;
      final double y = _priceToY(maxValue, chartHeight, maxPrice, minPrice);

      final tp = TextPainter(
        text: TextSpan(
          text: FormatUtils.formatPrice(maxValue),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawLine(
        Offset(x + candleWidth / 2, y),
        Offset(x + candleWidth / 2 + tp.width / 3, y),
        Paint()..color = AppColors.textPrimary,
      );

      tp.paint(
        canvas,
        Offset(x + candleWidth / 2 + tp.width / 3 + 2, y - tp.height / 2),
      );
    }

    if (minIndex != null && minValue != null) {
      final double x =
          minIndex * candleWidthWithSpacing - scrollX + spacing / 2;
      final double y = _priceToY(minValue, chartHeight, maxPrice, minPrice);

      final tp = TextPainter(
        text: TextSpan(
          text: FormatUtils.formatPrice(minValue),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawLine(
        Offset(x + candleWidth / 2, y),
        Offset(x + candleWidth / 2 + tp.width / 3, y),
        Paint()..color = AppColors.textPrimary,
      );

      tp.paint(
        canvas,
        Offset(x + candleWidth / 2 + tp.width / 3 + 2, y - tp.height / 2),
      );
    }
  }
}
