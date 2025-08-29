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
}
