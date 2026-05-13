T enumFromString<T>(List<T> values, String? value, T defaultValue) {
  return values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => defaultValue,
  );
}