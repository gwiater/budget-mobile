import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await SecureStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String path) async {
    final uri = Uri.parse('${Config.apiUrl}$path');
    final resp = await http.get(uri, headers: await _headers());
    return _handle(resp);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final uri = Uri.parse('${Config.apiUrl}$path');
    final resp = await http.post(
      uri,
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  static dynamic _handle(http.Response resp) {
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    if (resp.statusCode >= 200 && resp.statusCode < 300) return body;
    final msg = body['message'] ?? body['detail'] ?? 'Błąd ${resp.statusCode}';
    throw ApiException(msg, statusCode: resp.statusCode);
  }

  // Auth
  static Future<String> login(String username, String password) async {
    final data = await post('/login',
        {'username': username, 'password': password}, auth: false);
    final token = data['token'] as String;
    await SecureStorage.saveToken(token);
    return token;
  }

  static Future<void> logout() => SecureStorage.deleteToken();

  // Categories
  static Future<List<dynamic>> getCategories() async =>
      (await get('/categories')) as List<dynamic>;

  static Future<List<dynamic>> getSavingCategories() async =>
      (await get('/saving-categories')) as List<dynamic>;

  // Expenses
  static Future<dynamic> createExpenses(Map<String, dynamic> body) =>
      post('/expenses', body);

  static Future<dynamic> getExpenses({
    String? dateFrom,
    String? dateTo,
    int? categoryId,
    int limit = 50,
    String sort = 'e.date',
    String order = 'desc',
  }) {
    final params = <String, String>{
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    };
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (categoryId != null) params['category_id'] = categoryId.toString();

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return get('/expenses?$query');
  }

  static Future<dynamic> getBalance({String? date}) =>
      get('/balance${date != null ? '?date=$date' : ''}');

  // Planned expenses
  static Future<dynamic> getPlannedExpenses({String? date}) =>
      get('/planned-expenses${date != null ? '?date=$date' : ''}');

  static Future<dynamic> movePlannedExpense(int id, String date) =>
      post('/planned-expenses/$id/move', {'date': date});
}
