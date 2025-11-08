import 'dart:math';

import 'package:flutter/material.dart';
import 'package:chart/candlestick/candlestick_painter.dart';
import 'package:chart/chart_screen.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/utils/const.dart';

class CandlestickChart extends StatefulWidget {
  final List<KlineData> klines;
  final bool showEMA20,
      showEMA50,
      showBB,
      showVolume,
      showRSI,
      showMACD,
      showMFI,
      showIchimoku,
      showVolumeProfile; // Thêm parameter này
  final bool autoScrollToLatest;

  const CandlestickChart({
    super.key,
    required this.klines,
    this.showEMA20 = false,
    this.showEMA50 = false,
    this.showBB = false,
    this.showVolume = false,
    this.showRSI = false,
    this.showMACD = false,
    this.showMFI = false,
    this.showIchimoku = false,
    this.showVolumeProfile = false, // Thêm parameter này
    this.autoScrollToLatest = true,
  });

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  double scrollX = 0.0;
  bool _initialized = false;
  bool isViewingLatest = true;
  int? hoveredIndex;
  int countFrame = 3;
  int _previousKlineLength = 0;
  bool _userHasScrolled = false;

  @override
  void initState() {
    super.initState();
    _previousKlineLength = widget.klines.length;
  }

  /// Tính toán bước chia lưới "đẹp"
  double _calculateNiceGridStep(double range, int desiredSteps) {
    if (range <= 0) return 1.0;

    final double roughStep = range / desiredSteps;
    final double magnitude = pow(
      10,
      (log(roughStep) / ln10).floor(),
    ).toDouble();
    final double normalizedStep = roughStep / magnitude;

    double niceStep;
    if (normalizedStep <= 1) {
      niceStep = 1;
    } else if (normalizedStep <= 2) {
      niceStep = 2;
    } else if (normalizedStep <= 5) {
      niceStep = 5;
    } else {
      niceStep = 10;
    }

    return niceStep * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    countFrame = 3;
    if (widget.showVolume) ++countFrame;
    if (widget.showRSI) ++countFrame;
    if (widget.showMACD) ++countFrame;
    if (widget.showMFI) ++countFrame;

    final klines = widget.klines;

    return Padding(
      padding: const EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        left: 2.0,
        right:
            39.0, // Giảm từ 80.0 xuống 55.0 (50px cho price labels + 5px buffer)
      ),
      child: SizedBox(
        height: volumeAreaHeight * countFrame.toDouble() + 30,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double candleWidthWithSpacing = candleWidth + spacing;
            if (klines.isEmpty || candleWidthWithSpacing == 0) {
              // Không tính toán gì khi không có dữ liệu
              return const SizedBox.shrink();
            }

            final double baseContentWidth =
                candleWidthWithSpacing * klines.length;

            final double ichimokuExtension = widget.showIchimoku
                ? candleWidthWithSpacing * 26
                : 0;
            final double displayContentWidth =
                baseContentWidth + ichimokuExtension;

            final int totalCandles = klines.length;
            final double lastVisibleIndex =
                (scrollX + constraints.maxWidth) / candleWidthWithSpacing;

            isViewingLatest = lastVisibleIndex >= totalCandles - 3;

            if (klines.length > _previousKlineLength) {
              if (widget.autoScrollToLatest &&
                  (!_userHasScrolled || isViewingLatest)) {
                final double newScrollX =
                    (baseContentWidth - constraints.maxWidth).clamp(
                      0,
                      double.infinity,
                    );
                scrollX = newScrollX;
                _userHasScrolled = false;
              }
              _previousKlineLength = klines.length;
            }

            if (!_initialized && klines.isNotEmpty) {
              scrollX = (baseContentWidth - constraints.maxWidth).clamp(
                0,
                double.infinity,
              );
              _initialized = true;
            }

            final double startOffset = scrollX;
            final double endOffset = scrollX + constraints.maxWidth;

            final int startIndex = (startOffset / candleWidthWithSpacing)
                .floor()
                .clamp(0, klines.length - 1);
            final int endIndex = (endOffset / candleWidthWithSpacing)
                .ceil()
                .clamp(0, klines.length - 1);

            final visibleKlines = klines.sublist(startIndex, endIndex + 1);

            // ✅ FIXED: Tính toán range chính xác
            final double rawMinPrice = visibleKlines
                .map((k) => k.low)
                .reduce(min);
            final double rawMaxPrice = visibleKlines
                .map((k) => k.high)
                .reduce(max);

            // Tính range và padding động (3% cho mỗi bên)
            final double priceRange = rawMaxPrice - rawMinPrice;
            final double padding = priceRange * 0.03;

            // Áp dụng padding đều cho cả trên và dưới
            double minPrice = rawMinPrice - padding;
            double maxPrice = rawMaxPrice + padding;

            // Tính nice number cho grid để labels đẹp hơn
            final double adjustedRange = maxPrice - minPrice;
            final double gridStep = _calculateNiceGridStep(adjustedRange, 5);

            // Căn chỉnh theo grid
            minPrice = (minPrice / gridStep).floor() * gridStep;
            maxPrice = (maxPrice / gridStep).ceil() * gridStep;

            // Đảm bảo range không bằng 0
            if (maxPrice == minPrice) {
              maxPrice = minPrice + 1;
            }

            final double maxVolume =
                widget.showVolume && visibleKlines.isNotEmpty
                ? visibleKlines.map((k) => k.volume).reduce(max)
                : 1;

            return GestureDetector(
              onLongPressStart: (details) {
                final localX = details.localPosition.dx;
                final index = ((scrollX + localX) / candleWidthWithSpacing)
                    .floor();

                setState(() {
                  hoveredIndex = index.clamp(0, widget.klines.length - 1);
                });
              },

              onLongPressMoveUpdate: (details) {
                final localX = details.localPosition.dx;
                final index = ((scrollX + localX) / candleWidthWithSpacing)
                    .floor();

                setState(() {
                  hoveredIndex = index.clamp(0, widget.klines.length - 1);
                });
              },

              onLongPressEnd: (_) {
                setState(() {
                  hoveredIndex = null;
                });
              },

              onHorizontalDragStart: (details) {
                _userHasScrolled = true;
              },

              onHorizontalDragUpdate: (details) {
                setState(() {
                  scrollX -= details.delta.dx;

                  final double minScrollX = -30;

                  double maxScrollX =
                      baseContentWidth - constraints.maxWidth + 50;

                  if (widget.showIchimoku && isViewingLatest) {
                    maxScrollX += ichimokuExtension;
                  }

                  scrollX = scrollX.clamp(minScrollX, maxScrollX);
                });
              },

              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(displayContentWidth + 35, constraints.maxHeight),
                    painter: CandlestickPainter(
                      klines: klines,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                      maxVolume: maxVolume,
                      showEMA20: widget.showEMA20,
                      showEMA50: widget.showEMA50,
                      showBB: widget.showBB,
                      showVolume: widget.showVolume,
                      showRSI: widget.showRSI,
                      showMACD: widget.showMACD,
                      showMFI: widget.showMFI,
                      showIchimoku: widget.showIchimoku,
                      showVolumeProfile:
                          widget.showVolumeProfile, // Thêm dòng này
                      chartWidth: displayContentWidth,
                      chartHeight: constraints.maxHeight,
                      scrollX: scrollX,
                      hoveredCandleIndex: hoveredIndex,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
