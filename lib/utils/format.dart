class FormatUtils {
  static String formatPrice(double price, {int decimalPlaces = -1}) {
    if (price.isNaN || price.isInfinite) return '0.00';
    if (decimalPlaces != -1) return price.toStringAsFixed(decimalPlaces);
    if (price >= 1000) return price.toStringAsFixed(0);
    if (price >= 1) return price.toStringAsFixed(2);
    if (price >= 0.01) return price.toStringAsFixed(4);
    return price.toStringAsFixed(8);
  }

  static String formatNumber(double number, {int decimalPlaces = 2}) {
    if (number.isNaN || number.isInfinite) return '0.00';
    if (number >= 1000000000)
      return '${(number / 1000000000).toStringAsFixed(decimalPlaces)}B';
    if (number >= 1000000)
      return '${(number / 1000000).toStringAsFixed(decimalPlaces)}M';
    if (number >= 1000)
      return '${(number / 1000).toStringAsFixed(decimalPlaces)}K';
    return number.toStringAsFixed(decimalPlaces);
  }
}
