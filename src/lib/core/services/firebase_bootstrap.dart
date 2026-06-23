import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_environment.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> ensureInitialized() async {
    if (!FirebaseEnvironment.isConfigured) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseEnvironment.options);
      }
    } catch (e) {
      // Si Firebase ya fue inicializado nativamente o en otro lado, ignoramos el error de duplicado.
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
  }
}
