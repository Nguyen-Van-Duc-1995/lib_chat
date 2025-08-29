class OrderBookEntry {
  final double price;
  final double quantity;
  final bool isBid;

  double get total => price * quantity;

  OrderBookEntry({
    required this.price,
    required this.quantity,
    required this.isBid,
  });
}
