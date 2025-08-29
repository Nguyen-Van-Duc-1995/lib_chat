import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/indicator_calculator.dart';

mixin DrawRSIMixin {
  void drawRSILine({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required double rsiChartHeight,
    required double rsiTopY,
    required int period,
  }) {
    List<double> closes = klines.map((e) => e.close).toList();
    List<double> rsiValues = IndicatorCalculator.calculateRSI(closes, period);
    if (rsiValues.isEmpty) return;

    final double lastRSI = rsiValues.last;
    final double yRSI = rsiTopY + (100 - lastRSI) / 100 * rsiChartHeight;

    _drawGridForRSI(
      canvas: canvas,
      size: size,
      rsiTopY: rsiTopY,
      rsiChartHeight: rsiChartHeight,
      klines: klines,
    );

    // Các thông số vẽ
    final path = Path();
    final rsiPaint = Paint()
      ..color = Color(0xff7350AF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final candleWidthWithSpacing = candleWidth + spacing;
    final double spacingX = candleWidthWithSpacing * 0.3;

    // Tính ngưỡng 30 và 70 theo toạ độ
    final y30 = rsiTopY + (100 - 30) / 100 * rsiChartHeight;
    final y70 = rsiTopY + (100 - 70) / 100 * rsiChartHeight;

    // Vẽ nền vùng 30–70
    final fillRect = Rect.fromLTRB(0, y70, size.width, y30);
    final fillPaint = Paint()
      ..color = Color.fromARGB(255, 221, 208, 244).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(fillRect, fillPaint);

    // Vẽ các đường ngưỡng 30 và 70
    final thresholdPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(0, y30),
      Offset(size.width, y30),
      thresholdPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, y70),
      Offset(size.width, y70),
      thresholdPaint,
    );
    _drawRSILabel(canvas, size, y30, '30.00');
    _drawRSILabel(canvas, size, y70, '70.00');
    _drawCurrentRSIValue(canvas, size, yRSI, lastRSI);

    // Khởi tạo vẽ RSI
    bool started = false;

    // Danh sách để lưu các điểm cho vùng fill
    List<Offset> overboughtPoints = [];
    List<Offset> oversoldPoints = [];
    bool inOverbought = false;
    bool inOversold = false;

    // Tìm điểm đầu tiên hiển thị trên màn hình để xử lý fill từ đầu
    int firstVisibleIndex = -1;
    double firstVisibleX = 0;
    double firstVisibleRSI = 0;

    for (int i = 0; i < rsiValues.length; i++) {
      final int candleIndex = i + period;
      if (candleIndex >= klines.length) break;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacingX / 2;

      if (x + candleWidth >= 0) {
        firstVisibleIndex = i;
        firstVisibleX = x;
        firstVisibleRSI = rsiValues[i];
        break;
      }
    }

    // Nếu điểm đầu tiên đã trong vùng overbought/oversold, khởi tạo fill từ cạnh trái
    if (firstVisibleIndex >= 0) {
      if (firstVisibleRSI > 70) {
        inOverbought = true;
        overboughtPoints.add(Offset(0, y70)); // Bắt đầu từ cạnh trái màn hình
        overboughtPoints.add(
          Offset(0, rsiTopY + (100 - firstVisibleRSI) / 100 * rsiChartHeight),
        );
      }

      if (firstVisibleRSI < 30) {
        inOversold = true;
        oversoldPoints.add(Offset(0, y30)); // Bắt đầu từ cạnh trái màn hình
        oversoldPoints.add(
          Offset(0, rsiTopY + (100 - firstVisibleRSI) / 100 * rsiChartHeight),
        );
      }
    }

    for (int i = 0; i < rsiValues.length; i++) {
      final int candleIndex = i + period;
      if (candleIndex >= klines.length) break;

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacingX / 2;
      final double rsi = rsiValues[i];

      if (x + candleWidth < 0) continue;
      if (x > size.width) break;

      final double y = rsiTopY + (100 - rsi) / 100 * rsiChartHeight;

      // Vẽ đường RSI
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }

      // Xử lý vùng overbought (RSI > 70)
      if (rsi > 70) {
        if (!inOverbought) {
          // Bắt đầu vùng overbought mới
          inOverbought = true;
          overboughtPoints.clear();

          // Nếu có điểm trước đó, tìm điểm giao với đường 70
          if (i > 0 && i - 1 >= 0) {
            final prevIndex = i - 1;
            final prevCandleIndex = prevIndex + period;
            if (prevCandleIndex < klines.length) {
              final prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;
              final prevRSI = rsiValues[prevIndex];

              if (prevRSI <= 70) {
                // Tính điểm giao với đường 70
                final intersectionX =
                    prevX + (x - prevX) * (70 - prevRSI) / (rsi - prevRSI);
                overboughtPoints.add(Offset(intersectionX, y70));
              }
            }
          } else {
            overboughtPoints.add(Offset(x, y70));
          }
        }
        overboughtPoints.add(Offset(x, y));
      } else {
        if (inOverbought) {
          // Tính điểm giao với đường 70 khi thoát vùng overbought
          if (i > 0) {
            final prevIndex = i - 1;
            final prevCandleIndex = prevIndex + period;
            if (prevCandleIndex < klines.length) {
              final prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;
              final prevRSI = rsiValues[prevIndex];

              if (prevRSI > 70) {
                final intersectionX =
                    prevX + (x - prevX) * (70 - prevRSI) / (rsi - prevRSI);
                overboughtPoints.add(Offset(intersectionX, y70));
              }
            }
          } else {
            overboughtPoints.add(Offset(x, y70));
          }

          _drawFillArea(
            canvas,
            overboughtPoints,
            Colors.green.withOpacity(0.3),
          );
          inOverbought = false;
          overboughtPoints.clear();
        }
      }

      // Xử lý vùng oversold (RSI < 30)
      if (rsi < 30) {
        if (!inOversold) {
          // Bắt đầu vùng oversold mới
          inOversold = true;
          oversoldPoints.clear();

          // Nếu có điểm trước đó, tìm điểm giao với đường 30
          if (i > 0 && i - 1 >= 0) {
            final prevIndex = i - 1;
            final prevCandleIndex = prevIndex + period;
            if (prevCandleIndex < klines.length) {
              final prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;
              final prevRSI = rsiValues[prevIndex];

              if (prevRSI >= 30) {
                // Tính điểm giao với đường 30
                final intersectionX =
                    prevX + (x - prevX) * (30 - prevRSI) / (rsi - prevRSI);
                oversoldPoints.add(Offset(intersectionX, y30));
              }
            }
          } else {
            oversoldPoints.add(Offset(x, y30));
          }
        }
        oversoldPoints.add(Offset(x, y));
      } else {
        if (inOversold) {
          // Tính điểm giao với đường 30 khi thoát vùng oversold
          if (i > 0) {
            final prevIndex = i - 1;
            final prevCandleIndex = prevIndex + period;
            if (prevCandleIndex < klines.length) {
              final prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;
              final prevRSI = rsiValues[prevIndex];

              if (prevRSI < 30) {
                final intersectionX =
                    prevX + (x - prevX) * (30 - prevRSI) / (rsi - prevRSI);
                oversoldPoints.add(Offset(intersectionX, y30));
              }
            }
          } else {
            oversoldPoints.add(Offset(x, y30));
          }

          _drawFillArea(
            canvas,
            oversoldPoints,
            Color(0xff541F2C).withOpacity(0.3),
          );
          inOversold = false;
          oversoldPoints.clear();
        }
      }
    }

    // Xử lý các vùng chưa đóng ở cuối
    if (inOverbought && overboughtPoints.isNotEmpty) {
      overboughtPoints.add(Offset(size.width, y70));
      _drawFillArea(canvas, overboughtPoints, Colors.green.withOpacity(0.3));
    }

    if (inOversold && oversoldPoints.isNotEmpty) {
      oversoldPoints.add(Offset(size.width, y30));
      _drawFillArea(canvas, oversoldPoints, Color(0xff541F2C).withOpacity(0.3));
    }

    // Vẽ đường RSI cuối cùng
    canvas.drawPath(path, rsiPaint);
  }

  void _drawFillArea(Canvas canvas, List<Offset> points, Color color) {
    if (points.length < 3) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawRSILabel(Canvas canvas, Size size, double y, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingRight = 4.0;
    final dx = size.width - textPainter.width - paddingRight + 45;
    final dy = y - textPainter.height / 2;

    textPainter.paint(canvas, Offset(dx, dy));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 4,
  }) {
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double dashCount = distance / (dashWidth + gapWidth);

    final double xStep = dx / dashCount;
    final double yStep = dy / dashCount;

    double currentX = start.dx;
    double currentY = start.dy;

    for (int i = 0; i < dashCount; ++i) {
      final xEnd = currentX + xStep * (dashWidth / (dashWidth + gapWidth));
      final yEnd = currentY + yStep * (dashWidth / (dashWidth + gapWidth));
      canvas.drawLine(Offset(currentX, currentY), Offset(xEnd, yEnd), paint);
      currentX += xStep;
      currentY += yStep;
    }
  }

  void _drawGridForRSI({
    required Canvas canvas,
    required Size size,
    required double rsiTopY,
    required double rsiChartHeight,
    required List<KlineData> klines,
  }) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Vẽ 1 đường ngang
    const int horizontalLines = 1;
    for (int i = 0; i <= horizontalLines; i++) {
      final y = rsiTopY + (rsiChartHeight / horizontalLines) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vẽ các đường dọc nếu có đủ nến
    const int verticalLines = 4;
    if (klines.length > verticalLines * 5) {
      for (int i = 0; i <= verticalLines; i++) {
        final x = (size.width / verticalLines) * i;
        canvas.drawLine(
          Offset(x, rsiTopY),
          Offset(x, rsiTopY + rsiChartHeight),
          gridPaint,
        );
      }
    }
  }

  void _drawCurrentRSIValue(Canvas canvas, Size size, double y, double value) {
    final text = value.toStringAsFixed(2);
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingX = 4.0;
    const double paddingY = 1.0;

    final double boxWidth = textPainter.width + paddingX * 2;
    final double boxHeight = textPainter.height + paddingY * 2;

    final double dx = size.width - boxWidth + 35;
    final double dy = y - boxHeight / 2 + 1;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, boxWidth, boxHeight),
      const Radius.circular(4),
    );

    final bgPaint = Paint()..color = Colors.purple.withOpacity(0.7);
    canvas.drawRRect(rect, bgPaint);

    textPainter.paint(canvas, Offset(dx + paddingX, dy + paddingY));
  }
}
