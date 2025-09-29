import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chart/model/indicator_point.dart';
import 'package:chart/model/kline_data.dart';
import 'package:chart/model/order_book_entry.dart';
import 'package:chart/model/ticker_data.dart';
import 'package:chart/model/trade_entry.dart';
import 'dart:ui' as ui;

import 'package:chart/socket.dart';
import 'package:chart/utils/format.dart';
import 'package:chart/utils/indicator_calculator.dart';
import 'package:chart/utils/manager_value.dart';
import 'utils/colors.dart';

final double candleWidth = 3.5;
final double spacing = 0.75;

class TradingViewModel extends ChangeNotifier {
  final BinanceService _binanceService;
  String symbol;
  final dynamic stockdata;
  final dynamic klineStream;
  final dynamic exchange;

  TradingViewModel({
    required this.symbol,
    this.klineStream,
    this.stockdata,
    this.exchange,
  }) : _binanceService = BinanceService(
         symbol: symbol,
         streamdata: klineStream,
         stockdata: stockdata,
       ) {
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

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    await _fetchInitialData();
    _subscribeToStreams();
    _setLoading(false);
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
        if (_trades.length > 100) {
          _trades = _trades.sublist(0, 100);
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
            final newKline = KlineData.fromJson({
              "TradingDate": data['TradingDate'],
              "Time": data['Time'],
              "RefPrice": data['RefPrice'],
              "Highest": hightest,
              "Lowest": lowest,
              "LastPrice": data['LastPrice'],
              "TotalVol": data['TotalVol'] - _klines.last.volume,
            });
            print(newKline.time);
            print(_klines.last.time);
            if (_klines.isEmpty || newKline.time > _klines.last.time + 5000) {
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
              _tickerData = TickerData(
                symbol: data['Symbol'],
                currentPrice: (data['LastPrice'] / 1000 as num).toDouble(),
                priceChange: (data['Change'] / 1000 as num).toDouble(),
                priceChangePercent: double.parse(data['RatioChange']),
                volume24h: (data['TotalVol'] as num).toDouble(),
                high24h: (data['Highest'] as num).toDouble(),
                low24h: (data['Lowest'] as num).toDouble(),
              );
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

class VolumeChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final List<KlineData> klines;
  const VolumeChart({super.key, required this.klines});

  @override
  Widget build(BuildContext context) {
    if (klines.isEmpty) return const SizedBox.shrink();
    final double maxVolume = klines.isNotEmpty
        ? klines.map((k) => k.volume).reduce(max)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Volume",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: constraints.biggest,
                  painter: VolumePainter(
                    klines: klines,
                    maxVolume: maxVolume > 0 ? maxVolume : 1.0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VolumePainter extends CustomPainter {
  /* ... giữ nguyên ... */
  final List<KlineData> klines;
  final double maxVolume;
  VolumePainter({required this.klines, required this.maxVolume});

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty || maxVolume <= 0) return;
    final double barWidthWithSpacing = size.width / klines.length;
    final double barWidth = barWidthWithSpacing * 0.7;
    final double spacing = barWidthWithSpacing * 0.3;

    for (int i = 0; i < klines.length; i++) {
      final kline = klines[i];
      final double x = i * barWidthWithSpacing + spacing / 2;
      final double barHeight = (kline.volume / maxVolume) * size.height;
      final bool isBullish = kline.close >= kline.open;
      final volumePaint = Paint()
        ..color = (isBullish ? AppColors.priceUp : AppColors.priceDown)
            .withOpacity(0.3);
      canvas.drawRect(
        Rect.fromLTRB(x, size.height - barHeight, x + barWidth, size.height),
        volumePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VolumePainter oldDelegate) =>
      oldDelegate.klines != klines || oldDelegate.maxVolume != maxVolume;
}

class IndicatorPane extends StatelessWidget {
  /* ... giữ nguyên ... */
  final TradingViewModel viewModel;
  const IndicatorPane({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    if (viewModel.showRSI && viewModel.rsiData.isNotEmpty)
      return RSIChart(data: viewModel.rsiData);
    if (viewModel.showMACD &&
        viewModel.macdData != null &&
        viewModel.macdData!.macdLine.isNotEmpty)
      return MACDChart(data: viewModel.macdData!);
    if (viewModel.showMFI && viewModel.mfiData.isNotEmpty)
      return MFIChart(data: viewModel.mfiData);
    return Center(
      child: Text(
        viewModel.isLoading ? 'Đang tải chỉ báo...' : 'Chọn một chỉ báo',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class RSIChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final List<IndicatorPoint> data;
  const RSIChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RSI (14)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              if (data.isNotEmpty)
                Text(
                  data.last.value.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.accentYellow,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: RSIPainter(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class RSIPainter extends CustomPainter {
  /* ... giữ nguyên, ngoại trừ _drawGridAndLevels ... */
  final List<IndicatorPoint> data;
  RSIPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _drawGridAndLevels(canvas, size);
    final rsiPaint = Paint()
      ..color = AppColors.accentYellow.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth = data.length > 1
        ? size.width / (data.length - 1)
        : size.width;

    for (int i = 0; i < data.length; i++) {
      final x = i * pointWidth;
      final y = ((100 - data[i].value.clamp(0, 100)) / 100) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, rsiPaint);
  }

  void _drawGridAndLevels(Canvas canvas, Size size) {
    final gridPaint = Paint()
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

  @override
  bool shouldRepaint(covariant RSIPainter oldDelegate) =>
      oldDelegate.data != data;
}

class MACDChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final MACDData data;
  const MACDChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MACD (12,26,9)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ), // Bỏ const nếu cần
              if (data.macdLine.isNotEmpty &&
                  data.signalLine.isNotEmpty &&
                  data.histogram.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'M: ${data.macdLine.last.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.priceUp,
                        fontSize: 10,
                      ),
                    ), // Bỏ const nếu cần
                    Text(
                      'S: ${data.signalLine.last.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.priceDown,
                        fontSize: 10,
                      ),
                    ), // Bỏ const nếu cần
                    Text(
                      'H: ${data.histogram.last.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: data.histogram.last.value >= 0
                            ? AppColors.priceUp.withOpacity(0.7)
                            : AppColors.priceDown.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ) /* Bỏ const nếu cần */,
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: MACDPainter(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class MACDPainter extends CustomPainter {
  /* ... giữ nguyên ... */
  final MACDData data;
  MACDPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.macdLine.isEmpty &&
        data.signalLine.isEmpty &&
        data.histogram.isEmpty)
      return;
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    final allPoints = [...data.macdLine, ...data.signalLine, ...data.histogram];
    if (allPoints.isEmpty) return;
    for (final point in allPoints) {
      minValue = min(minValue, point.value);
      maxValue = max(maxValue, point.value);
    }
    if (minValue.isInfinite || maxValue.isInfinite || minValue == maxValue) {
      maxValue = minValue + 1;
    }
    final padding = (maxValue - minValue) * 0.1;
    maxValue += padding;
    minValue -= padding;
    if (minValue == maxValue) {
      maxValue = minValue + 0.5;
      minValue = minValue - 0.5;
    }

    _drawGrid(canvas, size, minValue, maxValue);
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

  void _drawGrid(Canvas canvas, Size size, double minValue, double maxValue) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 0.5;
    if (maxValue - minValue == 0) return;
    if (minValue <= 0 && maxValue >= 0) {
      final zeroY =
          size.height - ((0 - minValue) / (maxValue - minValue)) * size.height;
      _drawDashedLine(
        canvas,
        Offset(0, zeroY),
        Offset(size.width, zeroY),
        gridPaint,
      );
    }
  }

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

  void _drawHistogram(
    Canvas canvas,
    Size size,
    double minValue,
    double maxValue,
  ) {
    if (data.histogram.isEmpty || maxValue - minValue == 0) return;
    final double barWidthWithSpacing = size.width / data.histogram.length;
    final double barWidth = barWidthWithSpacing * 0.7;
    for (int i = 0; i < data.histogram.length; i++) {
      final value = data.histogram[i].value;
      final x = i * barWidthWithSpacing + (barWidthWithSpacing - barWidth) / 2;
      final zeroY =
          size.height - ((0 - minValue) / (maxValue - minValue)) * size.height;
      final valueY =
          size.height -
          ((value - minValue) / (maxValue - minValue)) * size.height;
      final paint = Paint()
        ..color = (value >= 0 ? AppColors.priceUp : AppColors.priceDown)
            .withOpacity(0.5);
      canvas.drawRect(
        Rect.fromLTRB(x, min(zeroY, valueY), x + barWidth, max(zeroY, valueY)),
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth = points.length > 1
        ? size.width / (points.length - 1)
        : size.width;
    for (int i = 0; i < points.length; i++) {
      final x = i * pointWidth;
      final y =
          size.height -
          ((points[i].value - minValue) / (maxValue - minValue)) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MACDPainter oldDelegate) =>
      oldDelegate.data != data;
}

class MFIChart extends StatelessWidget {
  /* ... giữ nguyên ... */
  final List<IndicatorPoint> data;
  const MFIChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MFI (14)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              if (data.isNotEmpty)
                Text(
                  data.last.value.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: MFIPainter(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class MFIPainter extends CustomPainter {
  /* ... giữ nguyên, ngoại trừ _drawGridAndLevels ... */
  final List<IndicatorPoint> data;
  MFIPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _drawGridAndLevels(canvas, size);
    final mfiPaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final double pointWidth = data.length > 1
        ? size.width / (data.length - 1)
        : size.width;
    for (int i = 0; i < data.length; i++) {
      final x = i * pointWidth;
      final y = ((100 - data[i].value.clamp(0, 100)) / 100) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, mfiPaint);
  }

  void _drawGridAndLevels(Canvas canvas, Size size) {
    final gridPaint = Paint()
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
      80: ((100 - 80) / 100) * size.height,
      50: ((100 - 50) / 100) * size.height,
      20: ((100 - 20) / 100) * size.height,
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

  @override
  bool shouldRepaint(covariant MFIPainter oldDelegate) =>
      oldDelegate.data != data;
}

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng Mua chưa cài đặt'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.controlButtonHover,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.priceUp),
            child: const Text(
              'MUA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng Bán chưa cài đặt'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.controlButtonHover,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceDown,
            ),
            child: const Text(
              'BÁN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OrderBookSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const OrderBookSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.asks.isEmpty && viewModel.bids.isEmpty && viewModel.isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentYellow),
      );
    if (viewModel.asks.isEmpty && viewModel.bids.isEmpty)
      return const Center(
        child: Text(
          "Không có dữ liệu sổ lệnh.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    double maxCumulativeTotal = viewModel.maxCumulativeTotal;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Giá (USDT)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ), // Bỏ const
              Expanded(
                flex: 3,
                child: Text(
                  'KL (${viewModel.tickerData?.symbol.replaceAll("USDT", "").replaceAll("BUSD", "") ?? "COIN"})',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ), // Đã sửa: Bỏ const
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Tổng (USDT)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ), // Bỏ const
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: min(viewModel.asks.length, 15),
                  itemBuilder: (context, index) {
                    final entry =
                        viewModel.asks[viewModel.asks.length - 1 - index];
                    final cumulativeTotalForDepth = viewModel.asks
                        .take(viewModel.asks.length - index)
                        .fold(0.0, (prev, e) => prev + e.total);
                    final depthPercentage =
                        cumulativeTotalForDepth / (maxCumulativeTotal + 1e-9);
                    return _buildOrderBookRow(
                      entry,
                      AppColors.askColor,
                      AppColors.askBgOpacity,
                      depthPercentage,
                      true,
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: min(viewModel.bids.length, 15),
                  itemBuilder: (context, index) {
                    final entry = viewModel.bids[index];
                    final cumulativeTotalForDepth = viewModel.bids
                        .take(index + 1)
                        .fold(0.0, (prev, e) => prev + e.total);
                    final depthPercentage =
                        cumulativeTotalForDepth / (maxCumulativeTotal + 1e-9);
                    return _buildOrderBookRow(
                      entry,
                      AppColors.bidColor,
                      AppColors.bidBgOpacity,
                      depthPercentage,
                      false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (viewModel.orderBookMidPrice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Giá giữa: ${FormatUtils.formatPrice(viewModel.orderBookMidPrice!)}',
              style: const TextStyle(
                color: AppColors.accentYellow,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderBookRow(
    OrderBookEntry entry,
    Color priceColor,
    Color rowBackgroundColor,
    double depthPercentage,
    bool isAsk,
  ) {
    // rowBackgroundColor là tên tham số đã sửa
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 20,
          margin: const EdgeInsets.symmetric(vertical: 0.5),
          child: Stack(
            children: [
              Positioned(
                right: isAsk ? null : 0,
                left: isAsk ? 0 : null,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * depthPercentage.clamp(0.0, 1.0),
                child: Container(color: rowBackgroundColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatPrice(entry.price, decimalPlaces: 2),
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatNumber(
                          entry.quantity,
                          decimalPlaces: 4,
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ), // Bỏ const
                    Expanded(
                      flex: 4,
                      child: Text(
                        FormatUtils.formatNumber(entry.total, decimalPlaces: 2),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ); // Bỏ const
  }
}
