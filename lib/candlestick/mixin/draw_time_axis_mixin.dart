import 'package:flutter/material.dart';
import 'package:chart/model/kline_data.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

mixin DrawTimeAxisMixin {
  void drawTimeAxis({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double candleWidth,
    required double spacing,
    required double scrollX,
    required double timeAxisHeight,
    required double timeAxisTopY,
  }) {
    if (klines.isEmpty) return;

    final textStyle = TextStyle(
      color: Colors.grey[400],
      fontSize: 10,
      fontWeight: FontWeight.w400,
    );

    final double candleWidthWithSpacing = candleWidth + spacing;

    // Tính toán khoảng cách tối thiểu giữa các label (khoảng 80-100px)
    const double minLabelSpacing = 80.0;

    // Tính step dựa trên khoảng cách pixel thay vì số lượng label cố định
    final int step = (minLabelSpacing / candleWidthWithSpacing).ceil().clamp(
      1,
      50,
    );

    // Tìm index của candle đầu tiên hiển thị (với buffer để labels không bị cắt đột ngột)
    final int startIndex = ((scrollX - 100) / candleWidthWithSpacing)
        .floor()
        .clamp(0, klines.length - 1);

    final int endIndex = ((scrollX + size.width + 100) / candleWidthWithSpacing)
        .ceil()
        .clamp(0, klines.length - 1);

    if (startIndex >= endIndex) return;

    // Tạo danh sách tất cả các index có thể hiển thị với step cố định
    List<int> allPossibleIndices = [];

    // Bắt đầu từ một index được align với step để đảm bảo consistency
    final int alignedStart = (startIndex / step).floor() * step;

    for (int i = alignedStart; i <= endIndex; i += step) {
      if (i >= 0 && i < klines.length) {
        allPossibleIndices.add(i);
      }
    }

    // Vẽ tất cả các label có thể, kể cả những cái nằm ngoài màn hình một chút
    for (int index in allPossibleIndices) {
      final klineData = klines[index];
      final String timeText = _formatDateTime(klineData.dateTime);

      // Tính toán vị trí X thực của candle (theo hệ tọa độ chart)
      final double realCandleX =
          index * candleWidthWithSpacing + candleWidth / 2;

      // Tính toán vị trí X hiển thị trên màn hình (sau khi trừ scroll)
      final double displayCandleX = realCandleX - scrollX;

      // Tạo TextPainter để đo kích thước text
      final textPainter = TextPainter(
        text: TextSpan(text: timeText, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      // Tính toán vị trí text để căn giữa theo candle
      final double textX = displayCandleX - textPainter.width / 2;
      final double textY =
          timeAxisTopY + (timeAxisHeight - textPainter.height) / 2;

      // Vẽ text (cho phép vẽ cả bên ngoài bounds để di chuyển mượt mà)
      textPainter.paint(canvas, Offset(textX, textY));

      // Vẽ tick mark nhỏ ở đầu time axis
      final tickPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 0.5;

      // Vẽ tick mark tại vị trí chính xác của candle
      canvas.drawLine(
        Offset(displayCandleX, timeAxisTopY),
        Offset(displayCandleX, timeAxisTopY + 3),
        tickPaint,
      );
    }

    // Vẽ đường viền trên của time axis
    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(0, timeAxisTopY),
      Offset(size.width, timeAxisTopY),
      borderPaint,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Nếu trong cùng ngày
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    }
    // Nếu trong tuần này
    else if (difference.inDays < 7) {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
    // Nếu trong năm này
    else if (dateTime.year == now.year) {
      return DateFormat('MM-dd').format(dateTime);
    }
    // Nếu khác năm
    else {
      return DateFormat('yy-MM-dd').format(dateTime);
    }
  }
}

// Extension để dễ dàng sử dụng với các timeframe khác nhau
extension TimeAxisFormatting on DrawTimeAxisMixin {
  String formatTimeByInterval(DateTime dateTime, String interval) {
    switch (interval.toLowerCase()) {
      case '1m':
      case '5m':
      case '15m':
      case '30m':
        return DateFormat('HH:mm').format(dateTime);
      case '1h':
      case '2h':
      case '4h':
        return DateFormat('MM-dd HH:mm').format(dateTime);
      case '1d':
        return DateFormat('MM-dd').format(dateTime);
      case '1w':
      case '1mo':
        return DateFormat('yy-MM').format(dateTime);
      default:
        return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }
}
