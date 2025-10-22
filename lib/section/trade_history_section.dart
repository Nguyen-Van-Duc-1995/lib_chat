import 'package:chart/providers/trading_view_model.dart';
import 'package:chart/utils/colors.dart';
import 'package:chart/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TradeHistorySection extends StatelessWidget {
  /* ... giữ nguyên, bỏ const ở TextStyle nếu cần ... */
  final TradingViewModel viewModel;
  const TradeHistorySection({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    if (viewModel.trades.isEmpty && viewModel.isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentYellow),
      );
    if (viewModel.trades.isEmpty)
      return const Center(
        child: Text(
          "Không có dữ liệu lệnh khớp.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
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
                  'Giá(USDT)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ), // Bỏ const
              Expanded(
                flex: 3,
                child: Text(
                  'KL(${viewModel.tickerData?.symbol.replaceAll("USDT", "").replaceAll("BUSD", "") ?? "COIN"})',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ), // Bỏ const
              Expanded(
                flex: 4,
                child: Text(
                  'Thời gian',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ), // Bỏ const
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.trades.length,
            itemBuilder: (context, index) {
              final trade = viewModel.trades[index];
              final Color priceColor = trade.isBuyerMaker
                  ? AppColors.priceDown
                  : AppColors.priceUp;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 3.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatPrice(trade.price, decimalPlaces: 2),
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatNumber(
                          trade.quantity,
                          decimalPlaces: 4,
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ), // Bỏ const
                    Expanded(
                      flex: 4,
                      child: Text(
                        DateFormat('HH:mm:ss').format(trade.dateTime),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ); // Bỏ const
  }
}
