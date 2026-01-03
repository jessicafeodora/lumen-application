import 'package:flutter/material.dart';

import '../state/lamp_controller.dart';
import '../theme/lumen_theme.dart';
import 'glass.dart';

/// Floating header card (NOT an AppBar).
/// Place it in a Stack using Positioned, so the background can scroll underneath.
class LumenHeader extends StatelessWidget {
  final LampController controller;
  final bool showSettings;

  const LumenHeader({
    super.key,
    required this.controller,
    required this.showSettings,
  });

  // Handy constant for page layouts that need to offset content under the header.
  static const double cardHeight = 40;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Glass(
        size: GlassSize.md,
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SizedBox(
          height: cardHeight,
          child: Row(
            children: [
              // Logo block (DO NOT CHANGE ICON)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD36E),
                      Color(0xFF4A70A9),
                      Color(0xFF8FABD4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'L',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                'Lúmen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: (isDark ? LumenColors.darkFg : LumenColors.lightFg).withValues(alpha: 0.95),
                ),
              ),

              const Spacer(),

              if (showSettings) ...[
                _HeaderButton(
                  isDark: isDark,
                  icon: Icons.settings,
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
                const SizedBox(width: 10),
              ],

              // Theme button
              _HeaderButton(
                isDark: isDark,
                icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                iconColor: isDark ? LumenColors.darkAccent : LumenColors.lightPrimary,
                onTap: controller.toggleTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      size: GlassSize.sm,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
