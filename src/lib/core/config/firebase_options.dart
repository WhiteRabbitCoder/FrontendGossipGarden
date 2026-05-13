class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static dynamic get currentPlatform {
    throw UnsupportedError(
      'Firebase no esta configurado. Genera este archivo con flutterfire configure.',
    );
  }
}
