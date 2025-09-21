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
        create: (context) => TradingViewModel(
          symbol: 'SSI',
          stockdata: null,
          klineStream: null,
          exchange: [
            {
              "Advances": 123,
              "AllQty": 927990635,
              "AllValue": 29161148940400,
              "Ceilings": 10,
              "Change": -6.56,
              "Declines": 186,
              "Exchange": "HOSE",
              "Floors": 3,
              "IndexId": "VNINDEX",
              "IndexName": "VNINDEX",
              "IndexType": "Main",
              "IndexValue": 1658.62,
              "MarketId": "HOSE",
              "NoChanges": 58,
              "PriorIndexValue": 1665.18,
              "RType": "MI",
              "RatioChange": -0.39,
              "Time": "15:05:05",
              "TotalQtty": 863955588,
              "TotalQttyOd": 0,
              "TotalQttyPt": 64035047,
              "TotalTrade": 0,
              "TotalValue": 27262107445040,
              "TotalValueOd": 0,
              "TotalValuePt": 1899041495360,
              "TradingDate": "19/09/2025",
              "TradingSession": "C",
              "_id": "68af05d378aa894510996fbc",
              "symbol": "VNINDEX",
            },
          ],
        ),
        child: const TradingScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
