// lib/screens/auth/forgot_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent   = false;
  bool _busy   = false;

  @override void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final exists = await context.read<AuthProvider>().checkEmailExists(_email.text);
    setState(() { _busy = false; _sent = true; });
    // We always show "sent" to avoid email enumeration
    // remove this line
// _ = exists;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [Color(0xFF0E1F38), Color(0xFF080C14)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // Back
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: T.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _sent ? _SentView(email: _email.text) : _FormView(
                        form: _form, email: _email, busy: _busy, onSubmit: _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> form;
  final TextEditingController email;
  final bool busy;
  final VoidCallback onSubmit;
  const _FormView({required this.form, required this.email, required this.busy, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          color: T.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: T.amber.withOpacity(0.35)),
        ),
        child: const Icon(Icons.lock_reset_rounded, color: T.amber, size: 32),
      ).animate().scale(),
      const SizedBox(height: 20),
      const Text('Reset Password',
        style: TextStyle(color: T.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text("Enter your email and we'll send a reset link",
        textAlign: TextAlign.center,
        style: TextStyle(color: T.textSecondary, fontSize: 13)),
      const SizedBox(height: 36),
      Container(
        padding: const EdgeInsets.all(32),
        decoration: glassBox(border: T.amber.withOpacity(0.2), r: 20),
        child: Form(
          key: form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Email Address',
              style: TextStyle(color: T.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: T.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.alternate_email, size: 18, color: T.textSecondary),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                return null;
              },
              onFieldSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: busy ? null : onSubmit,
                style: ElevatedButton.styleFrom(backgroundColor: T.amber),
                child: busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Reset Link'),
              ),
            ),
          ]),
        ),
      ),
    ]).animate().fadeIn();
  }
}

class _SentView extends StatelessWidget {
  final String email;
  const _SentView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: T.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: T.success.withOpacity(0.35)),
        ),
        child: const Icon(Icons.mark_email_read_outlined, color: T.success, size: 38),
      ).animate().scale(delay: 100.ms).then().shake(hz: 2, delay: 400.ms),
      const SizedBox(height: 24),
      const Text('Check your inbox',
        style: TextStyle(color: T.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text('If $email is registered, a reset link has been sent.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: T.textSecondary, fontSize: 13, height: 1.6)),
      const SizedBox(height: 36),
      SizedBox(
        width: double.infinity, height: 50,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: T.primary),
            foregroundColor: T.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Back to Login'),
        ),
      ),
    ]).animate().fadeIn();
  }
}
