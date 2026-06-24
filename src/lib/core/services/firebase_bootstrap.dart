import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_environment.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> ensureInitialized() async {
    if (!FirebaseEnvironment.isConfigured) {
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      return;
    }

    try {
      if (FirebaseEnvironment.hasWebOptions) {
        await Firebase.initializeApp(options: FirebaseEnvironment.options);
      } else {
        await Firebase.initializeApp();
      }
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        // Si ya fue inicializado (ej. por parte nativa), lo ignoramos.
        return;
      }
      rethrow;
    }
  }
}
