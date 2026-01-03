import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lumen_application/theme/lumen_theme.dart';
import 'package:lumen_application/widgets/glass.dart';

class BrightnessCard extends StatelessWidget {
  final int value;
  final bool disabled;
  final ValueChanged<int> onChanged;

  const BrightnessCard({
    super.key,
    required this.value,
    required this.disabled,
    required this.onChanged,
  });

  void _setPreset(int v) => onChanged(v.clamp(0, 100));

  static const presets = [25, 50, 75];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isDark ? LumenColors.darkAccent : LumenColors.lightAccent;
    final mutedText = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
    final mutedIcon = Theme.of(context).colorScheme.onSurface.withOpacity(0.45);

    return Stack(
      children: [
        Glass(
          size: GlassSize.md,
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 20,
                    color: disabled ? mutedIcon : (value > 50 ? accent : mutedIcon),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Brightness',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _GradientSlider(
                value: value,
                disabled: disabled,
                onChanged: onChanged,
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$value%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: disabled ? mutedText : accent,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ✅ Presets behave like Timer chips (instant glow, no ripple animation)
              Row(
                children: [
                  for (final p in presets) ...[
                    Expanded(
                      child: _BrightnessPresetChip(
                        label: '$p%',
                        active: !disabled && value == p,
                        disabled: disabled,
                        onTap: () => _setPreset(p),
                      ),
                    ),
                    if (p != presets.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Keep your card glow (this is separate from chip glow)
        if (!disabled && value > 70)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.20 : 0.12,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: RadialGradient(
                      radius: 0.95,
                      colors: [
                        (isDark ? LumenColors.darkAccent : LumenColors.lightPrimary).withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrightnessPresetChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  const _BrightnessPresetChip({
    required this.label,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ EXACT Timer chip background/border logic
    final bg = active
        ? Colors.white.withOpacity(isDark ? 0.10 : 0.20)
        : Colors.white.withOpacity(isDark ? 0.05 : 0.10);

    final border = active
        ? Colors.white.withOpacity(isDark ? 0.20 : 0.30)
        : Colors.white.withOpacity(isDark ? 0.15 : 0.20);

    return Opacity(
      opacity: disabled ? 0.60 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 44, // ✅ same as Timer chips
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1),

            // ✅ glow appears instantly ONLY when selected
            boxShadow: active
                ? const [
              BoxShadow(
                blurRadius: 20,
                color: Color.fromRGBO(127, 227, 255, 0.20),
                offset: Offset(0, 0),
              ),
            ]
                : null,
          ),
          child: Stack(
            children: [
              // ✅ same center sheen as Timer chips (static, not animated)
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
                    color: active
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientSlider extends StatefulWidget {
  final int value;
  final bool disabled;
  final ValueChanged<int> onChanged;

  const _GradientSlider({
    required this.value,
    required this.disabled,
    required this.onChanged,
  });

  @override
  State<_GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<_GradientSlider> {
  bool dragging = false;
  int? _lastSent;

  void _setFromDx(double dx, double width) {
    final t = (dx / width).clamp(0.0, 1.0);
    final v = (t * 100).round();
    if (_lastSent != v) {
      _lastSent = v;
      widget.onChanged(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? LumenColors.darkAccent : LumenColors.lightAccent;

    final filledStart = accent.withOpacity(isDark ? 0.28 : 0.22);
    final filledEnd = accent.withOpacity(isDark ? 0.80 : 0.55);

    final remaining = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.10)
        : const Color.fromRGBO(0, 0, 0, 0.08);

    final disabledRemaining = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.06)
        : const Color.fromRGBO(0, 0, 0, 0.05);

    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final t = (widget.value / 100.0).clamp(0.0, 1.0);
        final thumbX = w * t;
        final trackRemaining = widget.disabled ? disabledRemaining : remaining;

        final thumbSize = dragging ? 22.0 : 20.0;
        final thumbRadius = thumbSize / 2;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: widget.disabled
              ? null
              : (_) {
            _lastSent = null;
            setState(() => dragging = true);
          },
          onPanEnd: widget.disabled ? null : (_) => setState(() => dragging = false),
          onPanUpdate: widget.disabled ? null : (d) => _setFromDx(d.localPosition.dx, w),
          onTapDown: widget.disabled ? null : (d) => _setFromDx(d.localPosition.dx, w),
          child: SizedBox(
            height: 26,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        stops: [0.0, t, t, 1.0],
                        colors: [
                          filledStart,
                          widget.disabled ? filledStart.withOpacity(0.25) : filledEnd,
                          trackRemaining,
                          trackRemaining,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.06 : 0.18),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (thumbX - thumbRadius).clamp(0.0, math.max(0.0, w - thumbSize)),
                  child: Opacity(
                    opacity: widget.disabled ? 0.55 : 1.0,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.disabled
                            ? Colors.white.withOpacity(isDark ? 0.14 : 0.55)
                            : accent,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: dragging ? 18 : 14,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
                          ),
                          if (!widget.disabled)
                            BoxShadow(
                              blurRadius: dragging ? 26 : 18,
                              spreadRadius: dragging ? 2 : 0,
                              color: accent.withOpacity(isDark ? 0.25 : 0.18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
