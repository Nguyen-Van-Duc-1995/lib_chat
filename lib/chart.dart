library;

import 'package:chart/chart_screen.dart';
import 'package:chart/model/kline_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'trading_screen.dart';

class ChartApp extends StatelessWidget {
  final String symbol;
  final Stream<KlineData> klineStream;

  const ChartApp({super.key, required this.symbol, required this.klineStream});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradingViewModel(symbol: symbol, klineStream: klineStream),
      child: TradingScreen(symbol: symbol),
    );
  }
}
