import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';

mixin DrawVolumeProfileMixin {
  void drawVolumeProfile({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double maxPrice,
    required double minPrice,
    required double chartHeight,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required double Function(double, double) priceToY,
    int priceLevels = 24, // Number of price levels to divide the range
    double profileWidth = 150, // Maximum width of volume profile bars
    bool showOnRight = true, // Show profile on right side
    double opacity = 0.8,
    bool showBuySellSeparately = true, // Show buy/sell volume separately
  }) {
    if (klines.isEmpty || maxPrice == minPrice) return;

    // Calculate visible range
    final candleWidthWithSpacing = candleWidth + spacing;
    final visibleStartIndex = (scrollX / candleWidthWithSpacing).floor().clamp(
      0,
      klines.length - 1,
    );
    final visibleEndIndex = ((scrollX + size.width) / candleWidthWithSpacing)
        .ceil()
        .clamp(0, klines.length - 1);

    // Get visible klines
    final visibleKlines = klines.sublist(
      visibleStartIndex,
      (visibleEndIndex + 1).clamp(0, klines.length),
    );

    if (visibleKlines.isEmpty) return;

    // Calculate price step
    final priceStep = (maxPrice - minPrice) / priceLevels.toDouble();

    // Create volume profile data - separate buy and sell
    final buyVolumeProfile = <double>[];
    final sellVolumeProfile = <double>[];
    for (int i = 0; i < priceLevels; i++) {
      buyVolumeProfile.add(0.0);
      sellVolumeProfile.add(0.0);
    }

    // Accumulate volume for each price level
    for (final kline in visibleKlines) {
      // Distribute volume across the price range of the candle
      final high = kline.high;
      final low = kline.low;
      final volume = kline.volume;
      final isBullish = kline.close >= kline.open;

      // Find the price levels that this candle spans
      final startLevel = ((low - minPrice) / priceStep).floor().clamp(
        0,
        priceLevels - 1,
      );
      final endLevel = ((high - minPrice) / priceStep).floor().clamp(
        0,
        priceLevels - 1,
      );

      // Distribute volume proportionally across price levels
      final levelsSpanned = (endLevel - startLevel + 1).toDouble();
      final volumePerLevel = volume / levelsSpanned;

      for (int level = startLevel; level <= endLevel; level++) {
        if (isBullish) {
          buyVolumeProfile[level] += volumePerLevel;
        } else {
          sellVolumeProfile[level] += volumePerLevel;
        }
      }
    }

    // Find maximum volume for scaling
    final maxBuyVolume = buyVolumeProfile.reduce((a, b) => a > b ? a : b);
    final maxSellVolume = sellVolumeProfile.reduce((a, b) => a > b ? a : b);
    final maxVolumeInProfile = max(maxBuyVolume, maxSellVolume);

    if (maxVolumeInProfile == 0) return;

    // Calculate total volume and POC
    final totalVolumeProfile = <double>[];
    for (int i = 0; i < priceLevels; i++) {
      totalVolumeProfile.add(buyVolumeProfile[i] + sellVolumeProfile[i]);
    }

    final maxTotalVolume = totalVolumeProfile.reduce((a, b) => a > b ? a : b);
    final pocIndex = totalVolumeProfile.indexWhere(
      (vol) => vol == maxTotalVolume,
    );

    // Draw volume profile bars
    for (int i = 0; i < priceLevels; i++) {
      final buyVolume = buyVolumeProfile[i];
      final sellVolume = sellVolumeProfile[i];
      final totalVolume = buyVolume + sellVolume;

      if (totalVolume <= 0) continue;

      // Calculate price for this level
      final levelPrice = minPrice + (i + 0.5) * priceStep;
      final y = priceToY(levelPrice, chartHeight);

      // Calculate bar width based on total volume
      final totalBarWidth = (totalVolume / maxVolumeInProfile) * profileWidth;

      // Calculate bar position
      final barX = showOnRight
          ? size.width -
                totalBarWidth // Right side without padding
          : 0.0; // Left side without padding

      // Calculate bar height (covers the price level)
      final barHeight = chartHeight / priceLevels.toDouble();
      final barY = y - barHeight / 2;

      if (showBuySellSeparately && buyVolume > 0 && sellVolume > 0) {
        // Show buy and sell volume side by side
        final buyRatio = buyVolume / totalVolume;
        final sellRatio = sellVolume / totalVolume;

        final buyBarWidth = totalBarWidth * buyRatio;
        final sellBarWidth = totalBarWidth * sellRatio;

        // Draw buy volume (left side of bar) - Orange/Yellow
        final buyPaint = Paint()
          ..color = Colors.orange.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(barX, barY, buyBarWidth, barHeight),
          buyPaint,
        );

        // Draw sell volume (right side of bar) - Blue
        final sellPaint = Paint()
          ..color = Colors.blue.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(barX + buyBarWidth, barY, sellBarWidth, barHeight),
          sellPaint,
        );

        // Draw separator line
        if (buyBarWidth > 1 && sellBarWidth > 1) {
          final separatorPaint = Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..strokeWidth = 0.5;

          canvas.drawLine(
            Offset(barX + buyBarWidth, barY),
            Offset(barX + buyBarWidth, barY + barHeight),
            separatorPaint,
          );
        }
      } else {
        // Show single color based on dominant volume
        Color barColor;
        if (buyVolume > sellVolume) {
          barColor = Colors.orange.withOpacity(opacity); // Buy dominant
        } else if (sellVolume > buyVolume) {
          barColor = Colors.blue.withOpacity(opacity); // Sell dominant
        } else {
          barColor = Colors.grey.withOpacity(opacity); // Equal
        }

        final paint = Paint()
          ..color = barColor
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(barX, barY, totalBarWidth, barHeight),
          paint,
        );
      }
    }

    // Draw POC (Point of Control) - highest total volume level
    final pocPrice = minPrice + (pocIndex + 0.5) * priceStep;
    final pocY = priceToY(pocPrice, chartHeight);

    // Draw POC line
    final pocPaint = Paint()
      ..color = Colors.red.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw POC line across the entire screen width
    final pocLineStart = 0.0; // Start from left edge
    final pocLineEnd = size.width; // End at right edge

    canvas.drawLine(
      Offset(pocLineStart, pocY),
      Offset(pocLineEnd, pocY),
      pocPaint,
    );

    // Draw POC price label (like price labels on right)
    _drawPriceLabel(canvas, 'POC', pocPrice, pocY, Colors.white, size.width);

    // Draw Value Area (70% of total volume)
    final valueAreaData = _calculateValueArea(
      totalVolumeProfile,
      minPrice,
      priceStep,
    );
    if (valueAreaData != null) {
      final vahPrice = valueAreaData['vahPrice'] as double;
      final valPrice = valueAreaData['valPrice'] as double;
      final vahY = priceToY(vahPrice, chartHeight);
      final valY = priceToY(valPrice, chartHeight);

      // Draw Value Area rectangle
      final valueAreaPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      final vaX = showOnRight ? size.width - profileWidth : 0.0;

      canvas.drawRect(
        Rect.fromLTWH(vaX, vahY, profileWidth, valY - vahY),
        valueAreaPaint,
      );

      // Draw VAH and VAL lines across entire screen
      final valuePaint = Paint()
        ..color = Colors.cyan.withOpacity(0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // VAH line - full width
      canvas.drawLine(Offset(0.0, vahY), Offset(size.width, vahY), valuePaint);

      // VAL line - full width
      canvas.drawLine(Offset(0.0, valY), Offset(size.width, valY), valuePaint);

      // Draw VAH and VAL price labels (like price labels on right)
      _drawPriceLabel(canvas, 'VAH', vahPrice, vahY, Colors.cyan, size.width);
      _drawPriceLabel(canvas, 'VAL', valPrice, valY, Colors.cyan, size.width);
    }

    // Draw legend
    if (showBuySellSeparately) {
      _drawLegend(canvas, size, showOnRight);
    }
  }

  // New method to draw price labels like the main price labels
  void _drawPriceLabel(
    Canvas canvas,
    String prefix,
    double price,
    double y,
    Color color,
    double canvasWidth,
  ) {
    final priceText = price.toStringAsFixed(2);
    final fullText = '$prefix: $priceText';

    final textPainter = TextPainter(
      text: TextSpan(
        text: fullText,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position very close to right edge, only 10px margin
    final labelX = canvasWidth - textPainter.width + 45.0;

    // Draw background rectangle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelX - 4.0,
        y - textPainter.height / 2 - 2.0,
        textPainter.width + 8.0,
        textPainter.height + 4.0,
      ),
      const Radius.circular(3.0),
    );

    canvas.drawRRect(backgroundRect, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(backgroundRect, borderPaint);

    // Draw text
    final textColor = color == Colors.white ? Colors.black : Colors.white;
    final finalTextPainter = TextPainter(
      text: TextSpan(
        text: fullText,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    finalTextPainter.layout();
    finalTextPainter.paint(
      canvas,
      Offset(labelX, y - finalTextPainter.height / 2),
    );
  }

  // Helper method to calculate Value Area
  Map<String, double>? _calculateValueArea(
    List<double> volumeProfile,
    double minPrice,
    double priceStep,
  ) {
    // Calculate total volume
    final totalVolume = volumeProfile.fold(0.0, (sum, vol) => sum + vol);
    if (totalVolume == 0) return null;

    final valueAreaVolume = totalVolume * 0.7; // 70% of total volume

    // Find POC (Point of Control)
    final maxVolume = volumeProfile.reduce((a, b) => a > b ? a : b);
    final pocIndex = volumeProfile.indexWhere((vol) => vol == maxVolume);

    // Expand from POC to find Value Area High and Low
    double accumulatedVolume = volumeProfile[pocIndex];
    int vahIndex = pocIndex; // Value Area High index
    int valIndex = pocIndex; // Value Area Low index

    while (accumulatedVolume < valueAreaVolume &&
        (vahIndex < volumeProfile.length - 1 || valIndex > 0)) {
      // Determine which direction to expand
      final expandUp =
          vahIndex < volumeProfile.length - 1 &&
          (valIndex == 0 ||
              volumeProfile[vahIndex + 1] >= volumeProfile[valIndex - 1]);

      if (expandUp) {
        vahIndex++;
        accumulatedVolume += volumeProfile[vahIndex];
      } else {
        valIndex--;
        accumulatedVolume += volumeProfile[valIndex];
      }
    }

    // Calculate VAH and VAL prices
    final vahPrice = minPrice + (vahIndex + 1) * priceStep;
    final valPrice = minPrice + valIndex * priceStep;

    return {'vahPrice': vahPrice, 'valPrice': valPrice};
  }

  void _drawLegend(Canvas canvas, Size size, bool showOnRight) {
    const legendHeight = 40.0;
    const legendWidth = 80.0;
    const legendPadding = 10.0;

    // Always show legend at top-left corner
    const legendX = legendPadding;
    const legendY = legendPadding;

    // Draw legend background
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(legendX, legendY, legendWidth, legendHeight),
        const Radius.circular(4.0),
      ),
      backgroundPaint,
    );

    // Draw buy color indicator
    final buyPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(legendX + 5, legendY + 8, 12, 8), buyPaint);

    // Draw sell color indicator
    final sellPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(legendX + 5, legendY + 22, 12, 8), sellPaint);

    // Draw text labels
    final buyTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Buy',
        style: TextStyle(color: Colors.white, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    );
    buyTextPainter.layout();
    buyTextPainter.paint(canvas, Offset(legendX + 20, legendY + 7));

    final sellTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Sell',
        style: TextStyle(color: Colors.white, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    );
    sellTextPainter.layout();
    sellTextPainter.paint(canvas, Offset(legendX + 20, legendY + 21));
  }
}
