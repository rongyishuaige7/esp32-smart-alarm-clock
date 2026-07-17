class Alarm {
  final int id;
  final int hour;
  final int minute;
  final bool enabled;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.enabled,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, [int fallback = 0]) {
      if (v == null) {
        return fallback;
      }
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return int.tryParse(v.toString()) ?? fallback;
    }

    bool asBool(dynamic v, [bool fallback = true]) {
      if (v == null) {
        return fallback;
      }
      if (v is bool) {
        return v;
      }
      if (v is num) {
        return v != 0;
      }
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') {
        return true;
      }
      if (s == 'false' || s == '0') {
        return false;
      }
      return fallback;
    }

    return Alarm(
      id: asInt(json['id']),
      hour: asInt(json['hour']),
      minute: asInt(json['minute']),
      enabled: asBool(json['enabled'], true),
    );
  }

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Alarm copyWith({
    int? id,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }
}
