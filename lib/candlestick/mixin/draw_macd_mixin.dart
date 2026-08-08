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

    if (macdLine.isEmpty || signalLine.isEmpty || histogram.isEmpty) {
      return;
    }

    // ============================================================
    // MAP DateTime -> candle index
    // Thay cho việc gọi klines.indexWhere() trong mỗi vòng lặp
    // ============================================================

    final Map<DateTime, int> candleIndexByTime = {
      for (int i = 0; i < klines.length; i++) klines[i].dateTime: i,
    };

    // ============================================================
    // Vẽ grid MACD
    // ============================================================

    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    const int horizontalLines = 1;

    for (int i = 0; i <= horizontalLines; i++) {
      final double y = macdTopY + (macdChartHeight / horizontalLines) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const int verticalLines = 4;

    if (klines.length > verticalLines * 5) {
      for (int i = 0; i <= verticalLines; i++) {
        final double x = (size.width / verticalLines) * i;

        canvas.drawLine(
          Offset(x, macdTopY),
          Offset(x, macdTopY + macdChartHeight),
          gridPaint,
        );
      }
    }

    // ============================================================
    // Tìm min / max để scale MACD
    // ============================================================

    final List<double> allValues = [
      ...macdLine.map((e) => e.value),
      ...signalLine.map((e) => e.value),
      ...histogram.map((e) => e.value),
    ];

    final double maxV = allValues.reduce(max);
    final double minV = allValues.reduce(min);

    final double range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

    double valueToY(double value) {
      return macdTopY + (maxV - value) / range * macdChartHeight;
    }

    // ============================================================
    // Kích thước candle / histogram
    // ============================================================

    final double candleWidthWithSpacing = candleWidth + spacing;

    final double barWidth = candleWidth * 0.8;

    // ============================================================
    // Paint MACD
    // ============================================================

    final Paint macdPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint signalPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint histogramUpPaint = Paint()..color = Colors.greenAccent;

    final Paint histogramDownPaint = Paint()..color = Colors.redAccent;

    // ============================================================
    // Zero line
    // ============================================================

    final double zeroY = valueToY(0);

    final Paint zeroLinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroLinePaint);

    // ============================================================
    // Paths
    // ============================================================

    final Path macdPath = Path();
    final Path signalPath = Path();

    bool macdStarted = false;
    bool signalStarted = false;

    // ============================================================
    // Draw histogram + MACD + Signal
    // ============================================================

    for (int i = 0; i < histogram.length; i++) {
      // ----------------------------------------------------------
      // O(1) lookup thay vì:
      //
      // klines.indexWhere(
      //   (k) => k.dateTime == histogram[i].time,
      // );
      // ----------------------------------------------------------

      final int? candleIndex = candleIndexByTime[histogram[i].time];

      if (candleIndex == null) {
        continue;
      }

      // Vị trí X tương ứng với candle
      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      // ----------------------------------------------------------
      // Không nằm trong viewport thì bỏ qua
      // ----------------------------------------------------------

      if (x + candleWidth < 0 || x > size.width) {
        continue;
      }

      // ==========================================================
      // Histogram
      // ==========================================================

      final double histogramValue = histogram[i].value;

      final double barTop = valueToY(histogramValue);

      final double barBottom = zeroY;

      final Paint barPaint = histogramValue >= 0
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

      // ==========================================================
      // MACD line
      // ==========================================================

      if (i < macdLine.length) {
        final double yMacd = valueToY(macdLine[i].value);

        if (!macdStarted) {
          macdPath.moveTo(x, yMacd);
          macdStarted = true;
        } else {
          macdPath.lineTo(x, yMacd);
        }
      }

      // ==========================================================
      // Signal line
      // ==========================================================

      if (i < signalLine.length) {
        final double ySignal = valueToY(signalLine[i].value);

        if (!signalStarted) {
          signalPath.moveTo(x, ySignal);
          signalStarted = true;
        } else {
          signalPath.lineTo(x, ySignal);
        }
      }
    }

    // ============================================================
    // Vẽ MACD + Signal
    // ============================================================

    canvas.drawPath(macdPath, macdPaint);

    canvas.drawPath(signalPath, signalPaint);
  }
}
