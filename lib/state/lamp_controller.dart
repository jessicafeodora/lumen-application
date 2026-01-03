import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumen_application/services/rtdb_service.dart';
import 'package:lumen_application/services/activity_rtdb.dart';

/// =========================
/// Central logging helper
/// =========================
void lumenLog(String msg, {Object? err, StackTrace? st}) {
  if (!kDebugMode) return;
  final t = DateTime.now().toIso8601String();
  debugPrint('[$t][Lumen] $msg');
  if (err != null) debugPrint('  err=$err');
  if (st != null) debugPrint('  st=$st');
}

/// =========================
/// UI/App state (theme, auth, signout UX)
/// =========================
class AppState extends ChangeNotifier {
  static const String _kThemeModeKey = 'themeMode';

  ThemeMode themeMode = ThemeMode.light;

  bool isSigningOut = false;
  User? user;

  StreamSubscription<User?>? _authSub;

  AppState() {
    _loadThemeMode();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _loadThemeMode() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = sp.getString(_kThemeModeKey);
      if (v == null) return;

      switch (v) {
        case 'system':
          themeMode = ThemeMode.system;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'light':
        default:
          themeMode = ThemeMode.light;
          break;
      }
      notifyListeners();
    } catch (e, st) {
      lumenLog('load theme failed', err: e, st: st);
    }
  }

  Future<void> _saveThemeMode() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = themeMode == ThemeMode.dark
          ? 'dark'
          : themeMode == ThemeMode.system
          ? 'system'
          : 'light';
      await sp.setString(_kThemeModeKey, v);
    } catch (e, st) {
      lumenLog('save theme failed', err: e, st: st);
    }
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _saveThemeMode();
    _hapticSelection();
  }

  void setThemeMode(ThemeMode v) {
    themeMode = v;
    notifyListeners();
    _saveThemeMode();
    _hapticSelection();
  }

  Future<void> signOutGracefully() async {
    if (isSigningOut) return;
    isSigningOut = true;
    notifyListeners();
    _hapticMedium();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e, st) {
      lumenLog('signOut failed', err: e, st: st);
    } finally {
      isSigningOut = false;
      notifyListeners();
    }
  }

  void _hapticSelection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void _hapticMedium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

/// =========================
/// Device state (RTDB, offline detection, writes, smoothing)
/// =========================
class DeviceState extends ChangeNotifier {
  static const String _kDeviceIdKey = 'deviceId';
  static const String _kDeviceNameKeyPrefix = 'deviceName_';
  static const String _kAutoOffKey = 'autoOff';

  // UI/device state
  bool isOn = false;
  bool autoOff = false;
  int brightness = 75;
  String mode = 'normal';
  int? timerMinutes;

  String deviceName = 'Living Room Lamp';

  // Connection monitoring
  bool isConnected = false; // Firebase .info/connected
  String? fwVersion;
  DateTime? lastSeen;
  DateTime? _lastRemoteEventAt;

  // Soft warning: write failure
  bool lastWriteFailed = false;
  DateTime? lastWriteFailedAt;

  // Offline / stale detection ticker
  Timer? _staleTicker;

  // Device selection (not hardcoded)
  String? deviceId;
  String? _uid; // current signed-in user uid

  // Refs/subscriptions
  DatabaseReference? _rootRef;
  DatabaseReference? _metaRef;
  DatabaseReference? _desiredRef; // points to users/{uid}/desired
  DatabaseReference? _runtimeDesiredRef;
  DatabaseReference? _runtimeActiveUidRef;
  DatabaseReference? _reportedRef;
  DatabaseReference? _userDeviceNameRef;

  StreamSubscription<DatabaseEvent>? _userDeviceNameSub;

  late final DatabaseReference _connectedRef;
  StreamSubscription<DatabaseEvent>? _connSub;
  StreamSubscription<DatabaseEvent>? _metaSub;
  StreamSubscription<DatabaseEvent>? _desiredSub;
  StreamSubscription<DatabaseEvent>? _reportedSub;

  bool _applyingRemote = false;

  // Debounce smoothing
  Timer? _brightnessDebounce;
  Timer? _nameDebounce;

  // Auth listener
  StreamSubscription<User?>? _authSub;

  // Guards
  bool _binding = false;

  DeviceState() {
    _connectedRef = RTDBService.globalRef('.info/connected');

    // Load cached prefs (fallback only)
    _loadLocalDevicePrefs();

    // Stale ticker: keep UI fresh even if RTDB stops updating
    _staleTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      notifyListeners();
    });

    _listenConnection();

    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  /// Force re-resolve/reattach device binding for the currently signed-in user.
  Future<void> refreshForCurrentUser() async {
    await _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  // ===== Derived labels =====
  String get lastUpdatedLabel {
    final t = _lastRemoteEventAt;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get lastSeenLabel {
    final t = lastSeen;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Offline / stale detection (2 minutes)
  bool get deviceOnline {
    final t = lastSeen;
    if (t == null) return false;
    return DateTime.now().difference(t).inMinutes <= 2;
  }

  /// User-centered: allow control as long as app connected + deviceId exists.
  /// (Device might be offline; we still allow writes / optimistic UI.)
  bool get canControl {
    if (deviceId == null || deviceId!.isEmpty) return false;
    if (!isConnected) return false;
    if (!deviceOnline) return false;
    return true;
  }

  // ===== Auth attach/detach =====
  Future<void> _onAuthChanged(User? user) async {
    Future<void> _ensureUserDesired(String uid) async {
      final ref = RTDBService.globalRef('users/$uid/desired');
      final snap = await ref.get();
      if (snap.value is Map) return;

      await ref.set({
        'isOn': false,
        'brightness': 75,
        'mode': 'normal',
        'timerMinutes': null,
        'autoOff': false,
      });
    }

    if (user == null) {
      _uid = null;
      deviceName = 'Living Room Lamp';
      _detachDevice();

      // reset volatile status
      fwVersion = null;
      lastSeen = null;
      _lastRemoteEventAt = null;
      lastWriteFailed = false;
      lastWriteFailedAt = null;

      notifyListeners();
      return;
    }

    lumenLog('[auth] uid=${user.uid}');
    _uid = user.uid;
    await _ensureUserDesired(user.uid);
    await _loadDeviceNameLocalForUid(user.uid);
    await _ensureUserDeviceName(user.uid);

    deviceId = 'ESP32-D4-E9-F4-86-EC-E4';

    // Resolve deviceId, then enforce binding (ownerUid + activeDeviceId + users map),
    // then attach listeners.
    await _resolveDeviceIdForUser(user.uid);

    if (deviceId == null || deviceId!.isEmpty) {
      lumenLog('No deviceId resolved; staying detached');
      _detachDevice();
      notifyListeners();
      return;
    }

    // Ensure user<->device mapping + owner claim (safe under your current rules)
    await _ensureBinding(user.uid, deviceId!);

    // Now attach listeners (so reads won’t be denied)
    _attachDevice(deviceId!);
  }

  // ===== Device resolution (auto-claim) =====

  Future<void> _resolveDeviceIdForUser(String uid) async {
    Future<String?> _autoScanAndClaim(String uid) async {
      final devicesRef = RTDBService.globalRef('devices');

      final snap = await devicesRef.limitToFirst(50).get();
      if (snap.value is! Map) return null;

      final m = Map<String, dynamic>.from(snap.value as Map);

      String? freeId;

      for (final entry in m.entries) {
        final dev = (entry.value is Map)
            ? Map<String, dynamic>.from(entry.value as Map)
            : <String, dynamic>{};
        final meta = (dev['meta'] is Map)
            ? Map<String, dynamic>.from(dev['meta'] as Map)
            : <String, dynamic>{};

        final owner = meta['ownerUid'];
        final ownerStr = owner is String ? owner.trim() : '';

        freeId = entry.key; // pick first available device (single-device demo)
        break;
      }

      if (freeId == null) return null;

      final updates = <String, Object?>{
        'users/$uid/activeDeviceId': freeId,
        'users/$uid/devices/$freeId': true,
      };

      await RTDBService.globalRef('/').update(updates);

      return freeId;
    }

    // 1) profile
    try {
      final userRef = RTDBService.globalRef('users/$uid');

      final activeSnap = await userRef.child('activeDeviceId').get();
      final active = activeSnap.value;
      if (active is String && active.trim().isNotEmpty) {
        deviceId = active.trim();
        await _saveDeviceIdLocal(deviceId!);
        lumenLog('[device] from activeDeviceId = $deviceId');
        return;
      }
    } catch (e, st) {
      lumenLog('read activeDeviceId failed', err: e, st: st);
    }

    // 2) auto-scan + claim
    try {
      final id = await _autoScanAndClaim(uid);
      if (id != null && id.trim().isNotEmpty) {
        deviceId = id.trim();
        await _saveDeviceIdLocal(deviceId!);
        lumenLog('[device] auto-claimed = $deviceId');
        return;
      }
    } catch (e, st) {
      lumenLog('auto scan/claim failed', err: e, st: st);
    }

    // 3) fallback cache
    if (deviceId != null && deviceId!.trim().isNotEmpty) {
      deviceId = deviceId!.trim();
      lumenLog('[device] fallback cache = $deviceId');
      return;
    }

    deviceId = null;
  }


  // ===== Binding enforcement (user-centered) =====
  Future<void> _ensureBinding(String uid, String id) async {
    if (_binding) return;
    _binding = true;
    try {
      final updates = <String, Object?>{
        // NOTE: ownership claim removed for per-user isolated mode
        // User pointers
        'users/$uid/activeDeviceId': id,
        'users/$uid/devices/$id': true,
      };
      await RTDBService.globalRef('/').update(updates);
      lumenLog('[bind] ensured uid=$uid deviceId=$id');
    } catch (e, st) {
      lumenLog('ensureBinding failed', err: e, st: st);
    } finally {
      _binding = false;
    }
  }

  // ===== Attach/detach =====
  void _attachDevice(String id) {
    lumenLog('[attach] deviceId=$id');
    final root = RTDBService.deviceRoot(id);
    if (root == null) {
      _detachDevice();
      return;
    }

    _rootRef = root;
    _metaRef = root.child('meta');
    _desiredRef = RTDBService.globalRef('users/${_uid ?? ''}/desired');
    _userDeviceNameRef = RTDBService.globalRef('users/${_uid ?? ''}/deviceName');
    _runtimeDesiredRef = RTDBService.globalRef('runtime/desired');
    _runtimeActiveUidRef = RTDBService.globalRef('runtime/activeUid');
    _reportedRef = root.child('reported');

    _listenUserDeviceName();
    _listenDesired();
    _listenReported();

    notifyListeners();
  }

  void _detachDevice() {
    _metaSub?.cancel();
    _desiredSub?.cancel();
    _reportedSub?.cancel();
    _userDeviceNameSub?.cancel();
    _metaSub = null;
    _desiredSub = null;
    _reportedSub = null;
    _userDeviceNameSub = null;

    _rootRef = null;
    _metaRef = null;
    _desiredRef = null;
    _runtimeDesiredRef = null;
    _runtimeActiveUidRef = null;
    _reportedRef = null;
    _userDeviceNameRef = null;
  }

  // ===== Connection listener =====
  void _listenConnection() {
    _connSub?.cancel();
    _connSub = _connectedRef.onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is bool) {
        isConnected = v;
        lumenLog('[conn] .info/connected=$isConnected');
        notifyListeners();
      }
    }, onError: (e) {
      lumenLog('[conn] listen error', err: e);
    });
  }


  void _listenUserDeviceName() {
    _userDeviceNameSub?.cancel();
    final ref = _userDeviceNameRef;
    if (ref == null) return;

    _userDeviceNameSub = ref.onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is! String) return;
      final name = v.trim();
      if (name.isEmpty) return;

      deviceName = name;
      if (_uid != null && _uid!.isNotEmpty) {
        _saveDeviceNameLocalForUid(_uid!);
      }
      notifyListeners();
    }, onError: (e) {
      lumenLog('[deviceName] listen error', err: e);
    });
  }

  void _listenMeta() {
    _metaSub?.cancel();
    final ref = _metaRef;
    if (ref == null) return;

    _metaSub = ref.onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is! Map) return;
      notifyListeners();
    }, onError: (e) {
      lumenLog('[meta] listen error', err: e);
    });
  }

  void _listenDesired() {
    _desiredSub?.cancel();
    final ref = _desiredRef;
    if (ref == null) return;

    _desiredSub = ref.onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is! Map) return;

      _applyingRemote = true;
      try {
        final p = v['isOn'];
        final b = v['brightness'];
        final m = v['mode'];
        final t = v['timerMinutes'];
        final ao = v['autoOff'];

        if (p is bool) isOn = p;
        if (b is num) brightness = b.toInt().clamp(0, 100);
        if (m is String && m.trim().isNotEmpty) mode = m.trim();

        if (t == null) {
          timerMinutes = null;
        } else if (t is num) {
          timerMinutes = t.toInt();
        }

        if (ao is bool) {
          autoOff = ao;
          _saveAutoOffLocal();
        }


        // On login/account switch, mirror full user state to runtime so ESP32 follows the active account immediately.
        final a = _runtimeActiveUidRef;
        final r = _runtimeDesiredRef;
        if (a != null && r != null && _uid != null && _uid!.isNotEmpty) {
          a.set(_uid);
          r.set({
            'isOn': isOn,
            'brightness': brightness,
            'mode': mode,
            'timerMinutes': timerMinutes,
          });
        }
        _lastRemoteEventAt = DateTime.now();
        notifyListeners();
      } finally {
        _applyingRemote = false;
      }
    }, onError: (e) {
      lumenLog('[desired] listen error', err: e);
    });
  }

  void _listenReported() {
    _reportedSub?.cancel();
    final ref = _reportedRef;
    if (ref == null) return;

    _reportedSub = ref.onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is! Map) return;

      final fw = v['fwVersion'];
      if (fw is String && fw.trim().isNotEmpty) fwVersion = fw.trim();

      final seen = v['lastSeen'];
      if (seen is int && seen > 0) {
        lastSeen = DateTime.fromMillisecondsSinceEpoch(seen);
      }

      notifyListeners();
    }, onError: (e) {
      lumenLog('[reported] listen error', err: e);
    });
  }

  // ===== Local cache =====
  Future<void> _loadLocalDevicePrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();

      final id = sp.getString(_kDeviceIdKey);
      if (id != null && id.trim().isNotEmpty) deviceId = id.trim();

      final cachedAutoOff = sp.getBool(_kAutoOffKey);
      if (cachedAutoOff != null) autoOff = cachedAutoOff;

      notifyListeners();
    } catch (e, st) {
      lumenLog('load local device prefs failed', err: e, st: st);
    }
  }


  String _deviceNameKeyForUid(String uid) => '$_kDeviceNameKeyPrefix$uid';

  Future<void> _loadDeviceNameLocalForUid(String uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cached = sp.getString(_deviceNameKeyForUid(uid));
      if (cached != null && cached.trim().isNotEmpty) {
        deviceName = cached.trim();
        notifyListeners();
      }
    } catch (e, st) {
      lumenLog('load local deviceName failed', err: e, st: st);
    }
  }

  Future<void> _saveDeviceNameLocalForUid(String uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_deviceNameKeyForUid(uid), deviceName);
    } catch (e, st) {
      lumenLog('save deviceName failed', err: e, st: st);
    }
  }

  Future<void> _ensureUserDeviceName(String uid) async {
    // Ensure RTDB has a per-user deviceName so new accounts don't inherit previous user's cache.
    final ref = RTDBService.globalRef('users/$uid/deviceName');
    final snap = await ref.get();
    if (snap.value is String && (snap.value as String).trim().isNotEmpty) return;

    final fallback = deviceName.trim().isNotEmpty ? deviceName : 'Living Room Lamp';
    await ref.set(fallback);
  }

  Future<void> _saveDeviceIdLocal(String id) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kDeviceIdKey, id);
    } catch (_) {}
  }


  Future<void> _saveAutoOffLocal() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kAutoOffKey, autoOff);
    } catch (_) {}
  }

  // ===== Writes (with failure feedback) =====
  Future<void> _writeDesired(Map<String, dynamic> patch) async {
    if (_applyingRemote) return;
    final ref = _desiredRef;
    if (ref == null) return;

    try {
      lastWriteFailed = false;
      await ref.update(patch);
      await ref.child('updatedAt').set(ServerValue.timestamp);
      // Mirror to runtime/desired so ESP32 (single device) follows the active account
      final r = _runtimeDesiredRef;
      final a = _runtimeActiveUidRef;
      if (r != null && a != null && _uid != null && _uid!.isNotEmpty) {
        await a.set(_uid);
        await r.update(patch);
      }
    } catch (e, st) {
      lastWriteFailed = true;
      lastWriteFailedAt = DateTime.now();
      lumenLog('writeDesired failed patch=$patch', err: e, st: st);
      notifyListeners();
    }
  }

  Future<void> _writeMeta(Map<String, dynamic> patch) async {
    final ref = _metaRef;
    if (ref == null) return;

    try {
      lastWriteFailed = false;
      await ref.update(patch);
    } catch (e, st) {
      lastWriteFailed = true;
      lastWriteFailedAt = DateTime.now();
      lumenLog('writeMeta failed patch=$patch', err: e, st: st);
      notifyListeners();
    }
  }

  // ===== User actions (with haptics + smoothing) =====
  Future<void> setPower(bool v) async {
    if (!canControl) {
      _hapticError();
      return;
    }

    _hapticLight();

    // optimistic UI
    isOn = v;
    if (!isOn) brightness = 0;
    if (isOn && brightness == 0) brightness = 75;
    notifyListeners();

    await _writeDesired({'isOn': isOn, 'brightness': brightness});

    await ActivityRTDB.add(
      deviceId: deviceId ?? '',
      action: isOn ? 'Power ON' : 'Power OFF',
      actor: 'app',
    );
  }

  Future<void> setAutoOff(bool v) async {
    if (!canControl) {
      _hapticError();
      return;
    }

    _hapticSelection();

    autoOff = v;
    notifyListeners();
    await _saveAutoOffLocal();

    await _writeDesired({'autoOff': autoOff});

    await ActivityRTDB.add(
      deviceId: deviceId ?? '',
      action: autoOff ? 'Auto Off enabled' : 'Auto Off disabled',
      actor: 'app',
    );
  }

  Future<void> setBrightness(int v) async {
    if (!canControl) {
      _hapticError();
      return;
    }

    // optimistic UI
    brightness = v.clamp(0, 100);
    if (brightness > 0) isOn = true;
    notifyListeners();

    _brightnessDebounce?.cancel();
    _brightnessDebounce = Timer(const Duration(milliseconds: 120), () async {
      await _writeDesired({'brightness': brightness, 'isOn': isOn});

      await ActivityRTDB.add(
        deviceId: deviceId ?? '',
        action: 'Brightness set to $brightness%',
        actor: 'app',
      );
    });
  }

  Future<void> setMode(String v) async {
    if (!canControl) {
      _hapticError();
      return;
    }

    _hapticSelection();

    mode = v;
    notifyListeners();

    await _writeDesired({'mode': mode});

    await ActivityRTDB.add(
      deviceId: deviceId ?? '',
      action: 'Mode changed to $mode',
      actor: 'app',
    );
  }

  Future<void> setTimer(int? minutes) async {
    if (!canControl) {
      _hapticError();
      return;
    }

    _hapticSelection();

    timerMinutes = minutes;
    notifyListeners();

    await _writeDesired({'timerMinutes': timerMinutes});

    await ActivityRTDB.add(
      deviceId: deviceId ?? '',
      action: timerMinutes == null ? 'Timer cleared' : 'Timer set to ${timerMinutes}m',
      actor: 'app',
    );
  }

  Future<void> setDeviceName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == deviceName) return;

    deviceName = trimmed;
    notifyListeners();
    if (_uid != null) await _saveDeviceNameLocalForUid(_uid!);

    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(seconds: 1), () async {
      if (_uid != null && _uid!.isNotEmpty) {
        await RTDBService.globalRef('users/${_uid!}/deviceName').set(deviceName);
      }
    });
  }

  // ===== Haptics =====
  void _hapticSelection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void _hapticLight() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _hapticError() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _brightnessDebounce?.cancel();
    _nameDebounce?.cancel();
    _staleTicker?.cancel();

    _authSub?.cancel();
    _connSub?.cancel();
    _detachDevice();

    super.dispose();
  }
}

/// =========================
/// Facade (keeps old API stable)
/// =========================
class LampController extends ChangeNotifier {
  final AppState app = AppState();
  final DeviceState device = DeviceState();

  LampController() {
    app.addListener(notifyListeners);
    device.addListener(notifyListeners);
  }

  // ---- Old fields/properties (forwarders) ----
  ThemeMode get themeMode => app.themeMode;
  void toggleTheme() => app.toggleTheme();
  void setThemeMode(ThemeMode v) => app.setThemeMode(v);

  bool get isSigningOut => app.isSigningOut;
  User? get user => app.user;

  bool get isOn => device.isOn;
  bool get autoOff => device.autoOff;
  int get brightness => device.brightness;
  String get mode => device.mode;
  int? get timerMinutes => device.timerMinutes;

  String get deviceName => device.deviceName;
  String? get deviceId => device.deviceId;

  Future<void> refreshForCurrentUser() => device.refreshForCurrentUser();

  bool get isConnected => device.isConnected;
  bool get deviceOnline => device.deviceOnline;
  bool get canControl => device.canControl && !app.isSigningOut;

  String? get fwVersion => device.fwVersion;
  DateTime? get lastSeen => device.lastSeen;
  String get lastSeenLabel => device.lastSeenLabel;
  String get lastUpdatedLabel => device.lastUpdatedLabel;

  bool get lastWriteFailed => device.lastWriteFailed;
  DateTime? get lastWriteFailedAt => device.lastWriteFailedAt;

  // ---- Actions ----
  Future<void> setPower(bool v) => app.isSigningOut ? Future.value() : device.setPower(v);
  Future<void> setAutoOff(bool v) => app.isSigningOut ? Future.value() : device.setAutoOff(v);
  Future<void> setBrightness(int v) => app.isSigningOut ? Future.value() : device.setBrightness(v);
  Future<void> setMode(String v) => app.isSigningOut ? Future.value() : device.setMode(v);
  Future<void> setTimer(int? minutes) => app.isSigningOut ? Future.value() : device.setTimer(minutes);
  Future<void> setDeviceName(String name) => app.isSigningOut ? Future.value() : device.setDeviceName(name);

  Future<void> signOutGracefully() => app.signOutGracefully();

  @override
  void dispose() {
    app.removeListener(notifyListeners);
    device.removeListener(notifyListeners);
    app.dispose();
    device.dispose();
    super.dispose();
  }
}