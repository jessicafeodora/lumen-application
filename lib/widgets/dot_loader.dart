import 'package:flutter/material.dart';

class DotLoader extends StatefulWidget {
  const DotLoader({super.key});

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        double phase(int i) {
          final t = (_c.value + i * 0.18) % 1.0;
          return (t < 0.5) ? (t / 0.5) : ((1 - t) / 0.5);
        }

        Widget dot(int i) {
          final p = phase(i);
          final s = 6.0 + 3.0 * p;
          return Container(
            width: 14,
            alignment: Alignment.center,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(0.35 + 0.45 * p),
              ),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [dot(0), dot(1), dot(2)],
        );
      },
    );
  }
}
