import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static const String _baseUrl = 'https://softsama.com/stock/api/orders';

  /// Lấy danh sách lệnh theo symbol (có thể truyền URL đầy đủ)
  static Future<List<dynamic>> listOrdersServices(
    String symbol, {
    int? time,
  }) async {
    // Nếu time != null thì thêm query time
    final queryParameters = {
      'symbol': symbol,
      'limit': '100',
      if (time != null) 'time': time.toString(),
    };

    final url = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Lỗi khi gọi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }
}
