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

  factory TradeEntry.fromBinanceTrade(Map<String, dynamic> trade) {
    return TradeEntry(
      price: double.parse(trade['p']),
      quantity: double.parse(trade['q']),
      time: trade['T'],
      isBuyerMaker: trade['m'],
    );
  }
}
