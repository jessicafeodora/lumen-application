import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'rtdb_service.dart';

class UserProfileRTDB {
  static DatabaseReference _userRef(String uid) =>
      RTDBService.globalRef('users/$uid');


  /// Ensure user profile exists; update lastLoginAt on each login.
  static Future<void> ensureUserProfile(User user) async {
    final ref = _userRef(user.uid);
    final snap = await ref.get();

    final now = ServerValue.timestamp;

    // Build display name fallback
    final displayName = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : (user.email ?? '').split('@').first;

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': (user.email ?? '').trim().toLowerCase(),
        'displayName': displayName,
        'createdAt': now,
        'lastLoginAt': now,
      });
    } else {
      // keep profile but refresh lastLoginAt & email/displayName if needed
      await ref.update({
        'email': (user.email ?? '').trim().toLowerCase(),
        'displayName': displayName,
        'lastLoginAt': now,
      });
    }
  }
}
