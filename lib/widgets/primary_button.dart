import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final canTap = widget.enabled && !widget.loading;

    final bg = canTap
        ? scheme.primary
        : scheme.onSurface.withOpacity(0.10);

    final fg = canTap
        ? scheme.onPrimary
        : scheme.onSurface.withOpacity(0.45);

    final glow = canTap && _hover;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(0.0, glow ? -2.0 : 0.0)
        ..scale(_down ? 0.98 : 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: bg,
        boxShadow: glow
            ? [
          BoxShadow(
            color: scheme.primary.withOpacity(0.30),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          )
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Center(
        child: widget.loading
            ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(fg),
          ),
        )
            : Text(
          widget.text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: fg,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );

    Widget wrap = GestureDetector(
      onTap: canTap ? widget.onTap : null,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: button,
    );

    if (!kIsWeb) return wrap;

    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: wrap,
    );
  }
}
