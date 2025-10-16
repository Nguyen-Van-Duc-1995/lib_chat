// Model cho chỉ số thị trường
class MarketIndex {
  final String indexId;
  final double indexValue;
  final double change;
  final double ratioChange;
  final double allValue;
  final double allQty;

  MarketIndex({
    required this.indexId,
    required this.indexValue,
    required this.change,
    required this.ratioChange,
    required this.allValue,
    required this.allQty,
  });

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      indexId: json['IndexId'] ?? '',
      indexValue: _parseDouble(json['IndexValue']),
      change: _parseDouble(json['Change']),
      ratioChange: _parseDouble(json['RatioChange']),
      allValue: _parseDouble(json['AllValue']),
      allQty: _parseDouble(json['AllQty']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Xử lý format "35.6K tỷ" hoặc "Vol. 1.38B"
      String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  bool get isPositive => change >= 0;

  String get formattedValue => indexValue.toStringAsFixed(2);
  String get formattedChange =>
      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}';
  String get formattedRatioChange =>
      '${ratioChange >= 0 ? '+' : ''}${ratioChange.toStringAsFixed(2)}%';

  String get formattedAllValue {
    if (allValue >= 1e12) {
      return '${(allValue / 1e12).toStringAsFixed(1)}K tỷ';
    } else if (allValue >= 1e9) {
      return '${(allValue / 1e9).toStringAsFixed(1)} tỷ';
    }
    return allValue.toStringAsFixed(0);
  }

  String get formattedAllQty {
    if (allQty >= 1e9) {
      return 'Vol. ${(allQty / 1e9).toStringAsFixed(2)}B';
    } else if (allQty >= 1e6) {
      return 'Vol. ${(allQty / 1e6).toStringAsFixed(2)}M';
    }
    return 'Vol. ${allQty.toStringAsFixed(0)}';
  }
}
