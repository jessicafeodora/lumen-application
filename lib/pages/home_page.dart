import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lumen_application/services/activity_rtdb.dart';
import 'package:lumen_application/state/lamp_controller.dart';
import 'package:lumen_application/widgets/activity_log.dart';
import 'package:lumen_application/widgets/brightness_slider.dart';
import 'package:lumen_application/widgets/connection_status.dart';
import 'package:lumen_application/widgets/glass.dart';
import 'package:lumen_application/widgets/header.dart';
import 'package:lumen_application/widgets/mode_selector.dart';
import 'package:lumen_application/widgets/power_toggle.dart';
import 'package:lumen_application/widgets/timer_chips.dart';
import '../services/device_pairing_service.dart';

class HomePage extends StatelessWidget {
  final LampController controller;
  const HomePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final isDesktop = screenW >= 1024;

              // Floating header geometry
              final topSafe = MediaQuery.of(context).padding.top;
              const headerSide = 12.0;
              const headerTopGap = 8.0;
              const headerBottomGap = 55.0;

              final headerTop = topSafe + headerTopGap;
              final headerHeight = LumenHeader.cardHeight;
              final contentTopMin = headerTop + headerHeight + headerBottomGap;

              final horizontalPadding = screenW < 640 ? 16.0 : 24.0;
              final bottomPadding = isDesktop ? 24.0 : 110.0;

              final contentTop =
              math.max(isDesktop ? 24.0 : 20.0, contentTopMin);

              return Stack(
                children: [
                  // Scrollable content
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        contentTop,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          child: isDesktop
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 8,
                                child: _LeftColumn(
                                  controller: controller,
                                  isDesktop: true,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child:
                                _RightColumn(controller: controller),
                              ),
                            ],
                          )
                              : _LeftColumn(
                            controller: controller,
                            isDesktop: false,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating header card
                  Positioned(
                    top: headerTop,
                    left: headerSide,
                    right: headerSide,
                    child: LumenHeader(
                      controller: controller,
                      showSettings: true,
                    ),
                  ),

                  // Mobile bottom connection status
                  if (!isDesktop)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Glass(
                          size: GlassSize.md,
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(22),
                          child: SafeArea(
                            top: false,
                            child: ConnectionStatusBar(
                              isConnected: controller.isConnected,
                              showOnlineRight: true,
                            ),
                          ),
                        ),
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
}

class _LeftColumn extends StatelessWidget {
  final LampController controller;
  final bool isDesktop;

  const _LeftColumn({
    required this.controller,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final pad = isDesktop ? 40.0 : 28.0;
    final deviceOnline = controller.deviceOnline;
    final powerEnabled = deviceOnline;
    final controlsEnabled = deviceOnline && controller.isOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top lamp card
        Glass(
          size: GlassSize.lg,
          glow: controller.isOn,
          borderRadius: BorderRadius.circular(28),
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.deviceName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                controller.isOn ? 'ON • ${controller.brightness}%' : 'OFF',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              PowerToggle(
                isOn: controller.isOn,
                label: controller.deviceName,
                onToggle: controller.setPower,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Brightness + Timer (same size)
        LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth;
            final twoCol = w >= 640;

            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: twoCol ? (w - 20) / 2 : w,
                  child: BrightnessCard(
                    value: controller.isOn ? controller.brightness : 0,
                    disabled: !controller.isOn,
                    onChanged: controller.setBrightness,
                  ),
                ),
                SizedBox(
                  width: twoCol ? (w - 20) / 2 : w,
                  child: IgnorePointer(
                    ignoring: !controlsEnabled,
                    child: Opacity(
                      opacity: controlsEnabled ? 1.0 : 0.45,
                      child: TimerCard(
                        selectedMinutes: controller.timerMinutes,
                        onSelect: controller.setTimer,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Mode (disabled when OFF)
        IgnorePointer(
          ignoring: !controlsEnabled,
          child: Opacity(
            opacity: controlsEnabled ? 1.0 : 0.45,
            child: ModeSelectorCard(
              selected: controller.mode,
              onSelect: controller.setMode,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Mobile: show activity log here, streamed from RTDB
        if (!isDesktop) _ActivityStream(deviceId: controller.deviceId ?? ''),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  final LampController controller;
  const _RightColumn({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Device status
        Glass(
          size: GlassSize.md,
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Status',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ConnectionStatusTile(
                isConnected: controller.isConnected,
                deviceName: controller.deviceId ?? 'No Device',
                lastUpdated: controller.lastUpdatedLabel,
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.20)),
              const SizedBox(height: 16),
              _kv(context, 'Firmware', controller.fwVersion ?? '—'),
              const SizedBox(height: 12),
              _kv(context, 'Last seen', controller.lastSeenLabel),
              const SizedBox(height: 12),
              _kv(context, 'Device',
                  controller.deviceOnline ? 'Online' : 'Offline'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Desktop: activity log in right column (streamed from RTDB)
        _ActivityStream(deviceId: controller.deviceId ?? ''),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool accent = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF7DE3FF) : const Color(0xFF4A70A9);

    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ),
        Text(
          v,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: accent ? accentColor : null,
          ),
        ),
      ],
    );
  }
}

class _ActivityStream extends StatefulWidget {
  final String deviceId;
  const _ActivityStream({required this.deviceId});

  @override
  State<_ActivityStream> createState() => _ActivityStreamState();
}

class _ActivityStreamState extends State<_ActivityStream> {
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _tryClaimOnce();
  }

  @override
  void didUpdateWidget(covariant _ActivityStream oldWidget) {
    super.didUpdateWidget(oldWidget);

    // kalau deviceId berubah (misal setelah load setting), claim lagi sekali
    if (oldWidget.deviceId != widget.deviceId) {
      _claimed = false;
      _tryClaimOnce();
    }
  }

  Future<void> _tryClaimOnce() async {
    if (_claimed) return;

    final deviceId = widget.deviceId.trim();
    if (deviceId.isEmpty) return;

    _claimed = true;

    try {
      await DevicePairingService().claimDevice(deviceId);
      // ignore: avoid_print
      print('Device berhasil di-claim: $deviceId');
    } catch (e) {
      // kalau gagal, biarin aja UI tetap jalan (log doang)
      // ignore: avoid_print
      print('Claim device gagal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceId = widget.deviceId.trim();

    if (deviceId.isEmpty) {
      return const ActivityLogCard(entries: <ActivityEntry>[]);
    }

    return StreamBuilder<List<ActivityEntry>>(
      stream: ActivityRTDB.stream(deviceId: deviceId, limit: 20),
      builder: (context, snap) {
        if (snap.hasError) {
          return const ActivityLogCard(entries: <ActivityEntry>[]);
        }
        if (!snap.hasData) {
          return const ActivityLogCard(entries: <ActivityEntry>[]);
        }
        final entries = snap.data ?? const <ActivityEntry>[];
        return ActivityLogCard(entries: entries);
      },
    );
  }
}
