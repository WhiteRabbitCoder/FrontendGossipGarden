class AppConfig {
  const AppConfig._();

  static const String backendTarget = String.fromEnvironment(
    'BACKEND_TARGET',
    defaultValue: 'remote',
  );

  static const String localBackendUrl = String.fromEnvironment(
    'BACKEND_LOCAL_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String deployedBackendUrl = String.fromEnvironment(
    'BACKEND_DEPLOY_URL',
    defaultValue: 'https://gossip-garden-backend.up.railway.app',
  );

  static const bool enableFirebase = bool.fromEnvironment(
    'ENABLE_FIREBASE',
    defaultValue: false,
  );

  static String get backendBaseUrl {
    final normalizedTarget = backendTarget.toLowerCase();

    if (normalizedTarget == 'prod' ||
        normalizedTarget == 'production' ||
        normalizedTarget == 'deploy' ||
        normalizedTarget == 'remote') {
      return _normalizeUrl(deployedBackendUrl);
    }

    return _normalizeUrl(localBackendUrl);
  }

  static String _normalizeUrl(String rawUrl) {
    if (rawUrl.endsWith('/')) {
      return rawUrl.substring(0, rawUrl.length - 1);
    }

    return rawUrl;
  }
}
