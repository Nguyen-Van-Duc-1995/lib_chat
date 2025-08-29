import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/indicator_calculator.dart';
import '../../model/ichimoku_data.dart';

class CloudPoint {
  final Offset offset;
  final int dataIndex;
  final double spanAValue;
  final double spanBValue;

  CloudPoint({
    required this.offset,
    required this.dataIndex,
    required this.spanAValue,
    required this.spanBValue,
  });
}

mixin DrawIchimokuMixin {
  void drawIchimoku({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double maxPrice,
    required double minPrice,
    required double chartHeight,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required Function(double, double) priceToY,
    int tenkanPeriod = 9,
    int kijunPeriod = 26,
    int senkouSpanBPeriod = 52,
    int displacement = 26,
  }) {
    if (klines.isEmpty) return;

    final ichimokuData = IndicatorCalculator.calculateIchimoku(
      klines,
      tenkanPeriod: tenkanPeriod,
      kijunPeriod: kijunPeriod,
      senkouSpanBPeriod: senkouSpanBPeriod,
      displacement: displacement,
    );

    if (ichimokuData.isEmpty) return;

    final candleWidthWithSpacing = candleWidth + spacing;

    // Colors for Ichimoku lines - corrected to match TradingView standard
    final tenkanColor = Color(
      0xFFFF6B9D,
    ); // Pink for Tenkan-sen (Conversion Line)
    final kijunColor = Color(
      0xFF4FC3F7,
    ); // Light Blue for Kijun-sen (Base Line)
    final chikouColor = Color(
      0xFF66BB6A,
    ); // Green for Chikou Span (Lagging Span)
    final cloudBullishColor = Color(
      0xFF4CAF50,
    ).withOpacity(0.2); // Green cloud when Span A > Span B
    final cloudBearishColor = Color(
      0xFF8D4E85,
    ).withOpacity(0.2); // Brown/Purple cloud when Span A < Span B

    // Paint objects
    final tenkanPaint = Paint()
      ..color = tenkanColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final kijunPaint = Paint()
      ..color = kijunColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final chikouPaint = Paint()
      ..color = chikouColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Paths for lines
    final tenkanPath = Path();
    final kijunPath = Path();
    final chikouPath = Path();
    final senkouSpanAPath = Path();
    final senkouSpanBPath = Path();

    bool tenkanStarted = false;
    bool kijunStarted = false;
    bool chikouStarted = false;
    bool senkouAStarted = false;
    bool senkouBStarted = false;

    // Lists to store cloud points for filling with corresponding data
    List<CloudPoint> cloudPointsA = [];
    List<CloudPoint> cloudPointsB = [];

    // Only extend cloud when we're near the end of data (optimization)
    final bool shouldExtendCloud =
        scrollX > (ichimokuData.length - 50) * candleWidthWithSpacing;
    final int futureExtension = shouldExtendCloud ? displacement : 0;

    // First pass: collect all cloud points including displaced ones
    for (int i = 0; i < ichimokuData.length; i++) {
      final data = ichimokuData[i];

      // For Senkou Spans - these are displaced FORWARD by 26 periods
      final futureIndex = i + displacement;
      if (data.senkouSpanA > 0 && data.senkouSpanB > 0) {
        final double futureX =
            futureIndex * candleWidthWithSpacing - scrollX + spacing / 2;

        // Add cloud points even beyond the last candle (for future projection)
        if (futureX >= -100 && futureX <= size.width + 200) {
          final yA = priceToY(data.senkouSpanA, chartHeight);
          final yB = priceToY(data.senkouSpanB, chartHeight);

          cloudPointsA.add(
            CloudPoint(
              offset: Offset(futureX, yA),
              dataIndex: i,
              spanAValue: data.senkouSpanA,
              spanBValue: data.senkouSpanB,
            ),
          );
          cloudPointsB.add(
            CloudPoint(
              offset: Offset(futureX, yB),
              dataIndex: i,
              spanAValue: data.senkouSpanA,
              spanBValue: data.senkouSpanB,
            ),
          );
        }
      }
    }

    // Add future extension points (repeat last values into the future)
    if (shouldExtendCloud &&
        ichimokuData.isNotEmpty &&
        cloudPointsA.isNotEmpty) {
      final lastData = ichimokuData.last;
      if (lastData.senkouSpanA > 0 && lastData.senkouSpanB > 0) {
        for (int i = 1; i <= futureExtension; i++) {
          final futureIndex = ichimokuData.length - 1 + displacement + i;
          final futureX =
              futureIndex * candleWidthWithSpacing - scrollX + spacing / 2;

          if (futureX <= size.width + 200) {
            final yA = priceToY(lastData.senkouSpanA, chartHeight);
            final yB = priceToY(lastData.senkouSpanB, chartHeight);

            cloudPointsA.add(
              CloudPoint(
                offset: Offset(futureX, yA),
                dataIndex: ichimokuData.length - 1,
                spanAValue: lastData.senkouSpanA,
                spanBValue: lastData.senkouSpanB,
              ),
            );
            cloudPointsB.add(
              CloudPoint(
                offset: Offset(futureX, yB),
                dataIndex: ichimokuData.length - 1,
                spanAValue: lastData.senkouSpanA,
                spanBValue: lastData.senkouSpanB,
              ),
            );
          }
        }
      }
    }

    // Draw the cloud first (so it appears behind other lines)
    _drawIchimokuCloud(
      canvas,
      cloudPointsA,
      cloudPointsB,
      cloudBullishColor,
      cloudBearishColor,
    );

    // Second pass: draw the lines
    for (int i = 0; i < ichimokuData.length; i++) {
      final data = ichimokuData[i];
      final double x = i * candleWidthWithSpacing - scrollX + spacing / 2;

      // Skip if outside visible area for line drawing
      if (x + candleWidth < -50 || x > size.width + 50) continue;

      // Draw Tenkan-sen (Conversion Line)
      if (data.tenkanSen > 0 && i >= tenkanPeriod - 1) {
        final y = priceToY(data.tenkanSen, chartHeight);
        if (!tenkanStarted) {
          tenkanPath.moveTo(x, y);
          tenkanStarted = true;
        } else {
          tenkanPath.lineTo(x, y);
        }
      }

      // Draw Kijun-sen (Base Line)
      if (data.kijunSen > 0 && i >= kijunPeriod - 1) {
        final y = priceToY(data.kijunSen, chartHeight);
        if (!kijunStarted) {
          kijunPath.moveTo(x, y);
          kijunStarted = true;
        } else {
          kijunPath.lineTo(x, y);
        }
      }

      // Draw Chikou Span (Lagging Span) - displaced backwards by 26 periods
      final chikouIndex = i - displacement;
      if (chikouIndex >= 0 && chikouIndex < klines.length) {
        final chikouX =
            chikouIndex * candleWidthWithSpacing - scrollX + spacing / 2;
        if (chikouX >= -50 && chikouX <= size.width + 50) {
          final y = priceToY(data.chikouSpan, chartHeight);
          if (!chikouStarted) {
            chikouPath.moveTo(chikouX, y);
            chikouStarted = true;
          } else {
            chikouPath.lineTo(chikouX, y);
          }
        }
      }

      // Draw Senkou Spans (Leading Spans) - displaced forward by 26 periods
      final senkouIndex = i + displacement;
      if (data.senkouSpanA > 0 && data.senkouSpanB > 0) {
        final senkouX =
            senkouIndex * candleWidthWithSpacing - scrollX + spacing / 2;

        // Draw Senkou spans even beyond the current data (into future)
        if (senkouX >= -50 && senkouX <= size.width + 200) {
          final yA = priceToY(data.senkouSpanA, chartHeight);
          final yB = priceToY(data.senkouSpanB, chartHeight);

          // Draw Senkou Span A path
          if (!senkouAStarted) {
            senkouSpanAPath.moveTo(senkouX, yA);
            senkouAStarted = true;
          } else {
            senkouSpanAPath.lineTo(senkouX, yA);
          }

          // Draw Senkou Span B path
          if (!senkouBStarted) {
            senkouSpanBPath.moveTo(senkouX, yB);
            senkouBStarted = true;
          } else {
            senkouSpanBPath.lineTo(senkouX, yB);
          }
        }
      }
    }

    // Extend Senkou Span lines into the future (repeat last values)
    if (ichimokuData.isNotEmpty) {
      final lastData = ichimokuData.last;
      if (lastData.senkouSpanA > 0 && lastData.senkouSpanB > 0) {
        for (int i = 1; i <= displacement; i++) {
          final futureIndex = ichimokuData.length - 1 + displacement + i;
          final futureX =
              futureIndex * candleWidthWithSpacing - scrollX + spacing / 2;

          if (futureX <= size.width + 200) {
            final yA = priceToY(lastData.senkouSpanA, chartHeight);
            final yB = priceToY(lastData.senkouSpanB, chartHeight);

            senkouSpanAPath.lineTo(futureX, yA);
            senkouSpanBPath.lineTo(futureX, yB);
          }
        }
      }
    }

    // Draw Senkou Span lines with different colors for A and B
    final senkouSpanAPaint = Paint()
      ..color = Color(0xFF4CAF50)
          .withOpacity(0.7) // Green for Senkou Span A
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final senkouSpanBPaint = Paint()
      ..color = Color(0xFFFF7043)
          .withOpacity(0.7) // Light Red for Senkou Span B
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawPath(senkouSpanAPath, senkouSpanAPaint);
    canvas.drawPath(senkouSpanBPath, senkouSpanBPaint);

    // Draw main lines
    canvas.drawPath(tenkanPath, tenkanPaint);
    canvas.drawPath(kijunPath, kijunPaint);
    canvas.drawPath(chikouPath, chikouPaint);

    // Draw current values labels
    if (ichimokuData.isNotEmpty) {
      final lastData = ichimokuData.last;
      _drawIchimokuLabels(canvas, size, lastData, priceToY, chartHeight);
    }
  }

  void _drawIchimokuCloud(
    Canvas canvas,
    List<CloudPoint> pointsA,
    List<CloudPoint> pointsB,
    Color bullishColor,
    Color bearishColor,
  ) {
    if (pointsA.length < 2 ||
        pointsB.length < 2 ||
        pointsA.length != pointsB.length)
      return;

    // Draw cloud segments with proper color logic based on actual data values
    for (int i = 0; i < pointsA.length - 1; i++) {
      final pointA1 = pointsA[i];
      final pointA2 = pointsA[i + 1];
      final pointB1 = pointsB[i];
      final pointB2 = pointsB[i + 1];

      // Color determination: Green when Span A > Span B, Brown when Span A < Span B
      final bool isBullish = pointA1.spanAValue > pointA1.spanBValue;
      final color = isBullish ? bullishColor : bearishColor;

      // Create path for this segment
      final path = Path();
      path.moveTo(pointA1.offset.dx, pointA1.offset.dy);
      path.lineTo(pointA2.offset.dx, pointA2.offset.dy);
      path.lineTo(pointB2.offset.dx, pointB2.offset.dy);
      path.lineTo(pointB1.offset.dx, pointB1.offset.dy);
      path.close();

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  void _drawIchimokuLabels(
    Canvas canvas,
    Size size,
    IchimokuData data,
    Function(double, double) priceToY,
    double chartHeight,
  ) {
    const double paddingX = 4.0;
    const double paddingY = 2.0;
    const double rightMargin = 45.0;

    // Labels data with corrected colors
    final labels = [
      {
        'text': 'T: ${data.tenkanSen.toStringAsFixed(2)}',
        'color': Color(0xFFFF6B9D), // Pink for Tenkan
        'value': data.tenkanSen,
      },
      {
        'text': 'K: ${data.kijunSen.toStringAsFixed(2)}',
        'color': Color(0xFF4FC3F7), // Light Blue for Kijun
        'value': data.kijunSen,
      },
      {
        'text': 'C: ${data.chikouSpan.toStringAsFixed(2)}',
        'color': Color(0xFF66BB6A), // Green for Chikou
        'value': data.chikouSpan,
      },
    ];

    for (final label in labels) {
      if (label['value'] as double <= 0) continue;

      final text = label['text'] as String;
      final color = label['color'] as Color;
      final value = label['value'] as double;

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final boxWidth = textPainter.width + paddingX * 2;
      final boxHeight = textPainter.height + paddingY * 2;

      final y = priceToY(value, chartHeight);
      final dx = size.width - boxWidth + rightMargin;
      final dy = y - boxHeight / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, boxWidth, boxHeight),
        const Radius.circular(3),
      );

      final bgPaint = Paint()..color = color.withOpacity(0.8);
      canvas.drawRRect(rect, bgPaint);

      textPainter.paint(canvas, Offset(dx + paddingX, dy + paddingY));
    }
  }
}
