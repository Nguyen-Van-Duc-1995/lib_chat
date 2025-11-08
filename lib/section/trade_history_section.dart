import 'package:chart/providers/trading_view_model.dart';
import 'package:chart/utils/colors.dart';
import 'package:chart/utils/format.dart';
import 'package:chart/utils/loader.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TradeHistorySection extends StatelessWidget {
  final TradingViewModel viewModel;
  const TradeHistorySection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###.##');

    if (viewModel.trades.isEmpty && viewModel.isLoading)
      return Center(child: GlowingLoader());

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
                  'Giá(VND)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
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
              ),
              SizedBox(width: 29),
              Expanded(
                flex: 3,
                child: Text(
                  'M/B',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
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
        ),
        if (viewModel.trades.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.trades.length,
              itemBuilder: (context, index) {
                final trade = viewModel.trades[index];
                final Color priceColor = trade.isBuyerMaker
                    ? AppColors.priceDown
                    : AppColors.priceUp;
                final String tradeType = trade.isBuyerMaker ? 'Mua' : 'Bán';

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
                          FormatUtils.formatPrice(
                            trade.price / 1000,
                            decimalPlaces: 2,
                          ),
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
                          numberFormat.format(trade.quantity),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(width: 29),
                      Expanded(
                        flex: 3,
                        child: Text(
                          tradeType,
                          style: TextStyle(
                            color: trade.isBuyerMaker
                                ? AppColors.priceUp
                                : AppColors.priceDown,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
    );
  }
}
