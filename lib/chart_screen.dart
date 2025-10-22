import 'dart:math';
import 'package:chart/providers/trading_view_model.dart';
import 'package:flutter/material.dart';
import 'package:chart/model/indicator_point.dart';
import 'package:chart/model/kline_data.dart';
import 'dart:ui' as ui;
import 'utils/colors.dart';

final double candleWidth = 3.5;
final double spacing = 0.75;

class VolumeChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final List<KlineData> klines;
  const VolumeChart({super.key, required this.klines});

  @override
  Widget build(BuildContext context) {
    if (klines.isEmpty) return const SizedBox.shrink();
    final double maxVolume = klines.isNotEmpty
        ? klines.map((k) => k.volume).reduce(max)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Volume",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: constraints.biggest,
                  painter: VolumePainter(
                    klines: klines,
                    maxVolume: maxVolume > 0 ? maxVolume : 1.0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VolumePainter extends CustomPainter {
  /* ... giữ nguyên ... */
  final List<KlineData> klines;
  final double maxVolume;
  VolumePainter({required this.klines, required this.maxVolume});

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty || maxVolume <= 0) return;
    final double barWidthWithSpacing = size.width / klines.length;
    final double barWidth = barWidthWithSpacing * 0.7;
    final double spacing = barWidthWithSpacing * 0.3;

    for (int i = 0; i < klines.length; i++) {
      final kline = klines[i];
      final double x = i * barWidthWithSpacing + spacing / 2;
      final double barHeight = (kline.volume / maxVolume) * size.height;
      final bool isBullish = kline.close >= kline.open;
      final volumePaint = Paint()
        ..color = (isBullish ? AppColors.priceUp : AppColors.priceDown)
            .withOpacity(0.3);
      canvas.drawRect(
        Rect.fromLTRB(x, size.height - barHeight, x + barWidth, size.height),
        volumePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VolumePainter oldDelegate) =>
      oldDelegate.klines != klines || oldDelegate.maxVolume != maxVolume;
}

class IndicatorPane extends StatelessWidget {
  /* ... giữ nguyên ... */
  final TradingViewModel viewModel;
  const IndicatorPane({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    if (viewModel.showRSI && viewModel.rsiData.isNotEmpty)
      return RSIChart(data: viewModel.rsiData);
    if (viewModel.showMACD &&
        viewModel.macdData != null &&
        viewModel.macdData!.macdLine.isNotEmpty)
      return MACDChart(data: viewModel.macdData!);
    if (viewModel.showMFI && viewModel.mfiData.isNotEmpty)
      return MFIChart(data: viewModel.mfiData);
    return Center(
      child: Text(
        viewModel.isLoading ? 'Đang tải chỉ báo...' : 'Chọn một chỉ báo',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class RSIChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final List<IndicatorPoint> data;
  const RSIChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RSI (14)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              if (data.isNotEmpty)
                Text(
                  data.last.value.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.accentYellow,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: RSIPainter(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class RSIPainter extends CustomPainter {
  /* ... giữ nguyên, ngoại trừ _drawGridAndLevels ... */
  final List<IndicatorPoint> data;
  RSIPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _drawGridAndLevels(canvas, size);
    final rsiPaint = Paint()
      ..color = AppColors.accentYellow.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth = data.length > 1
        ? size.width / (data.length - 1)
        : size.width;

    for (int i = 0; i < data.length; i++) {
      final x = i * pointWidth;
      final y = ((100 - data[i].value.clamp(0, 100)) / 100) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, rsiPaint);
  }

  void _drawGridAndLevels(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 0.5;
    final levelTextPaint = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );
    final levelTextStyle = TextStyle(
      color: AppColors.textSecondary.withOpacity(0.7),
      fontSize: 9,
    ); // Bỏ const
    Map<double, double> levels = {
      70: ((100 - 70) / 100) * size.height,
      50: ((100 - 50) / 100) * size.height,
      30: ((100 - 30) / 100) * size.height,
    };
    levels.forEach((levelValue, yPos) {
      _drawDashedLine(
        canvas,
        Offset(0, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
      levelTextPaint.text = TextSpan(
        text: levelValue.toInt().toString(),
        style: levelTextStyle,
      );
      levelTextPaint.layout();
      levelTextPaint.paint(
        canvas,
        Offset(
          size.width - levelTextPaint.width - 2,
          yPos - levelTextPaint.height - 2,
        ),
      );
    });
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3;
    const dashSpace = 2;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(min(currentX + dashWidth, end.dx), end.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant RSIPainter oldDelegate) =>
      oldDelegate.data != data;
}

class MACDChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final MACDData data;
  const MACDChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MACD (12,26,9)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ), // Bỏ const nếu cần
              if (data.macdLine.isNotEmpty &&
                  data.signalLine.isNotEmpty &&
                  data.histogram.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'M: ${data.macdLine.last.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.priceUp,
                        fontSize: 10,
                      ),
                    ), // Bỏ const nếu cần
                    Text(
                      'S: ${data.signalLine.last.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.priceDown,
                        fontSize: 10,
                      ),
                    ), // Bỏ const nếu cần
                    Text(
                      'H: ${data.histogram.last.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: data.histogram.last.value >= 0
                            ? AppColors.priceUp.withOpacity(0.7)
                            : AppColors.priceDown.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ) /* Bỏ const nếu cần */,
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: MACDPainter(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class MACDPainter extends CustomPainter {
  /* ... giữ nguyên ... */
  final MACDData data;
  MACDPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.macdLine.isEmpty &&
        data.signalLine.isEmpty &&
        data.histogram.isEmpty)
      return;
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    final allPoints = [...data.macdLine, ...data.signalLine, ...data.histogram];
    if (allPoints.isEmpty) return;
    for (final point in allPoints) {
      minValue = min(minValue, point.value);
      maxValue = max(maxValue, point.value);
    }
    if (minValue.isInfinite || maxValue.isInfinite || minValue == maxValue) {
      maxValue = minValue + 1;
    }
    final padding = (maxValue - minValue) * 0.1;
    maxValue += padding;
    minValue -= padding;
    if (minValue == maxValue) {
      maxValue = minValue + 0.5;
      minValue = minValue - 0.5;
    }

    _drawGrid(canvas, size, minValue, maxValue);
    _drawHistogram(canvas, size, minValue, maxValue);
    _drawLine(
      canvas,
      size,
      data.macdLine,
      minValue,
      maxValue,
      AppColors.priceUp,
      1.5,
    );
    _drawLine(
      canvas,
      size,
      data.signalLine,
      minValue,
      maxValue,
      AppColors.priceDown,
      1.5,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double minValue, double maxValue) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 0.5;
    if (maxValue - minValue == 0) return;
    if (minValue <= 0 && maxValue >= 0) {
      final zeroY =
          size.height - ((0 - minValue) / (maxValue - minValue)) * size.height;
      _drawDashedLine(
        canvas,
        Offset(0, zeroY),
        Offset(size.width, zeroY),
        gridPaint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3;
    const dashSpace = 2;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(min(currentX + dashWidth, end.dx), end.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawHistogram(
    Canvas canvas,
    Size size,
    double minValue,
    double maxValue,
  ) {
    if (data.histogram.isEmpty || maxValue - minValue == 0) return;
    final double barWidthWithSpacing = size.width / data.histogram.length;
    final double barWidth = barWidthWithSpacing * 0.7;
    for (int i = 0; i < data.histogram.length; i++) {
      final value = data.histogram[i].value;
      final x = i * barWidthWithSpacing + (barWidthWithSpacing - barWidth) / 2;
      final zeroY =
          size.height - ((0 - minValue) / (maxValue - minValue)) * size.height;
      final valueY =
          size.height -
          ((value - minValue) / (maxValue - minValue)) * size.height;
      final paint = Paint()
        ..color = (value >= 0 ? AppColors.priceUp : AppColors.priceDown)
            .withOpacity(0.5);
      canvas.drawRect(
        Rect.fromLTRB(x, min(zeroY, valueY), x + barWidth, max(zeroY, valueY)),
        paint,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<IndicatorPoint> points,
    double minValue,
    double maxValue,
    Color color,
    double strokeWidth,
  ) {
    if (points.isEmpty || maxValue - minValue == 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth = points.length > 1
        ? size.width / (points.length - 1)
        : size.width;
    for (int i = 0; i < points.length; i++) {
      final x = i * pointWidth;
      final y =
          size.height -
          ((points[i].value - minValue) / (maxValue - minValue)) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MACDPainter oldDelegate) =>
      oldDelegate.data != data;
}

class MFIChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final List<IndicatorPoint> data;
  const MFIChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MFI (14)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              if (data.isNotEmpty)
                Text(
                  data.last.value.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: MFIPainter(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class MFIPainter extends CustomPainter {
  /* ... giữ nguyên, ngoại trừ _drawGridAndLevels ... */
  final List<IndicatorPoint> data;
  MFIPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _drawGridAndLevels(canvas, size);
    final mfiPaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth = data.length > 1
        ? size.width / (data.length - 1)
        : size.width;
    for (int i = 0; i < data.length; i++) {
      final x = i * pointWidth;
      final y = ((100 - data[i].value.clamp(0, 100)) / 100) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, mfiPaint);
  }

  void _drawGridAndLevels(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 0.5;
    final levelTextPaint = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );
    final levelTextStyle = TextStyle(
      color: AppColors.textSecondary.withOpacity(0.7),
      fontSize: 9,
    ); // Bỏ const
    Map<double, double> levels = {
      80: ((100 - 80) / 100) * size.height,
      50: ((100 - 50) / 100) * size.height,
      20: ((100 - 20) / 100) * size.height,
    };
    levels.forEach((levelValue, yPos) {
      _drawDashedLine(
        canvas,
        Offset(0, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
      levelTextPaint.text = TextSpan(
        text: levelValue.toInt().toString(),
        style: levelTextStyle,
      );
      levelTextPaint.layout();
      levelTextPaint.paint(
        canvas,
        Offset(
          size.width - levelTextPaint.width - 2,
          yPos - levelTextPaint.height - 2,
        ),
      );
    });
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3;
    const dashSpace = 2;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(min(currentX + dashWidth, end.dx), end.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant MFIPainter oldDelegate) =>
      oldDelegate.data != data;
}
