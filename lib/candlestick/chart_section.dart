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
    return Stack(
      children: [
        // Biểu đồ (hiện khung kể cả khi trống)
        Container(
          color: Colors.black.withOpacity(0.02),
          child: CandlestickChart(
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
        ),

        // Overlay loading khi đang tải
        if (viewModel.klines.isEmpty && viewModel.isLoading)
          Positioned.fill(child: const GlowingLoader()),

        // Hiển thị khi không có dữ liệu nến
        if (viewModel.klines.isEmpty && !viewModel.isLoading)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.03),
              child: Icon(
                Icons.bar_chart_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}
