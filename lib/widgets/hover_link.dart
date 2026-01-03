import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HoverLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const HoverLink({super.key, required this.text, required this.onTap});

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final text = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      style: Theme.of(context).textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.primary.withOpacity(_hover ? 0.95 : 0.78),
        decoration: _hover ? TextDecoration.underline : TextDecoration.none,
        decorationThickness: 2,
      ),
      child: Text(widget.text),
    );

    final child = GestureDetector(onTap: widget.onTap, child: text);

    if (!kIsWeb) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: child,
    );
  }
}
