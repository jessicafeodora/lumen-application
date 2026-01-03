import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RTDBService {
  RTDBService._();

  static const String dbUrl = 'https://smart-home-lamp-d68de-default-rtdb.firebaseio.com';

  static FirebaseDatabase db() {
    // Explicit URL so it always hits the right RTDB instance
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    );
  }

  static DatabaseReference ref(String path) => db().ref(path);

  /// Root reference (optionally with path) using the configured databaseURL.
  static DatabaseReference globalRef([String? path]) =>
      (path == null || path.isEmpty) ? db().ref() : db().ref(path);

  /// Convenience reference to a specific device root: devices/{deviceId}
  static DatabaseReference deviceRoot(String deviceId) =>
      globalRef('devices/$deviceId');
}