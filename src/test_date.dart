void main() {
  try {
    print(DateTime.parse("2026-06-28 04:09:19"));
  } catch (e) {
    print("Error parsing: $e");
  }
}
