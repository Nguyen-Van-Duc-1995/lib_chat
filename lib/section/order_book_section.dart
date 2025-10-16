import 'dart:math';
import 'package:chart/chart_screen.dart';
import 'package:chart/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:chart/model/order_book_entry.dart';

import 'package:chart/utils/format.dart';

class OrderBookSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const OrderBookSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.asks.isEmpty && viewModel.bids.isEmpty && viewModel.isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentYellow),
      );
    if (viewModel.asks.isEmpty && viewModel.bids.isEmpty)
      return const Center(
        child: Text(
          "Không có dữ liệu sổ lệnh.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    double maxCumulativeTotal = viewModel.maxCumulativeTotal;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Giá (USDT)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ), // Bỏ const
              Expanded(
                flex: 3,
                child: Text(
                  'KL (${viewModel.tickerData?.symbol.replaceAll("USDT", "").replaceAll("BUSD", "") ?? "COIN"})',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ), // Đã sửa: Bỏ const
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Tổng (USDT)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ), // Bỏ const
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: min(viewModel.asks.length, 15),
                  itemBuilder: (context, index) {
                    final entry =
                        viewModel.asks[viewModel.asks.length - 1 - index];
                    final cumulativeTotalForDepth = viewModel.asks
                        .take(viewModel.asks.length - index)
                        .fold(0.0, (prev, e) => prev + e.total);
                    final depthPercentage =
                        cumulativeTotalForDepth / (maxCumulativeTotal + 1e-9);
                    return _buildOrderBookRow(
                      entry,
                      AppColors.askColor,
                      AppColors.askBgOpacity,
                      depthPercentage,
                      true,
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: min(viewModel.bids.length, 15),
                  itemBuilder: (context, index) {
                    final entry = viewModel.bids[index];
                    final cumulativeTotalForDepth = viewModel.bids
                        .take(index + 1)
                        .fold(0.0, (prev, e) => prev + e.total);
                    final depthPercentage =
                        cumulativeTotalForDepth / (maxCumulativeTotal + 1e-9);
                    return _buildOrderBookRow(
                      entry,
                      AppColors.bidColor,
                      AppColors.bidBgOpacity,
                      depthPercentage,
                      false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (viewModel.orderBookMidPrice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Giá giữa: ${FormatUtils.formatPrice(viewModel.orderBookMidPrice!)}',
              style: const TextStyle(
                color: AppColors.accentYellow,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderBookRow(
    OrderBookEntry entry,
    Color priceColor,
    Color rowBackgroundColor,
    double depthPercentage,
    bool isAsk,
  ) {
    // rowBackgroundColor là tên tham số đã sửa
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 20,
          margin: const EdgeInsets.symmetric(vertical: 0.5),
          child: Stack(
            children: [
              Positioned(
                right: isAsk ? null : 0,
                left: isAsk ? 0 : null,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * depthPercentage.clamp(0.0, 1.0),
                child: Container(color: rowBackgroundColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatPrice(entry.price, decimalPlaces: 2),
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatNumber(
                          entry.quantity,
                          decimalPlaces: 4,
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ), // Bỏ const
                    Expanded(
                      flex: 4,
                      child: Text(
                        FormatUtils.formatNumber(entry.total, decimalPlaces: 2),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ); // Bỏ const
  }
}
