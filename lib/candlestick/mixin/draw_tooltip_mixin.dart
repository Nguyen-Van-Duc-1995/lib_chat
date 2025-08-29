import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chart/model/kline_data.dart';

mixin DrawTooltipMixin {
  void drawTooltip({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required int? hoveredCandleIndex,
    required double scrollX,
    required double candleWidth,
    required double spacing,
  }) {
    if (hoveredCandleIndex == null ||
        hoveredCandleIndex < 0 ||
        hoveredCandleIndex >= klines.length)
      return;

    final kline = klines[hoveredCandleIndex];
    final candleWidthWithSpacing = candleWidth + spacing;
    final double x =
        hoveredCandleIndex * candleWidthWithSpacing - scrollX + spacing / 2;

    if (x + candleWidth < 0 || x > size.width) return;

    const double y = 0;
    final bool isRightSide = x < size.width / 2;

    const double tooltipWidth = 140.0;
    const double tooltipHeight = 100.0;
    const double padding = 8.0;
    final double rectLeft = isRightSide ? size.width - tooltipWidth - 6 : 6.0;
    final double rectTop = max(0, y - tooltipHeight / 2);

    final RRect tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectLeft, rectTop, tooltipWidth, tooltipHeight),
      const Radius.circular(6),
    );

    final Paint bgPaint = Paint()..color = Colors.black45.withOpacity(0.7);
    canvas.drawRRect(tooltipRect, bgPaint);

    const TextStyle labelStyle = TextStyle(color: Colors.white70, fontSize: 10);
    const TextStyle valueStyle = TextStyle(color: Colors.white, fontSize: 10);
    final TextPainter tp = TextPainter(textDirection: ui.TextDirection.ltr);

    double dx = rectLeft + padding;
    double dy = rectTop + padding;
    const double labelColWidth = 40;

    void drawRow(String label, String value) {
      tp.text = TextSpan(text: label, style: labelStyle);
      tp.layout(maxWidth: labelColWidth);
      tp.paint(canvas, Offset(dx, dy));

      tp.text = TextSpan(text: value, style: valueStyle);
      tp.layout(maxWidth: tooltipWidth - labelColWidth - padding * 2 - 4);
      tp.paint(
        canvas,
        Offset(rectLeft + tooltipWidth - padding - tp.width, dy),
      );

      dy += tp.height + 4;
    }

    drawRow('Ngày', DateFormat('yyyy-MM-dd HH:mm').format(kline.dateTime));
    drawRow('Mở', kline.open.toStringAsFixed(2));
    drawRow('Cao', kline.high.toStringAsFixed(2));
    drawRow('Thấp', kline.low.toStringAsFixed(2));
    drawRow('Đóng', kline.close.toStringAsFixed(2));
    drawRow('±', (kline.close - kline.open).toStringAsFixed(2));
  }
}
