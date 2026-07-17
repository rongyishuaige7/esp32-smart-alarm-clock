import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alarm.dart';

/// 固件 REST 在业务失败时仍常返回 HTTP 200，必须解析 body 中的 [success]。
class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService([String? baseUrl])
      : _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl);

  /// 配网页面使用的中性默认地址。REST API 只会在设备连接到家庭/实验路由器
  /// 后监听；用户必须在设置中改成串口或 DHCP 列表中看到的实际设备地址。
  static const String defaultBaseUrl = 'http://192.168.4.1';
  static const Duration requestTimeout = Duration(seconds: 10);

  String _baseUrl;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = _normalizeBaseUrl(url);
  }

  static String _normalizeBaseUrl(String url) {
    var s = url.trim();
    if (s.isEmpty) {
      return defaultBaseUrl;
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    if (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  Uri _u(String path) => Uri.parse('$_baseUrl$path');

  static Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid JSON response');
    }
    return decoded;
  }

  /// 解析固件统一信封；成功时返回整图（含可选 [data]）。
  static Map<String, dynamic> _parseEnvelope(http.Response response) {
    if (response.statusCode == 204) {
      return {'success': true};
    }
    if (response.body.isEmpty) {
      throw ApiException('Empty response (HTTP ${response.statusCode})');
    }
    final map = _decodeJson(response.body);
    if (map['success'] != true) {
      final err = map['error']?.toString() ?? 'Request failed';
      throw ApiException(err.isEmpty ? 'Request failed' : err);
    }
    return map;
  }

  Future<List<Alarm>> getAlarms() async {
    final response = await http.get(_u('/alarms')).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    final map = _parseEnvelope(response);
    final raw = map['data'];
    if (raw == null) {
      return [];
    }
    if (raw is! List) {
      throw ApiException('Invalid alarms payload');
    }
    return raw
        .whereType<Map>()
        .map((e) => Alarm.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Alarm> addAlarm(int hour, int minute, bool enabled) async {
    final response = await http
        .post(
          _u('/alarms'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'hour': hour,
            'minute': minute,
            'enabled': enabled,
          }),
        )
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    final map = _parseEnvelope(response);
    final data = map['data'];
    if (data == null || data is! Map) {
      throw ApiException('No alarm data in response');
    }
    return Alarm.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Alarm> updateAlarm(int id, int hour, int minute, bool enabled) async {
    final response = await http
        .put(
          _u('/alarms/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'hour': hour,
            'minute': minute,
            'enabled': enabled,
          }),
        )
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    final map = _parseEnvelope(response);
    final data = map['data'];
    if (data == null || data is! Map) {
      throw ApiException('No alarm data in response');
    }
    return Alarm.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteAlarm(int id) async {
    final response =
        await http.delete(_u('/alarms/$id')).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    _parseEnvelope(response);
  }

  Future<void> stopAlarm() async {
    final response =
        await http.post(_u('/alarm/stop')).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    _parseEnvelope(response);
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(_u('/status')).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    final map = _parseEnvelope(response);
    final data = map['data'];
    if (data == null) {
      return {};
    }
    if (data is! Map) {
      throw ApiException('No status data');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> getTime() async {
    final response = await http.get(_u('/time')).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    final map = _parseEnvelope(response);
    final data = map['data'];
    if (data == null) {
      return {};
    }
    if (data is! Map) {
      throw ApiException('No time data');
    }
    return Map<String, dynamic>.from(data);
  }
}
