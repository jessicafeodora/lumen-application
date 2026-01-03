import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:lumen_application/services/rtdb_service.dart';
import 'package:lumen_application/widgets/glass.dart';
import 'package:lumen_application/widgets/header.dart';
import 'package:lumen_application/widgets/primary_button.dart';
import 'package:lumen_application/state/lamp_controller.dart';

class PairDevicePage extends StatefulWidget {
  final LampController controller;
  const PairDevicePage({super.key, required this.controller});

  @override
  State<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends State<PairDevicePage> {
  final _manual = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _pair(String deviceId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final id = deviceId.trim();
    if (id.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // 1) Save to user profile (multi-device ready)
      final userRef = RTDBService.globalRef('users/$uid');
      await userRef.child('devices/$id').set(true);

      // Preferred by rules: activeDeviceId
      await userRef.child('activeDeviceId').set(id);

      // Legacy key support (optional; harmless)
      await userRef.child('deviceId').set(id);

      // 2) Claim ownerUid if empty (first writer wins)
      final ownerRef = RTDBService.globalRef('devices/$id/meta/ownerUid');
      await ownerRef.runTransaction((current) {
        if (current == null || (current is String && current.trim().isEmpty)) {
          return Transaction.success(uid);
        }
        return Transaction.abort();
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Failed to pair device. (${e.runtimeType})');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;

              // Floating header geometry (same style as v4)
              final topSafe = MediaQuery.of(context).padding.top;
              const headerSide = 12.0;
              const headerTopGap = 8.0;
              const headerBottomGap = 55.0;

              final headerTop = topSafe + headerTopGap;
              final headerHeight = LumenHeader.cardHeight;
              final contentTopMin = headerTop + headerHeight + headerBottomGap;

              final horizontalPadding = screenW < 640 ? 16.0 : 24.0;
              final bottomPadding = 24.0;

              final contentTop = 20.0;
              final topPad = contentTopMin > contentTop ? contentTopMin : contentTop;

              final child = _manualCard(context);

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topPad,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: child,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: headerTop,
                    left: headerSide,
                    right: headerSide,
                    child: LumenHeader(
                      controller: widget.controller,
                      showSettings: false,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _manualCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Glass(
      size: GlassSize.lg,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _manual,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: 'Device ID',
              hintText: 'e.g. ESP32-Lamp',
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          PrimaryButton(
            text: _busy ? 'Pairing...' : 'Pair device',
            loading: _busy,
            enabled: !_busy,
            onTap: () => _pair(_manual.text),
          ),
          const SizedBox(height: 10),
          Text(
            'After pairing, this device becomes your active device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
