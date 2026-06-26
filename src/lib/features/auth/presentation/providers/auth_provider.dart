import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../data/auth_dto.dart';

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

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final backendAuthServiceProvider =
    Provider<BackendAuthService>((_) => BackendAuthService());

final authServiceProvider = Provider<AuthService>((ref) {
  if (!FirebaseEnvironment.isConfigured || Firebase.apps.isEmpty) {
    return AuthService();
  }
  return AuthService(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      clientId: kIsWeb 
          ? (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : 'dummy.apps.googleusercontent.com') 
          : null,
      serverClientId: !kIsWeb && AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
    ),
    firestore: FirebaseFirestore.instance,
  );
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthSession>>(
  (ref) => AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(backendAuthServiceProvider),
    ref.read(tokenStorageProvider),
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
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn(
         clientId: kIsWeb && AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
         serverClientId: !kIsWeb && AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
       ),
       super(
          AsyncValue.data(
            AuthSession(
              profile: null,
              firebaseEnabled: FirebaseEnvironment.isConfigured,
            ),
          ),
        ) {
    _bootstrap();
  }

  final AuthService _authService;
  final BackendAuthService _backendAuth;
  final TokenStorage _tokenStorage;
  final Ref _ref;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _subscription;

  Future<void> _bootstrap() async {
    final token = await _tokenStorage.getToken();
    if (token != null) {
      _ref.read(backendTokenProvider.notifier).state = token;
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
                preferredLanguage: profileData['preferredLanguage'] as String? ?? 'es',
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
        'preferredLanguage': profile.preferredLanguage,
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
                displayName: user.displayName ?? user.email?.split('@').first,
                email: user.email,
                photoUrl: user.photoURL,
                onboardingCompleted: false,
                favoritePlantIds: const [],
                useGridView: true,
                notificationPreference: 'important',
                preferredLanguage: 'es',
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

    try {
      // Limpiar sesión previa para que el picker siempre aparezca
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Inicio de sesión con Google cancelado por el usuario.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('No se recibió idToken de Google.');
      }

      final supabaseJwt = await _backendAuth.signInWithGoogleIdToken(idToken);
      await _tokenStorage.saveToken(supabaseJwt);
      _ref.read(backendTokenProvider.notifier).state = supabaseJwt;

      final profile = UserProfile(
        uid: googleUser.id,
        displayName: googleUser.displayName,
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        // TODO: Consultar el perfil del backend para verificar si el usuario ya había completado el onboarding en lugar de forzar false
        onboardingCompleted: false,
        favoritePlantIds: const [],
        useGridView: true,
        notificationPreference: 'important',
        preferredLanguage: 'es',
      );

      await _tokenStorage.saveProfile(_profileToMap(profile));

      if (!FirebaseEnvironment.isConfigured) {
        state = AsyncValue.data(
          AuthSession(
            profile: profile,
            firebaseEnabled: false,
            onboardingCompleted: false,
          ),
        );
      } else {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> registerWithEmailAndPassword(
      String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      if (FirebaseEnvironment.isConfigured) {
        await _authService.registerWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
        );

        // Evitar condición de carrera con authStateChanges actualizando de inmediato la sesión local
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          state = AsyncValue.data(
            AuthSession(
              profile: UserProfile(
                uid: user.uid,
                displayName: name,
                email: email,
                photoUrl: user.photoURL,
                onboardingCompleted: false,
                favoritePlantIds: const [],
                useGridView: true,
                notificationPreference: 'important',
                preferredLanguage: 'es',
              ),
              firebaseEnabled: true,
              onboardingCompleted: false,
            ),
          );
        }
      }
      // Intentar registrar en backend también
      final userId = await _backendAuth.register(UserRegister(
        email: email, 
        password: password, 
        name: name,
      ));
      if (userId == null) {
        throw Exception('Error al registrar en el backend.');
      }

      // Login en el backend de forma automática tras registrar
      final tokenResponse = await _backendAuth.login(UserLogin(email: email, password: password));
      if (tokenResponse != null) {
        _ref.read(backendTokenProvider.notifier).state = tokenResponse.accessToken;
        await _tokenStorage.saveToken(tokenResponse.accessToken);
      }

      // Si no hay Firebase, persistimos localmente el nombre elegido y hacemos login
      if (!FirebaseEnvironment.isConfigured) {
        final profile = UserProfile(
          uid: email,
          displayName: name,
          email: email,
          onboardingCompleted: false, // <-- Los usuarios nuevos por correo deben ver el onboarding
          favoritePlantIds: const [],
          useGridView: true,
          notificationPreference: 'important',
          preferredLanguage: 'es',
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      if (FirebaseEnvironment.isConfigured) {
        try {
          // Firebase maneja el estado vía _bindFirebaseAuth
          await _authService.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (e) {
          throw Exception('Credenciales inválidas');
        }
      }

      // Siempre intentar obtener JWT del backend
      final tokenResponse = await _backendAuth.login(UserLogin(email: email, password: password));
      if (tokenResponse != null) {
        _ref.read(backendTokenProvider.notifier).state = tokenResponse.accessToken;
        await _tokenStorage.saveToken(tokenResponse.accessToken);
      }

      // Sincronizar perfil con backend
      Map<String, dynamic>? backendProfile;
      if (tokenResponse != null) {
        try {
          backendProfile = await _backendAuth.getUserProfile();
          if (FirebaseEnvironment.isConfigured) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final newName = backendProfile['username'];
              final newLang = backendProfile['preferred_language'] ?? 'es';
              if (newName != null && user.displayName != newName) {
                await user.updateDisplayName(newName);
              }
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                {
                  if (newName != null) 'displayName': newName,
                  'preferredLanguage': newLang,
                },
                SetOptions(merge: true),
              );
            }
          }
        } catch (_) {}
      }

      // Si no hay Firebase, creamos la sesión local basada en el éxito del backend
      if (!FirebaseEnvironment.isConfigured) {
        final cachedProfile = await _tokenStorage.readProfile();
        final profile = (cachedProfile != null && cachedProfile['email'] == email)
            ? UserProfile(
                uid: cachedProfile['uid'] as String? ?? email,
                displayName: backendProfile?['username'] ?? cachedProfile['displayName'] as String?,
                email: cachedProfile['email'] as String?,
                photoUrl: cachedProfile['photoUrl'] as String?,
                onboardingCompleted: cachedProfile['onboardingCompleted'] as bool? ?? true,
                favoritePlantIds: (cachedProfile['favoritePlantIds'] as List?)?.cast<String>() ?? const [],
                useGridView: cachedProfile['useGridView'] as bool? ?? true,
                notificationPreference: cachedProfile['notificationPreference'] as String? ?? 'important',
                preferredLanguage: backendProfile?['preferred_language'] ?? cachedProfile['preferredLanguage'] as String? ?? 'es',
              )
            : UserProfile(
                uid: email,
                displayName: backendProfile?['username'] ?? email.split('@').first,
                email: email,
                onboardingCompleted: true,
                favoritePlantIds: const [],
                useGridView: true,
                notificationPreference: 'important',
                preferredLanguage: backendProfile?['preferred_language'] ?? 'es',
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _ref.read(backendTokenProvider.notifier).state = null;
    await _tokenStorage.deleteToken();
    await _tokenStorage.clearProfile();

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
            preferredLanguage: profile.preferredLanguage,
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

  Future<void> updateProfile({String? displayName, String? photoUrl, String? preferredLanguage}) async {
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
      preferredLanguage: preferredLanguage ?? current.profile!.preferredLanguage,
    );

    await _tokenStorage.saveProfile(_profileToMap(updatedProfile));

    if (FirebaseEnvironment.isConfigured) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (displayName != null) await user.updateDisplayName(displayName);
          if (photoUrl != null) await user.updatePhotoURL(photoUrl);

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            updatedProfile.toJson(),
            SetOptions(merge: true),
          );
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
