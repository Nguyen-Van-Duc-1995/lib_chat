import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static const String _baseUrl = 'https://softsama.com/stock/api/orders';

  /// Hàm lấy danh sách lệnh theo mã chứng khoán (VD: MBB)
  static Future<List<dynamic>> listOrdersServices(String symbol) async {
    final url = Uri.parse('$_baseUrl?symbol=$symbol&limit=100');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Giải mã JSON trả về
        final data = jsonDecode(response.body);
        // Trả về danh sách lệnh
        return data['data'];
      } else {
        throw Exception('Lỗi khi gọi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }
}
