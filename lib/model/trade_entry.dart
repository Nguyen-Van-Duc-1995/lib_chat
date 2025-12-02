class TradeEntry {
  final String id;
  final double price;
  final double quantity;
  final int time;
  final bool isBuyerMaker;
  final double change;
  final double ratioChange;
  final DateTime updatedAt;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);

  TradeEntry({
    required this.id,
    required this.price,
    required this.quantity,
    required this.time,
    required this.isBuyerMaker,
    this.change = 0.0,
    this.ratioChange = 0.0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory TradeEntry.fromBinanceTrade(Map<String, dynamic> trade) {
    return TradeEntry(
      id: '',
      price: double.parse(trade['p']),
      quantity: double.parse(trade['q']),
      time: trade['T'],
      isBuyerMaker: trade['m'],
      change: 0.0,
      ratioChange: 0.0,
      updatedAt: DateTime.now(),
    );
  }

  factory TradeEntry.fromJson(Map<String, dynamic> json) {
    final dateStr = json['TradingDate'] as String?;
    final timeStr = json['Time'] as String?;

    DateTime dt;
    if (dateStr != null && timeStr != null) {
      final partsDate = dateStr.split('/');
      final partsTime = timeStr.split(':');
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
      updatedAt: DateTime.now(),
    );
  }

  TradeEntry copyWith({
    String? id,
    double? price,
    double? quantity,
    int? time,
    bool? isBuyerMaker,
    double? change,
    double? ratioChange,
    DateTime? updatedAt,
  }) {
    return TradeEntry(
      id: id ?? this.id,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      isBuyerMaker: isBuyerMaker ?? this.isBuyerMaker,
      change: change ?? this.change,
      ratioChange: ratioChange ?? this.ratioChange,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
