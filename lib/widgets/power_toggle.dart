import 'package:flutter/material.dart';
import 'package:lumen_application/widgets/glass.dart';

class PowerToggle extends StatelessWidget {
  final bool isOn;
  final String label;
  final ValueChanged<bool> onToggle;

  const PowerToggle({
    super.key,
    required this.isOn,
    required this.label,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconColor = const Color(0xFF7DE3FF).withValues(alpha: isOn ? 0.95 : 0.55);
    final roomColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.42);
    final statusColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.92);

    return GestureDetector(
      onTap: () => onToggle(!isOn),
      child: Glass(
        size: GlassSize.lg,
        // inner panel should NOT glow; only hero glows
        glow: false,
        borderRadius: BorderRadius.circular(26),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.power_settings_new_rounded, size: 56, color: iconColor),
                const SizedBox(height: 26),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                    color: roomColor,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isOn ? 'ON' : 'OFF',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
