import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lumen_application/services/auth_persistence.dart';
import 'package:lumen_application/services/user_profile_rtdb.dart';
import 'package:lumen_application/widgets/hover_link.dart';
import 'package:lumen_application/widgets/primary_button.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onGoRegister;
  const LoginForm({super.key, required this.onGoRegister});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _remember = true;
  bool _showPass = false;
  bool _loading = false;
  String _error = '';

  bool get _validBasic {
    final e = _email.text.trim();
    final p = _pass.text;
    return e.contains('@') && p.length >= 6;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Login failed.';
    }
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      // Apply remember-me persistence (web: LOCAL vs SESSION). Safe no-op on other platforms.
      try {
        await AuthPersistence.apply(rememberMe: _remember);
      } catch (_) {}

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );

      final user = cred.user;
      if (user != null) {
        // Ensure minimal profile exists (RTDB) for device binding.
        await UserProfileRTDB.ensureUserProfile(user);
      }

      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use your account to continue.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.62),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            children: [
              _Field(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_loading,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Email is required';
                  if (!s.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Password',
                controller: _pass,
                enabled: !_loading,
                obscureText: !_showPass,
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Password is required';
                  if (s.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
                trailing: IconButton(
                  tooltip: _showPass ? 'Hide password' : 'Show password',
                  onPressed: _loading ? null : () => setState(() => _showPass = !_showPass),
                  icon: Icon(
                    _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: _loading ? null : (v) => setState(() => _remember = v ?? true),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  Text(
                    'Remember me',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              PrimaryButton(
                text: 'Sign in',
                loading: _loading,
                enabled: _validBasic && !_loading,
                onTap: _submit,
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  HoverLink(
                    text: 'Register',
                    onTap: widget.onGoRegister,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? trailing;
  final bool enabled;

  const _Field({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.55),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.70), width: 1.2),
        ),
      ),
    );
  }
}
