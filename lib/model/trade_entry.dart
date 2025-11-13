class TradeEntry {
  final String id; // <--- thêm id
  final double price;
  final double quantity;
  final int time;
  final bool isBuyerMaker;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);

  TradeEntry({
    required this.id, // <--- bắt buộc
    required this.price,
    required this.quantity,
    required this.time,
    required this.isBuyerMaker,
  });

  // Factory từ dữ liệu trade thực Binance
  factory TradeEntry.fromBinanceTrade(Map<String, dynamic> trade) {
    return TradeEntry(
      id: '', // Binance không có _id → để rỗng
      price: double.parse(trade['p']),
      quantity: double.parse(trade['q']),
      time: trade['T'],
      isBuyerMaker: trade['m'],
    );
  }

  // Factory mới từ dữ liệu JSON tổng hợp (MongoDB)
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

    // Lấy _id từ JSON và convert sang String
    final idStr = (json['_id'] is Map && json['_id']['\$oid'] != null)
        ? json['_id']['\$oid'] as String
        : (json['_id'] as String? ?? '');

    return TradeEntry(
      id: idStr,
      time: dt.millisecondsSinceEpoch,
      price: (json['LastPrice'] as num).toDouble(),
      quantity: (json['LastVol'] as num).toDouble(),
      isBuyerMaker: (json['Side'] == 'BU'), // mặc định false nếu không có
    );
  }

  // CopyWith method
  TradeEntry copyWith({
    String? id,
    double? price,
    double? quantity,
    int? time,
    bool? isBuyerMaker,
  }) {
    return TradeEntry(
      id: id ?? this.id,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      isBuyerMaker: isBuyerMaker ?? this.isBuyerMaker,
    );
  }
}
