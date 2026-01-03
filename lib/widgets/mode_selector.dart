import 'package:flutter/material.dart';
import 'package:lumen_application/widgets/glass.dart';

class ModeSelectorCard extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const ModeSelectorCard({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Glass(
      size: GlassSize.md,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: accent.withOpacity(isDark ? 0.95 : 0.85),
              ),
              const SizedBox(width: 10),
              Text(
                'Mode',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _ModeTile(
            selectedKey: selected,
            tileKeyName: 'normal',
            title: 'Normal',
            subtitle: 'Bright & warm',
            onSelect: onSelect,
          ),
          const SizedBox(height: 12),
          _ModeTile(
            selectedKey: selected,
            tileKeyName: 'reading',
            title: 'Reading',
            subtitle: 'Focused light',
            onSelect: onSelect,
          ),
          const SizedBox(height: 12),
          _ModeTile(
            selectedKey: selected,
            tileKeyName: 'night',
            title: 'Night',
            subtitle: 'Soft glow',
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String selectedKey;
  final String tileKeyName;
  final String title;
  final String subtitle;
  final ValueChanged<String> onSelect;

  const _ModeTile({
    required this.selectedKey,
    required this.tileKeyName,
    required this.title,
    required this.subtitle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedKey == tileKeyName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Keep your exact backgrounds/borders
    final bgSelected = Colors.white.withOpacity(isDark ? 0.18 : 0.70);
    final bgIdle = Colors.white.withOpacity(isDark ? 0.06 : 0.40);

    final borderSelected = Colors.white.withOpacity(isDark ? 0.22 : 0.65);
    final borderIdle = Colors.white.withOpacity(isDark ? 0.12 : 0.45);

    final titleColor =
    Theme.of(context).colorScheme.onSurface.withOpacity(isSelected ? 1.0 : 0.95);
    final subColor =
    Theme.of(context).colorScheme.onSurface.withOpacity(isSelected ? 0.65 : 0.55);

    // ✅ EXACT timer glow (instant, no motion)
    const timerGlow = Color.fromRGBO(127, 227, 255, 0.20);

    return GestureDetector(
      onTap: () => onSelect(tileKeyName),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? bgSelected : bgIdle,
          border: Border.all(
            color: isSelected ? borderSelected : borderIdle,
            width: 1,
          ),
          // ✅ appears instantly when selected, like Timer chips
          boxShadow: isSelected
              ? const [
            BoxShadow(
              blurRadius: 20,
              color: timerGlow,
              offset: Offset(0, 0),
            ),
          ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
