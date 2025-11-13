import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:chart/model/indicator_point.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/model/order_book_entry.dart';
import 'package:chart/model/ticker_data.dart';
import 'package:chart/model/trade_entry.dart';
import 'package:chart/services/list_orders_services.dart';
import 'package:chart/socket.dart';
import 'package:chart/utils/indicator_calculator.dart';
import 'package:chart/utils/manager_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TradingViewModel extends ChangeNotifier {
  final BinanceService _binanceService;
  String symbol;
  final dynamic stockdata;
  final dynamic klineStream;
  final dynamic exchange;
  final dynamic exchangeStream;
  final dynamic _currentExchange;
  final Function(dynamic)? onSearchPressed;

  TradingViewModel({
    required this.symbol,
    this.klineStream,
    this.stockdata,
    this.exchange,
    this.exchangeStream,
    this.onSearchPressed,
  }) : _binanceService = BinanceService(
         symbol: symbol,
         streamdata: klineStream,
         stockdata: stockdata,
       ),
       _currentExchange = exchange {
    // Khởi tạo với giá trị ban đầu
    debugPrint(
      "TradingViewModel created with callback: ${onSearchPressed != null ? 'NOT NULL' : 'NULL'}",
    );
    _initialize();
  }
  String _currentInterval = '1d';
  final List<String> timeframes = [
    '5m',
    '15m',
    '30m',
    '1h',
    '1d',
    '1 tuần',
    '1 tháng',
  ];
  final List<String> indicators = [
    'EMA20',
    'EMA50',
    'BB',
    'Volume',
    'RSI',
    'MACD',
    'MFI',
    'Ichimoku',
    'More',
  ];

  TickerData? _tickerData;
  TickerData? get tickerData => _tickerData;
  dynamic get getExchange => _currentExchange ?? exchange;

  List<OrderBookEntry> _asks = [];
  List<OrderBookEntry> get asks => _asks;
  List<OrderBookEntry> _bids = [];
  List<OrderBookEntry> get bids => _bids;
  double _maxCumulativeTotal = 0;
  double get maxCumulativeTotal => _maxCumulativeTotal;
  double? _orderBookMidPrice;
  double? get orderBookMidPrice => _orderBookMidPrice;

  List<TradeEntry> _trades = [];
  List<TradeEntry> get trades => _trades;

  List<KlineData> _klines = [];
  List<KlineData> get klines => _klines;
  String get currentInterval => _currentInterval;

  // Indicator toggles
  bool _showBB = false;
  bool get showBB => _showBB;
  bool _showEMA20 = true;
  bool get showEMA20 => _showEMA20;
  bool _showEMA50 = false;
  bool get showEMA50 => _showEMA50;
  bool _showVolume = true;
  bool get showVolume => _showVolume;
  bool _showRSI = false;
  bool get showRSI => _showRSI;
  bool _showMACD = false;
  bool get showMACD => _showMACD;
  bool _showMFI = false;
  bool get showMFI => _showMFI;
  bool _showIchimoku = false;
  bool get showIchimoku => _showIchimoku;

  // Indicator data
  final List<IndicatorPoint> _rsiData = [];
  List<IndicatorPoint> get rsiData => _rsiData;
  MACDData? _macdData;
  MACDData? get macdData => _macdData;
  List<IndicatorPoint> _mfiData = [];
  List<IndicatorPoint> get mfiData => _mfiData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription? _tickerSubscription;
  StreamSubscription? _depthSubscription;
  StreamSubscription? _tradeSubscription;
  StreamSubscription? _klineSubscription;

  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void handleSearchPressed(dynamic data) {
    if (onSearchPressed != null) {
      onSearchPressed!(data);
    } else {
      debugPrint("Search pressed - no callback assigned.");
    }
  }

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _orderList(String symbol) async {
    try {
      List<dynamic> orders = await OrderService.listOrdersServices(symbol);
      _trades.addAll(orders.map((data) => TradeEntry.fromJson(data)).toList());
    } catch (e) {
      print('Lỗi khi lấy danh sách lệnh: $e');
    }
  }

  Future<void> loadMoreTrades() async {
    if (_trades.isEmpty) return;

    try {
      final lastTradeTime = _trades.last.dateTime.millisecondsSinceEpoch;

      // Truyền time vào API
      List<dynamic> orders = await OrderService.listOrdersServices(
        symbol,
        time: lastTradeTime,
      );

      final newTrades = orders
          .map((data) => TradeEntry.fromJson(data))
          .toList();

      _trades.addAll(newTrades);
    } catch (e) {
      print('Lỗi khi lấy danh sách lệnh: $e');
    }
  }

  Future<void> _initialize() async {
    _orderList(symbol);
    _setLoading(true);
    await _fetchInitialData();
    _subscribeToStreams();
    _setLoading(false);
    _subscribeToStreamsExchange();
  }

  void _subscribeToStreamsExchange() {
    exchangeStream?.stream.listen(
      (data) {
        final indexId = data['IndexId'];
        if (indexId == 'VNINDEX' || indexId == 'VN30') {
          // Xóa item cũ nếu đã tồn tại
          _currentExchange.removeWhere((item) => item['IndexId'] == indexId);
          // Thêm item mới
          _currentExchange.add(data);
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Exchange stream error: $error');
      },
    );
  }

  Future<void> _fetchInitialData() async {
    try {
      // _tickerData = await _binanceService.fetch24hrTicker();
      if (stockdata == null) {
        _tickerData = await _binanceService.fetch24hrTicker();
      } else {
        _tickerData = _binanceService.initSymbol();
      }

      // Fetch historical klines and initial ticker data
      _klines = await _binanceService.fetchKlines(_currentInterval, limit: 200);

      _calculateIndicators();
    } catch (e) {
      print('Error fetching initial data: $e');
    }
  }

  void updateSymbol(String newSymbol) {
    if (newSymbol != symbol) {
      symbol = newSymbol;
      _initialize();
      notifyListeners();
    }
  }

  void _subscribeToStreams() {
    // Subscribe to ticker updates
    _tickerSubscription?.cancel();
    _tickerSubscription = _binanceService.subscribeToTicker().listen((data) {
      try {
        _tickerData = TickerData(
          symbol: data['s'],
          currentPrice: double.parse(data['c']),
          priceChange: double.parse(
            data['P'],
          ), // Note: 'P' is percentage change
          priceChangePercent: double.parse(data['P']),
          volume24h: double.parse(data['v']),
          high24h: double.parse(data['h']),
          low24h: double.parse(data['l']),
        );
        notifyListeners();
      } catch (e) {
        print('Error processing ticker data: $e');
      }
    }, onError: (error) => print('Ticker stream error: $error'));

    // Subscribe to order book updates
    _depthSubscription?.cancel();
    _depthSubscription = _binanceService.subscribeToDepth().listen((data) {
      try {
        final List<dynamic> askUpdates = data['asks'] ?? [];
        final List<dynamic> bidUpdates = data['bids'] ?? [];

        _asks = askUpdates
            .map(
              (ask) => OrderBookEntry(
                price: double.parse(ask[0]),
                quantity: double.parse(ask[1]),
                isBid: false,
              ),
            )
            .where((entry) => entry.quantity > 0) // Filter out zero quantities
            .toList();

        _bids = bidUpdates
            .map(
              (bid) => OrderBookEntry(
                price: double.parse(bid[0]),
                quantity: double.parse(bid[1]),
                isBid: true,
              ),
            )
            .where((entry) => entry.quantity > 0) // Filter out zero quantities
            .toList();

        // Sort order book
        _asks.sort((a, b) => a.price.compareTo(b.price));
        _bids.sort((a, b) => b.price.compareTo(a.price));

        // Calculate mid price
        if (_asks.isNotEmpty && _bids.isNotEmpty) {
          _orderBookMidPrice = (_asks.first.price + _bids.first.price) / 2;
        }

        // Calculate cumulative totals for depth visualization
        double cumulativeAskTotal = _asks.fold(
          0.0,
          (sum, entry) => sum + entry.total,
        );
        double cumulativeBidTotal = _bids.fold(
          0.0,
          (sum, entry) => sum + entry.total,
        );
        _maxCumulativeTotal = max(cumulativeAskTotal, cumulativeBidTotal);
        if (_maxCumulativeTotal == 0) _maxCumulativeTotal = 1;

        notifyListeners();
      } catch (e) {
        print('Error processing depth data: $e');
      }
    }, onError: (error) => print('Depth stream error: $error'));

    // Subscribe to trade updates
    _tradeSubscription?.cancel();
    _tradeSubscription = _binanceService.subscribeToTrades().listen((data) {
      try {
        _trades.insert(0, TradeEntry.fromBinanceTrade(data));
        if (_trades.length > 1000) {
          _trades = _trades.sublist(0, 1000);
        }
        notifyListeners();
      } catch (e) {
        print('Error processing trade data: $e');
      }
    }, onError: (error) => print('Trade stream error: $error'));

    // Subscribe to kline updates
    _klineSubscription?.cancel();

    // _klineSubscription = _binanceService
    //     .subscribeToKline(_currentInterval)
    //     .listen((data) {
    //       try {
    //         final klineData = data['k'];
    //         final newKline = KlineData(
    //           time: klineData['t'],
    //           open: double.parse(klineData['o']),
    //           high: double.parse(klineData['h']),
    //           low: double.parse(klineData['l']),
    //           close: double.parse(klineData['c']),
    //           volume: double.parse(klineData['v']),
    //         );

    //         // Update or add kline data
    //         if (_klines.isNotEmpty && _klines.last.time == newKline.time) {
    //           // Update existing kline
    //           _klines[_klines.length - 1] = newKline;
    //         } else if (_klines.isEmpty || newKline.time > _klines.last.time) {
    //           // Add new kline
    //           _klines.add(newKline);
    //           // Limit to last 500 klines
    //           if (_klines.length > 500) {
    //             _klines.removeAt(0);
    //           }
    //         }

    //         notifyListeners();
    //       } catch (e) {
    //         print('Error processing kline data: $e');
    //       }
    //     }, onError: (error) => print('Kline stream error: $error'));
    //     final newKline = KlineData.fromJson({
    //   "TradingDate": data['TradingDate'],
    //   "Time": data['Time'],
    //   "RefPrice": data['RefPrice'],
    //   "Highest": data['Highest'],
    //   "Lowest": data['Lowest'],
    //   "LastPrice": data['LastPrice'],
    //   "TotalVol": data['TotalVol'] - _klines.last.volume,
    // });
    double hightest = 0, lowest = 1000000000;
    _klineSubscription = _binanceService
        .subscribeToKline(_currentInterval)
        .listen((data) {
          hightest = hightest == 0
              ? data['LastPrice'].toDouble()
              : math.max(hightest, data['LastPrice'].toDouble());
          lowest = lowest == 1000000000
              ? data['LastPrice'].toDouble()
              : math.min(lowest, data['LastPrice'].toDouble());
          try {
            _trades.insert(0, TradeEntry.fromJson(data));
            if (_trades.length > 1000) {
              _trades = _trades.sublist(0, 1000);
            }
            notifyListeners();
          } catch (e) {}
          try {
            final newKline = KlineData.fromJson({
              "TradingDate": data['TradingDate'],
              "Time": data['Time'],
              "RefPrice": data['LastPrice'],
              "Highest": hightest,
              "Lowest": lowest,
              "LastPrice": data['LastPrice'],
              "TotalVol": data['TotalVol'] - _klines.last.volume,
            });
            if (_klines.isEmpty ||
                newKline.time >
                    _klines.last.time +
                        (_currentInterval == '1d'
                            ? 99999
                            : _currentInterval == '5m'
                            ? 200
                            : 500)) {
              _klines.add(newKline);
              hightest = 0;
              lowest = 1000000000;
              // Limit to last 500 klines
              if (_klines.length > 500) {
                _klines.removeAt(0);
              }
            } else {
              // _klines[_klines.length - 1].close = data['LastPrice'] / 1000;
              // _klines[_klines.length - 1] = newKline;
              if (_klines.isNotEmpty) {
                _klines[_klines.length - 1] = _klines.last.copyWith(
                  close: data['LastPrice'] / 1000,
                );
              }
            }

            try {
              _tickerData = TickerData.fromStockApi(data);
              if (_tickerData != null) {
                print(_tickerData!.currentPrice.toString());
              }
            } catch (e) {
              print('Error processing ticker data: $e');
            }

            notifyListeners();
          } catch (e) {
            print('Error processing kline data: $e');
          }
        }, onError: (error) => print('Kline stream error: $error'));
  }

  void _calculateIndicators() {
    if (_klines.isEmpty) return;

    try {
      if (_showRSI) {}
      if (_showMACD) {
        _macdData = IndicatorCalculator.calculateMACD(_klines);
      }
      if (_showMFI) {
        _mfiData = IndicatorCalculator.calculateMFI(_klines, 14);
      }
    } catch (e) {
      print('Error calculating indicators: $e');
    }
  }

  void changeTimeframe(String interval) {
    if (_currentInterval == interval) return;

    _currentInterval = interval;
    HapticFeedback.lightImpact();
    _setLoading(true);

    // Cancel existing subscriptions
    _klineSubscription?.cancel();

    // Clear existing data
    _klines.clear();
    _rsiData.clear();
    _macdData = null;
    _mfiData.clear();

    // Update service interval and refetch data
    _binanceService.updateKlineInterval(interval);

    _fetchInitialData().then((_) {
      _subscribeToStreams();
      _setLoading(false);
    });
  }

  // Indicator toggle methods remain the same
  void toggleBB(bool? v) {
    if (v != null) {
      _showBB = v;
      HapticFeedback.selectionClick();
      _calculateIndicators();
      notifyListeners();
    }
  }

  void toggleMA20(bool? v) {
    if (v != null) {
      _showEMA20 = v;
      HapticFeedback.selectionClick();
      _calculateIndicators();
      notifyListeners();
    }
  }

  void toggleMA50(bool? v) {
    if (v != null) {
      _showEMA50 = v;
      HapticFeedback.selectionClick();
      _calculateIndicators();
      notifyListeners();
    }
  }

  void toggleVolume(bool? v) {
    if (v != null) {
      _showVolume = v;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void toggleRSI(bool? v) {
    if (v != null) {
      if (v) {
        if (!indicatorTT.contains('RSI')) {
          indicatorTT.add('RSI');
        }
      } else {
        indicatorTT.remove('RSI');
      }
      _showRSI = v;
      HapticFeedback.selectionClick();
      _calculateIndicators();
      notifyListeners();
    }
  }

  void toggleMACD(bool? v) {
    if (v != null) {
      if (v) {
        if (!indicatorTT.contains('MACD')) {
          indicatorTT.add('MACD');
        }
      } else {
        indicatorTT.remove('MACD');
      }
      _showMACD = v;
      HapticFeedback.selectionClick();
      _calculateIndicators();
      notifyListeners();
    }
  }

  void toggleMFI(bool? v) {
    if (v != null) {
      if (v) {
        if (!indicatorTT.contains('MFI')) {
          indicatorTT.add('MFI');
        }
      } else {
        indicatorTT.remove('MFI');
      }
      _showMFI = v;
      HapticFeedback.selectionClick();
      _calculateIndicators();
      notifyListeners();
    }
  }

  void toggleIchimoku(bool? v) {
    _showIchimoku = v ?? false;
    HapticFeedback.selectionClick();
    _calculateIndicators();
    notifyListeners();
  }

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    _depthSubscription?.cancel();
    _tradeSubscription?.cancel();
    _klineSubscription?.cancel();
    _binanceService.dispose();
    super.dispose();
  }
}
