import 'package:chart/model/ticker_data.dart';
import 'package:flutter/material.dart';

// --- CONSTANTS & COLORS ---
class AppColors {
  static const Color background = Color(0xff0B0B25);
  static const Color cardBackground = Color(0xFF161A1E);
  static const Color cardBackgroundLight = Color(0xFF1E2329);
  static const Color chartBackground = Color(0xFF252930);
  static const Color controlButton = Color(0xFF2B3139);
  static const Color controlButtonHover = Color(0xFF3D444D);
  static const Color controlButtonActive = Color(0xFFFCD535);
  static const Color textPrimary = Color(0xFFEBEEF2);
  static const Color textSecondary = Color(0xFF848E9C);
  static const Color textTertiary = Color(0xFFB7BDC6);
  static const Color priceUp = Color(0xFF0ECB81);
  static const Color priceDown = Color(0xFFF6465D);
  static const Color askColor = Color(0xFFF6465D);
  static const Color bidColor = Color(0xFF0ECB81);
  static const Color askBgOpacity = Color(0x1AF6465D);
  static const Color bidBgOpacity = Color(0x1A0ECB81);
  static const Color border = Color(0xFF2B3139);
  static const Color accentYellow = Color(0xFFFCD535);
  static const Color gridLine = Color(0xFF2B3139);

  static const backgroundColor = Color(0xff0B0B25); // nền xanh đen
  static const increaseColor = Color(0xff27AE60);
  static const decreaseColor = Color(0xffC0392B);
  static const yellowColor = Color(0xffF39C12);
  static const ceilingColor = Color(0xffBB2AFF);
  static const floorColor = Color(0xff2980B9);
}

abstract class FilterColors {
  /// Màu sắc theo logic trần/sàn/tham chiếu/tăng/giảm
  static Color getColor(dynamic price, Map<String, dynamic> code) {
    final double p = _toDoubleSafe(price); // giá đang xét
    final double ceilPrice = _toDoubleSafe(code['Ceiling']);
    final double floorPrice = _toDoubleSafe(code['Floor']);
    final double refPrice = _toDoubleSafe(code['RefPrice']);

    if (p == ceilPrice) {
      return AppColors.ceilingColor; // Màu trần
    }
    if (p == floorPrice) {
      return AppColors.floorColor; // Màu sàn
    }
    if (p == refPrice) {
      return AppColors.yellowColor; // Màu tham chiếu
    }
    if (p < refPrice) {
      return AppColors.decreaseColor; // Màu giảm
    }

    return AppColors.increaseColor; // Màu tăng
  }

  static double _toDoubleSafe(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

abstract class FilterColorsFromTicker {
  /// Màu sắc theo logic trần/sàn/tham chiếu/tăng/giảm
  static Color getColor(dynamic price, TickerData tickerData) {
    final double p = _toDoubleSafe(price);
    final double ceilPrice = tickerData.ceiling;
    final double floorPrice = tickerData.floor;
    final double refPrice = tickerData.refPrice;

    if (p == ceilPrice) {
      return AppColors.ceilingColor;
    }
    if (p == floorPrice) {
      return AppColors.floorColor;
    }
    if (p == refPrice) {
      return AppColors.yellowColor;
    }
    if (p < refPrice) {
      return AppColors.decreaseColor;
    }

    return AppColors.increaseColor;
  }

  static double _toDoubleSafe(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
