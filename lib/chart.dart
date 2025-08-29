library;

import 'package:chart/chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'trading_screen.dart';

/// App wrapper cho TradingScreen với Provider.
class ChartApp extends StatelessWidget {
  const ChartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TradingViewModel>(
      create: (_) => TradingViewModel(),
      child: const TradingScreen(),
    );
  }
}
