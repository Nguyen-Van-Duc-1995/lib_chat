import 'package:flutter/material.dart';

class BuySellBar extends StatelessWidget {
  final double buyPercent; // 0 → 100
  final double sellPercent; // 0 → 100

  const BuySellBar({
    super.key,
    required this.buyPercent,
    required this.sellPercent,
  });

  @override
  Widget build(BuildContext context) {
    final total = buyPercent + sellPercent;
    final buyFlex = (buyPercent / total * 100).round();
    final sellFlex = 100 - buyFlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 9,
          child: Row(
            children: [
              Expanded(
                flex: buyFlex,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
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
                    color: Colors.red,
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
              "Mua ${buyPercent.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              "Bán ${sellPercent.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}
