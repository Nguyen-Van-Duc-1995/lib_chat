import 'dart:math';
import 'dart:ui' as ui;

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

    // ============================================================
    // CALCULATE MACD
    // ============================================================

    final MACDData macdData = IndicatorCalculator.calculateMACD(klines);

    final List<IndicatorPoint> macdLine = macdData.macdLine;

    final List<IndicatorPoint> signalLine = macdData.signalLine;

    final List<IndicatorPoint> histogram = macdData.histogram;

    if (macdLine.isEmpty || signalLine.isEmpty || histogram.isEmpty) {
      return;
    }

    // ============================================================
    // CANDLE WIDTH
    // ============================================================

    final double candleWidthWithSpacing = candleWidth + spacing;

    // ============================================================
    // VISIBLE RANGE
    //
    // Tương tự Volume:
    // chỉ quan tâm candle đang nằm trên màn hình.
    // ============================================================

    final int rawStartIndex = (scrollX / candleWidthWithSpacing).floor();

    final int rawEndIndex = ((scrollX + size.width) / candleWidthWithSpacing)
        .ceil();

    final int visibleStartIndex = max(0, min(klines.length - 1, rawStartIndex));

    final int visibleEndIndex = max(0, min(klines.length - 1, rawEndIndex));

    if (visibleEndIndex < visibleStartIndex) {
      return;
    }

    // ============================================================
    // MAP DateTime -> candle index
    //
    // Lookup O(1)
    // Không dùng indexWhere trong vòng loop.
    // ============================================================

    final Map<DateTime, int> candleIndexByTime = {
      for (int i = 0; i < klines.length; i++) klines[i].dateTime: i,
    };

    // ============================================================
    // TÌM MIN / MAX VISIBLE
    //
    // Scale MACD theo khu vực đang hiển thị.
    // Đồng thời lấy giá trị cuối cùng visible để hiện label.
    // ============================================================

    double maxV = 0.0;
    double minV = 0.0;

    bool hasVisibleData = false;

    double? currentMACD;
    double? currentSignal;
    double? currentHistogram;

    int currentMACDIndex = -1;
    int currentSignalIndex = -1;
    int currentHistogramIndex = -1;

    // ------------------------------------------------------------
    // MACD
    // ------------------------------------------------------------

    for (final IndicatorPoint point in macdLine) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) {
        continue;
      }

      if (candleIndex < visibleStartIndex || candleIndex > visibleEndIndex) {
        continue;
      }

      hasVisibleData = true;

      if (point.value > maxV) {
        maxV = point.value;
      }

      if (point.value < minV) {
        minV = point.value;
      }

      // Candle bên phải nhất đang visible
      if (candleIndex >= currentMACDIndex) {
        currentMACDIndex = candleIndex;
        currentMACD = point.value;
      }
    }

    // ------------------------------------------------------------
    // SIGNAL
    // ------------------------------------------------------------

    for (final IndicatorPoint point in signalLine) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) {
        continue;
      }

      if (candleIndex < visibleStartIndex || candleIndex > visibleEndIndex) {
        continue;
      }

      hasVisibleData = true;

      if (point.value > maxV) {
        maxV = point.value;
      }

      if (point.value < minV) {
        minV = point.value;
      }

      if (candleIndex >= currentSignalIndex) {
        currentSignalIndex = candleIndex;
        currentSignal = point.value;
      }
    }

    // ------------------------------------------------------------
    // HISTOGRAM
    // ------------------------------------------------------------

    for (final IndicatorPoint point in histogram) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) {
        continue;
      }

      if (candleIndex < visibleStartIndex || candleIndex > visibleEndIndex) {
        continue;
      }

      hasVisibleData = true;

      if (point.value > maxV) {
        maxV = point.value;
      }

      if (point.value < minV) {
        minV = point.value;
      }

      if (candleIndex >= currentHistogramIndex) {
        currentHistogramIndex = candleIndex;
        currentHistogram = point.value;
      }
    }

    if (!hasVisibleData) {
      return;
    }

    // ============================================================
    // SCALE PADDING
    //
    // Zero luôn nằm trong chart vì maxV/minV bắt đầu từ 0.
    // ============================================================

    double range = maxV - minV;

    if (range.abs() < 1e-9) {
      // Trường hợp toàn bộ giá trị = 0
      maxV = 0.5;
      minV = -0.5;
    } else {
      final double padding = range * 0.10;

      maxV += padding;
      minV -= padding;
    }

    range = maxV - minV;

    if (range.abs() < 1e-9) {
      range = 1.0;
    }

    // ============================================================
    // VALUE -> Y
    // ============================================================

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

    // ------------------------------------------------------------
    // Horizontal grid
    // ------------------------------------------------------------

    const int horizontalLines = 1;

    for (int i = 0; i <= horizontalLines; i++) {
      final double y = macdTopY + (macdChartHeight / horizontalLines) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ------------------------------------------------------------
    // Vertical grid
    // ------------------------------------------------------------

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
    // ZERO LINE
    // ============================================================

    final double zeroY = valueToY(0);

    final Paint zeroLinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.45)
      ..strokeWidth = 0.7;

    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroLinePaint);

    // ============================================================
    // PAINT
    // ============================================================

    final Paint macdPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.95)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final Paint signalPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.95)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final Paint histogramUpPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final Paint histogramDownPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // ============================================================
    // HISTOGRAM
    // ============================================================

    final double barWidth = max(1.0, candleWidth * 0.8);

    for (final IndicatorPoint point in histogram) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) {
        continue;
      }

      if (candleIndex < visibleStartIndex || candleIndex > visibleEndIndex) {
        continue;
      }

      final double candleX =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (candleX + candleWidth < 0 || candleX > size.width) {
        continue;
      }

      final double histogramValue = point.value;

      final double barY = valueToY(histogramValue);

      // Căn histogram vào giữa candle
      final double barX = candleX + (candleWidth - barWidth) / 2;

      final Paint barPaint = histogramValue >= 0
          ? histogramUpPaint
          : histogramDownPaint;

      canvas.drawRect(
        Rect.fromLTRB(
          barX,
          min(barY, zeroY),
          barX + barWidth,
          max(barY, zeroY),
        ),
        barPaint,
      );
    }

    // ============================================================
    // MACD PATH
    // ============================================================

    final Path macdPath = Path();

    bool macdStarted = false;

    for (final IndicatorPoint point in macdLine) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) {
        continue;
      }

      if (candleIndex < visibleStartIndex || candleIndex > visibleEndIndex) {
        continue;
      }

      final double candleX =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (candleX + candleWidth < 0 || candleX > size.width) {
        continue;
      }

      // Line nằm giữa candle
      final double x = candleX + candleWidth / 2;

      final double y = valueToY(point.value);

      if (!macdStarted) {
        macdPath.moveTo(x, y);
        macdStarted = true;
      } else {
        macdPath.lineTo(x, y);
      }
    }

    if (macdStarted) {
      canvas.drawPath(macdPath, macdPaint);
    }

    // ============================================================
    // SIGNAL PATH
    // ============================================================

    final Path signalPath = Path();

    bool signalStarted = false;

    for (final IndicatorPoint point in signalLine) {
      final int? candleIndex = candleIndexByTime[point.time];

      if (candleIndex == null) {
        continue;
      }

      if (candleIndex < visibleStartIndex || candleIndex > visibleEndIndex) {
        continue;
      }

      final double candleX =
          candleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      if (candleX + candleWidth < 0 || candleX > size.width) {
        continue;
      }

      final double x = candleX + candleWidth / 2;

      final double y = valueToY(point.value);

      if (!signalStarted) {
        signalPath.moveTo(x, y);
        signalStarted = true;
      } else {
        signalPath.lineTo(x, y);
      }
    }

    if (signalStarted) {
      canvas.drawPath(signalPath, signalPaint);
    }

    // ============================================================
    // LABEL GÓC TRÊN BÊN TRÁI
    //
    // Giống Volume MA:
    //
    // MACD(12,26,9)  MACD: xxx  Signal: xxx  Hist: xxx
    // ============================================================

    if (currentMACD != null &&
        currentSignal != null &&
        currentHistogram != null) {
      _drawMACDLabelTopLeft(
        canvas: canvas,
        macdTopY: macdTopY,
        macdValue: currentMACD,
        signalValue: currentSignal,
        histogramValue: currentHistogram,
      );
    }

    canvas.restore();

    // ============================================================
    // LABEL SCALE BÊN PHẢI
    // ============================================================

    _drawMACDRightLabels(
      canvas: canvas,
      size: size,
      macdTopY: macdTopY,
      macdChartHeight: macdChartHeight,
      maxValue: maxV,
      minValue: minV,
      zeroY: zeroY,
      currentMACD: currentMACD,
      currentSignal: currentSignal,
      valueToY: valueToY,
    );
  }

  // ==============================================================
  // MACD LABEL TOP LEFT
  //
  // Tham khảo:
  // _drawVolumeMALabelTopLeft()
  // ==============================================================

  void _drawMACDLabelTopLeft({
    required Canvas canvas,
    required double macdTopY,
    required double macdValue,
    required double signalValue,
    required double histogramValue,
  }) {
    // ============================================================
    // COLORS
    // ============================================================

    final Color titleColor = Colors.white.withValues(alpha: 0.75);

    final Color macdColor = Colors.blueAccent.withValues(alpha: 0.95);

    final Color signalColor = Colors.orange.withValues(alpha: 0.95);

    final Color histogramColor = histogramValue >= 0
        ? Colors.greenAccent.withValues(alpha: 0.95)
        : Colors.redAccent.withValues(alpha: 0.95);

    // ============================================================
    // TEXT
    // ============================================================

    final TextSpan textSpan = TextSpan(
      children: [
        // --------------------------------------------------------
        // TITLE
        // --------------------------------------------------------
        TextSpan(
          text: 'MACD(12,26,9)  ',
          style: TextStyle(
            color: titleColor,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),

        // --------------------------------------------------------
        // MACD
        // --------------------------------------------------------
        TextSpan(
          text: 'MACD: ${_formatMACD(macdValue)}',
          style: TextStyle(
            color: macdColor,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),

        // --------------------------------------------------------
        // SPACE
        // --------------------------------------------------------
        TextSpan(
          text: '    ',
          style: TextStyle(color: titleColor, fontSize: 9),
        ),

        // --------------------------------------------------------
        // SIGNAL
        // --------------------------------------------------------
        TextSpan(
          text: 'Signal: ${_formatMACD(signalValue)}',
          style: TextStyle(
            color: signalColor,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),

        // --------------------------------------------------------
        // SPACE
        // --------------------------------------------------------
        TextSpan(
          text: '    ',
          style: TextStyle(color: titleColor, fontSize: 9),
        ),

        // --------------------------------------------------------
        // HISTOGRAM
        // --------------------------------------------------------
        TextSpan(
          text: 'Hist: ${_formatMACD(histogramValue)}',
          style: TextStyle(
            color: histogramColor,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();

    // ============================================================
    // Giống Volume:
    //
    // tp.paint(
    //   canvas,
    //   Offset(6, volumeTopY + 2),
    // );
    // ============================================================

    textPainter.paint(canvas, Offset(6, macdTopY + 2));
  }

  // ==============================================================
  // FORMAT MACD
  // ==============================================================

  String _formatMACD(double value) {
    final double absValue = value.abs();

    if (absValue >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (absValue >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
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

  void _drawMACDRightLabels({
    required Canvas canvas,
    required Size size,
    required double macdTopY,
    required double macdChartHeight,
    required double maxValue,
    required double minValue,
    required double zeroY,
    required double? currentMACD,
    required double? currentSignal,
    required double Function(double) valueToY,
  }) {
    const double rightOffset = 2.0;
    const double paddingX = 4.0;
    const double paddingY = 1.0;

    // ============================================================
    // LABEL THƯỜNG: MAX / 0 / MIN
    // ============================================================

    void drawNormalLabel(String text, double y) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // Số nằm sát mép phải, nhưng vẫn trong canvas.
      final double x = size.width - textPainter.width - rightOffset;

      double safeY = y;

      safeY = safeY.clamp(
        macdTopY,
        macdTopY + macdChartHeight - textPainter.height,
      );

      textPainter.paint(canvas, Offset(x, safeY));
    }

    // MAX
    drawNormalLabel(_formatMACD(maxValue), macdTopY + 1);

    // ZERO
    drawNormalLabel('0', zeroY - 5);

    // MIN
    drawNormalLabel(_formatMACD(minValue), macdTopY + macdChartHeight - 11);

    // ============================================================
    // CURRENT MACD LABEL
    // ============================================================

    if (currentMACD != null) {
      _drawMACDCurrentRightLabel(
        canvas: canvas,
        size: size,
        value: currentMACD,
        y: valueToY(currentMACD),
        macdTopY: macdTopY,
        macdChartHeight: macdChartHeight,
        color: Colors.blueAccent,
        paddingX: paddingX,
        paddingY: paddingY,
      );
    }

    // ============================================================
    // CURRENT SIGNAL LABEL
    // ============================================================

    if (currentSignal != null) {
      double signalY = valueToY(currentSignal);

      // Nếu MACD và Signal quá gần nhau,
      // đẩy Signal xuống một chút để không đè chữ.
      if (currentMACD != null) {
        final double macdY = valueToY(currentMACD);

        if ((signalY - macdY).abs() < 14) {
          if (signalY >= macdY) {
            signalY += 14;
          } else {
            signalY -= 14;
          }
        }
      }

      _drawMACDCurrentRightLabel(
        canvas: canvas,
        size: size,
        value: currentSignal,
        y: signalY,
        macdTopY: macdTopY,
        macdChartHeight: macdChartHeight,
        color: Colors.orange,
        paddingX: paddingX,
        paddingY: paddingY,
      );
    }
  }

  void _drawMACDCurrentRightLabel({
    required Canvas canvas,
    required Size size,
    required double value,
    required double y,
    required double macdTopY,
    required double macdChartHeight,
    required Color color,
    required double paddingX,
    required double paddingY,
  }) {
    final String text = _formatMACD(value);

    final TextPainter textPainter = TextPainter(
      text: const TextSpan(),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    );

    textPainter.layout();

    final double boxWidth = textPainter.width + paddingX * 2;

    final double boxHeight = textPainter.height + paddingY * 2;

    // ============================================================
    // X: sát mép phải
    // ============================================================

    const double rightShift = 35.0;
    final double x = size.width - boxWidth + rightShift;

    // ============================================================
    // Y
    // ============================================================

    double safeY = y - boxHeight / 2;

    safeY = safeY.clamp(macdTopY, macdTopY + macdChartHeight - boxHeight);

    // ============================================================
    // BACKGROUND
    // ============================================================

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, safeY, boxWidth, boxHeight),
      const Radius.circular(3),
    );

    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.75));

    // ============================================================
    // TEXT
    // ============================================================

    textPainter.paint(canvas, Offset(x + paddingX, safeY + paddingY));
  }
}
