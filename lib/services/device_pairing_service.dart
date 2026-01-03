import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DevicePairingService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Claim device:
  /// - set devices/{deviceId}/meta/ownerUid
  /// - map users/{uid}/devices/{deviceId} = true
  /// - set users/{uid}/activeDeviceId
  Future<void> claimDevice(String deviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    final uid = user.uid;

    // 1️⃣ Claim ownerUid (atomic, anti ketiban)
    final ownerRef = _db.child('devices/$deviceId/meta/ownerUid');

    final tx = await ownerRef.runTransaction((current) {
      // sudah dimiliki orang lain → gagal
      if (current != null &&
          current is String &&
          current.isNotEmpty &&
          current != uid) {
        return Transaction.abort();
      }
      // kosong / null → klaim
      return Transaction.success(uid);
    });

    if (!tx.committed) {
      throw Exception('Device sudah dimiliki user lain');
    }

    // 2️⃣ Mapping user → device
    await _db.update({
      'users/$uid/devices/$deviceId': true,
      'users/$uid/activeDeviceId': deviceId,
    });
  }
}