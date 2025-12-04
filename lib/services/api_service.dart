import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Production: Cloudflare Tunnel URL
  // static const String baseUrl =
  //     'https://mai-lake-indoor-teeth.trycloudflare.com/api';

  // Development: Local emulator
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Production server (currently unreachable)
  // static const String baseUrl = 'http://42.116.145.85:5000/api';
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

  static Future<void> saveUser(Map<String, dynamic> user) async {
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

  static Future<void> setSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
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
        await saveUser(user);
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

    if (res.statusCode == 429) {
      throw SosBannedException(
        data['message'] ?? 'Bạn đã gửi quá nhiều yêu cầu',
      );
    }

    throw Exception(data['message'] ?? 'Gửi SOS thất bại');
  }

  static Future<bool> hasActiveSession() async {
    try {
      final remember = await getRememberMe().timeout(
        const Duration(seconds: 3),
        onTimeout: () => true, // Default to true to check token
      );
      if (!remember) return false;
      final token = await getToken();
      return token != null;
    } catch (e) {
      print('Error in hasActiveSession: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Vui lòng đăng nhập để xem tài khoản');
    }

    final url = Uri.parse('$baseUrl/auth/me');
    final headers = await _headers();
    final res = await http.get(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        await saveUser(user);
        return user;
      }
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể lấy thông tin tài khoản');
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Vui lòng đăng nhập để cập nhật hồ sơ');
    }

    final url = Uri.parse('$baseUrl/auth/profile');
    final headers = await _headers();

    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (bio != null) body['bio'] = bio;
    if (dateOfBirth != null)
      body['dateOfBirth'] = dateOfBirth.toIso8601String();

    final res = await http.put(url, headers: headers, body: jsonEncode(body));
    final data = _decode(res);

    if (res.statusCode == 200) {
      final user = data['data'];
      if (user is Map<String, dynamic>) {
        await saveUser(user);
        return user;
      }
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể cập nhật hồ sơ');
  }

  static Future<Map<String, dynamic>> togglePostLike(String postId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Vui lòng đăng nhập để thích bài viết');
    }

    final url = Uri.parse('$baseUrl/articles/$postId/like');
    final headers = await _headers();

    final res = await http.post(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể thích bài viết');
  }

  static Future<List<dynamic>> fetchBlogs({
    int page = 1,
    int limit = 10,
    String? authorId,
    String? status,
  }) async {
    String urlString =
        '$baseUrl/articles?page=$page&limit=$limit&sortBy=publishedAt&sortOrder=desc';
    if (authorId != null) {
      urlString += '&author=$authorId';
    }
    if (status != null) {
      urlString += '&status=$status';
    }
    final url = Uri.parse(urlString);
    final headers = await _headers();

    try {
      final res = await http.get(url, headers: headers);
      final data = _decode(res);

      if (res.statusCode == 200) {
        return data['data'] ?? [];
      }
      throw Exception(data['message'] ?? 'Không thể tải bản tin');
    } catch (e) {
      print('Error fetching blogs: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchVolunteerProfile(
    String userId,
  ) async {
    final url = Uri.parse('$baseUrl/volunteers/user/$userId');
    final headers = await _headers();

    try {
      final res = await http.get(url, headers: headers);
      final data = _decode(res);

      if (res.statusCode == 200) {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching volunteer profile: $e');
      return null;
    }
  }

  /// Lấy profile TNV của chính mình
  static Future<Map<String, dynamic>?> fetchMyVolunteerProfile() async {
    final url = Uri.parse('$baseUrl/volunteers/me');
    final headers = await _headers();

    try {
      final res = await http.get(url, headers: headers);
      final data = _decode(res);

      if (res.statusCode == 200) {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching my volunteer profile: $e');
      return null;
    }
  }

  /// Chấp nhận SOS case (cho tình nguyện viên)
  static Future<Map<String, dynamic>> acceptSosCase(
    String caseId, {
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('$baseUrl/sos/$caseId/accept');
    final headers = await _headers();

    final body = <String, dynamic>{};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể chấp nhận SOS case');
  }

  /// Từ chối SOS case (cho tình nguyện viên)
  static Future<Map<String, dynamic>> declineSosCase(
    String caseId,
    String declineReason,
  ) async {
    final url = Uri.parse('$baseUrl/sos/$caseId/decline');
    final headers = await _headers();

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'declineReason': declineReason}),
    );

    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể từ chối SOS case');
  }

  /// Đánh dấu đã xem SOS case (soft dismiss - không từ chối)
  static Future<Map<String, dynamic>> markSosCaseAsSeen(String caseId) async {
    final url = Uri.parse('$baseUrl/sos/$caseId/seen');
    final headers = await _headers();

    final res = await http.post(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể đánh dấu case là seen');
  }

  /// Lấy chi tiết SOS case
  static Future<Map<String, dynamic>> getSosCaseDetails(String caseId) async {
    final url = Uri.parse('$baseUrl/sos/$caseId');
    final headers = await _headers();

    final res = await http.get(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể lấy thông tin SOS case');
  }

  /// Hủy SOS case (cho reporter hoặc volunteer)
  static Future<Map<String, dynamic>> cancelSosCase(
    String caseId,
    String cancelReason,
  ) async {
    final url = Uri.parse('$baseUrl/sos/$caseId/cancel');
    final headers = await _headers();

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'cancelReason': cancelReason}),
    );

    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể hủy SOS case');
  }

  /// Hoàn thành SOS case (cho tình nguyện viên)
  static Future<Map<String, dynamic>> completeSosCase(String caseId) async {
    final url = Uri.parse('$baseUrl/sos/$caseId/complete');
    final headers = await _headers();

    final res = await http.post(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể hoàn thành SOS case');
  }

  /// Đăng ký FCM device token với backend
  static Future<Map<String, dynamic>> registerDeviceToken(
    String pushToken, {
    String platform = 'ANDROID',
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('$baseUrl/devices/register');
    final headers = await _headers();

    final body = <String, dynamic>{
      'pushToken': pushToken,
      'platform': platform,
    };

    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể đăng ký device token');
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': res.body};
    }
  }

  /// Upload hình ảnh (dùng chung API upload của article)
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/articles/upload-image');
    final token = await getToken();

    final request = http.MultipartRequest('POST', url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Xác định mime type dựa trên extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg'; // Default
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'gif') {
      mimeType = 'image/gif';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    final data = _decode(res);

    if (res.statusCode == 200 || res.statusCode == 201) {
      // API trả về data: { data: { bucket: "...", key: "...", url: "..." } }
      if (data['data'] != null) {
        return data['data'];
      }
    }

    throw Exception(data['message'] ?? 'Upload ảnh thất bại');
  }

  /// Đăng ký làm tình nguyện viên
  static Future<Map<String, dynamic>> registerVolunteer(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl/volunteers');
    final headers = await _headers();

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    final data = _decode(res);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Đăng ký TNV thất bại');
  }

  /// Toggle volunteer ready status (TNV tự toggle)
  static Future<Map<String, dynamic>> toggleVolunteerReady() async {
    final url = Uri.parse('$baseUrl/volunteers/me/toggle-ready');
    final headers = await _headers();

    final res = await http.patch(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể cập nhật trạng thái');
  }

  /// Tạo bài viết mới
  static Future<Map<String, dynamic>> createArticle({
    required String title,
    required String content,
    required String category,
    File? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/articles');
    final request = http.MultipartRequest('POST', url);

    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['category'] = category;

    if (imageFile != null) {
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    final data = _decode(res);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể tạo bài viết');
  }

  /// Upload/Update user avatar
  static Future<Map<String, dynamic>> updateAvatar(File imageFile) async {
    final uri = Uri.parse('$baseUrl/auth/avatar');
    final request = http.MultipartRequest('PUT', uri);

    // Add authorization header
    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add image file
    final filename = imageFile.path.split('/').last;
    request.files.add(
      await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
        filename: filename,
      ),
    );

    // Send request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      // Update cached user with new avatar
      final user = data['data']['user'];
      if (user is Map<String, dynamic>) {
        await saveUser(user);
      }
      return data;
    } else {
      throw Exception(data['message'] ?? 'Không thể tải ảnh lên');
    }
  }

  /// Lấy danh sách hàng đợi và lịch sử hoạt động (cho TNV)
  static Future<List<dynamic>> getVolunteerQueue() async {
    final url = Uri.parse('$baseUrl/volunteers/queue');
    final headers = await _headers();

    final res = await http.get(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode == 200) {
      return data['data'] ?? [];
    }

    throw Exception(data['message'] ?? 'Không thể lấy danh sách hoạt động');
  }

  /// Xóa hàng đợi (các yêu cầu cũ)
  static Future<void> clearVolunteerQueue() async {
    final url = Uri.parse('$baseUrl/volunteers/queue');
    final headers = await _headers();

    final res = await http.delete(url, headers: headers);
    final data = _decode(res);

    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không thể xóa hàng đợi');
    }
  }

  // Lấy SOS case đang hoạt động
  static Future<Map<String, dynamic>?> getActiveSosCase() async {
    try {
      final url = Uri.parse('$baseUrl/sos/active');
      final headers = await _headers();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = _decode(response);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting active SOS case: $e');
      return null;
    }
  }
}

class SosBannedException implements Exception {
  final String message;
  SosBannedException(this.message);
  @override
  String toString() => message;
}
