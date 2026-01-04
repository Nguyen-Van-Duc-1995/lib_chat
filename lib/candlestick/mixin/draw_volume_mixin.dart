import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../model/kline_data.dart';
import '../../utils/colors.dart' show AppColors;

mixin DrawVolumeMixin {
  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      double millions = volume / 1000000;
      return '${millions.toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      double thousands = volume / 1000;
      return '${thousands.toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  List<double?> _calculateSMA(List<double> data, int period) {
    final result = List<double?>.filled(data.length, null);
    if (period <= 0 || data.isEmpty) return result;

    double sum = 0.0;
    for (int i = 0; i < data.length; i++) {
      sum += data[i];
      if (i >= period) sum -= data[i - period];
      if (i >= period - 1) {
        result[i] = sum / period;
      }
    }
    return result;
  }

  void _drawVolumeMALines({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double scrollX,
    required double candleWidth,
    required double spacing,
    required double maxVolume,
    required double volumeAreaHeight,
    required double volumeTopY,
    int ma20Period = 20,
    int ma50Period = 50,
    double strokeWidth = 1.2,
    bool showVolumeMA = true,
  }) {
    if (!showVolumeMA) return;
    if (klines.isEmpty || maxVolume <= 0) return;

    final double candleWidthWithSpacing = candleWidth + spacing;

    final int visibleStartIndex = (scrollX / candleWidthWithSpacing)
        .floor()
        .clamp(0, klines.length - 1);
    final int visibleEndIndex =
        ((scrollX + size.width) / candleWidthWithSpacing).ceil().clamp(
          0,
          klines.length - 1,
        );

    if (visibleEndIndex < visibleStartIndex) return;

    final volumes = klines.map((e) => e.volume).toList(growable: false);

    final ma20 = _calculateSMA(volumes, ma20Period);
    final ma50 = _calculateSMA(volumes, ma50Period);

    double volumeToY(double v) {
      // Giữ đúng cách scale cột volume đang dùng: * 0.9
      final barHeight = (v / (maxVolume + 1e-9)) * volumeAreaHeight * 0.9;
      return volumeTopY + volumeAreaHeight - barHeight;
    }

    final ma20Paint = Paint()
      ..color = Colors.yellow.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ma50Paint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawPath(List<double?> ma, Paint paint) {
      final path = Path();
      bool started = false;

      for (int i = visibleStartIndex; i <= visibleEndIndex; i++) {
        final v = ma[i];
        if (v == null) continue;

        final x =
            i * candleWidthWithSpacing -
            scrollX +
            spacing / 2 +
            candleWidth / 2;
        final y = volumeToY(v);

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }

      if (started) {
        canvas.drawPath(path, paint);
      }
    }

    drawPath(ma20, ma20Paint);
    drawPath(ma50, ma50Paint);
  }

  void drawVolumeBars({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double scrollX,
    required double candleWidth,
    required double spacing,
    required double maxVolume,
    required double volumeAreaHeight,
    required double volumeTopY,
    int? hoveredIndex,
    double? priceChartHeight,

    bool showVolumeMA = true,
    int ma20Period = 20,
    int ma50Period = 50,
    double maStrokeWidth = 0.5,
  }) {
    _drawVolumeGrid(
      canvas: canvas,
      size: size,
      volumeTopY: volumeTopY,
      volumeAreaHeight: volumeAreaHeight,
      klines: klines,
    );

    final double candleWidthWithSpacing = candleWidth + spacing;
    double? minVisibleVolume;
    double? maxVisibleVolume;

    for (int i = 0; i < klines.length; i++) {
      final kline = klines[i];
      final double x = i * candleWidthWithSpacing - scrollX + spacing / 2;

      if (x + candleWidth < 0 || x > size.width) continue;

      final double barHeight =
          (kline.volume / (maxVolume + 1e-9)) * volumeAreaHeight * 0.9;
      final bool isBullish = kline.close >= kline.open;

      final volumePaint = Paint()
        ..color = (isBullish ? AppColors.priceUp : AppColors.priceDown)
            .withOpacity(0.3);

      canvas.drawRect(
        Rect.fromLTRB(
          x,
          volumeTopY + volumeAreaHeight - barHeight,
          x + candleWidth,
          volumeTopY + volumeAreaHeight,
        ),
        volumePaint,
      );

      // Update visible volume range
      minVisibleVolume = minVisibleVolume == null
          ? kline.volume
          : (kline.volume < minVisibleVolume ? kline.volume : minVisibleVolume);
      maxVisibleVolume = maxVisibleVolume == null
          ? kline.volume
          : (kline.volume > maxVisibleVolume ? kline.volume : maxVisibleVolume);

      // Draw hover information
      if (hoveredIndex != null &&
          hoveredIndex == i &&
          priceChartHeight != null) {
        _drawHoverVolumeInfo(canvas, kline.volume, priceChartHeight);
      }
    }

    _drawVolumeMALines(
      canvas: canvas,
      size: size,
      klines: klines,
      scrollX: scrollX,
      candleWidth: candleWidth,
      spacing: spacing,
      maxVolume: maxVolume,
      volumeAreaHeight: volumeAreaHeight,
      volumeTopY: volumeTopY,
      ma20Period: ma20Period,
      ma50Period: ma50Period,
      strokeWidth: maStrokeWidth,
      showVolumeMA: showVolumeMA,
    );

    // Draw volume labels
    if (maxVisibleVolume != null && minVisibleVolume != null) {
      _drawVolumeLabels(
        canvas: canvas,
        size: size,
        volumeTopY: volumeTopY,
        volumeAreaHeight: volumeAreaHeight,
        minVolume: minVisibleVolume,
        maxVolume: maxVisibleVolume,
        klines: klines,
        scrollX: scrollX,
        candleWidth: candleWidth,
        spacing: spacing,
      );
    }

    _drawVolumeMALabelTopLeft(
      canvas: canvas,
      size: size,
      klines: klines,
      scrollX: scrollX,
      candleWidth: candleWidth,
      spacing: spacing,
      ma20Period: ma20Period,
      ma50Period: ma50Period,
      volumeTopY: volumeTopY,
    );
  }

  void _drawVolumeGrid({
    required Canvas canvas,
    required Size size,
    required double volumeTopY,
    required double volumeAreaHeight,
    required List<KlineData> klines,
  }) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Draw horizontal grid line
    const int horizontalLines = 1;
    for (int i = 0; i <= horizontalLines; i++) {
      final y = volumeTopY + (volumeAreaHeight / horizontalLines) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw vertical grid lines if enough candles
    const int verticalLines = 4;
    if (klines.length > verticalLines * 5) {
      for (int i = 0; i <= verticalLines; i++) {
        final x = (size.width / verticalLines) * i;
        canvas.drawLine(
          Offset(x, volumeTopY),
          Offset(x, volumeTopY + volumeAreaHeight),
          gridPaint,
        );
      }
    }
  }

  void _drawHoverVolumeInfo(
    Canvas canvas,
    double volume,
    double priceChartHeight,
  ) {
    final textSpan = TextSpan(
      text: 'Vol: ${_formatVolume(volume)}',
      style: const TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(0, priceChartHeight));
  }

  void _drawVolumeLabels({
    required Canvas canvas,
    required Size size,
    required double volumeTopY,
    required double volumeAreaHeight,
    required double minVolume,
    required double maxVolume,
    required List<KlineData> klines,
    required double scrollX,
    required double candleWidth,
    required double spacing,
  }) {
    final textStyle = TextStyle(color: AppColors.textSecondary, fontSize: 10);
    const double rightOffset = 1;
    const double padding = 4.0;
    const Radius radius = Radius.circular(4);

    void drawVolumeLabel(String text, double x, double y) {
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final double boxWidth = textPainter.width + padding * 2;
      final double boxHeight = textPainter.height + padding * 2;

      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, boxWidth, boxHeight),
        radius,
      );

      // (rect đang không vẽ background trong code gốc, giữ nguyên không đổi)
      textPainter.paint(canvas, Offset(x + padding, y + padding));
    }

    // Draw max volume label
    final String maxText = _formatVolume(maxVolume);
    final double maxX = size.width + rightOffset;
    final double maxY = volumeTopY;
    drawVolumeLabel(maxText, maxX, maxY);

    // Draw min volume label
    final String minText = _formatVolume(minVolume);
    final double minY = volumeTopY + volumeAreaHeight - 18;
    drawVolumeLabel(minText, maxX, minY);

    // Draw current volume label
    final int lastVisibleIndex =
        ((scrollX + size.width) / (candleWidth + spacing)).floor();
    final int safeIndex = lastVisibleIndex.clamp(0, klines.length - 1);
    final double currentVolume = klines[safeIndex].volume;

    final String currentVolumeText = _formatVolume(currentVolume);
    final TextStyle currentVolumeStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final textSpan = TextSpan(
      text: currentVolumeText,
      style: currentVolumeStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const double currentPaddingX = 5;
    const double currentPaddingY = 1;
    final double currentBoxWidth = textPainter.width + currentPaddingX * 2;
    final double currentBoxHeight = textPainter.height + currentPaddingY * 2;

    final double barHeight =
        (currentVolume / (maxVolume + 1e-9)) * volumeAreaHeight * 0.9;
    double currentY =
        volumeTopY + volumeAreaHeight - barHeight - currentBoxHeight / 2;
    currentY = currentY.clamp(
      volumeTopY,
      volumeTopY + volumeAreaHeight - currentBoxHeight,
    );

    final double currentX = size.width + rightOffset;

    final RRect currentRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(currentX, currentY, currentBoxWidth, currentBoxHeight),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      currentRect,
      Paint()..color = Colors.orangeAccent.withOpacity(0.7),
    );

    textPainter.paint(
      canvas,
      Offset(currentX + currentPaddingX, currentY + currentPaddingY),
    );
  }

  void _drawVolumeMALabelTopLeft({
    required Canvas canvas,
    required Size size,
    required List<KlineData> klines,
    required double scrollX,
    required double candleWidth,
    required double spacing,
    required int ma20Period,
    required int ma50Period,
    required double volumeTopY,
  }) {
    if (klines.isEmpty) return;

    final double candleWidthWithSpacing = candleWidth + spacing;
    final int lastVisibleIndex =
        ((scrollX + size.width) / candleWidthWithSpacing).floor();
    final int safeIndex = lastVisibleIndex.clamp(0, klines.length - 1);

    final volumes = klines.map((e) => e.volume).toList(growable: false);
    final ma20 = _calculateSMA(volumes, ma20Period);
    final ma50 = _calculateSMA(volumes, ma50Period);

    String v20 = '-';
    String v50 = '-';

    if (safeIndex >= ma20Period - 1 && ma20[safeIndex] != null) {
      v20 = _formatVolume(ma20[safeIndex]!);
    }
    if (safeIndex >= ma50Period - 1 && ma50[safeIndex] != null) {
      v50 = _formatVolume(ma50[safeIndex]!);
    }

    // Màu chữ theo đúng màu đường MA
    final Color ma20Color = Colors.yellow.withOpacity(0.9);
    final Color ma50Color = Colors.purpleAccent.withOpacity(0.9);
    final Color sepColor = Colors.white.withOpacity(0.85);

    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: 'MA20: $v20',
          style: TextStyle(
            color: ma20Color,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),
        TextSpan(
          text: '    ',
          style: TextStyle(
            color: sepColor,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),
        TextSpan(
          text: 'MA50: $v50',
          style: TextStyle(
            color: ma50Color,
            fontSize: 9,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );

    final tp = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr)
      ..layout();

    tp.paint(canvas, Offset(6, volumeTopY + 2));
  }
}
