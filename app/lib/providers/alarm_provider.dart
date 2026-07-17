import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/api_service.dart';

const String _prefsKeyBaseUrl = 'esp32_base_url';

class AlarmProvider extends ChangeNotifier {
  AlarmProvider() : _api = ApiService();

  final ApiService _api;

  bool _prefsLoaded = false;

  /// 在首次请求前调用，以加载保存的设备地址。
  Future<void> ensurePrefsLoaded() async {
    if (_prefsLoaded) {
      return;
    }
    await _loadSavedBaseUrl();
    _prefsLoaded = true;
  }

  List<Alarm> _alarms = [];
  bool _loading = false;
  String? _lastError;
  Map<String, dynamic>? _deviceStatus;
  Map<String, dynamic>? _deviceTime;

  List<Alarm> get alarms => _alarms;
  bool get loading => _loading;
  String? get lastError => _lastError;
  Map<String, dynamic>? get deviceStatus => _deviceStatus;
  Map<String, dynamic>? get deviceTime => _deviceTime;
  String get baseUrl => _api.baseUrl;

  Future<void> _loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKeyBaseUrl);
      if (saved != null && saved.isNotEmpty) {
        _api.setBaseUrl(saved);
      }
    } catch (e) {
      debugPrint('loadSavedBaseUrl: $e');
    }
    notifyListeners();
  }

  /// 持久化并更新 API 基地址（可填 `192.168.1.21` 或完整 `http://192.168.1.21`）
  Future<void> setBaseUrl(String url) async {
    _api.setBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyBaseUrl, _api.baseUrl);
    _prefsLoaded = true;
    notifyListeners();
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  Future<bool> loadAlarms() async {
    await ensurePrefsLoaded();
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      _alarms = await _api.getAlarms();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAlarm(int hour, int minute, [bool enabled = true]) async {
    await ensurePrefsLoaded();
    _lastError = null;
    try {
      final alarm = await _api.addAlarm(hour, minute, enabled);
      _alarms.add(alarm);
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAlarm(Alarm updated) async {
    await ensurePrefsLoaded();
    _lastError = null;
    try {
      final alarm = await _api.updateAlarm(
        updated.id,
        updated.hour,
        updated.minute,
        updated.enabled,
      );
      final i = _alarms.indexWhere((a) => a.id == alarm.id);
      if (i >= 0) {
        _alarms[i] = alarm;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAlarm(int id) async {
    await ensurePrefsLoaded();
    _lastError = null;
    try {
      await _api.deleteAlarm(id);
      _alarms.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopRemoteAlarm() async {
    await ensurePrefsLoaded();
    _lastError = null;
    try {
      await _api.stopAlarm();
      await refreshDashboard();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 拉取 /status 与 /time，用于首页展示
  Future<bool> refreshDashboard() async {
    await ensurePrefsLoaded();
    try {
      _deviceStatus = await _api.getStatus();
      _deviceTime = await _api.getTime();
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
