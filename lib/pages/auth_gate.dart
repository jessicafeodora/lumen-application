import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lumen_application/pages/home_page.dart';
import 'package:lumen_application/state/lamp_controller.dart';

import 'auth/auth_shell.dart';

class AuthGate extends StatelessWidget {
  final LampController controller;
  const AuthGate({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final user = snap.data;
        final target = (user != null)
            ? HomePage(controller: controller)
            : AuthShell(controller: controller);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(user != null ? 'home' : 'login'),
            child: target,
          ),
        );
      },
    );
  }
}
