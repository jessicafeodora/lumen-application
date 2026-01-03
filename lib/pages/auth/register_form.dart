import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumen_application/services/user_profile_rtdb.dart';
import 'package:lumen_application/widgets/primary_button.dart';
import 'package:lumen_application/widgets/hover_link.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onGoLogin;
  const RegisterForm({super.key, required this.onGoLogin});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;
  String _error = '';

  bool get _validBasic {
    final n = _username.text.trim();
    final e = _email.text.trim();
    final p = _pass.text;
    final c = _confirm.text;
    return n.isNotEmpty && e.contains('@') && p.length >= 6 && c == p;
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Registration is disabled.';
      default:
        return e.message ?? 'Register failed.';
    }
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      final user = cred.user;
      if (user != null) {
        // Set display name immediately
        final name = _username.text.trim();
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
          await user.reload(); // Reload to reflect changes locally
        }

        // Pass updated user to ensureUserProfile (it reads displayName)
        await UserProfileRTDB.ensureUserProfile(FirebaseAuth.instance.currentUser ?? user);
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
          'Create account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use your email to register.',
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
              // Username Field
              _Field(
                label: 'Username',
                controller: _username,
                keyboardType: TextInputType.text,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Username is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _Field(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = (v ?? '').trim().toLowerCase();
                  if (s.isEmpty) return 'Email is required';
                  if (!s.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Password',
                controller: _pass,
                obscureText: !_showPass,
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Password is required';
                  if (s.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
                trailing: IconButton(
                  onPressed: () => setState(() => _showPass = !_showPass),
                  icon: Icon(
                    _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Confirm password',
                controller: _confirm,
                obscureText: !_showConfirm,
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'Confirm your password';
                  if (v != _pass.text) return 'Passwords do not match';
                  return null;
                },
                trailing: IconButton(
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                  ),
                ),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
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

              const SizedBox(height: 12),

              PrimaryButton(
                text: 'Create account',
                loading: _loading,
                enabled: _validBasic && !_loading,
                onTap: _submit,
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  HoverLink(
                    text: 'Sign in',
                    onTap: widget.onGoLogin,
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

  const _Field({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
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
