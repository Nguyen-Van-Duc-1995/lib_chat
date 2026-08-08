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
    if (klines.isEmpty) return;

    final MACDData macdData = IndicatorCalculator.calculateMACD(klines);

    final macdLine = macdData.macdLine;
    final signalLine = macdData.signalLine;
    final histogram = macdData.histogram;

    if (macdLine.isEmpty || signalLine.isEmpty || histogram.isEmpty) {
      return;
    }

    final double candleWidthWithSpacing = candleWidth + spacing;

    // ============================================================
    // VÙNG CANDLE ĐANG HIỂN THỊ
    // Làm tương tự DrawVolumeProfileMixin
    // ============================================================

    final int visibleStartIndex = (scrollX / candleWidthWithSpacing)
        .floor()
        .clamp(0, klines.length - 1);

    final int visibleEndIndex =
        ((scrollX + size.width) / candleWidthWithSpacing).ceil().clamp(
          0,
          klines.length - 1,
        );

    // ============================================================
    // MAP DateTime -> candle index
    // ============================================================

    final Map<DateTime, int> candleIndexByTime = {
      for (int i = 0; i < klines.length; i++) klines[i].dateTime: i,
    };

    // ============================================================
    // Lấy MACD data nằm trong vùng visible
    // ============================================================

    final List<IndicatorPoint> visibleMACD = [];
    final List<IndicatorPoint> visibleSignal = [];
    final List<IndicatorPoint> visibleHistogram = [];

    for (final point in macdLine) {
      final int? index = candleIndexByTime[point.time];

      if (index == null) continue;

      if (index >= visibleStartIndex && index <= visibleEndIndex) {
        visibleMACD.add(point);
      }
    }

    for (final point in signalLine) {
      final int? index = candleIndexByTime[point.time];

      if (index == null) continue;

      if (index >= visibleStartIndex && index <= visibleEndIndex) {
        visibleSignal.add(point);
      }
    }

    for (final point in histogram) {
      final int? index = candleIndexByTime[point.time];

      if (index == null) continue;

      if (index >= visibleStartIndex && index <= visibleEndIndex) {
        visibleHistogram.add(point);
      }
    }

    if (visibleMACD.isEmpty ||
        visibleSignal.isEmpty ||
        visibleHistogram.isEmpty) {
      return;
    }

    // ============================================================
    // TÍNH MIN / MAX THEO VÙNG VISIBLE
    // ============================================================

    double maxV = 0;
    double minV = 0;

    for (final point in visibleMACD) {
      maxV = max(maxV, point.value);
      minV = min(minV, point.value);
    }

    for (final point in visibleSignal) {
      maxV = max(maxV, point.value);
      minV = min(minV, point.value);
    }

    for (final point in visibleHistogram) {
      maxV = max(maxV, point.value);
      minV = min(minV, point.value);
    }

    // Thêm khoảng trống trên/dưới.
    double range = maxV - minV;

    if (range.abs() < 0.000001) {
      range = 1.0;
    }

    final double padding = range * 0.12;

    maxV += padding;
    minV -= padding;

    range = maxV - minV;

    double valueToY(double value) {
      return macdTopY + ((maxV - value) / range) * macdChartHeight;
    }

    // ============================================================
    // CLIP VÙNG MACD
    // ============================================================

    canvas.save();

    canvas.clipRect(Rect.fromLTWH(0, macdTopY, size.width, macdChartHeight));

    // ============================================================
    // GRID
    // ============================================================

    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    const int horizontalLines = 2;

    for (int i = 0; i <= horizontalLines; i++) {
      final double y = macdTopY + (macdChartHeight / horizontalLines) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const int verticalLines = 4;

    for (int i = 0; i <= verticalLines; i++) {
      final double x = size.width / verticalLines * i;

      canvas.drawLine(
        Offset(x, macdTopY),
        Offset(x, macdTopY + macdChartHeight),
        gridPaint,
      );
    }

    // ============================================================
    // ZERO LINE
    // ============================================================

    final double zeroY = valueToY(0);

    final Paint zeroPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 0.7;

    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    // ============================================================
    // PAINT
    // ============================================================

    final Paint macdPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Paint signalPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Paint histogramUpPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final Paint histogramDownPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // ============================================================
    // PATH
    // ============================================================

    final Path macdPath = Path();
    final Path signalPath = Path();

    bool macdStarted = false;
    bool signalStarted = false;

    final double barWidth = max(1.0, candleWidth * 0.8);

    // Giá trị candle cuối cùng visible.
    double? currentMACD;
    double? currentSignal;
    double? currentHistogram;

    // ============================================================
    // HISTOGRAM
    // ============================================================

    for (final point in visibleHistogram) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) continue;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (x + candleWidth < 0 || x > size.width) {
        continue;
      }

      final double value = point.value;

      final double barY = valueToY(value);

      final Paint paint = value >= 0 ? histogramUpPaint : histogramDownPaint;

      canvas.drawRect(
        Rect.fromLTRB(x, min(barY, zeroY), x + barWidth, max(barY, zeroY)),
        paint,
      );

      currentHistogram = value;
    }

    // ============================================================
    // MACD LINE
    // ============================================================

    for (final point in visibleMACD) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) continue;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (x + candleWidth < 0 || x > size.width) {
        continue;
      }

      final double y = valueToY(point.value);

      if (!macdStarted) {
        macdPath.moveTo(x, y);
        macdStarted = true;
      } else {
        macdPath.lineTo(x, y);
      }

      currentMACD = point.value;
    }

    // ============================================================
    // SIGNAL LINE
    // ============================================================

    for (final point in visibleSignal) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) continue;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (x + candleWidth < 0 || x > size.width) {
        continue;
      }

      final double y = valueToY(point.value);

      if (!signalStarted) {
        signalPath.moveTo(x, y);
        signalStarted = true;
      } else {
        signalPath.lineTo(x, y);
      }

      currentSignal = point.value;
    }

    if (macdStarted) {
      canvas.drawPath(macdPath, macdPaint);
    }

    if (signalStarted) {
      canvas.drawPath(signalPath, signalPaint);
    }

    // ============================================================
    // LABEL GIÁ TRỊ BÊN PHẢI
    // Giống cách POC / VAH / VAL
    // ============================================================

    if (currentMACD != null) {
      _drawMACDPriceLabel(
        canvas,
        currentMACD,
        valueToY(currentMACD),
        Colors.blueAccent,
        size.width,
      );
    }

    if (currentSignal != null) {
      _drawMACDPriceLabel(
        canvas,
        currentSignal,
        valueToY(currentSignal),
        Colors.orange,
        size.width,
      );
    }

    // ============================================================
    // LEGEND TRÊN MACD
    // ============================================================

    if (currentMACD != null &&
        currentSignal != null &&
        currentHistogram != null) {
      _drawMACDLegend(
        canvas: canvas,
        topY: macdTopY,
        macd: currentMACD,
        signal: currentSignal,
        histogram: currentHistogram,
      );
    }

    canvas.restore();
  }

  // ==============================================================
  // HEADER / LEGEND
  // ==============================================================

  void _drawMACDLegend({
    required Canvas canvas,
    required double topY,
    required double macd,
    required double signal,
    required double histogram,
  }) {
    final Color histogramColor = histogram >= 0
        ? Colors.greenAccent
        : Colors.redAccent;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'MACD 12 26 close 9  ',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),

          TextSpan(
            text: '${_formatValue(macd)}  ',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextSpan(
            text: '${_formatValue(signal)}  ',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextSpan(
            text: _formatValue(histogram),
            style: TextStyle(
              color: histogramColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    painter.layout();

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);

    final RRect background = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, topY + 3, painter.width + 10, painter.height + 6),
      const Radius.circular(3),
    );

    canvas.drawRRect(background, backgroundPaint);

    painter.paint(canvas, Offset(9, topY + 6));
  }

  // ==============================================================
  // LABEL GIÁ TRỊ BÊN PHẢI
  // ==============================================================

  void _drawMACDPriceLabel(
    Canvas canvas,
    double value,
    double y,
    Color color,
    double canvasWidth,
  ) {
    final String valueText = _formatValue(value);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: valueText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    const double paddingX = 4;
    const double paddingY = 2;

    final double labelX = canvasWidth - textPainter.width - paddingX * 2;

    final double labelY = y - textPainter.height / 2;

    final RRect backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelX,
        labelY - paddingY,
        textPainter.width + paddingX * 2,
        textPainter.height + paddingY * 2,
      ),
      const Radius.circular(2),
    );

    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(backgroundRect, backgroundPaint);

    textPainter.paint(canvas, Offset(labelX + paddingX, labelY));
  }

  // ==============================================================
  // FORMAT
  // ==============================================================

  String _formatValue(double value) {
    final double absValue = value.abs();

    if (absValue >= 1000) {
      return value.toStringAsFixed(0);
    }

    if (absValue >= 100) {
      return value.toStringAsFixed(1);
    }

    if (absValue >= 1) {
      return value.toStringAsFixed(2);
    }

    if (absValue >= 0.01) {
      return value.toStringAsFixed(3);
    }

    return value.toStringAsFixed(4);
  }
}
