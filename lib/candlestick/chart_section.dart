import 'package:flutter/material.dart';
import 'package:chart/candlestick/candlestick_chart.dart';
import 'package:chart/chart_screen.dart' show TradingViewModel;
import 'package:chart/utils/colors.dart';

class ChartSection extends StatelessWidget {
  /* ... giữ nguyên ... */
  final TradingViewModel viewModel;
  const ChartSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        viewModel.klines.isEmpty && viewModel.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentYellow),
              )
            : CandlestickChart(
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
        if (viewModel.isLoading && viewModel.klines.isNotEmpty)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accentYellow),
              ),
            ),
          ),
      ],
    );
  }
}
