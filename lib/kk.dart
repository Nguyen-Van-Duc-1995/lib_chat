import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:web_socket_channel/web_socket_channel.dart';

// --- CONSTANTS & COLORS (Không đổi) ---
class AppColors {
  static const Color background = Color(0xFF0B0E11);
  static const Color cardBackground = Color(0xFF161A1E);
  static const Color cardBackgroundLight = Color(0xFF1E2329);
  static const Color chartBackground = Color(0xFF252930);
  static const Color controlButton = Color(0xFF2B3139);
  static const Color controlButtonHover = Color(0xFF3D444D);
  static const Color controlButtonActive = Color(0xFFFCD535);
  static const Color textPrimary = Color(0xFFEBEEF2);
  static const Color textSecondary = Color(0xFF848E9C);
  static const Color textTertiary = Color(0xFFB7BDC6);
  static const Color priceUp = Color(0xFF0ECB81);
  static const Color priceDown = Color(0xFFF6465D);
  static const Color askColor = Color(0xFFF6465D);
  static const Color bidColor = Color(0xFF0ECB81);
  static const Color askBgOpacity = Color(0x1AF6465D);
  static const Color bidBgOpacity = Color(0x1A0ECB81);
  static const Color border = Color(0xFF2B3139);
  static const Color accentYellow = Color(0xFFFCD535);
  static const Color gridLine = Color(0xFF2B3139);
}

// --- MODELS ---
class KlineData {
  final int time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);

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

class IndicatorPoint {
  final DateTime time;
  final double? value;
  IndicatorPoint(this.time, this.value);
} // value có thể null

class MACDData {
  final List<IndicatorPoint> macdLine, signalLine, histogram;
  MACDData({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

class FormatUtils {
  static String formatPrice(double price, {int decimalPlaces = -1}) {
    if (price.isNaN || price.isInfinite) return '0.00';
    if (decimalPlaces != -1) return price.toStringAsFixed(decimalPlaces);
    if (price >= 1000) return price.toStringAsFixed(0);
    if (price >= 1) return price.toStringAsFixed(2);
    if (price >= 0.01) return price.toStringAsFixed(4);
    return price.toStringAsFixed(8);
  }

  static String formatNumber(double number, {int decimalPlaces = 2}) {
    if (number.isNaN || number.isInfinite) return '0.00';
    if (number >= 1000000000)
      return '${(number / 1000000000).toStringAsFixed(decimalPlaces)}B';
    if (number >= 1000000)
      return '${(number / 1000000).toStringAsFixed(decimalPlaces)}M';
    if (number >= 1000)
      return '${(number / 1000).toStringAsFixed(decimalPlaces)}K';
    return number.toStringAsFixed(decimalPlaces);
  }
}

class IndicatorCalculator {
  // Hàm tính EMA không đổi
  static List<double> calculateEMA(List<double> values, int period) {
    if (values.isEmpty || values.length < period) return [];
    List<double> ema = [];
    double multiplier = 2.0 / (period + 1), sum = 0;
    for (int i = 0; i < period; i++) sum += values[i];
    ema.add(sum / period);
    for (int i = period; i < values.length; i++)
      ema.add((values[i] - ema.last) * multiplier + ema.last);
    return ema;
  }

  // Sửa các hàm tính toán để trả về list có cùng độ dài với klines, đệm null ở đầu
  static List<IndicatorPoint> calculateRSI(List<KlineData> klines, int period) {
    List<IndicatorPoint> rsiValues = List.filled(
      klines.length,
      IndicatorPoint(DateTime.now(), null),
      growable: true,
    );
    if (klines.length < period + 1) return rsiValues;
    List<double> gains = [], losses = [];
    for (int i = 1; i < klines.length; i++) {
      double change = klines[i].close - klines[i - 1].close;
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }
    if (gains.length < period) return rsiValues;
    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;
    int rsiStartIndex = period;

    double firstRsi;
    if (avgLoss == 0)
      firstRsi = 100;
    else
      firstRsi = 100 - (100 / (1 + avgGain / avgLoss));
    rsiValues[rsiStartIndex] = IndicatorPoint(
      klines[rsiStartIndex].dateTime,
      firstRsi,
    );

    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
      double rsi = avgLoss == 0 ? 100 : 100 - (100 / (1 + avgGain / avgLoss));
      rsiValues[i + 1] = IndicatorPoint(klines[i + 1].dateTime, rsi);
    }
    return rsiValues;
  }

  static MACDData calculateMACD(
    List<KlineData> klines, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    List<IndicatorPoint> emptyList = List.generate(
      klines.length,
      (index) => IndicatorPoint(klines[index].dateTime, null),
    );
    if (klines.length < slowPeriod + signalPeriod)
      return MACDData(
        macdLine: List.from(emptyList),
        signalLine: List.from(emptyList),
        histogram: List.from(emptyList),
      );
    List<double> closes = klines.map((k) => k.close).toList();
    List<double> emaFast = calculateEMA(closes, fastPeriod);
    List<double> emaSlow = calculateEMA(closes, slowPeriod);

    List<double> macdValues = [];
    int fastEmaOffset = slowPeriod - fastPeriod;
    for (int i = 0; i < emaSlow.length; i++) {
      macdValues.add(emaFast[i + fastEmaOffset] - emaSlow[i]);
    }
    List<double> signalValues = calculateEMA(macdValues, signalPeriod);

    List<IndicatorPoint> macdLineResult = List.from(emptyList);
    List<IndicatorPoint> signalLineResult = List.from(emptyList);
    List<IndicatorPoint> histogramResult = List.from(emptyList);

    int macdStartIndex = slowPeriod - 1;
    int signalStartIndex = macdStartIndex + signalPeriod - 1;

    for (int i = 0; i < signalValues.length; i++) {
      int klineIndex = signalStartIndex + i;
      double macd = macdValues[signalPeriod - 1 + i];
      double signal = signalValues[i];
      macdLineResult[klineIndex] = IndicatorPoint(
        klines[klineIndex].dateTime,
        macd,
      );
      signalLineResult[klineIndex] = IndicatorPoint(
        klines[klineIndex].dateTime,
        signal,
      );
      histogramResult[klineIndex] = IndicatorPoint(
        klines[klineIndex].dateTime,
        macd - signal,
      );
    }
    return MACDData(
      macdLine: macdLineResult,
      signalLine: signalLineResult,
      histogram: histogramResult,
    );
  }
}

// --- BINANCE SERVICE (SỬA LẠI HOÀN TOÀN ĐỂ DÙNG API THẬT) ---
class BinanceService {
  final String symbol;
  final String interval;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  final _tickerController = StreamController<Map<String, dynamic>>.broadcast();
  final _depthController = StreamController<Map<String, dynamic>>.broadcast();
  final _tradeController = StreamController<Map<String, dynamic>>.broadcast();
  final _klineController = StreamController<Map<String, dynamic>>.broadcast();

  BinanceService({required this.symbol, required this.interval}) {
    _initWebSocket();
  }

  void _initWebSocket() {
    final streams = [
      '${symbol.toLowerCase()}@ticker', // 24hr Ticker
      '${symbol.toLowerCase()}@depth20@100ms', // Top 20 levels, 100ms update
      '${symbol.toLowerCase()}@trade', // Trades
      '${symbol.toLowerCase()}@kline_$interval', // Klines for the specified interval
    ];
    final url =
        'wss://stream.binance.com:9443/stream?streams=${streams.join("/")}';

    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channelSubscription = _channel!.stream.listen(
      (message) {
        try {
          final decoded = json.decode(message) as Map<String, dynamic>;
          if (decoded.containsKey('stream') && decoded.containsKey('data')) {
            final data = decoded['data'] as Map<String, dynamic>;
            String streamName = decoded['stream'];
            if (streamName.contains('@ticker')) {
              _tickerController.add(data);
            } else if (streamName.contains('@depth')) {
              _depthController.add(data);
            } else if (streamName.contains('@trade')) {
              _tradeController.add(data);
            } else if (streamName.contains('@kline')) {
              _klineController.add(data);
            }
          }
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onDone: () {
        print('WebSocket stream done.');
        _reconnect(); // Reconnect on done
      },
      onError: (error) {
        print('WebSocket stream error: $error');
        _reconnect(); // Reconnect on error
      },
      cancelOnError: true,
    );
  }

  void _reconnect() {
    print('Reconnecting WebSocket in 5 seconds...');
    dispose(); // Close existing connections
    Future.delayed(const Duration(seconds: 5), () {
      _initWebSocket();
    });
  }

  Future<List<KlineData>> fetchInitialKlines({int limit = 200}) async {
    final uri = Uri.parse(
      'https://api.binance.com/api/v3/klines?symbol=${symbol.toUpperCase()}&interval=$interval&limit=$limit',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((kline) => KlineData.fromBinanceKline(kline)).toList();
      } else {
        throw Exception('Failed to load klines: ${response.body}');
      }
    } catch (e) {
      print('Error fetching initial klines: $e');
      return [];
    }
  }

  // Streams for the ViewModel to subscribe to
  Stream<Map<String, dynamic>> subscribeToTicker() => _tickerController.stream;
  Stream<Map<String, dynamic>> subscribeToDepth() => _depthController.stream;
  Stream<Map<String, dynamic>> subscribeToTrades() => _tradeController.stream;
  Stream<Map<String, dynamic>> subscribeToKline() => _klineController.stream;

  void dispose() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
  }
}

// --- VIEWMODEL (Cập nhật để dùng BinanceService thật) ---
class TradingViewModel extends ChangeNotifier {
  late BinanceService _binanceService;
  final String _currentSymbol = 'BTCUSDT';
  String _currentInterval = '15m';
  final List<String> timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1d'];

  // ... các getters và setters khác không đổi ...
  TickerData? _tickerData;
  TickerData? get tickerData => _tickerData;
  List<OrderBookEntry> _asks = [], _bids = [];
  List<OrderBookEntry> get asks => _asks;
  List<OrderBookEntry> get bids => _bids;
  double _maxCumulativeTotal = 0;
  double get maxCumulativeTotal => _maxCumulativeTotal;
  double? _orderBookMidPrice;
  double? get orderBookMidPrice => _orderBookMidPrice;
  final List<TradeEntry> _trades = [];
  List<TradeEntry> get trades => _trades;
  List<KlineData> _klines = [];
  List<KlineData> get klines => _klines;
  String get currentInterval => _currentInterval;
  bool _showBB = false,
      _showMA20 = true,
      _showMA50 = false,
      _showVolume = true,
      _showRSI = false,
      _showMACD = false,
      _showMFI = false;
  bool get showBB => _showBB;
  bool get showMA20 => _showMA20;
  bool get showMA50 => _showMA50;
  bool get showVolume => _showVolume;
  bool get showRSI => _showRSI;
  bool get showMACD => _showMACD;
  bool get showMFI => _showMFI;
  MACDData? _macdData;
  MACDData? get macdData => _macdData;
  List<IndicatorPoint> _rsiData = [], _mfiData = [];
  List<IndicatorPoint> get rsiData => _rsiData;
  List<IndicatorPoint> get mfiData => _mfiData;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  StreamSubscription? _tickerSubscription,
      _depthSubscription,
      _tradeSubscription,
      _klineSubscription;
  final int _selectedTab = 0;
  int get selectedTab => _selectedTab;
  TradingViewModel() {
    _binanceService = BinanceService(
      symbol: _currentSymbol,
      interval: _currentInterval,
    );
    _initialize();
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    _klines = await _binanceService.fetchInitialKlines();
    _subscribeToStreams();
    _calculateIndicators(); // Tính toán lần đầu
    _setLoading(false);
  }

  void _subscribeToStreams() {
    // Hủy các subscription cũ
    _tickerSubscription?.cancel();
    _depthSubscription?.cancel();
    _tradeSubscription?.cancel();
    _klineSubscription?.cancel();

    _tickerSubscription = _binanceService.subscribeToTicker().listen((data) {
      _tickerData = TickerData(
        symbol: data['s'],
        currentPrice: double.parse(data['c']),
        priceChange: double.parse(data['p']),
        priceChangePercent: double.parse(data['P']),
        volume24h: double.parse(data['v']),
        high24h: double.parse(data['h']),
        low24h: double.parse(data['l']),
      );
      notifyListeners();
    });

    _depthSubscription = _binanceService.subscribeToDepth().listen((data) {
      final List<dynamic> askUpdates = data['asks'] ?? [];
      final List<dynamic> bidUpdates = data['bids'] ?? [];
      _asks =
          askUpdates
              .map(
                (ask) => OrderBookEntry(
                  price: double.parse(ask[0]),
                  quantity: double.parse(ask[1]),
                  isBid: false,
                ),
              )
              .toList();
      _bids =
          bidUpdates
              .map(
                (bid) => OrderBookEntry(
                  price: double.parse(bid[0]),
                  quantity: double.parse(bid[1]),
                  isBid: true,
                ),
              )
              .toList();
      if (_asks.isNotEmpty && _bids.isNotEmpty)
        _orderBookMidPrice = (_asks.first.price + _bids.first.price) / 2;
      double cumulativeAskTotal = _asks.fold(0.0, (s, e) => s + e.total);
      double cumulativeBidTotal = _bids.fold(0.0, (s, e) => s + e.total);
      _maxCumulativeTotal = max(cumulativeAskTotal, cumulativeBidTotal);
      notifyListeners();
    });

    _tradeSubscription = _binanceService.subscribeToTrades().listen((data) {
      final newTrade = TradeEntry(
        price: double.parse(data['p']),
        quantity: double.parse(data['q']),
        time: data['T'],
        isBuyerMaker: data['m'],
      );
      _trades.insert(0, newTrade);
      if (_trades.length > 100) _trades.removeLast();
      notifyListeners();
    });

    _klineSubscription = _binanceService.subscribeToKline().listen((data) {
      final klinePayload = data['k'];
      final newKline = KlineData(
        time: klinePayload['t'],
        open: double.parse(klinePayload['o']),
        high: double.parse(klinePayload['h']),
        low: double.parse(klinePayload['l']),
        close: double.parse(klinePayload['c']),
        volume: double.parse(klinePayload['v']),
      );

      bool isClosed = klinePayload['x'];
      if (_klines.isNotEmpty && _klines.last.time == newKline.time) {
        _klines[_klines.length - 1] = newKline;
      } else if (isClosed &&
          (_klines.isEmpty || newKline.time > _klines.last.time)) {
        _klines.add(newKline);
        if (_klines.length > 500) _klines.removeAt(0);
      }
      _calculateIndicators();
      notifyListeners();
    });
  }

  void _calculateIndicators() {
    if (_klines.isEmpty) return;
    if (_showRSI) _rsiData = IndicatorCalculator.calculateRSI(_klines, 14);
    if (_showMACD) _macdData = IndicatorCalculator.calculateMACD(_klines);
    // if (_showMFI) _mfiData = IndicatorCalculator.calculateMFI(_klines, 14); // MFI can be added back here
  }

  void changeTimeframe(String interval) {
    if (_currentInterval == interval) return;
    _setLoading(true);
    _currentInterval = interval;
    _binanceService.dispose(); // Đóng kết nối cũ
    _binanceService = BinanceService(
      symbol: _currentSymbol,
      interval: _currentInterval,
    ); // Tạo service mới
    // Xóa dữ liệu cũ
    _klines.clear();
    _trades.clear();
    _asks.clear();
    _bids.clear();
    _rsiData.clear();
    _macdData = null;
    _mfiData.clear();

    _initialize(); // Khởi tạo lại với timeframe mới
  }

  void toggleIndicator(Function(bool) setter, bool value) {
    setter(value);
    HapticFeedback.selectionClick();
    _calculateIndicators();
    notifyListeners();
  }

  void toggleBB(bool? v) {
    if (v != null) toggleIndicator((val) => _showBB = val, v);
  }

  void toggleMA20(bool? v) {
    if (v != null) toggleIndicator((val) => _showMA20 = val, v);
  }

  void toggleMA50(bool? v) {
    if (v != null) toggleIndicator((val) => _showMA50 = val, v);
  }

  void toggleVolume(bool? v) {
    if (v != null) {
      _showVolume = v;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void toggleRSI(bool? v) {
    if (v != null) toggleIndicator((val) => _showRSI = val, v);
  }

  void toggleMACD(bool? v) {
    if (v != null) toggleIndicator((val) => _showMACD = val, v);
  }

  void toggleMFI(bool? v) {
    if (v != null) toggleIndicator((val) => _showMFI = val, v);
  }

  @override
  void dispose() {
    _binanceService.dispose();
    _tickerSubscription?.cancel();
    _depthSubscription?.cancel();
    _tradeSubscription?.cancel();
    _klineSubscription?.cancel();
    super.dispose();
  }
}

// --- UI WIDGETS (Cập nhật để chống Overflow và đồng bộ) ---

// ... Các widget MyApp, TradingScreen, ChartSection, VolumeChart... giữ nguyên hoặc có thay đổi nhỏ

// SỬA LẠI HEADERSECTION ĐỂ CHỐNG OVERFLOW
class HeaderSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const HeaderSection({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    final ticker = viewModel.tickerData;
    if (ticker == null)
      return Container(
        height: 90,
        alignment: Alignment.center,
        color: AppColors.cardBackground,
        child: const CircularProgressIndicator(color: AppColors.accentYellow),
      );
    final isPositiveChange =
        double.parse(ticker.priceChangePercent.toString()) >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                ticker.symbol,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                FormatUtils.formatPrice(ticker.currentPrice),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isPositiveChange
                          ? AppColors.priceUp
                          : AppColors.priceDown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  '${isPositiveChange ? '+' : ''}${FormatUtils.formatPrice(ticker.priceChange, decimalPlaces: 2)} (${isPositiveChange ? '+' : ''}${ticker.priceChangePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isPositiveChange
                            ? AppColors.priceUp
                            : AppColors.priceDown,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Vol: ${FormatUtils.formatNumber(ticker.volume24h, decimalPlaces: 2)} ${ticker.symbol.replaceAll("USDT", "").replaceAll("BUSD", "")}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  '24h Cao: ${FormatUtils.formatPrice(ticker.high24h)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '24h Thấp: ${FormatUtils.formatPrice(ticker.low24h)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SỬA LẠI MARKETINFOSECTION ĐỂ CHỐNG OVERFLOW
class MarketInfoSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const MarketInfoSection({super.key, required this.viewModel});
  Widget _buildInfoRow(
    String label,
    String value, {
    Color valueColor = AppColors.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticker = viewModel.tickerData;
    if (ticker == null)
      return Center(
        child:
            viewModel.isLoading
                ? const CircularProgressIndicator(color: AppColors.accentYellow)
                : const Text(
                  "Không có dữ liệu thị trường.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
      );
    final isPositiveChange = ticker.priceChange >= 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin ${ticker.symbol}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Giá hiện tại',
            FormatUtils.formatPrice(ticker.currentPrice),
            valueColor:
                isPositiveChange ? AppColors.priceUp : AppColors.priceDown,
          ),
          _buildInfoRow(
            'Thay đổi 24h',
            '${isPositiveChange ? '+' : ''}${FormatUtils.formatPrice(ticker.priceChange, decimalPlaces: 2)} (${isPositiveChange ? '+' : ''}${ticker.priceChangePercent.toStringAsFixed(2)}%)',
            valueColor:
                isPositiveChange ? AppColors.priceUp : AppColors.priceDown,
          ),
          _buildInfoRow(
            'Cao nhất 24h',
            FormatUtils.formatPrice(ticker.high24h),
          ),
          _buildInfoRow(
            'Thấp nhất 24h',
            FormatUtils.formatPrice(ticker.low24h),
          ),
          _buildInfoRow(
            'KL 24h (${ticker.symbol.replaceAll("USDT", "").replaceAll("BUSD", "")})',
            FormatUtils.formatNumber(ticker.volume24h, decimalPlaces: 3),
          ),
          _buildInfoRow(
            'KL 24h (USDT)',
            FormatUtils.formatNumber(
              ticker.volume24h * ticker.currentPrice,
              decimalPlaces: 0,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mô tả (ví dụ)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đây là mô tả ví dụ cho ${ticker.symbol}...',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// SỬA LẠI PAINTER CỦA CHỈ BÁO ĐỂ XỬ LÝ NULL (ĐỒNG BỘ HÓA)
class RSIPainter extends CustomPainter {
  final List<IndicatorPoint> data;
  RSIPainter({required this.data});
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3;
    const dashSpace = 2;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(min(currentX + dashWidth, end.dx), end.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawGridAndLevels(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = AppColors.gridLine.withOpacity(0.5)
          ..strokeWidth = 0.5;
    final levelTextPaint = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );
    final levelTextStyle = TextStyle(
      color: AppColors.textSecondary.withOpacity(0.7),
      fontSize: 9,
    ); // Bỏ const
    Map<double, double> levels = {
      70: ((100 - 70) / 100) * size.height,
      50: ((100 - 50) / 100) * size.height,
      30: ((100 - 30) / 100) * size.height,
    };
    levels.forEach((levelValue, yPos) {
      _drawDashedLine(
        canvas,
        Offset(0, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
      levelTextPaint.text = TextSpan(
        text: levelValue.toInt().toString(),
        style: levelTextStyle,
      );
      levelTextPaint.layout();
      levelTextPaint.paint(
        canvas,
        Offset(
          size.width - levelTextPaint.width - 2,
          yPos - levelTextPaint.height - 2,
        ),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _drawGridAndLevels(canvas, size);
    final rsiPaint =
        Paint()
          ..color = AppColors.accentYellow.withOpacity(0.9)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth =
        data.length > 1 ? size.width / (data.length - 1) : size.width;

    for (int i = 0; i < data.length; i++) {
      if (data[i].value == null) continue; // Bỏ qua nếu giá trị là null
      final x = i * pointWidth;
      final y = ((100 - data[i].value!.clamp(0, 100)) / 100) * size.height;
      // Nếu điểm trước đó là null, di chuyển đến điểm này thay vì vẽ đường nối
      if (i > 0 && data[i - 1].value == null) {
        path.moveTo(x, y);
      } else if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, rsiPaint);
  }

  @override
  bool shouldRepaint(covariant MACDPainter oldDelegate) =>
      oldDelegate.data != data;

  // ... các hàm helper của RSIPainter không đổi ...
}

class MACDPainter extends CustomPainter {
  final MACDData data;
  MACDPainter({required this.data});
  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3;
    const dashSpace = 2;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(min(currentX + dashWidth, end.dx), end.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.macdLine.isEmpty) return;
    double minValue = double.infinity, maxValue = double.negativeInfinity;
    final allPoints = [
      ...data.macdLine,
      ...data.signalLine,
      ...data.histogram,
    ].where((p) => p.value != null);
    if (allPoints.isEmpty) return;
    for (final p in allPoints) {
      minValue = min(minValue, p.value!);
      maxValue = max(maxValue, p.value!);
    }
    if (minValue.isInfinite || maxValue.isInfinite || minValue == maxValue) {
      maxValue = minValue + 1;
    }
    final padding = (maxValue - minValue) * 0.1;
    maxValue += padding;
    minValue -= padding;
    if (minValue == maxValue) {
      maxValue += 0.5;
      minValue -= 0.5;
    }
    void drawGrid(Canvas canvas, Size size, double minValue, double maxValue) {
      final gridPaint =
          Paint()
            ..color = AppColors.gridLine.withOpacity(0.5)
            ..strokeWidth = 0.5;
      if (maxValue - minValue == 0) return;
      if (minValue <= 0 && maxValue >= 0) {
        final zeroY =
            size.height -
            ((0 - minValue) / (maxValue - minValue)) * size.height;
        drawDashedLine(
          canvas,
          Offset(0, zeroY),
          Offset(size.width, zeroY),
          gridPaint,
        );
      }
    }

    drawGrid(canvas, size, minValue, maxValue);
    _drawHistogram(canvas, size, minValue, maxValue);
    _drawLine(
      canvas,
      size,
      data.macdLine,
      minValue,
      maxValue,
      AppColors.priceUp,
      1.5,
    );
    _drawLine(
      canvas,
      size,
      data.signalLine,
      minValue,
      maxValue,
      AppColors.priceDown,
      1.5,
    );
  }

  // Sửa lại _drawHistogram và _drawLine để xử lý null
  void _drawHistogram(
    Canvas canvas,
    Size size,
    double minValue,
    double maxValue,
  ) {
    final points = data.histogram;
    if (points.isEmpty || maxValue - minValue == 0) return;
    final double barWSpacing = size.width / points.length;
    final double barW = barWSpacing * 0.7;
    for (int i = 0; i < points.length; i++) {
      if (points[i].value == null) continue;
      final value = points[i].value!;
      final x = i * barWSpacing + (barWSpacing - barW) / 2;
      final zeroY =
          size.height - ((0 - minValue) / (maxValue - minValue)) * size.height;
      final valueY =
          size.height -
          ((value - minValue) / (maxValue - minValue)) * size.height;
      final paint =
          Paint()
            ..color = (value >= 0 ? AppColors.priceUp : AppColors.priceDown)
                .withOpacity(0.5);
      canvas.drawRect(
        Rect.fromLTRB(x, min(zeroY, valueY), x + barW, max(zeroY, valueY)),
        paint,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<IndicatorPoint> points,
    double minValue,
    double maxValue,
    Color color,
    double strokeWidth,
  ) {
    if (points.isEmpty || maxValue - minValue == 0) return;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointW =
        points.length > 1 ? size.width / (points.length - 1) : size.width;
    for (int i = 0; i < points.length; i++) {
      if (points[i].value == null) continue;
      final x = i * pointW;
      final y =
          size.height -
          ((points[i].value! - minValue) / (maxValue - minValue)) * size.height;
      if (i > 0 && points[i - 1].value == null)
        path.moveTo(x, y);
      else if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MACDPainter oldDelegate) =>
      oldDelegate.data != data;

  // ... các hàm helper khác của MACDPainter không đổi ...
}

// *** Các widget còn lại (MyApp, TradingScreen, ...) và các Painter khác có thể giữ nguyên
// hoặc đã được tích hợp các thay đổi nhỏ trong các đoạn code trên.
// Dán toàn bộ code này vào một file main.dart mới để đảm bảo tính toàn vẹn.
