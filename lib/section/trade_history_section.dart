import 'package:chart/providers/trading_view_model.dart';
import 'package:chart/utils/colors.dart';
import 'package:chart/utils/format.dart';
import 'package:chart/utils/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class TradeHistorySection extends HookWidget {
  final TradingViewModel viewModel;
  final bool isGrouped;

  const TradeHistorySection({
    super.key,
    required this.viewModel,
    this.isGrouped = false,
  });

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ChangeNotifier để rebuild
    useListenable(viewModel);

    final numberFormat = NumberFormat('#,###.##');
    final scrollController = useScrollController();

    // Loading lần đầu
    final isInitialLoading = useState(true);

    // Loading khi scroll lấy thêm
    final isLoadingMore = useState(false);

    useEffect(() {
      bool disposed = false;

      Future<void> init() async {
        isInitialLoading.value = true;

        viewModel.isGrouped = isGrouped;

        try {
          await viewModel.resetTrades();
        } finally {
          if (!disposed) {
            isInitialLoading.value = false;
          }
        }
      }

      init();

      return () {
        disposed = true;
      };
    }, [viewModel, isGrouped]);

    useEffect(() {
      Future<void> handleLoadMore() async {
        if (isLoadingMore.value ||
            isInitialLoading.value ||
            viewModel.trades.isEmpty) {
          return;
        }

        isLoadingMore.value = true;

        try {
          await viewModel.loadMoreTrades();
        } finally {
          isLoadingMore.value = false;
        }
      }

      void onScroll() {
        if (!scrollController.hasClients) {
          return;
        }

        final position = scrollController.position;

        if (position.pixels >= position.maxScrollExtent - 100) {
          handleLoadMore();
        }
      }

      scrollController.addListener(onScroll);

      return () {
        scrollController.removeListener(onScroll);
      };
    }, [scrollController, viewModel, isInitialLoading.value]);

    // ============================================
    // LOADING LẦN ĐẦU
    // ============================================

    if (isInitialLoading.value) {
      return const Center(child: GlowingLoader());
    }

    // ============================================
    // KHÔNG CÓ DATA
    // ============================================

    if (viewModel.trades.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        // ============================================
        // HEADER
        // ============================================
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
                  '+/-',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  '%',
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

        // ============================================
        // LIST
        // ============================================
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: viewModel.trades.length + (isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              // ============================================
              // LOADING MORE
              // ============================================

              if (index >= viewModel.trades.length) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: GlowingLoader()),
                );
              }

              final trade = viewModel.trades[index];

              final Color color = FilterColorsFromTicker.getColor(
                trade.price,
                viewModel.tickerData!,
              );

              final String tradeType = trade.isBuyerMaker ? 'Mua' : 'Bán';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TIME
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

                    // PRICE
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

                    // CHANGE
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

                    // RATIO
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

                    // QUANTITY
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

                    // BUY / SELL
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
