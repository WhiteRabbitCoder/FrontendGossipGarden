import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:gossip_garden/core/config/app_config.dart';
import 'package:gossip_garden/core/config/firebase_environment.dart';
import 'package:gossip_garden/core/services/backend_auth_service.dart';
import 'package:gossip_garden/core/services/token_storage.dart';

import '../../data/auth_service.dart';
import '../../data/user_profile.dart';

class AuthSession {
  final UserProfile? profile;
  final bool firebaseEnabled;
  final bool onboardingCompleted;

  const AuthSession({
    required this.profile,
    required this.firebaseEnabled,
    this.onboardingCompleted = false,
  });
}

/// JWT de Supabase devuelto por el backend. Null cuando no hay sesión activa.
final backendTokenProvider = StateProvider<String?>((_) => null);

final _tokenStorageProvider = Provider<TokenStorage>((_) => const TokenStorage());

final backendAuthServiceProvider =
    Provider<BackendAuthService>((_) => BackendAuthService());

final authServiceProvider = Provider<AuthService>((ref) {
  if (!FirebaseEnvironment.isConfigured || Firebase.apps.isEmpty) {
    return AuthService();
  }
  return AuthService(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(),
    firestore: FirebaseFirestore.instance,
  );
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthSession>>(
  (ref) => AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(backendAuthServiceProvider),
    ref.read(_tokenStorageProvider),
    ref,
  ),
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthSession>> {
  AuthNotifier(
    this._authService,
    this._backendAuth,
    this._tokenStorage,
    this._ref, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn =
           googleSignIn ?? GoogleSignIn(serverClientId: AppConfig.googleClientId),
       super(const AsyncValue.loading()) {
    _bootstrap();
  }

  final AuthService _authService;
  final BackendAuthService _backendAuth;
  final TokenStorage _tokenStorage;
  final Ref _ref;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _subscription;

  /// Al arrancar, restaura el token persistido y enlaza el stream de Firebase Auth.
  Future<void> _bootstrap() async {
    final saved = await _tokenStorage.readToken();
    if (saved != null) {
      _ref.read(backendTokenProvider.notifier).state = saved;
      if (!FirebaseEnvironment.isConfigured) {
        final profileData = await _tokenStorage.readProfile();
        final profile = profileData != null
            ? UserProfile(
                uid: profileData['uid'] as String? ?? '',
                displayName: profileData['displayName'] as String?,
                email: profileData['email'] as String?,
                photoUrl: profileData['photoUrl'] as String?,
                onboardingCompleted:
                    profileData['onboardingCompleted'] as bool? ?? false,
                favoritePlantIds: (profileData['favoritePlantIds'] as List?)
                        ?.cast<String>() ??
                    const [],
                useGridView: profileData['useGridView'] as bool? ?? true,
                notificationPreference:
                    profileData['notificationPreference'] as String? ??
                        'important',
              )
            : null;

        state = AsyncValue.data(
          AuthSession(
            profile: profile,
            firebaseEnabled: false,
            onboardingCompleted: profile?.onboardingCompleted ?? true,
          ),
        );
        return;
      }
    } else {
      if (!FirebaseEnvironment.isConfigured) {
        state = AsyncValue.data(
          AuthSession(
            profile: null,
            firebaseEnabled: false,
            onboardingCompleted: false,
          ),
        );
        return;
      }
    }
    _bindFirebaseAuth();
  }

  Map<String, dynamic> _profileToMap(UserProfile profile) => {
        'uid': profile.uid,
        'displayName': profile.displayName,
        'email': profile.email,
        'photoUrl': profile.photoUrl,
        'onboardingCompleted': profile.onboardingCompleted,
        'favoritePlantIds': profile.favoritePlantIds,
        'useGridView': profile.useGridView,
        'notificationPreference': profile.notificationPreference,
      };

  void _bindFirebaseAuth() {
    if (!FirebaseEnvironment.isConfigured) return;

    _subscription = _authService.authStateChanges().listen((user) async {
      if (user == null) {
        state = AsyncValue.data(
          AuthSession(
            profile: null,
            firebaseEnabled: true,
            onboardingCompleted: false,
          ),
        );
        return;
      }

      UserProfile? profile;
      try {
        profile = await _authService.loadProfile(user.uid);
      } catch (_) {}
      state = AsyncValue.data(
        AuthSession(
          profile: profile ??
              UserProfile(
                uid: user.uid,
                displayName: user.displayName,
                email: user.email,
                photoUrl: user.photoURL,
                onboardingCompleted: false,
                favoritePlantIds: const [],
                useGridView: true,
                notificationPreference: 'important',
              ),
          firebaseEnabled: true,
          onboardingCompleted:
              profile?.onboardingCompleted ?? (user.emailVerified ? true : false),
        ),
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    if (!FirebaseEnvironment.isConfigured) {
      try {
        await _signInWithBackendGoogle();
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
        rethrow;
      }
      return;
    }

    try {
      await _signInWithBackendGoogle();
      await _authService.signInWithGoogle();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _signInWithBackendGoogle() async {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw BackendAuthException('Inicio de sesión con Google cancelado');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw BackendAuthException('No se recibió idToken de Google');

    final supabaseJwt = await _backendAuth.signInWithGoogleIdToken(idToken);
    await _tokenStorage.saveToken(supabaseJwt);
    _ref.read(backendTokenProvider.notifier).state = supabaseJwt;

    if (!FirebaseEnvironment.isConfigured) {
      final profile = UserProfile(
        uid: googleUser.id,
        displayName: googleUser.displayName,
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        onboardingCompleted: false,
        favoritePlantIds: const [],
        useGridView: true,
        notificationPreference: 'important',
      );
      await _tokenStorage.saveProfile(_profileToMap(profile));
      state = AsyncValue.data(
        AuthSession(
          profile: profile,
          firebaseEnabled: false,
          onboardingCompleted: false,
        ),
      );
    }
  }

  Future<void> registerWithEmailAndPassword(
      String email, String password, String username) async {
    state = const AsyncValue.loading();
    try {
      await _backendAuth.register(
        email: email,
        password: password,
        username: username,
      );

      if (FirebaseEnvironment.isConfigured) {
        try {
          await _authService.registerWithEmailAndPassword(
            email: email,
            password: password,
            name: username,
          );
        } catch (_) {}
      }

      await _doLogin(email, password);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      if (FirebaseEnvironment.isConfigured) {
        await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final profile = UserProfile(
          uid: email,
          displayName: email.split('@').first,
          email: email,
          onboardingCompleted: true,
          favoritePlantIds: const [],
          useGridView: true,
          notificationPreference: 'important',
        );
        await _tokenStorage.saveProfile(_profileToMap(profile));
        state = AsyncValue.data(
          AuthSession(
            profile: profile,
            firebaseEnabled: false,
            onboardingCompleted: true,
          ),
        );
      }

      await _doLogin(email, password);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithTestUser() async {
    print('🔑 [Auth] Iniciando sesión bypass de test...');
    state = const AsyncValue.loading();
    // Simulamos un delay para que se sienta real
    await Future.delayed(const Duration(milliseconds: 500));
    
    final profile = UserProfile(
      uid: 'test-user-id',
      displayName: 'Explorador del Jardín',
      email: 'test@gossipgarden.com',
      photoUrl: 'https://cdn-icons-png.flaticon.com/512/190/190601.png',
      onboardingCompleted: true, // Saltamos el onboarding para tests
      favoritePlantIds: const [],
      useGridView: true,
      notificationPreference: 'important',
    );
    
    // Usamos un token de test
    const testToken = 'gg_test_token_bypass';
    print('📦 [Auth] Guardando token de test y perfil mock...');
    await _tokenStorage.saveToken(testToken);
    await _tokenStorage.saveProfile(_profileToMap(profile));
    
    _ref.read(backendTokenProvider.notifier).state = testToken;
    
    print('✅ [Auth] Sesión de test activa para: ${profile.displayName}');
    state = AsyncValue.data(
      AuthSession(
        profile: profile,
        firebaseEnabled: FirebaseEnvironment.isConfigured,
        onboardingCompleted: true,
      ),
    );
  }

  Future<void> _doLogin(String email, String password) async {
    final token = await _backendAuth.login(email, password);
    await _tokenStorage.saveToken(token);
    _ref.read(backendTokenProvider.notifier).state = token;
  }

  Future<void> signOut() async {
    await _tokenStorage.clearToken();
    await _tokenStorage.clearProfile();
    _ref.read(backendTokenProvider.notifier).state = null;
    await _googleSignIn.signOut();

    if (FirebaseEnvironment.isConfigured) {
      await _authService.signOut();
    }

    state = AsyncValue.data(
      AuthSession(
        profile: null,
        firebaseEnabled: FirebaseEnvironment.isConfigured,
      ),
    );
  }

  Future<void> completeOnboarding() async {
    final current = state.value;
    if (current == null) return;

    if (FirebaseEnvironment.isConfigured) {
      final uid = current.profile?.uid;
      if (uid != null) await _authService.completeOnboarding(uid);
    }

    final profile = current.profile;
    final updated = profile == null
        ? null
        : UserProfile(
            uid: profile.uid,
            displayName: profile.displayName,
            email: profile.email,
            photoUrl: profile.photoUrl,
            onboardingCompleted: true,
            favoritePlantIds: profile.favoritePlantIds,
            useGridView: profile.useGridView,
            notificationPreference: profile.notificationPreference,
          );

    if (updated != null && !FirebaseEnvironment.isConfigured) {
      await _tokenStorage.saveProfile(_profileToMap(updated));
    }

    state = AsyncValue.data(
      AuthSession(
        profile: updated,
        firebaseEnabled: current.firebaseEnabled,
        onboardingCompleted: true,
      ),
    );
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final current = state.value;
    if (current == null || current.profile == null) return;

    final updatedProfile = UserProfile(
      uid: current.profile!.uid,
      displayName: displayName ?? current.profile!.displayName,
      email: current.profile!.email,
      photoUrl: photoUrl ?? current.profile!.photoUrl,
      onboardingCompleted: current.profile!.onboardingCompleted,
      favoritePlantIds: current.profile!.favoritePlantIds,
      useGridView: current.profile!.useGridView,
      notificationPreference: current.profile!.notificationPreference,
    );

    await _tokenStorage.saveProfile(_profileToMap(updatedProfile));

    if (FirebaseEnvironment.isConfigured) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (displayName != null) await user.updateDisplayName(displayName);
          if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        }
      } catch (_) {}
    }

    state = AsyncValue.data(
      AuthSession(
        profile: updatedProfile,
        firebaseEnabled: current.firebaseEnabled,
        onboardingCompleted: current.onboardingCompleted,
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
