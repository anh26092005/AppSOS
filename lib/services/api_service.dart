import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static Map<String, String> _headers() => {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    final data = _decode(res);

    if (res.statusCode == 201 || res.statusCode == 200) return data;

    throw Exception(data['message'] ?? 'Đăng ký thất bại');
  }

  static Future<Map<String, dynamic>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      }),
    );

    final data = _decode(res);

    if (res.statusCode == 200) return data;

    throw Exception(data['message'] ?? 'Đăng nhập thất bại');
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': res.body};
    }
  }
}
