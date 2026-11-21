import 'package:cloud_firestore/cloud_firestore.dart';

double asNum(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int asInt(dynamic value, [int fallback = 0]) =>
    asNum(value, fallback.toDouble()).round();

String asString(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;

bool asBool(dynamic value, [bool fallback = false]) =>
    value is bool ? value : fallback;

DateTime asDate(dynamic value, [DateTime? fallback]) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  return fallback ?? DateTime.now();
}

DateTime? asOptionalDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<T> asList<T>(dynamic value, T? Function(dynamic item) mapper) {
  if (value is! List) return <T>[];
  return value.map(mapper).whereType<T>().toList();
}

List<String> asStringList(dynamic value) =>
    asList<String>(value, (item) => item is String ? item : null);
