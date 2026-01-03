import 'package:flutter/material.dart';
import 'package:lumen_application/widgets/glass.dart';

class TimerCard extends StatelessWidget {
  final int? selectedMinutes;
  final ValueChanged<int?> onSelect;

  const TimerCard({
    super.key,
    required this.selectedMinutes,
    required this.onSelect,
  });

  static const presets = <int>[5, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return Glass(
      size: GlassSize.md,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
              const SizedBox(width: 10),
              Text('Timer', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),

          // 2x2 pill grid
          Row(
            children: [
              Expanded(child: _pill(context, 5)),
              const SizedBox(width: 12),
              Expanded(child: _pill(context, 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _pill(context, 30)),
              const SizedBox(width: 12),
              Expanded(child: _pill(context, 60)),
            ],
          ),

          if (selectedMinutes != null) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Lamp will turn off in ${selectedMinutes!} minutes',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, int minutes) {
    final isSelected = selectedMinutes == minutes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isSelected
        ? Colors.white.withOpacity(isDark ? 0.10 : 0.20)
        : Colors.white.withOpacity(isDark ? 0.05 : 0.10);

    final border = isSelected
        ? Colors.white.withOpacity(isDark ? 0.20 : 0.30)
        : Colors.white.withOpacity(isDark ? 0.15 : 0.20);

    final label = minutes == 60 ? '1h' : '${minutes}m';

    return GestureDetector(
      onTap: () => onSelect(minutes),
      child: Container(
        height: 44, // IMPORTANT: keeps it pill, not circle
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
          boxShadow: isSelected
              ? [
            const BoxShadow(
              blurRadius: 20,
              color: Color.fromRGBO(127, 227, 255, 0.20),
              offset: Offset(0, 0),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
