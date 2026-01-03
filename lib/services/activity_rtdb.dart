import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'rtdb_service.dart';

class ActivityEntry {
  final String id;
  final String action;
  final String actor; // "app" | "device"
  final DateTime createdAt;

  ActivityEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.createdAt,
  });

  String get timestampLabel {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${createdAt.year}-${two(createdAt.month)}-${two(createdAt.day)}  '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }

  static DateTime _fromCreatedAtRaw(dynamic createdAtRaw) {
    // RTDB ServerValue.timestamp resolves to int milliseconds
    if (createdAtRaw is int) {
      return DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    }
    if (createdAtRaw is num) {
      return DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt());
    }
    return DateTime.now();
  }

  static ActivityEntry? fromMap(String id, dynamic v) {
    if (v is! Map) return null;

    final action = (v['action'] ?? '').toString().trim();
    if (action.isEmpty) return null;

    final actor = (v['actor'] ?? 'app').toString();
    final createdAtRaw = v['createdAt'];

    final createdAt = _fromCreatedAtRaw(createdAtRaw);

    return ActivityEntry(
      id: id,
      action: action,
      actor: actor,
      createdAt: createdAt,
    );
  }
}

class ActivityRTDB {
  static DatabaseReference _base() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Per-user isolated activity log
    return RTDBService.ref('users/$uid/activity');
  }

  /// Write log entry
  /// - actor: "app" by default (from the current FirebaseAuth user if present)
  /// - type: optional tag for filtering/grouping
  static Future<void> add({
    required String deviceId,
    required String action,
    String actor = 'app',
  }) async {
    final ref = _base().push();

    await ref.set({
      'action': action,
      'actor': actor, // "app" | "device"
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Realtime stream (latest N, newest-first)
  static Stream<List<ActivityEntry>> stream({
    required String deviceId,
    int limit = 20,
  }) {
    final query = _base()
        .orderByChild('createdAt')
        .limitToLast(limit);

    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return <ActivityEntry>[];

      final entries = <ActivityEntry>[];

      data.forEach((k, v) {
        final e = ActivityEntry.fromMap(k.toString(), v);
        if (e != null) entries.add(e);
      });

      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    });
  }
}
