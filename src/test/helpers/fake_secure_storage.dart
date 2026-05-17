import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class FakeSecureStorage extends Mock implements FlutterSecureStorage {}

/// Returns a [FakeSecureStorage] whose write/read/delete methods use
/// an in-memory map, simulating real secure storage without platform channels.
FakeSecureStorage buildFakeSecureStorage() {
  final fake = FakeSecureStorage();
  final store = <String, String>{};

  when(
    () => fake.write(key: any(named: 'key'), value: any(named: 'value')),
  ).thenAnswer((inv) async {
    final key = inv.namedArguments[#key] as String;
    final value = inv.namedArguments[#value] as String?;
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  });

  when(() => fake.read(key: any(named: 'key'))).thenAnswer((inv) async {
    return store[inv.namedArguments[#key] as String];
  });

  when(() => fake.delete(key: any(named: 'key'))).thenAnswer((inv) async {
    store.remove(inv.namedArguments[#key] as String);
  });

  return fake;
}
