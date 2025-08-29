import 'dart:ui';
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
    final double candleWidthWithSpacing = candleWidth + spacing;
    final int lastIndex = klines.length - 1;
    final double x = lastIndex * candleWidthWithSpacing - scrollX + spacing / 2;

    if (x + candleWidth < 0 || x > size.width) return;

    final double price = lastCandle.close;
    final double y = priceToY(price, chartHeight);
    final bool isBullish = lastCandle.close >= lastCandle.open;
    final Color priceColor = isBullish
        ? AppColors.priceUp
        : AppColors.priceDown;

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

    const double lineLength = 4;
    const double paddingH = 4;
    const double paddingV = 1;

    final double rectLeft = x + candleWidth / 2 + lineLength + 2;
    final double rectTop = y - tp.height / 2 - paddingV;
    final double rectRight = rectLeft + tp.width + paddingH * 2;
    final double rectBottom = y + tp.height / 2 + paddingV;

    final RRect backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
      const Radius.circular(4),
    );

    canvas.drawLine(
      Offset(x + candleWidth / 2, y),
      Offset(x + candleWidth / 2 + lineLength, y),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1,
    );

    canvas.drawRRect(
      backgroundRect,
      Paint()..color = priceColor.withOpacity(0.7),
    );

    tp.paint(canvas, Offset(rectLeft + paddingH, y - tp.height / 2));
  }
}
