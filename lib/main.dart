import 'package:chart/chart_screen.dart';
import 'package:chart/trading_screen.dart';
import 'package:chart/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binance Trading Mock',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.cardBackgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            backgroundColor: AppColors.controlButton,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentYellow,
          secondary: AppColors.priceUp,
          surface: AppColors.cardBackground,
        ),
      ),
      home: ChangeNotifierProvider<TradingViewModel>(
        create: (context) => TradingViewModel(),
        child: const TradingScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
