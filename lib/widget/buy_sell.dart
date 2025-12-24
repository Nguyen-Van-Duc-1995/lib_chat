import 'package:chart/model/trade_entry.dart';
import 'package:chart/utils/colors.dart';
import 'package:flutter/material.dart';

class BuySellBar extends StatelessWidget {
  final TradeEntry? buy;
  final TradeEntry? sell;

  const BuySellBar({super.key, required this.buy, required this.sell});

  @override
  Widget build(BuildContext context) {
    final buyValue = buy?.totalBU ?? 0;
    final sellValue = sell?.totalSD ?? 0;

    final total = buyValue + sellValue;

    // tránh chia 0
    final buyFlex = total == 0 ? 50 : ((buyValue / total) * 100).round();
    final sellFlex = 100 - buyFlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 6,
          child: Row(
            children: [
              Expanded(
                flex: buyFlex,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.increaseColor,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: sellFlex,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.decreaseColor,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mua: ${buyFlex.toStringAsFixed(1)}%",
              style: const TextStyle(
                color: AppColors.increaseColor,
                fontSize: 11,
              ),
            ),
            Text(
              "Bán: ${sellFlex.toStringAsFixed(1)}%",
              style: const TextStyle(
                color: AppColors.decreaseColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
