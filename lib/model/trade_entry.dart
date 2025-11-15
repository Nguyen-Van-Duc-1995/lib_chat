class TradeEntry {
  final String id; // <--- thêm id
  final double price;
  final double quantity;
  final int time;
  final bool isBuyerMaker;
  final double change;
  final double ratioChange;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);

  TradeEntry({
    required this.id,
    required this.price,
    required this.quantity,
    required this.time,
    required this.isBuyerMaker,
    this.change = 0.0, // default = 0
    this.ratioChange = 0.0, // default = 0
  });

  // Factory từ dữ liệu trade thực Binance
  factory TradeEntry.fromBinanceTrade(Map<String, dynamic> trade) {
    return TradeEntry(
      id: '', // Binance không có _id → để rỗng
      price: double.parse(trade['p']),
      quantity: double.parse(trade['q']),
      time: trade['T'],
      isBuyerMaker: trade['m'],
      change: 0.0,
      ratioChange: 0.0,
    );
  }

  // Factory mới từ dữ liệu JSON tổng hợp (MongoDB)
  factory TradeEntry.fromJson(Map<String, dynamic> json) {
    final dateStr = json['TradingDate'] as String?; // "14/11/2025"
    final timeStr = json['Time'] as String?; // "14:29:59"

    DateTime dt;
    if (dateStr != null && timeStr != null) {
      final partsDate = dateStr.split('/'); // [14,11,2025]
      final partsTime = timeStr.split(':'); // [14,29,59]
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

    final idStr = (json['_id'] is Map && json['_id']['\$oid'] != null)
        ? json['_id']['\$oid'] as String
        : (json['_id'] as String? ?? '');

    return TradeEntry(
      id: idStr,
      time: dt.millisecondsSinceEpoch,
      price: (json['LastPrice'] as num).toDouble(),
      quantity: (json['LastVol'] as num).toDouble(),
      isBuyerMaker: (json['Side'] == 'BU'),
      change: (json['Change'] as num?)?.toDouble() ?? 0.0,
      ratioChange: (json['RatioChange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // CopyWith method
  TradeEntry copyWith({
    String? id,
    double? price,
    double? quantity,
    int? time,
    bool? isBuyerMaker,
    double? change,
    double? ratioChange,
  }) {
    return TradeEntry(
      id: id ?? this.id,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      isBuyerMaker: isBuyerMaker ?? this.isBuyerMaker,
      change: change ?? this.change,
      ratioChange: ratioChange ?? this.ratioChange,
    );
  }
}
