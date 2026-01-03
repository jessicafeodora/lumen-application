import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart'; // ✅ FIX (ThemeMode lives here)

enum LumenMode { normal, reading, night }

class AppState extends ChangeNotifier {
  // Settings
  ThemeModePref _themePref = ThemeModePref.system;
  String _deviceName = "Living Room Lamp";
  bool _autoOff = false;

  // Dashboard state (mirrors the React demo logic)
  bool _isOn = false;
  int _brightness = 75;
  LumenMode _selectedMode = LumenMode.normal;
  int? _timerMinutes;
  bool _isConnected = true;

  final List<ActivityEntry> _activity = [
    ActivityEntry(action: "Lamp turned ON", timestamp: "2 minutes ago"),
    ActivityEntry(action: "Brightness set to 75%", timestamp: "5 minutes ago"),
    ActivityEntry(action: "Night mode activated", timestamp: "1 hour ago"),
    ActivityEntry(action: "Lamp turned OFF", timestamp: "2 hours ago"),
  ];

  Timer? _connectionSimTimer;
  final _rand = Random();

  AppState() {
    _connectionSimTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final flip = _rand.nextDouble() > 0.95;
      if (flip) {
        _isConnected = !_isConnected;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _connectionSimTimer?.cancel();
    super.dispose();
  }

  ThemeModePref get themePref => _themePref;
  String get deviceName => _deviceName;
  bool get autoOff => _autoOff;

  bool get isOn => _isOn;
  int get brightness => _brightness;
  LumenMode get selectedMode => _selectedMode;
  int? get timerMinutes => _timerMinutes;
  bool get isConnected => _isConnected;

  List<ActivityEntry> get activity => List.unmodifiable(_activity);

  String get powerStatusText => _isOn ? "ON • $_brightness%" : "OFF";

  void setThemePref(ThemeModePref pref) {
    _themePref = pref;
    notifyListeners();
  }

  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  void setAutoOff(bool v) {
    _autoOff = v;
    notifyListeners();
  }

  void togglePower() {
    final next = !_isOn;
    _isOn = next;
    if (!next) {
      _brightness = 0;
      _appendActivity("Lamp turned OFF");
    } else {
      _brightness = 75;
      _appendActivity("Lamp turned ON");
    }
    notifyListeners();
  }

  void setBrightness(int v) {
    if (!_isOn) return;
    _brightness = v.clamp(0, 100);
    _appendActivity("Brightness set to $_brightness%");
    notifyListeners();
  }

  void setTimerMinutes(int minutes) {
    _timerMinutes = minutes;
    notifyListeners();
  }

  void clearTimer() {
    _timerMinutes = null;
    notifyListeners();
  }

  void setMode(LumenMode mode) {
    _selectedMode = mode;
    _appendActivity("${modeLabelForLog(mode)} mode activated");
    notifyListeners();
  }

  String modeLabelForLog(LumenMode mode) {
    switch (mode) {
      case LumenMode.normal:
        return "Normal";
      case LumenMode.reading:
        return "Reading";
      case LumenMode.night:
        return "Night";
    }
  }

  void _appendActivity(String action) {
    _activity.insert(0, ActivityEntry(action: action, timestamp: "Just now"));
    if (_activity.length > 20) _activity.removeLast();
  }
}

enum ThemeModePref { light, dark, system }

class ActivityEntry {
  final String action;
  final String timestamp;

  ActivityEntry({required this.action, required this.timestamp});
}
