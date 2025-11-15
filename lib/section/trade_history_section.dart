import 'package:chart/providers/trading_view_model.dart';
import 'package:chart/utils/colors.dart';
import 'package:chart/utils/format.dart';
import 'package:chart/utils/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TradeHistorySection extends HookWidget {
  final TradingViewModel viewModel;
  const TradeHistorySection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TradingViewModel>();
    final numberFormat = NumberFormat('#,###.##');
    final scrollController = useScrollController();

    // 👇 Biến trạng thái riêng để quản lý "đang load thêm"
    final isLoadingMore = useState(false);

    // 👇 Lắng nghe khi cuộn đến gần cuối danh sách
    useEffect(() {
      Future<void> handleLoadMore() async {
        if (isLoadingMore.value ||
            viewModel.isLoading ||
            viewModel.trades.isEmpty)
          return;

        isLoadingMore.value = true;
        await viewModel.loadMoreTrades();
        isLoadingMore.value = false;
      }

      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100) {
          handleLoadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, viewModel]);

    if (viewModel.trades.isEmpty && viewModel.isLoading) {
      return const Center(child: GlowingLoader());
    }

    Color color = FilterColorsFromTicker.getColor(
      viewModel.tickerData!.high24h,
      viewModel.tickerData!,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Thời gian',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Giá',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '  +/-',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '   %',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  'KL',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  'M/B',
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
              controller: scrollController,
              itemCount:
                  viewModel.trades.length + (isLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= viewModel.trades.length) {
                  // Loader cuối danh sách
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: GlowingLoader()),
                  );
                }

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
                        flex: 4,
                        child: Text(
                          DateFormat('HH:mm:ss').format(trade.dateTime),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          FormatUtils.formatPrice(
                            trade.price / 1000,
                            decimalPlaces: 2,
                          ),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          FormatUtils.formatPrice(
                            trade.change / 1000,
                            decimalPlaces: 2,
                          ),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${trade.ratioChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: color,
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
