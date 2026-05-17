import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gossip_garden/core/services/token_storage.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage fakeStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    fakeStorage = buildFakeSecureStorage();
    tokenStorage = TokenStorage(fakeStorage);
  });

  group('TokenStorage.saveToken / readToken', () {
    test('guarda y lee el token correctamente', () async {
      await tokenStorage.saveToken('my_jwt_token');
      final token = await tokenStorage.readToken();

      expect(token, 'my_jwt_token');
    });

    test('readToken devuelve null si no hay token guardado', () async {
      final token = await tokenStorage.readToken();
      expect(token, isNull);
    });

    test('sobreescribe token previo', () async {
      await tokenStorage.saveToken('old_token');
      await tokenStorage.saveToken('new_token');
      final token = await tokenStorage.readToken();

      expect(token, 'new_token');
    });
  });

  group('TokenStorage.clearToken', () {
    test('elimina el token guardado', () async {
      await tokenStorage.saveToken('token_to_delete');
      await tokenStorage.clearToken();
      final token = await tokenStorage.readToken();

      expect(token, isNull);
    });

    test('no lanza error si no hay token que borrar', () async {
      await expectLater(tokenStorage.clearToken(), completes);
    });
  });

  group('TokenStorage.saveProfile / readProfile', () {
    test('guarda y lee perfil como JSON', () async {
      final profileData = {
        'uid': 'user-uuid',
        'displayName': 'Angel',
        'email': 'angel@example.com',
        'onboardingCompleted': true,
      };

      await tokenStorage.saveProfile(profileData);
      final read = await tokenStorage.readProfile();

      expect(read, isNotNull);
      expect(read!['uid'], 'user-uuid');
      expect(read['displayName'], 'Angel');
      expect(read['onboardingCompleted'], isTrue);
    });

    test('readProfile devuelve null si no hay perfil guardado', () async {
      final profile = await tokenStorage.readProfile();
      expect(profile, isNull);
    });

    test('readProfile devuelve null si el JSON almacenado es inválido', () async {
      // Escribe directamente en el storage un JSON malformado
      when(
        () => fakeStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'not-valid-json{{{');

      final profile = await tokenStorage.readProfile();
      expect(profile, isNull);
    });
  });

  group('TokenStorage.clearProfile', () {
    test('elimina el perfil guardado', () async {
      await tokenStorage.saveProfile({'uid': 'test'});
      await tokenStorage.clearProfile();
      final profile = await tokenStorage.readProfile();

      expect(profile, isNull);
    });
  });
}
