import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chart/candlestick/mixin/draw_mfi_mixin.dart';
import 'package:chart/candlestick/mixin/draw_ichimoku_mixin.dart';
import 'package:chart/candlestick/mixin/draw_time_axis_mixin.dart';
import 'package:chart/candlestick/mixin/draw_volume_profile_mixin.dart'; // Add this import
import 'package:chart/chart_screen.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/const.dart';
import 'package:chart/utils/manager_value.dart';
import '../utils/colors.dart';
import 'mixin/draw_bollinger_mixin.dart';
import 'mixin/draw_current_price_mixin.dart';
import 'mixin/draw_high_low_mixin.dart';
import 'mixin/draw_macd_mixin.dart';
import 'mixin/draw_moving_average_mixin.dart';
import 'mixin/draw_price_labels_mixin.dart';
import 'mixin/draw_rsi_mixin.dart';
import 'mixin/draw_tooltip_mixin.dart';
import 'mixin/draw_volume_mixin.dart';

class CandlestickPainter extends CustomPainter
    with
        DrawVolumeMixin,
        DrawPriceLabelsMixin,
        DrawBollingerBandsMixin,
        DrawHighLowMixin,
        DrawRSIMixin,
        DrawMACDMixin,
        DrawMovingAverageMixin,
        DrawCurrentPriceMixin,
        DrawMFIMixin,
        DrawIchimokuMixin,
        DrawVolumeProfileMixin, // Add this mixin
        DrawTimeAxisMixin,
        DrawTooltipMixin {
  @override
  final List<KlineData> klines;
  final double minPrice, maxPrice, maxVolume, chartWidth, chartHeight;
  final bool showEMA20,
      showEMA50,
      showBB,
      showVolume,
      showRSI,
      showMACD,
      showMFI,
      showIchimoku,
      showVolumeProfile; // Add this parameter
  @override
  final double scrollX;
  final int? hoveredCandleIndex;

  CandlestickPainter({
    required this.klines,
    required this.minPrice,
    required this.maxPrice,
    required this.maxVolume,
    this.showEMA20 = false,
    this.showEMA50 = false,
    this.showBB = false,
    this.showVolume = true,
    this.showRSI = false,
    this.showMACD = false,
    this.showMFI = false,
    this.showIchimoku = true,
    this.showVolumeProfile = false,
    required this.chartWidth,
    required this.chartHeight,
    required this.scrollX,
    this.hoveredCandleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double usedSize = volumeAreaHeight * 3;
    if (klines.isEmpty || maxPrice == minPrice) return;
    final actualChartHeight = volumeAreaHeight * 3;
    _drawGrid(canvas, size, actualChartHeight);
    drawPriceLabels(
      canvas: canvas,
      size: size,
      chartHeight: actualChartHeight,
      maxPrice: maxPrice,
      minPrice: minPrice,
      maxVolume: maxVolume,
    );

    // Vẽ Volume
    if (showVolume) {
      usedSize += volumeAreaHeight;
      drawVolumeBars(
        canvas: canvas,
        size: size,
        klines: klines,
        scrollX: scrollX,
        candleWidth: candleWidth,
        spacing: spacing,
        maxVolume: maxVolume,
        volumeAreaHeight: volumeAreaHeight,
        volumeTopY: 240,
        hoveredIndex: hoveredCandleIndex,
        priceChartHeight: actualChartHeight,
      );
    }
    if (showRSI) {
      drawRSILine(
        canvas: canvas,
        size: size,
        klines: klines,
        candleWidth: candleWidth,
        spacing: spacing,
        scrollX: scrollX,
        rsiChartHeight: volumeAreaHeight,
        rsiTopY: usedSize + indicatorTT.indexOf('RSI') * volumeAreaHeight,
        period: 14,
      );
    }
    if (showMFI) {
      drawMFILine(
        canvas: canvas,
        size: size,
        klines: klines,
        candleWidth: candleWidth,
        spacing: spacing,
        scrollX: scrollX,
        mfiChartHeight: volumeAreaHeight,
        mfiTopY: usedSize + indicatorTT.indexOf('MFI') * volumeAreaHeight,
        period: 14,
      );
    }

    if (showMACD) {
      drawMACD(
        canvas: canvas,
        size: size,
        klines: klines,
        candleWidth: candleWidth,
        spacing: spacing,
        scrollX: scrollX,
        macdChartHeight: volumeAreaHeight,
        macdTopY: usedSize + indicatorTT.indexOf('MACD') * volumeAreaHeight,
      );
    }

    final double candleWidthWithSpacing = candleWidth + spacing; // ~8.5

    // Draw Volume Profile first (behind all other indicators)
    if (showVolumeProfile) {
      drawVolumeProfile(
        canvas: canvas,
        size: size,
        klines: klines,
        maxPrice: maxPrice,
        minPrice: minPrice,
        chartHeight: actualChartHeight,
        candleWidth: candleWidth,
        spacing: spacing,
        scrollX: scrollX,
        priceToY: _priceToY,
        priceLevels: 24,
        profileWidth: 120,
        showOnRight: true,
        opacity: 0.6,
      );
    }

    // Draw Ichimoku (behind other indicators but above volume profile)
    if (showIchimoku) {
      drawIchimoku(
        canvas: canvas,
        size: size,
        klines: klines,
        maxPrice: maxPrice,
        minPrice: minPrice,
        chartHeight: actualChartHeight,
        candleWidth: candleWidth,
        spacing: spacing,
        scrollX: scrollX,
        priceToY: _priceToY,
      );
    }

    if (showEMA20) {
      drawMovingAverage(
        canvas: canvas,
        size: size,
        klines: klines,
        chartHeight: actualChartHeight,
        period: 20,
        color: AppColors.accentYellow.withOpacity(0.8),
        candleWidthWithSpacing: candleWidthWithSpacing,
        scrollX: scrollX,
        priceToY: _priceToY,
      );
    }
    if (showEMA50) {
      drawMovingAverage(
        canvas: canvas,
        size: size,
        klines: klines,
        chartHeight: actualChartHeight,
        period: 50,
        color: Colors.purpleAccent.withOpacity(0.8),
        candleWidthWithSpacing: candleWidthWithSpacing,
        scrollX: scrollX,
        priceToY: _priceToY,
      );
    }

    if (showBB) {
      drawBollingerBands(
        canvas: canvas,
        size: size,
        klines: klines,
        maxPrice: maxPrice,
        minPrice: minPrice,
        chartHeight: actualChartHeight,
        candleWidthWithSpacing: candleWidthWithSpacing,
        scrollX: scrollX,
        spacing: spacing,
        candleWidth: candleWidth,
      );
    }

    for (int i = 0; i < klines.length; i++) {
      final kline = klines[i];
      final double x = i * candleWidthWithSpacing - scrollX + spacing / 2;
      // ✅ Bỏ qua các nến bị tràn ra ngoài khung hiển thị
      if (x + candleWidth < 0 || x > size.width) continue;

      final double highY = _priceToY(kline.high, actualChartHeight);
      final double lowY = _priceToY(kline.low, actualChartHeight);
      final double openY = _priceToY(kline.open, actualChartHeight);
      final double closeY = _priceToY(kline.close, actualChartHeight);
      final bool isBullish = kline.close >= kline.open;
      final Color candleColor = isBullish
          ? AppColors.priceUp
          : AppColors.priceDown;

      final wickPaint = Paint()
        ..color = candleColor
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x + candleWidth / 2, highY),
        Offset(x + candleWidth / 2, lowY),
        wickPaint,
      );
      final double candleTop = min(openY, closeY);
      final double candleBottom = max(openY, closeY);
      final double bodyHeight = candleBottom - candleTop;

      // Đảm bảo thân nến hiển thị được nếu quá nhỏ
      final double minBodyHeight = 1.0;
      final double adjustedBottom = bodyHeight < minBodyHeight
          ? candleTop + minBodyHeight
          : candleBottom;

      final Paint bodyPaint = Paint()..color = candleColor;

      // Nến tăng: chỉ viền
      if (isBullish) {
        bodyPaint.style = PaintingStyle.fill;
      } else {
        bodyPaint.style = PaintingStyle.fill;
      }

      // Vẽ thân nến
      canvas.drawRect(
        Rect.fromLTRB(x, candleTop, x + candleWidth, adjustedBottom),
        bodyPaint,
      );
    }
    drawHighLowAnnotations(
      canvas: canvas,
      size: size,
      chartHeight: actualChartHeight,
      maxPrice: maxPrice,
      minPrice: minPrice,
      klines: klines,
      scrollX: scrollX,
      candleWidth: candleWidth,
      spacing: spacing,
    );

    drawCurrentPrice(
      canvas: canvas,
      size: size,
      klines: klines,
      candleWidth: candleWidth,
      spacing: spacing,
      scrollX: scrollX,
      chartHeight: actualChartHeight,
      priceToY: _priceToY,
    );
    drawTooltip(
      canvas: canvas,
      size: size,
      klines: klines,
      hoveredCandleIndex: hoveredCandleIndex,
      scrollX: scrollX,
      candleWidth: candleWidth,
      spacing: spacing,
    );
    _drawVerticalCrosshair(canvas, size);
    drawTimeAxis(
      canvas: canvas,
      size: size,
      klines: klines,
      candleWidth: candleWidth,
      spacing: spacing,
      scrollX: scrollX,
      timeAxisHeight: 30, // Chiều cao vùng time axis
      timeAxisTopY: size.height - 30, // Vị trí bắt đầu time axis
    );
  }

  void _drawVerticalCrosshair(Canvas canvas, Size size) {
    if (hoveredCandleIndex == null ||
        hoveredCandleIndex! < 0 ||
        hoveredCandleIndex! >= klines.length)
      return;

    final candleWidthWithSpacing = candleWidth + spacing;
    final double x =
        hoveredCandleIndex! * candleWidthWithSpacing - scrollX + spacing / 2;

    if (x < 0 || x > size.width) return;

    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(x + candleWidth / 2, 0),
      Offset(x + candleWidth / 2, size.height),
      linePaint,
    );
  }

  // void _drawGrid(Canvas canvas, Size size, double chartHeight) {
  //   final gridPaint =
  //       Paint()
  //         ..color = AppColors.gridLine.withOpacity(0.5)
  //         ..strokeWidth = 0.5;
  //   const int horizontalLines = 5;
  //   for (int i = 0; i <= horizontalLines; i++) {
  //     final y = (chartHeight / horizontalLines) * i;
  //     canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
  //   }
  //   const int verticalLines = 4;
  //   if (klines.length > verticalLines * 5) {
  //     for (int i = 0; i <= verticalLines; i++) {
  //       final x = (size.width / verticalLines) * i;
  //       canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
  //     }
  //   }
  // }

  // Thay thế hàm _priceToY trong CandlestickPainter

  double _priceToY(double price, double chartHeightToUse) {
    if (maxPrice == minPrice) return chartHeightToUse / 2;

    // Không cần thêm margin ở đây vì đã tính trong price range
    return ((maxPrice - price) / (maxPrice - minPrice)) * chartHeightToUse;
  }

  // Và cập nhật hàm _drawGrid để sử dụng grid steps chính xác
  void _drawGrid(Canvas canvas, Size size, double chartHeight) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 0.5;

    // Horizontal lines - sử dụng price-based grid
    const int horizontalLines = 5;
    final double priceStep = (maxPrice - minPrice) / horizontalLines;

    for (int i = 0; i <= horizontalLines; i++) {
      final double price = maxPrice - (priceStep * i);
      final double y = _priceToY(price, chartHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical lines
    const int verticalLines = 4;
    if (klines.length > verticalLines * 5) {
      for (int i = 0; i <= verticalLines; i++) {
        final x = (size.width / verticalLines) * i;
        canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) =>
      oldDelegate.klines != klines ||
      oldDelegate.minPrice != minPrice ||
      oldDelegate.maxPrice != maxPrice ||
      oldDelegate.maxVolume != maxVolume ||
      oldDelegate.showEMA20 != showEMA20 ||
      oldDelegate.showEMA50 != showEMA50 ||
      oldDelegate.showBB != showBB ||
      oldDelegate.showVolume != showVolume ||
      oldDelegate.showIchimoku != showIchimoku ||
      oldDelegate.showVolumeProfile != showVolumeProfile || // Add this line
      oldDelegate.chartHeight != chartHeight ||
      oldDelegate.chartWidth != chartWidth ||
      oldDelegate.scrollX != scrollX;
}
