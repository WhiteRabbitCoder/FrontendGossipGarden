import 'dart:io';

String loadFixture(String filename) {
  final path = 'test/fixtures/$filename';
  return File(path).readAsStringSync();
}
