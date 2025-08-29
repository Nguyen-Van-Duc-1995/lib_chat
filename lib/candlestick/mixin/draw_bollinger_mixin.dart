import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';

mixin DrawBollingerBandsMixin {
  double priceToY(
    double price,
    double maxPrice,
    double minPrice,
    double chartHeight,
  ) {
    if (maxPrice == minPrice) return chartHeight / 2;
    return ((maxPrice - price) / (maxPrice - minPrice)) * chartHeight;
  }

  void drawBollingerBands({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double maxPrice,
    required double minPrice,
    required double chartHeight,
    required double candleWidthWithSpacing,
    required double scrollX,
    required double spacing,
    required double candleWidth,
  }) {
    const int period = 20;
    const double stdDevFactor = 2.0;
    if (klines.length < period) return;

    final bandPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final middlePaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final upperPath = Path();
    final lowerPath = Path();
    final middlePath = Path();

    List<double> closes = klines.map((k) => k.close).toList();
    List<double> smaValues = [];
    List<double> stdDevValues = [];

    for (int i = period - 1; i < klines.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) sum += closes[i - j];
      final sma = sum / period;
      smaValues.add(sma);

      double varianceSum = 0;
      for (int j = 0; j < period; j++) {
        varianceSum += pow(closes[i - j] - sma, 2);
      }
      stdDevValues.add(sqrt(varianceSum / period));
    }

    bool started = false;
    for (int i = 0; i < smaValues.length; i++) {
      final int candleIndex = i + period - 1;
      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (x + candleWidth < 0 || x > size.width) continue;

      final sma = smaValues[i];
      final stdDev = stdDevValues[i];

      final upperY = priceToY(
        sma + stdDev * stdDevFactor,
        maxPrice,
        minPrice,
        chartHeight,
      );
      final lowerY = priceToY(
        sma - stdDev * stdDevFactor,
        maxPrice,
        minPrice,
        chartHeight,
      );
      final middleY = priceToY(sma, maxPrice, minPrice, chartHeight);

      if (!started) {
        upperPath.moveTo(x, upperY);
        lowerPath.moveTo(x, lowerY);
        middlePath.moveTo(x, middleY);
        started = true;
      } else {
        upperPath.lineTo(x, upperY);
        lowerPath.lineTo(x, lowerY);
        middlePath.lineTo(x, middleY);
      }
    }

    canvas.drawPath(upperPath, bandPaint);
    canvas.drawPath(lowerPath, bandPaint);
    canvas.drawPath(middlePath, middlePaint);
  }
}
