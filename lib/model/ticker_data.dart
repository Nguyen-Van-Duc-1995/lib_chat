class TickerData {
  final String symbol;
  final double currentPrice;
  final double priceChange;
  final double priceChangePercent;
  final double volume24h;
  final double high24h;
  final double low24h;
  double ceiling;
  double floor;
  double avgPrice;
  double refPrice;

  TickerData({
    required this.symbol,
    required this.currentPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    this.ceiling = 0.0,
    this.floor = 0.0,
    this.avgPrice = 0.0,
    this.refPrice = 0.0,
  });

  /// Mapping từ Binance (giữ nguyên)
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

  /// Mapping từ API chứng khoán (softsama.com)
  factory TickerData.fromStockApi(Map<String, dynamic> data) {
    return TickerData(
      symbol: data['Symbol'] ?? '',
      currentPrice: (data['LastPrice'] ?? 0).toDouble(),
      priceChange: (data['Change'] ?? 0).toDouble(),
      priceChangePercent: (data['RatioChange'] ?? 0).toDouble(),
      volume24h: (data['TotalVol'] ?? 0).toDouble(),
      high24h: (data['Highest'] ?? 0).toDouble(),
      low24h: (data['Lowest'] ?? 0).toDouble(),
      ceiling: data['Ceiling']?.toDouble() ?? 0.0,
      floor: data['Floor']?.toDouble() ?? 0.0,
      avgPrice: data['AvgPrice']?.toDouble() ?? 0.0,
      refPrice: data['RefPrice']?.toDouble() ?? 0.0,
    );
  }
}
