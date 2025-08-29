class TickerData {
  final String symbol;
  final double currentPrice;
  final double priceChange;
  final double priceChangePercent;
  final double volume24h;
  final double high24h;
  final double low24h;

  TickerData({
    required this.symbol,
    required this.currentPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
  });

  factory TickerData.fromBinance24hrTicker(Map<String, dynamic> ticker) {
    return TickerData(
      symbol: ticker['symbol'],
      currentPrice: double.parse(ticker['lastPrice']),
      priceChange: double.parse(ticker['priceChange']),
      priceChangePercent: double.parse(ticker['priceChangePercent']),
      volume24h: double.parse(ticker['volume']),
      high24h: double.parse(ticker['highPrice']),
      low24h: double.parse(ticker['lowPrice']),
    );
  }
}
