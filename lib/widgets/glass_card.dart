import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum GlassSize { sm, md, lg }

class GlassCard extends StatefulWidget {
  final Widget child;
  final GlassSize size;

  /// If true, applies hover/press transform & cursor affordance (web),
  /// and enables onTap if provided.
  final bool interactive;

  /// Adds soft glow shadow (accented).
  final bool glow;

  final EdgeInsets? padding;

  /// Optional overrides
  final Color? tintOverride;
  final BorderRadius? radiusOverride;
  final BoxBorder? borderOverride;

  /// ✅ NEW: disable the 1px top highlight line (needed for header)
  final bool disableTopHighlight;

  /// ✅ NEW: tap handler (optional)
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.size = GlassSize.md,
    this.interactive = false,
    this.glow = false,
    this.padding,
    this.tintOverride,
    this.radiusOverride,
    this.borderOverride,
    this.disableTopHighlight = false,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hover = false;
  bool _pressed = false;

  bool get _enableHover => kIsWeb; // only web has hover

  double get _blur {
    switch (widget.size) {
      case GlassSize.sm:
        return 18; // closer to spec 16–24
      case GlassSize.md:
        return 22;
      case GlassSize.lg:
        return 28;
    }
  }

  BorderRadius get _radius {
    if (widget.radiusOverride != null) return widget.radiusOverride!;
    switch (widget.size) {
      case GlassSize.sm:
        return BorderRadius.circular(16);
      case GlassSize.md:
        return BorderRadius.circular(20);
      case GlassSize.lg:
        return BorderRadius.circular(28);
    }
  }

  double get _opacityBase {
    // glass fill 10–20%
    switch (widget.size) {
      case GlassSize.sm:
        return 0.10;
      case GlassSize.md:
        return 0.15;
      case GlassSize.lg:
        return 0.20;
    }
  }

  double get _borderOpacityBase {
    // border 20–35%
    switch (widget.size) {
      case GlassSize.sm:
        return 0.18;
      case GlassSize.md:
        return 0.22;
      case GlassSize.lg:
        return 0.26;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Better default tint:
    // - Light mode: warm neutral glass (less "blue-white")
    // - Dark mode: cool glass but subtle
    final Color defaultTint = isDark
        ? const Color(0xFFFFFFFF).withOpacity(_opacityBase) // still white, but low opacity
        : const Color(0xFFFFFCF2).withOpacity(_opacityBase); // warm off-white

    final baseTint = widget.tintOverride ?? defaultTint;

    final borderColor = Colors.white.withOpacity(
      (_borderOpacityBase) + ((_enableHover && _hover) ? 0.06 : 0.0),
    );

    final border = widget.borderOverride ??
        Border.all(
          color: borderColor,
          width: 1,
        );

    // Hover/press transforms
    final translateY = (!widget.interactive || !_enableHover)
        ? 0.0
        : (_pressed ? 0.0 : (_hover ? -2.0 : 0.0));

    final scale = (!widget.interactive)
        ? 1.0
        : (_pressed ? 0.98 : 1.0);

    // Softer shadows to avoid "band lines" around header areas
    final shadowDepth = BoxShadow(
      blurRadius: 26,
      offset: const Offset(0, 16),
      color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
    );

    final shadowSoft = BoxShadow(
      blurRadius: 10,
      offset: const Offset(0, 6),
      color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
    );

    final glowShadow = widget.glow
        ? BoxShadow(
      blurRadius: 46,
      spreadRadius: 2,
      // cyan in dark, golden in light
      color: (isDark ? const Color(0xFF7DE3FF) : const Color(0xFFFFD36E))
          .withOpacity(0.18),
    )
        : null;

    Widget card = ClipRRect(
      borderRadius: _radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: _radius,
            color: baseTint,
            border: border,
            boxShadow: [
              if (glowShadow != null) glowShadow,
              shadowSoft,
              shadowDepth,
            ],
          ),
          child: Stack(
            children: [
              // ✅ Optional top highlight edge — can be disabled (header needs this OFF)
              if (!widget.disableTopHighlight)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(isDark ? 0.18 : 0.30),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              widget.child,
            ],
          ),
        ),
      ),
    );

    // No interactivity → done
    if (!widget.interactive) return card;

    // Add transform animation
    card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(0.0, translateY)
        ..scale(scale),
      child: card,
    );

    // Web hover + click
    if (_enableHover) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: card,
        ),
      );
      return card;
    }

    // Mobile: no hover, still allow tap + pressed scale
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: card,
    );
  }
}
