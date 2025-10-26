library;

import 'package:chart/providers/trading_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trading_screen.dart';

class ChartApp extends StatelessWidget {
  final dynamic stockdata;
  final Function(dynamic)? onSearchPressed;

  const ChartApp({super.key, required this.stockdata, this.onSearchPressed});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return TradingViewModel(
          symbol: stockdata['item']['Symbol'],
          klineStream: stockdata['klineStream'],
          stockdata: stockdata['item'],
          exchange: stockdata['exchange'],
          exchangeStream: stockdata['exchangeStream'],
          onSearchPressed: onSearchPressed, // Pass it here directly
        );
      },
      child: TradingScreen(symbol: stockdata['item']['Symbol']),
    );
  }
}
