import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lumen_application/state/lamp_controller.dart';
import 'package:lumen_application/utils/responsive.dart';
import 'package:lumen_application/widgets/glass.dart';
import 'package:lumen_application/widgets/dot_loader.dart';

class SplashPage extends StatefulWidget {
  final LampController controller;
  final Widget Function() nextBuilder;

  const SplashPage({
    super.key,
    required this.controller,
    required this.nextBuilder,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breath;

  bool _authReady = false;
  bool _minDelayDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _breath = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );

    // min show time
    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      _minDelayDone = true;
      _tryAdvance();
    });

    // auth check
    FirebaseAuth.instance.authStateChanges().first.then((_) {
      if (!mounted) return;
      _authReady = true;
      _tryAdvance();
    });

    // hard cap
    Timer(const Duration(milliseconds: 5200), () {
      if (!mounted) return;
      _minDelayDone = true;
      _tryAdvance(force: true);
    });
  }

  void _tryAdvance({bool force = false}) {
    if (_navigated) return;
    if (!force && !(_minDelayDone && _authReady)) return;

    _navigated = true;
    Navigator.of(context).pushReplacement(_fadeRoute(widget.nextBuilder()));
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final layout = layoutForWidth(MediaQuery.of(context).size.width);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            return Transform.scale(
              scale: _breath.value,
              child: const _LumenLogoMark(),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Lúmen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Smart Home Lamp Control',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.62),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 26),
        const DotLoader(),
        const SizedBox(height: 10),
        Text(
          'Opening the application…',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.58),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest.withOpacity(0.72),
              scheme.surface.withOpacity(0.92),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: layout == LumenLayout.desktop
                ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Glass(
                size: GlassSize.lg,
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: content,
                ),
              ),
            )
                : content,
          ),
        ),
      ),
    );
  }
}

// Reuse the homepage header logo style (gradient square "L")
class _LumenLogoMark extends StatelessWidget {
  const _LumenLogoMark();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
