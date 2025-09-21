library;

import 'package:chart/chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'trading_screen.dart';

class ChartApp extends StatelessWidget {
  // final dynamic item;
  // final dynamic klineStream;
  final dynamic stockdata;

  const ChartApp({super.key, required this.stockdata});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradingViewModel(
        symbol: stockdata['item']['Symbol'],
        klineStream: stockdata['klineStream'],
        stockdata: stockdata['item'],
      ),
      child: TradingScreen(symbol: stockdata['item']['Symbol']),
    );
  }
}
