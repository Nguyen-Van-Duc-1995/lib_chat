import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/indicator_calculator.dart';
import '../../model/ichimoku_data.dart';

// ================================================================
// CLOUD POINT
// ================================================================

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

// ================================================================
// LABEL POINT
//
// Lưu giá trị + vị trí X của điểm ngoài cùng bên phải đang hiển thị.
// ================================================================

class IchimokuLabelPoint {
  final double x;
  final double value;

  IchimokuLabelPoint({required this.x, required this.value});
}

// ================================================================
// DRAW ICHIMOKU
// ================================================================

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

    // Project của bạn đang dùng:
    // double _priceToY(double price, double chartHeight)
    required double Function(double, double) priceToY,

    int tenkanPeriod = 9,
    int kijunPeriod = 26,
    int senkouSpanBPeriod = 52,
    int displacement = 26,

    // ============================================================
    // LỀ PHẢI ICHIMOKU
    // ============================================================
    double rightPadding = 0.0,
  }) {
    if (klines.isEmpty) {
      return;
    }

    if (chartHeight <= 0) {
      return;
    }

    // ============================================================
    // 1. CALCULATE ICHIMOKU
    // ============================================================

    final List<IchimokuData> ichimokuData =
        IndicatorCalculator.calculateIchimoku(
          klines,
          tenkanPeriod: tenkanPeriod,
          kijunPeriod: kijunPeriod,
          senkouSpanBPeriod: senkouSpanBPeriod,
          displacement: displacement,
        );

    if (ichimokuData.isEmpty) {
      return;
    }

    // ============================================================
    // 2. X SETTINGS
    // ============================================================

    final double candleWidthWithSpacing = candleWidth + spacing;

    // Giữ đúng cách tính X của code hiện tại.
    final double xOffset = spacing / 2;

    // ============================================================
    // 3. MÉP PHẢI ICHIMOKU
    //
    // Ví dụ:
    //
    // |-----------------------------|----------|
    // |        ICHIMOKU             |   50px   |
    // |-----------------------------|----------|
    //
    // ============================================================

    final double ichimokuRight = size.width > rightPadding
        ? size.width - rightPadding
        : 0.0;

    // ============================================================
    // 4. COLORS
    // ============================================================

    const Color tenkanColor = Color(0xFFFF6B9D);

    const Color kijunColor = Color(0xFF4FC3F7);

    const Color chikouColor = Color(0xFF66BB6A);

    const Color senkouAColor = Color(0xFF4CAF50);

    const Color senkouBColor = Color(0xFFFF7043);

    final Color cloudBullishColor = const Color(
      0xFF4CAF50,
    ).withValues(alpha: 0.20);

    final Color cloudBearishColor = const Color(
      0xFF8D4E85,
    ).withValues(alpha: 0.20);

    // ============================================================
    // 5. PAINTS
    // ============================================================

    final Paint tenkanPaint = Paint()
      ..color = tenkanColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint kijunPaint = Paint()
      ..color = kijunColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint chikouPaint = Paint()
      ..color = chikouColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint senkouSpanAPaint = Paint()
      ..color = senkouAColor.withValues(alpha: 0.70)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint senkouSpanBPaint = Paint()
      ..color = senkouBColor.withValues(alpha: 0.70)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // ============================================================
    // 6. PATHS
    // ============================================================

    final Path tenkanPath = Path();
    final Path kijunPath = Path();
    final Path chikouPath = Path();

    final Path senkouSpanAPath = Path();
    final Path senkouSpanBPath = Path();

    bool tenkanStarted = false;
    bool kijunStarted = false;
    bool chikouStarted = false;

    bool senkouAStarted = false;
    bool senkouBStarted = false;

    // ============================================================
    // 7. CLOUD POINTS
    // ============================================================

    final List<CloudPoint> cloudPointsA = [];
    final List<CloudPoint> cloudPointsB = [];

    // ============================================================
    // 8. BUILD CLOUD DATA
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final IchimokuData data = ichimokuData[i];

      if (data.senkouSpanA <= 0 || data.senkouSpanB <= 0) {
        continue;
      }

      // Senkou tiến về trước displacement.
      final int senkouIndex = i + displacement;

      final double senkouX =
          senkouIndex * candleWidthWithSpacing - scrollX + xOffset;

      // ----------------------------------------------------------
      // Quá xa bên trái
      // ----------------------------------------------------------

      if (senkouX < -100) {
        continue;
      }

      // ----------------------------------------------------------
      // Quá xa bên phải.
      //
      // Có buffer để segment cuối được nối tới mép clip.
      // ----------------------------------------------------------

      if (senkouX > ichimokuRight + 100) {
        break;
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
    // 9. BẮT ĐẦU CLIP ICHIMOKU
    //
    // Cloud + tất cả đường chỉ được vẽ tới:
    //
    // size.width - rightPadding
    // ============================================================

    canvas.save();

    canvas.clipRect(Rect.fromLTRB(0, 0, ichimokuRight, chartHeight));

    // ============================================================
    // 10. DRAW CLOUD
    // ============================================================

    _drawIchimokuCloud(
      canvas,
      cloudPointsA,
      cloudPointsB,
      cloudBullishColor,
      cloudBearishColor,
    );

    // ============================================================
    // 11. BUILD LINES
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final IchimokuData data = ichimokuData[i];

      final double x = i * candleWidthWithSpacing - scrollX + xOffset;

      // ==========================================================
      // TENKAN-SEN
      // ==========================================================

      if (data.tenkanSen > 0 && i >= tenkanPeriod - 1) {
        if (x >= -50 && x <= ichimokuRight + 50) {
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
        if (x >= -50 && x <= ichimokuRight + 50) {
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
      // Chikou lùi về phía sau displacement.
      // ==========================================================

      final int chikouIndex = i - displacement;

      if (chikouIndex >= 0 &&
          chikouIndex < klines.length &&
          data.chikouSpan > 0) {
        final double chikouX =
            chikouIndex * candleWidthWithSpacing - scrollX + xOffset;

        if (chikouX >= -50 && chikouX <= ichimokuRight + 50) {
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
      // SENKOU A + B
      //
      // Tiến về phía trước displacement.
      // ==========================================================

      if (data.senkouSpanA > 0 && data.senkouSpanB > 0) {
        final int senkouIndex = i + displacement;

        final double senkouX =
            senkouIndex * candleWidthWithSpacing - scrollX + xOffset;

        if (senkouX >= -50 && senkouX <= ichimokuRight + 100) {
          final double yA = priceToY(data.senkouSpanA, chartHeight);

          final double yB = priceToY(data.senkouSpanB, chartHeight);

          // ------------------------------------------------------
          // SENKOU A
          // ------------------------------------------------------

          if (!senkouAStarted) {
            senkouSpanAPath.moveTo(senkouX, yA);

            senkouAStarted = true;
          } else {
            senkouSpanAPath.lineTo(senkouX, yA);
          }

          // ------------------------------------------------------
          // SENKOU B
          // ------------------------------------------------------

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
    // 12. DRAW SENKOU
    // ============================================================

    canvas.drawPath(senkouSpanAPath, senkouSpanAPaint);

    canvas.drawPath(senkouSpanBPath, senkouSpanBPaint);

    // ============================================================
    // 13. DRAW MAIN LINES
    // ============================================================

    canvas.drawPath(tenkanPath, tenkanPaint);

    canvas.drawPath(kijunPath, kijunPaint);

    canvas.drawPath(chikouPath, chikouPaint);

    // ============================================================
    // 14. END CLIP
    //
    // Labels sẽ được vẽ sau restore.
    // Vì vậy chúng có thể nằm trong vùng rightPadding.
    // ============================================================

    canvas.restore();

    // ============================================================
    // 15. LABELS CHẠY THEO ĐƯỜNG
    //
    // KHÔNG dùng:
    //
    // ichimokuData.last
    //
    // nữa.
    //
    // Tìm điểm ngoài cùng bên phải hiện đang hiển thị.
    // Khi scroll -> value thay đổi -> Y thay đổi -> label chạy.
    // ============================================================

    _drawVisibleIchimokuLabels(
      canvas: canvas,
      size: size,
      ichimokuData: ichimokuData,
      candleWidthWithSpacing: candleWidthWithSpacing,
      xOffset: xOffset,
      scrollX: scrollX,
      chartHeight: chartHeight,
      ichimokuRight: ichimokuRight,
      displacement: displacement,
      tenkanPeriod: tenkanPeriod,
      kijunPeriod: kijunPeriod,
      priceToY: priceToY,

      tenkanColor: tenkanColor,
      kijunColor: kijunColor,
      chikouColor: chikouColor,
      senkouAColor: senkouAColor,
      senkouBColor: senkouBColor,
    );
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

      // ==========================================================
      // Không nối cloud xuyên vùng thiếu dữ liệu.
      // ==========================================================

      if (pointA2.dataIndex != pointA1.dataIndex + 1 ||
          pointB2.dataIndex != pointB1.dataIndex + 1) {
        continue;
      }

      // ==========================================================
      // CLOUD COLOR
      // ==========================================================

      final bool isBullish = pointA1.spanAValue > pointA1.spanBValue;

      final Color color = isBullish ? bullishColor : bearishColor;

      // ==========================================================
      // CLOUD SEGMENT
      // ==========================================================

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
  // LABELS ĐANG HIỂN THỊ
  //
  // Tìm point ngoài cùng bên phải của từng đường.
  // ==============================================================

  void _drawVisibleIchimokuLabels({
    required Canvas canvas,
    required Size size,
    required List<IchimokuData> ichimokuData,
    required double candleWidthWithSpacing,
    required double xOffset,
    required double scrollX,
    required double chartHeight,
    required double ichimokuRight,
    required int displacement,
    required int tenkanPeriod,
    required int kijunPeriod,
    required double Function(double, double) priceToY,
    required Color tenkanColor,
    required Color kijunColor,
    required Color chikouColor,
    required Color senkouAColor,
    required Color senkouBColor,
  }) {
    if (ichimokuData.isEmpty) {
      return;
    }

    // ============================================================
    // POINT NGOÀI CÙNG BÊN PHẢI
    // ============================================================

    IchimokuLabelPoint? tenkanPoint;
    IchimokuLabelPoint? kijunPoint;
    IchimokuLabelPoint? chikouPoint;
    IchimokuLabelPoint? senkouAPoint;
    IchimokuLabelPoint? senkouBPoint;

    // ============================================================
    // TENKAN + KIJUN
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final IchimokuData data = ichimokuData[i];

      final double x = i * candleWidthWithSpacing - scrollX + xOffset;

      // Bên trái màn hình.
      if (x < 0) {
        continue;
      }

      // Qua vùng Ichimoku bên phải.
      if (x > ichimokuRight) {
        break;
      }

      // ----------------------------------------------------------
      // TENKAN
      // ----------------------------------------------------------

      if (i >= tenkanPeriod - 1 && data.tenkanSen > 0) {
        tenkanPoint = IchimokuLabelPoint(x: x, value: data.tenkanSen);
      }

      // ----------------------------------------------------------
      // KIJUN
      // ----------------------------------------------------------

      if (i >= kijunPeriod - 1 && data.kijunSen > 0) {
        kijunPoint = IchimokuLabelPoint(x: x, value: data.kijunSen);
      }
    }

    // ============================================================
    // CHIKOU
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final IchimokuData data = ichimokuData[i];

      if (data.chikouSpan <= 0) {
        continue;
      }

      final int chikouIndex = i - displacement;

      if (chikouIndex < 0) {
        continue;
      }

      final double chikouX =
          chikouIndex * candleWidthWithSpacing - scrollX + xOffset;

      if (chikouX < 0) {
        continue;
      }

      if (chikouX > ichimokuRight) {
        break;
      }

      chikouPoint = IchimokuLabelPoint(x: chikouX, value: data.chikouSpan);
    }

    // ============================================================
    // SENKOU A + B
    //
    // X phải cộng displacement giống lúc vẽ đường.
    // ============================================================

    for (int i = 0; i < ichimokuData.length; i++) {
      final IchimokuData data = ichimokuData[i];

      if (data.senkouSpanA <= 0 || data.senkouSpanB <= 0) {
        continue;
      }

      final int senkouIndex = i + displacement;

      final double senkouX =
          senkouIndex * candleWidthWithSpacing - scrollX + xOffset;

      if (senkouX < 0) {
        continue;
      }

      if (senkouX > ichimokuRight) {
        break;
      }

      senkouAPoint = IchimokuLabelPoint(x: senkouX, value: data.senkouSpanA);

      senkouBPoint = IchimokuLabelPoint(x: senkouX, value: data.senkouSpanB);
    }

    // ============================================================
    // DRAW LABELS
    //
    // Mỗi label:
    // - value lấy tại point hiện đang nhìn thấy.
    // - Y lấy đúng từ value của đường.
    // - X nằm ngay sau point cuối.
    // ============================================================

    if (tenkanPoint != null) {
      _drawIchimokuLineLabel(
        canvas: canvas,
        size: size,
        point: tenkanPoint,
        chartHeight: chartHeight,
        priceToY: priceToY,
        prefix: 'T',
        color: tenkanColor,
      );
    }

    if (kijunPoint != null) {
      _drawIchimokuLineLabel(
        canvas: canvas,
        size: size,
        point: kijunPoint,
        chartHeight: chartHeight,
        priceToY: priceToY,
        prefix: 'K',
        color: kijunColor,
      );
    }

    if (chikouPoint != null) {
      _drawIchimokuLineLabel(
        canvas: canvas,
        size: size,
        point: chikouPoint,
        chartHeight: chartHeight,
        priceToY: priceToY,
        prefix: 'C',
        color: chikouColor,
      );
    }

    if (senkouAPoint != null) {
      _drawIchimokuLineLabel(
        canvas: canvas,
        size: size,
        point: senkouAPoint,
        chartHeight: chartHeight,
        priceToY: priceToY,
        prefix: 'A',
        color: senkouAColor,
      );
    }

    if (senkouBPoint != null) {
      _drawIchimokuLineLabel(
        canvas: canvas,
        size: size,
        point: senkouBPoint,
        chartHeight: chartHeight,
        priceToY: priceToY,
        prefix: 'B',
        color: senkouBColor,
      );
    }
  }

  // ==============================================================
  // DRAW 1 LABEL TRÊN ĐƯỜNG
  // ==============================================================

  void _drawIchimokuLineLabel({
    required Canvas canvas,
    required Size size,
    required IchimokuLabelPoint point,
    required double chartHeight,
    required double Function(double, double) priceToY,
    required String prefix,
    required Color color,
  }) {
    // ============================================================
    // TEXT
    // ============================================================

    final String text = '$prefix: ${point.value.toStringAsFixed(2)}';

    const TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // ============================================================
    // BOX SIZE
    // ============================================================

    const double paddingX = 4.0;
    const double paddingY = 2.0;

    final double boxWidth = textPainter.width + paddingX * 2;
    final double boxHeight = textPainter.height + paddingY * 2;

    // ============================================================
    // Y BÁM THEO ĐƯỜNG
    //
    // Value vẫn lấy theo point ngoài cùng đang hiển thị.
    // Khi scroll -> value thay đổi -> Y thay đổi theo.
    // ============================================================

    final double y = priceToY(point.value, chartHeight);

    // ============================================================
    // X CỐ ĐỊNH Ở MÉP PHẢI
    //
    // Chỉ thay đổi phần này so với code cũ.
    // Không dùng point.x + 4 nữa.
    // ============================================================

    final double dx = size.width - boxWidth + 45;

    // ============================================================
    // VERTICAL POSITION
    // ============================================================

    double dy = y - boxHeight / 2;

    // Không vượt top.
    if (dy < 0) {
      dy = 0;
    }

    // Không vượt bottom chart.
    if (dy + boxHeight > chartHeight) {
      dy = chartHeight - boxHeight;
    }

    // ============================================================
    // RECT
    // ============================================================

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, boxWidth, boxHeight),
      const Radius.circular(3),
    );

    // ============================================================
    // BACKGROUND
    // ============================================================

    final Paint bgPaint = Paint()..color = color.withValues(alpha: 0.85);

    canvas.drawRRect(rect, bgPaint);

    // ============================================================
    // TEXT
    // ============================================================

    textPainter.paint(canvas, Offset(dx + paddingX, dy + paddingY));
  }
}
