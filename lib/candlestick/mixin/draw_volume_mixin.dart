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

      final volumePaint =
          Paint()
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
      minVisibleVolume =
          minVisibleVolume == null
              ? kline.volume
              : (kline.volume < minVisibleVolume
                  ? kline.volume
                  : minVisibleVolume);
      maxVisibleVolume =
          maxVisibleVolume == null
              ? kline.volume
              : (kline.volume > maxVisibleVolume
                  ? kline.volume
                  : maxVisibleVolume);

      // Draw hover information
      if (hoveredIndex != null &&
          hoveredIndex == i &&
          priceChartHeight != null) {
        _drawHoverVolumeInfo(canvas, kline.volume, priceChartHeight);
      }
    }

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
  }

  void _drawVolumeGrid({
    required Canvas canvas,
    required Size size,
    required double volumeTopY,
    required double volumeAreaHeight,
    required List<KlineData> klines,
  }) {
    final gridPaint =
        Paint()
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

    final double currentX =
        safeIndex * (candleWidth + spacing) -
        scrollX +
        spacing / 2 +
        candleWidth +
        2;

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
}
