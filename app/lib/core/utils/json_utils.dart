// Small helpers shared by the models' fromJson. Callable responses arrive as
// Map<Object?, Object?>, so every nested map/list is cast defensively.

Map<String, dynamic> asJsonMap(Object? value) =>
    Map<String, dynamic>.from(value as Map);

List<Map<String, dynamic>> asJsonList(Object? value) =>
    (value as List? ?? const []).map(asJsonMap).toList();

int asInt(Object? value) => (value as num? ?? 0).round();

double asDouble(Object? value) => (value as num? ?? 0).toDouble();

DateTime asDate(Object? value) => DateTime.parse(value as String);

/// `yyyy-MM-dd`, the wire format for dates (CONTRACT §5).
String dateToIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
