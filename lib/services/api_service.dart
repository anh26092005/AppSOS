import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const String _tokenStorageKey = 'auth_token';
  static const String _userStorageKey = 'auth_user';
  static const String _rememberStorageKey = 'remember_login';
  static String? _token;
  static Map<String, dynamic>? _cachedUser;
  static bool? _rememberLogin;

  static Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenStorageKey);
    return _token;
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    if (_cachedUser != null) return _cachedUser;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userStorageKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cachedUser = decoded;
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<void> clearSession() async {
    _token = null;
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
    await prefs.remove(_userStorageKey);
    await prefs.remove(_rememberStorageKey);
    _rememberLogin = null;
  }

  static Future<void> setRememberMe(bool value) async {
    _rememberLogin = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberStorageKey, value);
  }

  static Future<bool> getRememberMe() async {
    if (_rememberLogin != null) return _rememberLogin!;
    final prefs = await SharedPreferences.getInstance();
    _rememberLogin = prefs.getBool(_rememberStorageKey) ?? true;
    return _rememberLogin!;
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      }),
    );

    final data = _decode(res);

    if (res.statusCode == 200) {
      if (data.containsKey('token')) {
        await setToken(data['token']);
      }
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        await _saveUser(user);
      }
      return data;
    }

    throw Exception(data['message'] ?? 'Đăng nhập thất bại');
  }

  static Future<Map<String, dynamic>> sendSOS({
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String description,
  }) async {
    final url = Uri.parse('$baseUrl/sos');
    final headers = await _headers();

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'emergencyType': emergencyType,
        'description': description,
        'isUrgent': true,
      }),
    );

    final data = _decode(res);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Gửi SOS thất bại');
  }

  static Future<bool> hasActiveSession() async {
    final remember = await getRememberMe();
    if (!remember) return false;
    final token = await getToken();
    return token != null;
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Vui long dang nhap de xem tai khoan');
    }

    final url = Uri.parse('$baseUrl/auth/me');
    final headers = await _headers();
    final res = await http.get(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        await _saveUser(user);
        return user;
      }
      return data;
    }

    throw Exception(data['message'] ?? 'Khong the lay thong tin tai khoan');
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': res.body};
    }
  }
}
