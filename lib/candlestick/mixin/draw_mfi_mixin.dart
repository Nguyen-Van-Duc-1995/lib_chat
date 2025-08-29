import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chart/model/indicator_point.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/indicator_calculator.dart';

mixin DrawMFIMixin {
  void drawMFILine({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required double mfiChartHeight,
    required double mfiTopY,
    required int period,
  }) {
    final List<IndicatorPoint> mfiPoints = IndicatorCalculator.calculateMFI(
      klines,
      period,
    );
    final List<double> mfiValues = mfiPoints.map((e) => e.value).toList();

    if (mfiValues.isEmpty) return;

    final double lastMFI = mfiValues.last;
    final double yMFI = mfiTopY + (100 - lastMFI) / 100 * mfiChartHeight;

    _drawGridForMFI(
      canvas: canvas,
      size: size,
      mfiTopY: mfiTopY,
      mfiChartHeight: mfiChartHeight,
      klines: klines,
    );

    final path = Path();
    final mfiPaint = Paint()
      ..color = Color(0xff7350AF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final candleWidthWithSpacing = candleWidth + spacing;
    final spacingX = candleWidthWithSpacing * 0.3;

    // Tính toạ độ ngưỡng
    final y20 = mfiTopY + (100 - 20) / 100 * mfiChartHeight;
    final y80 = mfiTopY + (100 - 80) / 100 * mfiChartHeight;

    // Tô nền vùng trung tính 20–80
    final fillRect = Rect.fromLTRB(0, y80, size.width, y20);
    canvas.drawRect(
      fillRect,
      Paint()
        ..color = Colors.orangeAccent.withOpacity(0.05)
        ..style = PaintingStyle.fill,
    );

    // Vẽ các đường ngưỡng
    final thresholdPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(0, y20),
      Offset(size.width, y20),
      thresholdPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, y80),
      Offset(size.width, y80),
      thresholdPaint,
    );

    _drawMFILabel(canvas, size, y20, '20.00');
    _drawMFILabel(canvas, size, y80, '80.00');
    _drawCurrentMFIValue(canvas, size, yMFI, lastMFI);

    final Path overboughtPath = Path();
    final Path oversoldPath = Path();
    bool started = false, overStarted = false, underStarted = false;

    for (int i = 0; i < mfiValues.length; i++) {
      int index = i + period;
      if (index >= klines.length) break;

      final double x = index * candleWidthWithSpacing - scrollX + spacingX / 2;
      if (x + candleWidth < 0 || x > size.width) continue;

      final double mfi = mfiValues[i];
      final double y = mfiTopY + (100 - mfi) / 100 * mfiChartHeight;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }

      // Tô vùng > 80
      if (mfi > 80) {
        if (!overStarted) {
          overboughtPath.moveTo(x, y80);
          overboughtPath.lineTo(x, y);
          overStarted = true;
        } else {
          overboughtPath.lineTo(x, y);
        }
      } else if (overStarted) {
        overboughtPath.lineTo(x, y80);
        overboughtPath.close();
        canvas.drawPath(
          overboughtPath,
          Paint()
            ..color = Colors.red.withOpacity(0.12)
            ..style = PaintingStyle.fill,
        );
        overboughtPath.reset();
        overStarted = false;
      }

      // Tô vùng < 20
      if (mfi < 20) {
        if (!underStarted) {
          oversoldPath.moveTo(x, y20);
          oversoldPath.lineTo(x, y);
          underStarted = true;
        } else {
          oversoldPath.lineTo(x, y);
        }
      } else if (underStarted) {
        oversoldPath.lineTo(x, y20);
        oversoldPath.close();
        canvas.drawPath(
          oversoldPath,
          Paint()
            ..color = Colors.green.withOpacity(0.12)
            ..style = PaintingStyle.fill,
        );
        oversoldPath.reset();
        underStarted = false;
      }
    }

    if (overStarted) {
      overboughtPath.lineTo(size.width, y80);
      overboughtPath.close();
      canvas.drawPath(
        overboughtPath,
        Paint()
          ..color = Colors.red.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
    }
    if (underStarted) {
      oversoldPath.lineTo(size.width, y20);
      oversoldPath.close();
      canvas.drawPath(
        oversoldPath,
        Paint()
          ..color = Colors.green.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(path, mfiPaint);
  }

  void _drawMFILabel(Canvas canvas, Size size, double y, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = size.width - textPainter.width - 4 + 45;
    final dy = y - textPainter.height / 2;

    textPainter.paint(canvas, Offset(dx, dy));
  }

  void _drawCurrentMFIValue(Canvas canvas, Size size, double y, double value) {
    final text = value.toStringAsFixed(2);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingX = 4, paddingY = 1;
    final double boxWidth = textPainter.width + paddingX * 2;
    final double boxHeight = textPainter.height + paddingY * 2;
    final double dx = size.width - boxWidth + 35;
    final double dy = y - boxHeight / 2 + 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, boxWidth, boxHeight),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.purple.withOpacity(0.7),
    );

    textPainter.paint(canvas, Offset(dx + paddingX, dy + paddingY));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 4,
  }) {
    final dx = end.dx - start.dx, dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final dashCount = distance / (dashWidth + gapWidth);
    final xStep = dx / dashCount;
    final yStep = dy / dashCount;
    double currentX = start.dx, currentY = start.dy;

    for (int i = 0; i < dashCount; i++) {
      final xEnd = currentX + xStep * (dashWidth / (dashWidth + gapWidth));
      final yEnd = currentY + yStep * (dashWidth / (dashWidth + gapWidth));
      canvas.drawLine(Offset(currentX, currentY), Offset(xEnd, yEnd), paint);
      currentX += xStep;
      currentY += yStep;
    }
  }

  void _drawGridForMFI({
    required Canvas canvas,
    required Size size,
    required double mfiTopY,
    required double mfiChartHeight,
    required List<KlineData> klines,
  }) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 1; i++) {
      final y = mfiTopY + (mfiChartHeight / 1) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    if (klines.length > 20) {
      for (int i = 0; i <= 4; i++) {
        final x = (size.width / 4) * i;
        canvas.drawLine(
          Offset(x, mfiTopY),
          Offset(x, mfiTopY + mfiChartHeight),
          paint,
        );
      }
    }
  }
}
