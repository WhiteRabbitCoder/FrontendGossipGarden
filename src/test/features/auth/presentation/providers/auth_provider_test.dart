import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gossip_garden/core/services/backend_auth_service.dart';
import 'package:gossip_garden/core/services/token_storage.dart';
import 'package:gossip_garden/features/auth/data/auth_service.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockBackendAuthService extends Mock implements BackendAuthService {}

class MockAuthService extends Mock implements AuthService {}

class MockTokenStorage extends Mock implements TokenStorage {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Crea un [ProviderContainer] con mocks inyectados.
/// Inyecta [AuthNotifier] directamente para evitar el provider privado de
/// token_storage, que no es accesible fuera del archivo de declaración.
ProviderContainer buildContainer({
  required MockBackendAuthService mockBackendAuth,
  required MockTokenStorage mockTokenStorage,
}) {
  final mockAuthService = MockAuthService();
  when(() => mockAuthService.authStateChanges())
      .thenAnswer((_) => const Stream.empty());

  return ProviderContainer(
    overrides: [
      backendAuthServiceProvider.overrideWithValue(mockBackendAuth),
      authServiceProvider.overrideWithValue(mockAuthService),
      authStateProvider.overrideWith(
        (ref) => AuthNotifier(
          mockAuthService,
          mockBackendAuth,
          mockTokenStorage,
          ref,
        ),
      ),
    ],
  );
}

/// Fuerza la instanciación del [AuthNotifier] y espera a que [_bootstrap] complete.
/// Sin la lectura inicial el notifier no se crea y nunca sale de AsyncLoading.
Future<void> pumpBootstrap(ProviderContainer container) async {
  container.read(authStateProvider); // instancia AuthNotifier → dispara _bootstrap
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late MockBackendAuthService mockBackendAuth;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockBackendAuth = MockBackendAuthService();
    mockTokenStorage = MockTokenStorage();
  });

  // Registrar fallback values para mocktail
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('Bootstrap — sin token guardado', () {
    setUp(() {
      when(() => mockTokenStorage.readToken()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => null);
    });

    test('estado inicial es AsyncLoading', () {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);

      expect(container.read(authStateProvider), isA<AsyncLoading>());
    });

    test('estado final es AsyncData con profile null (sin sesión)', () async {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);

      await pumpBootstrap(container);

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<AuthSession>>());
      expect(state.value!.profile, isNull);
      expect(state.value!.onboardingCompleted, isFalse);
    });
  });

  group('Bootstrap — con token guardado', () {
    setUp(() {
      when(() => mockTokenStorage.readToken())
          .thenAnswer((_) async => 'saved_jwt_token');
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => {
            'uid': 'user-uuid',
            'displayName': 'Angel',
            'email': 'angel@example.com',
            'onboardingCompleted': true,
            'favoritePlantIds': <String>[],
            'useGridView': true,
            'notificationPreference': 'important',
          });
    });

    test('restaura la sesión y setea backendTokenProvider', () async {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);

      await pumpBootstrap(container);

      final state = container.read(authStateProvider);
      expect(state.value!.profile, isNotNull);
      expect(state.value!.profile!.uid, 'user-uuid');
      expect(state.value!.onboardingCompleted, isTrue);
      // Token debe estar en backendTokenProvider
      expect(container.read(backendTokenProvider), 'saved_jwt_token');
    });
  });

  group('signInWithEmailAndPassword — path Supabase-only', () {
    setUp(() {
      when(() => mockTokenStorage.readToken()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.saveToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStorage.saveProfile(any())).thenAnswer((_) async {});
    });

    test('transiciona loading→data con JWT en provider al hacer login', () async {
      when(() => mockBackendAuth.login('user@example.com', 'pass123'))
          .thenAnswer((_) async => 'fresh_jwt_token');

      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container
          .read(authStateProvider.notifier)
          .signInWithEmailAndPassword('user@example.com', 'pass123');

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<AuthSession>>());
      expect(container.read(backendTokenProvider), 'fresh_jwt_token');

      verify(() => mockTokenStorage.saveToken('fresh_jwt_token')).called(1);
    });

    test('transiciona a AsyncError cuando el login falla', () async {
      when(() => mockBackendAuth.login(any(), any()))
          .thenThrow(BackendAuthException('Credenciales incorrectas'));

      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await expectLater(
        container
            .read(authStateProvider.notifier)
            .signInWithEmailAndPassword('bad@example.com', 'wrong'),
        throwsA(isA<BackendAuthException>()),
      );

      expect(container.read(authStateProvider), isA<AsyncError>());
    });
  });

  group('registerWithEmailAndPassword — path Supabase-only', () {
    setUp(() {
      when(() => mockTokenStorage.readToken()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.saveToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStorage.saveProfile(any())).thenAnswer((_) async {});
    });

    test('registra y luego hace login automático', () async {
      when(() => mockBackendAuth.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          )).thenAnswer((_) async {});
      when(() => mockBackendAuth.login(any(), any()))
          .thenAnswer((_) async => 'new_user_jwt');

      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container
          .read(authStateProvider.notifier)
          .registerWithEmailAndPassword(
            'new@example.com',
            'password123',
            'NewUser',
          );

      expect(container.read(backendTokenProvider), 'new_user_jwt');
      verify(() => mockBackendAuth.register(
            email: 'new@example.com',
            password: 'password123',
            username: 'NewUser',
          )).called(1);
      verify(() => mockBackendAuth.login('new@example.com', 'password123'))
          .called(1);
    });
  });

  group('signOut', () {
    setUp(() {
      when(() => mockTokenStorage.readToken()).thenAnswer((_) async => 'jwt');
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => {
            'uid': 'u1',
            'onboardingCompleted': false,
            'favoritePlantIds': <String>[],
            'useGridView': true,
            'notificationPreference': 'important',
          });
      when(() => mockTokenStorage.clearToken()).thenAnswer((_) async {});
      when(() => mockTokenStorage.clearProfile()).thenAnswer((_) async {});
    });

    test('limpia el token y el perfil al cerrar sesión', () async {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container.read(authStateProvider.notifier).signOut();

      verify(() => mockTokenStorage.clearToken()).called(1);
      verify(() => mockTokenStorage.clearProfile()).called(1);
      expect(container.read(backendTokenProvider), isNull);
    });

    test('estado final tiene profile null tras signOut', () async {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container.read(authStateProvider.notifier).signOut();

      final state = container.read(authStateProvider);
      expect(state.value!.profile, isNull);
    });
  });

  group('completeOnboarding', () {
    setUp(() {
      when(() => mockTokenStorage.readToken())
          .thenAnswer((_) async => 'jwt_token');
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => {
            'uid': 'u1',
            'displayName': 'Test',
            'email': 'test@example.com',
            'onboardingCompleted': false,
            'favoritePlantIds': <String>[],
            'useGridView': true,
            'notificationPreference': 'important',
          });
      when(() => mockTokenStorage.saveProfile(any())).thenAnswer((_) async {});
    });

    test('actualiza onboardingCompleted a true', () async {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container.read(authStateProvider.notifier).completeOnboarding();

      final state = container.read(authStateProvider);
      expect(state.value!.onboardingCompleted, isTrue);
      expect(state.value!.profile!.onboardingCompleted, isTrue);
    });
  });

  group('updateProfile', () {
    setUp(() {
      when(() => mockTokenStorage.readToken())
          .thenAnswer((_) async => 'jwt_token');
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => {
            'uid': 'u1',
            'displayName': 'Original',
            'email': 'test@example.com',
            'onboardingCompleted': true,
            'favoritePlantIds': <String>[],
            'useGridView': true,
            'notificationPreference': 'important',
          });
      when(() => mockTokenStorage.saveProfile(any())).thenAnswer((_) async {});
    });

    test('actualiza displayName en el estado y persiste en storage', () async {
      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container
          .read(authStateProvider.notifier)
          .updateProfile(displayName: 'NuevoNombre');

      final state = container.read(authStateProvider);
      expect(state.value!.profile!.displayName, 'NuevoNombre');
      verify(() => mockTokenStorage.saveProfile(any())).called(1);
    });

    test('no modifica estado si no hay sesion activa', () async {
      when(() => mockTokenStorage.readToken()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.readProfile()).thenAnswer((_) async => null);

      final container = buildContainer(
        mockBackendAuth: mockBackendAuth,
        mockTokenStorage: mockTokenStorage,
      );
      addTearDown(container.dispose);
      await pumpBootstrap(container);

      await container
          .read(authStateProvider.notifier)
          .updateProfile(displayName: 'Ignored');

      final state = container.read(authStateProvider);
      expect(state.value!.profile, isNull);
      verifyNever(() => mockTokenStorage.saveProfile(any()));
    });
  });
}
