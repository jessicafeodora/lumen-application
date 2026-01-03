import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthPersistence {
  /// Apply persistence BEFORE sign-in / sign-up
  static Future<void> apply({required bool rememberMe}) async {
    // Only meaningful on Web
    if (!kIsWeb) return;

    final auth = FirebaseAuth.instance;

    await auth.setPersistence(
      rememberMe
          ? Persistence.LOCAL     // stay logged in
          : Persistence.SESSION,  // until tab/browser closed
    );
  }
}
