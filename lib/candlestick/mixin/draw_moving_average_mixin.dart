import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/indicator_calculator.dart';

mixin DrawMovingAverageMixin {
  void drawMovingAverage({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double chartHeight,
    required int period,
    required Color color,
    required double candleWidthWithSpacing,
    required double scrollX,
    required double Function(double price, double chartHeight) priceToY,
  }) {
    if (klines.length < period) return;

    final maPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    final closes = klines.map((k) => k.close).toList();
    final maValues = IndicatorCalculator.calculateEMA(closes, period);
    if (maValues.isEmpty) return;

    final double spacing = candleWidthWithSpacing * 0.3;
    bool started = false;

    // Vòng lặp qua tất cả các giá trị EMA
    for (int i = 0; i < maValues.length; i++) {
      // Index thật của candle tương ứng với EMA value
      final int candleIndex = i + period - 1;

      // Đảm bảo không vượt quá giới hạn
      if (candleIndex >= klines.length) break;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;
      final double y = priceToY(maValues[i], chartHeight);

      // Chỉ vẽ những điểm trong vùng hiển thị (với buffer)
      if (x < -candleWidthWithSpacing) continue;
      if (x > size.width + candleWidthWithSpacing) break;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    if (started) {
      canvas.drawPath(path, maPaint);
    }
  }
}
