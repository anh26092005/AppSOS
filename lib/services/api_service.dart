import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static Map<String, String> _headers() => {'Content-Type': 'application/json'};

  static bool _looksLikeEmail(String v) => v.contains('@');

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final payload = jsonEncode({
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
    });

    final res = await http.post(url, headers: _headers(), body: payload);
    final data = _tryDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Đăng ký thất bại (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final isEmail = _looksLikeEmail(phoneOrEmail);
    final payload = jsonEncode({
      if (isEmail) 'email': phoneOrEmail else 'phone': phoneOrEmail,
      'password': password,
    });

    final res = await http.post(url, headers: _headers(), body: payload);
    final data = _tryDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return data;
    throw Exception(
      data['message'] ?? 'Đăng nhập thất bại (${res.statusCode})',
    );
  }

  static Map<String, dynamic> _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }
}
