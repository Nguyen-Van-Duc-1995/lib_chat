import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/format.dart';
import '../../utils/colors.dart';

mixin DrawCurrentPriceMixin {
  void drawCurrentPrice({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required double chartHeight,
    required double Function(double price, double chartHeight) priceToY,
  }) {
    if (klines.isEmpty) return;

    final lastCandle = klines.last;
    final double price = lastCandle.close;
    double y = priceToY(price, chartHeight);
    y = y.clamp(0.0, chartHeight);
    final bool isBullish = lastCandle.close >= lastCandle.open;
    final Color priceColor = isBullish
        ? AppColors.priceUp
        : AppColors.priceDown;

    final Paint dashedPaint = Paint()
      ..color = priceColor
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(0, y),
      Offset(size.width, y),
      dashedPaint,
      dashWidth: 2,
      gapWidth: 4,
    );

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final String priceText = FormatUtils.formatPrice(price);
    final tp = TextPainter(
      text: TextSpan(text: priceText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingH = 4;
    const double paddingV = 1;

    final double rectRight = size.width + 35;
    final double rectLeft = rectRight - tp.width - paddingH * 2;
    final double rectTop = y - tp.height / 2 - paddingV;
    final double rectBottom = y + tp.height / 2 + paddingV;

    final RRect backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      backgroundRect,
      Paint()..color = priceColor.withOpacity(0.7),
    );

    tp.paint(canvas, Offset(rectLeft + paddingH, y - tp.height / 2));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 4,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = distance / (dashWidth + gapWidth);
    final xStep = dx / dashCount;
    final yStep = dy / dashCount;
    double currentX = start.dx;
    double currentY = start.dy;

    for (int i = 0; i < dashCount; i++) {
      final xEnd = currentX + xStep * (dashWidth / (dashWidth + gapWidth));
      final yEnd = currentY + yStep * (dashWidth / (dashWidth + gapWidth));
      canvas.drawLine(Offset(currentX, currentY), Offset(xEnd, yEnd), paint);
      currentX += xStep;
      currentY += yStep;
    }
  }
}
