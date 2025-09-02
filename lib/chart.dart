library;

import 'package:chart/chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'trading_screen.dart';

/// App wrapper cho TradingScreen với Provider.
class ChartApp extends StatelessWidget {
  final String symbol;
  const ChartApp({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TradingViewModel>(
      create: (_) => TradingViewModel(symbol: symbol),
      child: TradingScreen(symbol: symbol),
    );
  }
}
