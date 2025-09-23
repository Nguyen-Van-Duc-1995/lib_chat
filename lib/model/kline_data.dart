// Updated model classes to work with real Binance data
class KlineData {
  final int time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  // Convert seconds timestamp to DateTime
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time * 1000);

  KlineData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory KlineData.fromBinanceKline(List<dynamic> kline) {
    return KlineData(
      time: kline[0] as int,
      open: double.parse(kline[1].toString()),
      high: double.parse(kline[2].toString()),
      low: double.parse(kline[3].toString()),
      close: double.parse(kline[4].toString()),
      volume: double.parse(kline[5].toString()),
    );
  }

  factory KlineData.fromJson(Map<String, dynamic> json) {
    // Convert TradingDate + Time -> timestamp
    final dateStr = json['TradingDate'] as String?; // "12/09/2025"
    final timeStr = json['Time'] as String?; // "14:45:00"

    DateTime dt;
    if (dateStr != null && timeStr != null) {
      final partsDate = dateStr.split('/'); // [12,09,2025]
      final partsTime = timeStr.split(':'); // [14,45,00]
      dt = DateTime(
        int.parse(partsDate[2]),
        int.parse(partsDate[1]),
        int.parse(partsDate[0]),
        int.parse(partsTime[0]),
        int.parse(partsTime[1]),
        int.parse(partsTime[2]),
      );
    } else {
      dt = DateTime.now();
    }

    return KlineData(
      time: (dt.millisecondsSinceEpoch / 1000).round(),
      open: (json['RefPrice'] / 1000 as num).toDouble(),
      high: (json['Highest'] / 1000 as num).toDouble(),
      low: (json['Lowest'] / 1000 as num).toDouble(),
      close: (json['LastPrice'] / 1000 as num).toDouble(),
      volume: (json['TotalVol'] as num).toDouble(),
    );
  }
}
