import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lumen_application/state/lamp_controller.dart';
import 'package:lumen_application/widgets/glass.dart';
import 'package:lumen_application/widgets/header.dart';

class SettingsPage extends StatefulWidget {
  final LampController controller;
  const SettingsPage({super.key, required this.controller});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameCtrl;

  // Keep typography aligned with card inner padding
  static const double _contentInset = 22.0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.controller.deviceName);

    // Keep text field in sync if deviceName changes elsewhere.
    widget.controller.addListener(_syncName);
  }

  void _syncName() {
    final current = widget.controller.deviceName;
    if (_nameCtrl.text != current) {
      _nameCtrl.value = _nameCtrl.value.copyWith(
        text: current,
        selection: TextSelection.collapsed(offset: current.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncName);
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final user = FirebaseAuth.instance.currentUser;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: LayoutBuilder(
            builder: (_, c) {
              final isDesktop = c.maxWidth >= 1024;

              // Wide center column like the design
              final maxWidth = isDesktop ? 980.0 : double.infinity;

              // Floating header geometry
              final topSafe = MediaQuery.of(context).padding.top;
              const headerSide = 12.0;
              const headerTopGap = 8.0;
              const headerBottomGap = 40.0;

              final headerTop = topSafe + headerTopGap;
              final headerHeight = LumenHeader.cardHeight;
              final contentTopMin = headerTop + headerHeight + headerBottomGap;

              final horizontalPadding = c.maxWidth < 640 ? 16.0 : 24.0;
              final contentTop = math.max(24.0, contentTopMin);

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        contentTop,
                        horizontalPadding,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ Title block aligned to card content (NOT centered)
                              Padding(
                                padding: const EdgeInsets.only(left: _contentInset),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Settings',
                                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Customize your Lúmen experience',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 44),

                              _sectionLabel(context, 'GENERAL'),
                              const SizedBox(height: 16),

                              // Theme card
                              Glass(
                                size: GlassSize.md,
                                borderRadius: BorderRadius.circular(22),
                                padding: const EdgeInsets.symmetric(horizontal: _contentInset, vertical: 18),
                                child: _settingRow(
                                  context,
                                  icon: Icons.wb_sunny_outlined,
                                  title: 'Theme',
                                  subtitle: 'Choose your preferred appearance',
                                  trailing: DropdownButtonHideUnderline(
                                    child: DropdownButton<ThemeMode>(
                                      value: controller.themeMode,
                                      onChanged: (v) {
                                        if (v != null) controller.setThemeMode(v);
                                      },
                                      items: const [
                                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Device name card (editable, updates controller)
                              Glass(
                                size: GlassSize.md,
                                borderRadius: BorderRadius.circular(22),
                                padding: const EdgeInsets.symmetric(horizontal: _contentInset, vertical: 18),
                                child: _settingRow(
                                  context,
                                  icon: Icons.bolt,
                                  title: 'Device Name',
                                  subtitle: 'Customize your lamp name',
                                  trailing: SizedBox(
                                    width: 260,
                                    child: TextField(
                                      controller: _nameCtrl,
                                      textInputAction: TextInputAction.done,
                                      onChanged: controller.setDeviceName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        hintText: 'Living Room Lamp',
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Auto off card (UI only)
                              Glass(
                                size: GlassSize.md,
                                borderRadius: BorderRadius.circular(22),
                                padding: const EdgeInsets.symmetric(horizontal: _contentInset, vertical: 18),
                                child: _settingRow(
                                  context,
                                  icon: Icons.bolt,
                                  title: 'Auto Off',
                                  subtitle: 'Automatically turn off after 8 hours',
                                  trailing: Switch(
                                    value: false,
                                    onChanged: (_) {},
                                  ),
                                ),
                              ),

                              const SizedBox(height: 36),

                              _sectionLabel(context, 'ACCOUNT'),
                              const SizedBox(height: 16),
                              
                              // Account card
                              Glass(
                                size: GlassSize.md,
                                borderRadius: BorderRadius.circular(22),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    _kv(context, 'Username', user?.displayName ?? 'User'),
                                    const SizedBox(height: 12),
                                    _kv(context, 'Email', user?.email ?? '—'),
                                    const SizedBox(height: 24),
                                    InkWell(
                                      onTap: controller.isSigningOut
                                          ? null
                                          : () async {
                                        await controller.signOutGracefully();
                                        if (mounted) {
                                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          controller.isSigningOut ? 'Signing out…' : 'Sign out',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 36),

                              _sectionLabel(context, 'ABOUT'),
                              const SizedBox(height: 16),

                              // About card
                              Glass(
                                size: GlassSize.lg,
                                borderRadius: BorderRadius.circular(22),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 22,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Lúmen',
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Version 1.0.0',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.60),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                'Lúmen is a modern, glassmorphic lamp control interface designed for elegance and simplicity.\n'
                                                    'Control your smart lamp with precision and style.',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  height: 1.45,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.62),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Divider(
                                      height: 1,
                                      color: Theme.of(context).colorScheme.outline.withValues(
                                        alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.55,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _kv(context, 'Device Name', controller.deviceName),
                                    const SizedBox(height: 10),
                                    _kv(context, 'Device ID', controller.deviceId ?? '—'),
                                    const SizedBox(height: 10),
                                    _kv(context, 'Last Update', controller.lastUpdatedLabel),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Big back button (pill)
                              Glass(
                                size: GlassSize.md,
                                borderRadius: BorderRadius.circular(22),
                                padding: EdgeInsets.zero,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Back to Dashboard',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 22,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating header card only
                  Positioned(
                    top: headerTop,
                    left: headerSide,
                    right: headerSide,
                    child: LumenHeader(
                      controller: controller,
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

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: _contentInset),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
        ),
      ),
    );
  }

  Widget _settingRow(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Widget trailing,
      }) {
    final iconColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        trailing,
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          v,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
