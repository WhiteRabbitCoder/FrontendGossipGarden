import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:gossip_garden/core/config/firebase_environment.dart';
import 'package:gossip_garden/core/services/backend_auth_service.dart';

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
    ref,
  ),
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthSession>> {
  AuthNotifier(this._authService, this._backendAuth, this._ref)
      : super(
          AsyncValue.data(
            AuthSession(
              profile: null,
              firebaseEnabled: FirebaseEnvironment.isConfigured,
            ),
          ),
        ) {
    _bindFirebaseAuth();
  }

  final AuthService _authService;
  final BackendAuthService _backendAuth;
  final Ref _ref;
  StreamSubscription<User?>? _subscription;

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

      final profile = await _authService.loadProfile(user.uid);
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
      state = AsyncValue.data(
        AuthSession(
          profile: const UserProfile(
            uid: 'local-user',
            displayName: 'Garden User',
            email: 'user@example.com',
            onboardingCompleted: false,
            favoritePlantIds: [],
            useGridView: true,
            notificationPreference: 'important',
          ),
          firebaseEnabled: false,
          onboardingCompleted: false,
        ),
      );
      return;
    }

    try {
      await _authService.signInWithGoogle();
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
      }
      // Intentar registrar en backend también
      final userId = await _backendAuth.register(email, password, name);
      if (userId == null) {
        throw Exception('Error al registrar en el backend.');
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
        // Firebase maneja el estado vía _bindFirebaseAuth
        await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Sin Firebase: crear sesión local mínima
        state = AsyncValue.data(
          AuthSession(
            profile: UserProfile(
              uid: email,
              displayName: email.split('@').first,
              email: email,
              onboardingCompleted: true,
              favoritePlantIds: const [],
              useGridView: true,
              notificationPreference: 'important',
            ),
            firebaseEnabled: false,
            onboardingCompleted: true,
          ),
        );
      }

      // Siempre intentar obtener JWT del backend
      final token = await _backendAuth.login(email, password);
      _ref.read(backendTokenProvider.notifier).state = token;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _ref.read(backendTokenProvider.notifier).state = null;

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
    state = AsyncValue.data(
      AuthSession(
        profile: profile == null
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
              ),
        firebaseEnabled: current.firebaseEnabled,
        onboardingCompleted: true,
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
