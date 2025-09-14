library;

import 'package:chart/chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'trading_screen.dart';

class ChartApp extends StatelessWidget {
  final dynamic item;
  final dynamic klineStream;

  const ChartApp({super.key, required this.item, this.klineStream});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          TradingViewModel(symbol: item['Symbol'], klineStream: klineStream),
      child: TradingScreen(symbol: item['Symbol']),
    );
  }
}
