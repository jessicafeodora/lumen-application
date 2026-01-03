import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

enum GlassSize { sm, md, lg }

class Glass extends StatelessWidget {
  final Widget child;
  final GlassSize size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool glow;

  const Glass({
    super.key,
    required this.child,
    this.size = GlassSize.md,
    this.padding,
    this.borderRadius,
    this.glow = false,
  });

  double _blur() {
    switch (size) {
      case GlassSize.sm:
        return 12;
      case GlassSize.md:
        return 18;
      case GlassSize.lg:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final r = borderRadius ?? BorderRadius.circular(22);

    // Clean “glass” look: we control the surface tint ourselves (no muddy scrim)
    final surfaceTint = isDark
        ? scheme.surface.withOpacity(0.55) // deep blue glass panel
        : Colors.white.withOpacity(0.78); // clean light glass panel

    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    final innerHighlight = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.50);

    final shadowColor = Colors.black.withOpacity(isDark ? 0.20 : 0.10);

    final base = Container(
      decoration: BoxDecoration(
        borderRadius: r,
        // This gradient gives “glass lighting” without fogging the background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            innerHighlight,
            surfaceTint,
            surfaceTint.withOpacity(isDark ? 0.62 : 0.86),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: isDark ? 26 : 30,
            offset: const Offset(0, 14),
            color: shadowColor,
          ),
          if (glow)
            BoxShadow(
              blurRadius: 44,
              spreadRadius: 10,
              color: scheme.primary.withOpacity(isDark ? 0.22 : 0.16),
            ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    // IMPORTANT: disable package “frosted” overlay so it doesn’t add haze.
    // We only use it for the blur.
    return base.asGlass(
      blurX: _blur(),
      blurY: _blur(),
      frosted: false,
      tintColor: Colors.transparent,
      clipBorderRadius: r,
    );
  }
}
