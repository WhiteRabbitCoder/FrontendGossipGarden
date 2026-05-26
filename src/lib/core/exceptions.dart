class UnauthorizedException implements Exception {
  UnauthorizedException(this.message);
  final String message;
  @override
  String toString() => message;
}
