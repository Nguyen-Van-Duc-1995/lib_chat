class TradeEntry {
  final double price;
  final double quantity;
  final int time;
  final bool isBuyerMaker;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);

  TradeEntry({
    required this.price,
    required this.quantity,
    required this.time,
    required this.isBuyerMaker,
  });

  // Factory từ dữ liệu trade thực Binance
  factory TradeEntry.fromBinanceTrade(Map<String, dynamic> trade) {
    return TradeEntry(
      price: double.parse(trade['p']),
      quantity: double.parse(trade['q']),
      time: trade['T'],
      isBuyerMaker: trade['m'],
    );
  }

  // Factory mới từ dữ liệu JSON tổng hợp (giống KlineData.fromJson)
  factory TradeEntry.fromJson(Map<String, dynamic> json) {
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

    return TradeEntry(
      time: dt.millisecondsSinceEpoch,
      price: (json['LastPrice'] as num).toDouble(),
      quantity: (json['TotalVol'] as num).toDouble(),
      isBuyerMaker: false, // mặc định false nếu không có
    );
  }

  // CopyWith method (tuỳ chọn, giống KlineData)
  TradeEntry copyWith({
    double? price,
    double? quantity,
    int? time,
    bool? isBuyerMaker,
  }) {
    return TradeEntry(
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      isBuyerMaker: isBuyerMaker ?? this.isBuyerMaker,
    );
  }
}
