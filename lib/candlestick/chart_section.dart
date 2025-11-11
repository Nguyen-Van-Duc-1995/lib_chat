import 'package:chart/providers/trading_view_model.dart';
import 'package:chart/utils/loader.dart';
import 'package:flutter/material.dart';
import 'package:chart/candlestick/candlestick_chart.dart';
import 'package:chart/utils/colors.dart';

class ChartSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const ChartSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    const double baseHeight = 358;

    // Khi chưa có dữ liệu
    if (viewModel.klines.isEmpty) {
      return Container(
        height: baseHeight,
        color: Colors.black.withOpacity(0.02),
        alignment: Alignment.center,
        child: viewModel.isLoading
            ? const SizedBox(width: 40, height: 40, child: GlowingLoader())
            : Icon(
                Icons.bar_chart_rounded,
                color: AppColors.textSecondary.withOpacity(0.6),
                size: 22,
              ),
      );
    }

    // Khi đã có dữ liệu
    return Stack(
      children: [
        CandlestickChart(
          klines: viewModel.klines,
          showEMA20: viewModel.showEMA20,
          showEMA50: viewModel.showEMA50,
          showBB: viewModel.showBB,
          showVolume: viewModel.showVolume,
          showRSI: viewModel.showRSI,
          showMACD: viewModel.showMACD,
          showMFI: viewModel.showMFI,
          showIchimoku: viewModel.showIchimoku,
        ),

        // Overlay loading (vẫn xoay trong khung nến)
        if (viewModel.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.03),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: GlowingLoader(),
              ),
            ),
          ),
      ],
    );
  }
}
