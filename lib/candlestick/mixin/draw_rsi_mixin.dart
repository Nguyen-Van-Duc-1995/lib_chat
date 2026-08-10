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
    if (klines.isEmpty) return;

    // =========================================================
    // 1. TÍNH RSI
    // =========================================================
    final List<double> closes = klines.map((e) => e.close).toList();

    final List<double> rsiValues = IndicatorCalculator.calculateRSI(
      closes,
      period,
    );

    if (rsiValues.isEmpty) return;

    // Khoảng cách giữa 2 cây nến
    final double candleWidthWithSpacing = candleWidth + spacing;

    // Giữ nguyên cách tính vị trí X như code cũ
    final double spacingX = candleWidthWithSpacing * 0.3;

    // =========================================================
    // 2. VẼ GRID
    // =========================================================
    _drawGridForRSI(
      canvas: canvas,
      size: size,
      rsiTopY: rsiTopY,
      rsiChartHeight: rsiChartHeight,
      klines: klines,
    );

    // =========================================================
    // 3. TÍNH ĐƯỜNG 30 / 70
    // =========================================================
    final double y30 = rsiTopY + (100 - 30) / 100 * rsiChartHeight;

    final double y70 = rsiTopY + (100 - 70) / 100 * rsiChartHeight;

    // =========================================================
    // 4. VẼ NỀN VÙNG 30 - 70
    // =========================================================
    final fillRect = Rect.fromLTRB(0, y70, size.width, y30);

    final fillPaint = Paint()
      ..color = const Color.fromARGB(255, 221, 208, 244).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    canvas.drawRect(fillRect, fillPaint);

    // =========================================================
    // 5. VẼ ĐƯỜNG 30 / 70
    // =========================================================
    final thresholdPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
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

    // =========================================================
    // 6. TÌM RSI CUỐI CÙNG ĐANG HIỂN THỊ
    //
    // Đây là phần quan trọng:
    // KHÔNG dùng rsiValues.last.
    //
    // Khi scroll chart, tìm cây RSI ngoài cùng bên phải
    // đang nằm trên màn hình.
    // =========================================================
    double? currentVisibleRSI;

    for (int i = 0; i < rsiValues.length; i++) {
      final int candleIndex = i + period;

      if (candleIndex >= klines.length) {
        break;
      }

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacingX / 2;

      // Cây RSI đang nhìn thấy trên màn hình
      if (x + candleWidth >= 0 && x <= size.width) {
        currentVisibleRSI = rsiValues[i];
      }

      // Vì X tăng dần nên nếu vượt quá màn hình
      // thì không cần kiểm tra tiếp
      if (x > size.width) {
        break;
      }
    }

    // =========================================================
    // 7. VẼ Ô GIÁ TRỊ RSI HIỆN TẠI
    // =========================================================
    if (currentVisibleRSI != null) {
      final double yCurrentRSI =
          rsiTopY + (100 - currentVisibleRSI) / 100 * rsiChartHeight;

      _drawCurrentRSIValue(canvas, size, yCurrentRSI, currentVisibleRSI);
    }

    // =========================================================
    // 8. PAINT ĐƯỜNG RSI
    // =========================================================
    final Path rsiPath = Path();

    final Paint rsiPaint = Paint()
      ..color = const Color(0xff7350AF)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    bool started = false;

    // =========================================================
    // 9. BIẾN DÙNG CHO FILL OVERBOUGHT / OVERSOLD
    // =========================================================
    final List<Offset> overboughtPoints = [];
    final List<Offset> oversoldPoints = [];

    bool inOverbought = false;
    bool inOversold = false;

    // =========================================================
    // 10. TÌM ĐIỂM RSI ĐẦU TIÊN ĐANG HIỂN THỊ
    //
    // Dùng để fill đúng khi vùng >70 hoặc <30 bắt đầu
    // từ trước mép trái màn hình.
    // =========================================================
    int firstVisibleIndex = -1;
    double firstVisibleRSI = 0;

    for (int i = 0; i < rsiValues.length; i++) {
      final int candleIndex = i + period;

      if (candleIndex >= klines.length) {
        break;
      }

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacingX / 2;

      if (x + candleWidth >= 0) {
        firstVisibleIndex = i;
        firstVisibleRSI = rsiValues[i];
        break;
      }
    }

    // =========================================================
    // 11. NẾU VÙNG >70 BẮT ĐẦU TRƯỚC MÉP TRÁI
    // =========================================================
    if (firstVisibleIndex >= 0 && firstVisibleRSI > 70) {
      inOverbought = true;

      overboughtPoints.add(Offset(0, y70));

      overboughtPoints.add(
        Offset(0, rsiTopY + (100 - firstVisibleRSI) / 100 * rsiChartHeight),
      );
    }

    // =========================================================
    // 12. NẾU VÙNG <30 BẮT ĐẦU TRƯỚC MÉP TRÁI
    // =========================================================
    if (firstVisibleIndex >= 0 && firstVisibleRSI < 30) {
      inOversold = true;

      oversoldPoints.add(Offset(0, y30));

      oversoldPoints.add(
        Offset(0, rsiTopY + (100 - firstVisibleRSI) / 100 * rsiChartHeight),
      );
    }

    // =========================================================
    // 13. DUYỆT RSI ĐỂ VẼ
    // =========================================================
    for (int i = 0; i < rsiValues.length; i++) {
      final int candleIndex = i + period;

      if (candleIndex >= klines.length) {
        break;
      }

      final double x =
          candleIndex * candleWidthWithSpacing - scrollX + spacingX / 2;

      final double rsi = rsiValues[i];

      // RSI nằm hoàn toàn bên trái màn hình
      if (x + candleWidth < 0) {
        continue;
      }

      // RSI vượt khỏi cạnh phải
      if (x > size.width) {
        break;
      }

      final double y = rsiTopY + (100 - rsi) / 100 * rsiChartHeight;

      // =======================================================
      // VẼ LINE RSI
      // =======================================================
      if (!started) {
        rsiPath.moveTo(x, y);
        started = true;
      } else {
        rsiPath.lineTo(x, y);
      }

      // =======================================================
      // OVERBOUGHT: RSI > 70
      // =======================================================
      if (rsi > 70) {
        if (!inOverbought) {
          inOverbought = true;
          overboughtPoints.clear();

          if (i > 0) {
            final int prevIndex = i - 1;
            final int prevCandleIndex = prevIndex + period;

            if (prevCandleIndex < klines.length) {
              final double prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;

              final double prevRSI = rsiValues[prevIndex];

              // Đi từ <=70 lên >70
              if (prevRSI <= 70) {
                final double deltaRSI = rsi - prevRSI;

                if (deltaRSI != 0) {
                  final double ratio = (70 - prevRSI) / deltaRSI;

                  final double intersectionX = prevX + (x - prevX) * ratio;

                  overboughtPoints.add(Offset(intersectionX, y70));
                }
              }
            }
          } else {
            overboughtPoints.add(Offset(x, y70));
          }
        }

        overboughtPoints.add(Offset(x, y));
      } else {
        // =====================================================
        // RSI từ >70 xuống <=70
        // =====================================================
        if (inOverbought) {
          if (i > 0) {
            final int prevIndex = i - 1;
            final int prevCandleIndex = prevIndex + period;

            if (prevCandleIndex < klines.length) {
              final double prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;

              final double prevRSI = rsiValues[prevIndex];

              if (prevRSI > 70) {
                final double deltaRSI = rsi - prevRSI;

                if (deltaRSI != 0) {
                  final double ratio = (70 - prevRSI) / deltaRSI;

                  final double intersectionX = prevX + (x - prevX) * ratio;

                  overboughtPoints.add(Offset(intersectionX, y70));
                }
              }
            }
          } else {
            overboughtPoints.add(Offset(x, y70));
          }

          _drawFillArea(
            canvas,
            overboughtPoints,
            Colors.green.withValues(alpha: 0.3),
          );

          inOverbought = false;
          overboughtPoints.clear();
        }
      }

      // =======================================================
      // OVERSOLD: RSI < 30
      // =======================================================
      if (rsi < 30) {
        if (!inOversold) {
          inOversold = true;
          oversoldPoints.clear();

          if (i > 0) {
            final int prevIndex = i - 1;
            final int prevCandleIndex = prevIndex + period;

            if (prevCandleIndex < klines.length) {
              final double prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;

              final double prevRSI = rsiValues[prevIndex];

              // Đi từ >=30 xuống <30
              if (prevRSI >= 30) {
                final double deltaRSI = rsi - prevRSI;

                if (deltaRSI != 0) {
                  final double ratio = (30 - prevRSI) / deltaRSI;

                  final double intersectionX = prevX + (x - prevX) * ratio;

                  oversoldPoints.add(Offset(intersectionX, y30));
                }
              }
            }
          } else {
            oversoldPoints.add(Offset(x, y30));
          }
        }

        oversoldPoints.add(Offset(x, y));
      } else {
        // =====================================================
        // RSI từ <30 lên >=30
        // =====================================================
        if (inOversold) {
          if (i > 0) {
            final int prevIndex = i - 1;
            final int prevCandleIndex = prevIndex + period;

            if (prevCandleIndex < klines.length) {
              final double prevX =
                  prevCandleIndex * candleWidthWithSpacing -
                  scrollX +
                  spacingX / 2;

              final double prevRSI = rsiValues[prevIndex];

              if (prevRSI < 30) {
                final double deltaRSI = rsi - prevRSI;

                if (deltaRSI != 0) {
                  final double ratio = (30 - prevRSI) / deltaRSI;

                  final double intersectionX = prevX + (x - prevX) * ratio;

                  oversoldPoints.add(Offset(intersectionX, y30));
                }
              }
            }
          } else {
            oversoldPoints.add(Offset(x, y30));
          }

          _drawFillArea(
            canvas,
            oversoldPoints,
            const Color(0xff541F2C).withValues(alpha: 0.3),
          );

          inOversold = false;
          oversoldPoints.clear();
        }
      }
    }

    // =========================================================
    // 14. ĐÓNG VÙNG OVERBOUGHT Ở MÉP PHẢI
    // =========================================================
    if (inOverbought && overboughtPoints.isNotEmpty) {
      overboughtPoints.add(Offset(size.width, y70));

      _drawFillArea(
        canvas,
        overboughtPoints,
        Colors.green.withValues(alpha: 0.3),
      );
    }

    // =========================================================
    // 15. ĐÓNG VÙNG OVERSOLD Ở MÉP PHẢI
    // =========================================================
    if (inOversold && oversoldPoints.isNotEmpty) {
      oversoldPoints.add(Offset(size.width, y30));

      _drawFillArea(
        canvas,
        oversoldPoints,
        const Color(0xff541F2C).withValues(alpha: 0.3),
      );
    }

    // =========================================================
    // 16. VẼ ĐƯỜNG RSI CUỐI CÙNG
    // =========================================================
    if (started) {
      canvas.drawPath(rsiPath, rsiPaint);
    }
  }

  // ===========================================================
  // DRAW FILL AREA
  // ===========================================================
  void _drawFillArea(Canvas canvas, List<Offset> points, Color color) {
    if (points.length < 3) return;

    final Path path = Path();

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    path.close();

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  // ===========================================================
  // LABEL 30 / 70
  // ===========================================================
  void _drawRSILabel(Canvas canvas, Size size, double y, String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingRight = 4.0;

    // Không cộng +45 nữa để label không chạy ra ngoài
    final double dx = size.width - textPainter.width - paddingRight;

    final double dy = y - textPainter.height / 2;

    textPainter.paint(canvas, Offset(dx, dy));
  }

  // ===========================================================
  // DASHED LINE
  // ===========================================================
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

    if (distance <= 0) return;

    final double dashCount = distance / (dashWidth + gapWidth);

    if (dashCount <= 0) return;

    final double xStep = dx / dashCount;

    final double yStep = dy / dashCount;

    double currentX = start.dx;
    double currentY = start.dy;

    for (int i = 0; i < dashCount; i++) {
      final double xEnd =
          currentX + xStep * (dashWidth / (dashWidth + gapWidth));

      final double yEnd =
          currentY + yStep * (dashWidth / (dashWidth + gapWidth));

      canvas.drawLine(Offset(currentX, currentY), Offset(xEnd, yEnd), paint);

      currentX += xStep;
      currentY += yStep;
    }
  }

  // ===========================================================
  // GRID RSI
  // ===========================================================
  void _drawGridForRSI({
    required Canvas canvas,
    required Size size,
    required double rsiTopY,
    required double rsiChartHeight,
    required List<KlineData> klines,
  }) {
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // ---------------------------------------------------------
    // Horizontal grid
    // ---------------------------------------------------------
    const int horizontalLines = 1;

    for (int i = 0; i <= horizontalLines; i++) {
      final double y = rsiTopY + (rsiChartHeight / horizontalLines) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ---------------------------------------------------------
    // Vertical grid
    // ---------------------------------------------------------
    const int verticalLines = 4;

    if (klines.length > verticalLines * 5) {
      for (int i = 0; i <= verticalLines; i++) {
        final double x = (size.width / verticalLines) * i;

        canvas.drawLine(
          Offset(x, rsiTopY),
          Offset(x, rsiTopY + rsiChartHeight),
          gridPaint,
        );
      }
    }
  }

  // ===========================================================
  // CURRENT RSI VALUE
  // ===========================================================
  void _drawCurrentRSIValue(Canvas canvas, Size size, double y, double value) {
    final String text = value.toStringAsFixed(2);

    const TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingX = 4.0;
    const double paddingY = 1.0;

    final double boxWidth = textPainter.width + paddingX * 2;

    final double boxHeight = textPainter.height + paddingY * 2;

    // Ô RSI nằm sát mép phải.
    // Không +35 để tránh bị lệch ra ngoài.
    final double dx = size.width - boxWidth + 35;

    final double dy = y - boxHeight / 2;

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, boxWidth, boxHeight),
      const Radius.circular(4),
    );

    final Paint bgPaint = Paint()..color = Colors.purple.withValues(alpha: 0.7);

    canvas.drawRRect(rect, bgPaint);

    textPainter.paint(canvas, Offset(dx + paddingX, dy + paddingY));
  }
}
