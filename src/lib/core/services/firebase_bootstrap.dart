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

    await Firebase.initializeApp(options: FirebaseEnvironment.options);
  }
}
