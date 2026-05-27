import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/core/exceptions.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

/// Detecta UnauthorizedException en cualquier provider y cierra la sesión.
class SessionObserver extends ProviderObserver {
  bool _signingOut = false;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (_signingOut) return;

    final isUnauthorized = switch (newValue) {
      AsyncError(:final error) => error is UnauthorizedException,
      _ => false,
    };

    if (isUnauthorized) {
      _signingOut = true;
      Future.microtask(() async {
        await container.read(authStateProvider.notifier).signOut();
        _signingOut = false;
      });
    }
  }
}
