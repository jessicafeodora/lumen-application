import 'package:flutter/material.dart';
import 'package:lumen_application/state/lamp_controller.dart';
import 'package:lumen_application/utils/responsive.dart';
import 'package:lumen_application/widgets/glass.dart';

import 'login_form.dart';
import 'register_form.dart';

class AuthShell extends StatefulWidget {
  final LampController controller;
  const AuthShell({super.key, required this.controller});

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  bool _isLogin = true;

  void _goRegister() => setState(() => _isLogin = false);
  void _goLogin() => setState(() => _isLogin = true);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final layout = layoutForWidth(width);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest.withValues(alpha: 0.72),
              scheme.surface.withValues(alpha: 0.92),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: layout == LumenLayout.desktop
              ? _DesktopSplit(
            controller: widget.controller,
            isLogin: _isLogin,
            onGoRegister: _goRegister,
            onGoLogin: _goLogin,
          )
              : _Stacked(
            controller: widget.controller,
            isLogin: _isLogin,
            onGoRegister: _goRegister,
            onGoLogin: _goLogin,
          ),
        ),
      ),
    );
  }
}

class _DesktopSplit extends StatelessWidget {
  final LampController controller;
  final bool isLogin;
  final VoidCallback onGoRegister;
  final VoidCallback onGoLogin;

  const _DesktopSplit({
    required this.controller,
    required this.isLogin,
    required this.onGoRegister,
    required this.onGoLogin,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Make both sides vertically centered so the form doesn't "float"
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left branding (ONLY logo + title + texts)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 54),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const _BrandMinimal(),
              ),
            ),
          ),
        ),

        // Right form
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _AuthCard(
                controller: controller,
                isLogin: isLogin,
                onGoRegister: onGoRegister,
                onGoLogin: onGoLogin,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stacked extends StatelessWidget {
  final LampController controller;
  final bool isLogin;
  final VoidCallback onGoRegister;
  final VoidCallback onGoLogin;

  const _Stacked({
    required this.controller,
    required this.isLogin,
    required this.onGoRegister,
    required this.onGoLogin,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final pad = pagePaddingForWidth(width);

    // ✅ No blank bottom space: center when short, scroll when tall.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: pad,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _BrandTopCompact(),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _AuthCard(
                      controller: controller,
                      isLogin: isLogin,
                      onGoRegister: onGoRegister,
                      onGoLogin: onGoLogin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthCard extends StatelessWidget {
  final LampController controller;
  final bool isLogin;
  final VoidCallback onGoRegister;
  final VoidCallback onGoLogin;

  const _AuthCard({
    required this.controller,
    required this.isLogin,
    required this.onGoRegister,
    required this.onGoLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      size: GlassSize.lg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Theme toggle back (top-right)
            Row(
              children: [
                const Spacer(),
                _ThemeToggle(controller: controller),
              ],
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLogin
                  ? LoginForm(
                key: const ValueKey('login'),
                onGoRegister: onGoRegister,
              )
                  : RegisterForm(
                key: const ValueKey('register'),
                onGoLogin: onGoLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final LampController controller;
  const _ThemeToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Glass(
      size: GlassSize.sm,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: controller.toggleTheme,
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          size: 20,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _BrandMinimal extends StatelessWidget {
  const _BrandMinimal();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeaderLogoRow(),
        const SizedBox(height: 26),
        Text(
          'Control your lights with a touch.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Lúmen is a modern, glassmorphic lamp control interface designed for elegance and simplicity.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.66),
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BrandTopCompact extends StatelessWidget {
  const _BrandTopCompact();

  @override
  Widget build(BuildContext context) {
    return const _HeaderLogoRow(compact: true);
  }
}

class _HeaderLogoRow extends StatelessWidget {
  final bool compact;
  const _HeaderLogoRow({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment:
      compact ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD36E),
                Color(0xFF4A70A9),
                Color(0xFF8FABD4),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'L',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              'Lúmen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Smart Home Lamp Control',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
