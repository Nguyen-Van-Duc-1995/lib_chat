import 'dart:async';
import 'dart:convert';
import 'package:chart/model/kline_data.dart';
import 'package:chart/model/ticker_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class BinanceService {
  final String symbol;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  // Separate controllers for each stream type
  final _tickerController = StreamController<Map<String, dynamic>>.broadcast();
  final _depthController = StreamController<Map<String, dynamic>>.broadcast();
  final _tradeController = StreamController<Map<String, dynamic>>.broadcast();
  final _klineController = StreamController<Map<String, dynamic>>.broadcast();

  // Current kline interval for subscription
  String _currentKlineInterval = '1m';

  BinanceService({this.symbol = 'btcusdt'}) {
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      // Create stream names for Binance WebSocket
      final symbolLower = symbol.toLowerCase();
      final streams = [
        '$symbolLower@ticker', // 24hr ticker statistics
        '$symbolLower@depth20@100ms', // Order book depth
        '$symbolLower@trade', // Trade streams
        '$symbolLower@kline_$_currentKlineInterval', // Kline/candlestick
      ];

      // final url =
      //     'wss://stream.binance.com:9443/stream?streams=${streams.join("/")}';

      // _channel = WebSocketChannel.connect(Uri.parse(url));
      // _channelSubscription = _channel!.stream.listen(
      //   _handleWebSocketMessage,
      //   onError: _handleWebSocketError,
      //   onDone: _handleWebSocketClosed,
      // );

      // print('Connected to Binance WebSocket: $url');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _reconnectAfterDelay();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);

      // Check if it's a stream data message
      if (data['stream'] != null && data['data'] != null) {
        final stream = data['stream'] as String;
        final streamData = data['data'] as Map<String, dynamic>;

        // Route to appropriate controller based on stream type
        if (stream.contains('@ticker')) {
          _tickerController.add(streamData);
        } else if (stream.contains('@depth')) {
          _depthController.add(streamData);
        } else if (stream.contains('@trade')) {
          _tradeController.add(streamData);
        } else if (stream.contains('@kline')) {
          _klineController.add(streamData);
        }
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleWebSocketError(error) {
    print('WebSocket error: $error');
    _reconnectAfterDelay();
  }

  void _handleWebSocketClosed() {
    print('WebSocket connection closed');
    _reconnectAfterDelay();
  }

  void _reconnectAfterDelay() {
    Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        print('Attempting to reconnect...');
        _connectWebSocket();
      }
    });
  }

  // Update kline subscription when interval changes
  void updateKlineInterval(String interval) {
    if (_currentKlineInterval != interval) {
      _currentKlineInterval = interval;
      _reconnectWithNewInterval();
    }
  }

  void _reconnectWithNewInterval() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _connectWebSocket();
  }

  // Fetch historical kline data from REST API
  Future<List<KlineData>> fetchKlines(
    String interval, {
    int limit = 200,
  }) async {
    try {
      // final url =
      //     'https://api.binance.com/api/v3/klines'
      //     '?symbol=${symbol.toUpperCase()}'
      //     '&interval=$interval'
      //     '&limit=$limit';
      switch (interval) {
        case '1m':
          interval = '1';
          break;
        case '5m':
          interval = '5';
          break;
        case '15m':
          interval = '15';
          break;
        case '30m':
          interval = '30';
          break;
        case '1h':
          interval = '60';
          break;
        case '2h':
          interval = '120';
          break;
        case '1d':
          interval = '1D';
          break;
        case '1 tuần':
          interval = 'W';
          break;
        case '1 tháng':
          interval = 'M';
          break;
        default:
          interval = '1';
      }
      final now = DateTime.now();
      // Đổi sang UTC rồi lấy timestamp (giây)Unix
      final timestamp = now.toUtc().millisecondsSinceEpoch ~/ 1000;
      final response = await http.get(
        // Uri.parse("https://softsama.com/stock/api/candles"),
        Uri.parse(
          (interval == '1D' || interval == 'W' || interval == 'M')
              ? "https://iboard-api.ssi.com.vn/statistics/charts/history?resolution=$interval&symbol=${symbol.toUpperCase()}&from=1341705600&to=1757376000"
              : "https://iboard-api.ssi.com.vn/statistics/charts/history?resolution=$interval&symbol=${symbol.toUpperCase()}&from=1754641393&to=$timestamp",
        ),
      );

      if (response.statusCode == 200) {
        // final List<dynamic> data = json.decode(response.body);
        // return data.map((kline) => KlineData.fromBinanceKline(kline)).toList();
        final rawData = json.decode(response.body)['data'];
        final int length = rawData['t'].length;

        // Chuyển đổi thành List<List<dynamic>> để dùng được với fromBinanceKline
        final transformedData = List.generate(length, (index) {
          return [
            rawData['t'][index], // time
            rawData['o'][index], // open
            rawData['h'][index], // high
            rawData['l'][index], // low
            rawData['c'][index], // close
            rawData['v'][index], // volume
          ];
        });

        // Chuyển thành danh sách KlineData
        return transformedData
            .map((kline) => KlineData.fromBinanceKline(kline))
            .toList();
      } else {
        throw Exception('Failed to fetch klines: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching klines: $e');
      // Return empty list on error
      return [];
    }
  }

  // Fetch 24hr ticker data from REST API
  Future<TickerData?> fetch24hrTickerBiance() async {
    try {
      final url =
          'https://api.binance.com/api/v3/ticker/24hr'
          '?symbol=${symbol.toUpperCase()}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TickerData.fromBinance24hrTicker(data);
      } else {
        throw Exception('Failed to fetch ticker: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ticker: $e');
      return null;
    }
  }

  Future<TickerData?> fetch24hrTicker() async {
    try {
      final url =
          'https://softsama.com/stock/api/onlycode?${symbol.toUpperCase()}';
      print(url);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TickerData.fromStockApi(data['data']);
      } else {
        throw Exception('Failed to fetch ticker: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ticker: $e');
      return null;
    }
  }

  // Stream getters
  Stream<Map<String, dynamic>> subscribeToTicker() => _tickerController.stream;
  Stream<Map<String, dynamic>> subscribeToDepth() => _depthController.stream;
  Stream<Map<String, dynamic>> subscribeToTrades() => _tradeController.stream;
  Stream<Map<String, dynamic>> subscribeToKline(String interval) {
    // Update interval if different
    if (interval != _currentKlineInterval) {
      updateKlineInterval(interval);
    }
    return _klineController.stream;
  }

  bool _isDisposed = false;

  void dispose() {
    _isDisposed = true;
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _tickerController.close();
    _depthController.close();
    _tradeController.close();
    _klineController.close();
  }
}
