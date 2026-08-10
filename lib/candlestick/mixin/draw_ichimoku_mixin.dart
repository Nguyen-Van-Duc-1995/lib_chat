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

    final double candleWidthWithSpacing = candleWidth + spacing;

    // ============================================================
    // COLORS
    // ============================================================

    final tenkanColor = const Color(0xFFFF6B9D);
    final kijunColor = const Color(0xFF4FC3F7);
    final chikouColor = const Color(0xFF66BB6A);

    final cloudBullishColor = const Color(0xFF4CAF50).withValues(alpha: 0.2);

    final cloudBearishColor = const Color(0xFF8D4E85).withValues(alpha: 0.2);

    // ============================================================
    // PAINTS
    // ============================================================

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

    final senkouSpanAPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.7)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final senkouSpanBPaint = Paint()
      ..color = const Color(0xFFFF7043).withValues(alpha: 0.7)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // ============================================================
    // PATHS
    // ============================================================

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

    // ============================================================
    // CLOUD POINTS
    // ============================================================

    final List<CloudPoint> cloudPointsA = [];
    final List<CloudPoint> cloudPointsB = [];

    // ============================================================
    // BUILD CLOUD
    //
    // QUAN TRỌNG:
    // Senkou Span chỉ được đẩy về phía trước đúng `displacement`.
    //
    // Ví dụ:
    // candle cuối = N
    // cloud cuối  = N + 26
    //
    // Không extend tiếp N + 27 ... N + 52.
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final data = ichimokuData[i];

      if (data.senkouSpanA <= 0 || data.senkouSpanB <= 0) {
        continue;
      }

      final int senkouIndex = i + displacement;

      final double senkouX =
          senkouIndex * candleWidthWithSpacing - scrollX + spacing / 2;

      // Buffer ngoài màn hình một chút để path không bị cắt đột ngột.
      // Đây KHÔNG phải là extend thêm dữ liệu.
      if (senkouX < -100 || senkouX > size.width + 200) {
        continue;
      }

      final double yA = priceToY(data.senkouSpanA, chartHeight);

      final double yB = priceToY(data.senkouSpanB, chartHeight);

      cloudPointsA.add(
        CloudPoint(
          offset: Offset(senkouX, yA),
          dataIndex: i,
          spanAValue: data.senkouSpanA,
          spanBValue: data.senkouSpanB,
        ),
      );

      cloudPointsB.add(
        CloudPoint(
          offset: Offset(senkouX, yB),
          dataIndex: i,
          spanAValue: data.senkouSpanA,
          spanBValue: data.senkouSpanB,
        ),
      );
    }

    // ============================================================
    // DRAW CLOUD FIRST
    // ============================================================

    _drawIchimokuCloud(
      canvas,
      cloudPointsA,
      cloudPointsB,
      cloudBullishColor,
      cloudBearishColor,
    );

    // ============================================================
    // DRAW ICHIMOKU LINES
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final data = ichimokuData[i];

      final double x = i * candleWidthWithSpacing - scrollX + spacing / 2;

      // ==========================================================
      // TENKAN-SEN
      // ==========================================================

      if (data.tenkanSen > 0 && i >= tenkanPeriod - 1) {
        if (x >= -50 && x <= size.width + 50) {
          final double y = priceToY(data.tenkanSen, chartHeight);

          if (!tenkanStarted) {
            tenkanPath.moveTo(x, y);
            tenkanStarted = true;
          } else {
            tenkanPath.lineTo(x, y);
          }
        }
      }

      // ==========================================================
      // KIJUN-SEN
      // ==========================================================

      if (data.kijunSen > 0 && i >= kijunPeriod - 1) {
        if (x >= -50 && x <= size.width + 50) {
          final double y = priceToY(data.kijunSen, chartHeight);

          if (!kijunStarted) {
            kijunPath.moveTo(x, y);
            kijunStarted = true;
          } else {
            kijunPath.lineTo(x, y);
          }
        }
      }

      // ==========================================================
      // CHIKOU SPAN
      //
      // Lùi về phía sau `displacement`.
      // ==========================================================

      final int chikouIndex = i - displacement;

      if (chikouIndex >= 0 &&
          chikouIndex < klines.length &&
          data.chikouSpan > 0) {
        final double chikouX =
            chikouIndex * candleWidthWithSpacing - scrollX + spacing / 2;

        if (chikouX >= -50 && chikouX <= size.width + 50) {
          final double y = priceToY(data.chikouSpan, chartHeight);

          if (!chikouStarted) {
            chikouPath.moveTo(chikouX, y);
            chikouStarted = true;
          } else {
            chikouPath.lineTo(chikouX, y);
          }
        }
      }

      // ==========================================================
      // SENKOU SPAN A + B
      //
      // Đẩy về phía trước đúng `displacement`.
      // Không có loop extend thêm sau candle cuối.
      // ==========================================================

      if (data.senkouSpanA > 0 && data.senkouSpanB > 0) {
        final int senkouIndex = i + displacement;

        final double senkouX =
            senkouIndex * candleWidthWithSpacing - scrollX + spacing / 2;

        if (senkouX >= -50 && senkouX <= size.width + 200) {
          final double yA = priceToY(data.senkouSpanA, chartHeight);

          final double yB = priceToY(data.senkouSpanB, chartHeight);

          if (!senkouAStarted) {
            senkouSpanAPath.moveTo(senkouX, yA);
            senkouAStarted = true;
          } else {
            senkouSpanAPath.lineTo(senkouX, yA);
          }

          if (!senkouBStarted) {
            senkouSpanBPath.moveTo(senkouX, yB);
            senkouBStarted = true;
          } else {
            senkouSpanBPath.lineTo(senkouX, yB);
          }
        }
      }
    }

    // ============================================================
    // DRAW SENKOU LINES
    // ============================================================

    canvas.drawPath(senkouSpanAPath, senkouSpanAPaint);

    canvas.drawPath(senkouSpanBPath, senkouSpanBPaint);

    // ============================================================
    // DRAW MAIN LINES
    // ============================================================

    canvas.drawPath(tenkanPath, tenkanPaint);

    canvas.drawPath(kijunPath, kijunPaint);

    canvas.drawPath(chikouPath, chikouPaint);

    // ============================================================
    // LABELS
    // ============================================================

    if (ichimokuData.isNotEmpty) {
      final lastData = ichimokuData.last;

      _drawIchimokuLabels(canvas, size, lastData, priceToY, chartHeight);
    }
  }

  // ==============================================================
  // DRAW CLOUD
  // ==============================================================

  void _drawIchimokuCloud(
    Canvas canvas,
    List<CloudPoint> pointsA,
    List<CloudPoint> pointsB,
    Color bullishColor,
    Color bearishColor,
  ) {
    if (pointsA.length < 2 ||
        pointsB.length < 2 ||
        pointsA.length != pointsB.length) {
      return;
    }

    for (int i = 0; i < pointsA.length - 1; i++) {
      final CloudPoint pointA1 = pointsA[i];
      final CloudPoint pointA2 = pointsA[i + 1];

      final CloudPoint pointB1 = pointsB[i];
      final CloudPoint pointB2 = pointsB[i + 1];

      // Nếu 2 point không liên tiếp trong dữ liệu
      // thì không nối cloud xuyên qua vùng trống.
      if (pointA2.dataIndex != pointA1.dataIndex + 1 ||
          pointB2.dataIndex != pointB1.dataIndex + 1) {
        continue;
      }

      final bool isBullish = pointA1.spanAValue > pointA1.spanBValue;

      final Color color = isBullish ? bullishColor : bearishColor;

      final Path path = Path()
        ..moveTo(pointA1.offset.dx, pointA1.offset.dy)
        ..lineTo(pointA2.offset.dx, pointA2.offset.dy)
        ..lineTo(pointB2.offset.dx, pointB2.offset.dy)
        ..lineTo(pointB1.offset.dx, pointB1.offset.dy)
        ..close();

      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  // ==============================================================
  // DRAW LABELS
  // ==============================================================

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

    final labels = [
      {
        'text': 'T: ${data.tenkanSen.toStringAsFixed(2)}',
        'color': const Color(0xFFFF6B9D),
        'value': data.tenkanSen,
      },
      {
        'text': 'K: ${data.kijunSen.toStringAsFixed(2)}',
        'color': const Color(0xFF4FC3F7),
        'value': data.kijunSen,
      },
      {
        'text': 'C: ${data.chikouSpan.toStringAsFixed(2)}',
        'color': const Color(0xFF66BB6A),
        'value': data.chikouSpan,
      },
    ];

    for (final label in labels) {
      final double value = label['value'] as double;

      if (value <= 0) {
        continue;
      }

      final String text = label['text'] as String;

      final Color color = label['color'] as Color;

      const TextStyle textStyle = TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      );

      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final double boxWidth = textPainter.width + paddingX * 2;

      final double boxHeight = textPainter.height + paddingY * 2;

      final double y = priceToY(value, chartHeight);

      final double dx = size.width - boxWidth + rightMargin;

      final double dy = y - boxHeight / 2;

      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, boxWidth, boxHeight),
        const Radius.circular(3),
      );

      final Paint bgPaint = Paint()..color = color.withValues(alpha: 0.8);

      canvas.drawRRect(rect, bgPaint);

      textPainter.paint(canvas, Offset(dx + paddingX, dy + paddingY));
    }
  }
}
