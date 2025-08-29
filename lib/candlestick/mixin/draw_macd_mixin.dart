import 'dart:math';

import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/model/indicator_point.dart';
import 'package:chart/utils/indicator_calculator.dart';

mixin DrawMACDMixin {
  void drawMACD({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required double macdChartHeight,
    required double macdTopY,
  }) {
    final MACDData macdData = IndicatorCalculator.calculateMACD(klines);
    final macdLine = macdData.macdLine;
    final signalLine = macdData.signalLine;
    final histogram = macdData.histogram;

    if (macdLine.isEmpty || signalLine.isEmpty || histogram.isEmpty) return;

    // Vẽ lưới cho khung MACD
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const int horizontalLines = 1;
    for (int i = 0; i <= horizontalLines; i++) {
      final y = macdTopY + (macdChartHeight / horizontalLines) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const int verticalLines = 4;
    if (klines.length > verticalLines * 5) {
      for (int i = 0; i <= verticalLines; i++) {
        final x = (size.width / verticalLines) * i;
        canvas.drawLine(
          Offset(x, macdTopY),
          Offset(x, macdTopY + macdChartHeight),
          gridPaint,
        );
      }
    }

    // Chuẩn bị dữ liệu và scale
    final allValues = [
      ...macdLine.map((e) => e.value),
      ...signalLine.map((e) => e.value),
      ...histogram.map((e) => e.value),
    ];
    final double maxV = allValues.reduce(max);
    final double minV = allValues.reduce(min);
    final double range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    double valueToY(double value) {
      return macdTopY + (maxV - value) / range * macdChartHeight;
    }

    final double candleWidthWithSpacing = candleWidth + spacing;
    final double barWidth = candleWidth * 0.8;

    final macdPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final signalPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint histogramUpPaint = Paint()..color = Colors.greenAccent;
    final Paint histogramDownPaint = Paint()..color = Colors.redAccent;

    final Path macdPath = Path();
    final Path signalPath = Path();
    bool macdStarted = false;
    bool signalStarted = false;

    for (int i = 0; i < histogram.length; i++) {
      final candleIndex = klines.indexWhere(
        (k) => k.dateTime == histogram[i].time,
      );
      if (candleIndex == -1) continue;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;
      if (x + candleWidth < 0 || x > size.width) continue;

      final double barTop = valueToY(histogram[i].value);
      final double barBottom = valueToY(0);
      final Paint barPaint = histogram[i].value >= 0
          ? histogramUpPaint
          : histogramDownPaint;

      canvas.drawRect(
        Rect.fromLTRB(
          x,
          min(barTop, barBottom),
          x + barWidth,
          max(barTop, barBottom),
        ),
        barPaint,
      );

      final yMacd = valueToY(macdLine[i].value);
      final ySignal = valueToY(signalLine[i].value);

      if (!macdStarted) {
        macdPath.moveTo(x, yMacd);
        macdStarted = true;
      } else {
        macdPath.lineTo(x, yMacd);
      }

      if (!signalStarted) {
        signalPath.moveTo(x, ySignal);
        signalStarted = true;
      } else {
        signalPath.lineTo(x, ySignal);
      }
    }

    canvas.drawPath(macdPath, macdPaint);
    canvas.drawPath(signalPath, signalPaint);

    final zeroY = valueToY(0);
    final zeroLinePaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroLinePaint);
  }
}
