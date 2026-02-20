// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'register_screen.dart';
import 'forgot_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form    = GlobalKey<FormState>();
  final _email   = TextEditingController();
  final _pw      = TextEditingController();
  bool _showPw   = false;
  bool _remember = false;

  @override void dispose() { _email.dispose(); _pw.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().login(
      email: _email.text, password: _pw.text, remember: _remember,
    );
    if (!ok && mounted) _snack(context.read<AuthProvider>().error);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: T.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final busy  = auth.loading;
    final wide  = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.8),
            radius: 1.4,
            colors: [Color(0xFF0E1E3A), Color(0xFF080C14)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // ── Logo ───────────────────────────────────────────────────
              _AppLogo()
                .animate().fadeIn(duration: 700.ms).slideY(begin: -0.2),
              const SizedBox(height: 44),

              // ── Card ────────────────────────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: EdgeInsets.all(wide ? 40 : 28),
                  decoration: glassBox(border: T.border, r: 20),
                  child: Form(
                    key: _form,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Welcome back',
                        style: TextStyle(color: T.textPrimary, fontSize: 22,
                          fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      const Text('Sign in to your family tree',
                        style: TextStyle(color: T.textSecondary, fontSize: 13)),
                      const SizedBox(height: 32),

                      _Label('Email address'),
                      TextFormField(
                        controller: _email,
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
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 18),

                      _Label('Password'),
                      TextFormField(
                        controller: _pw,
                        obscureText: !_showPw,
                        style: const TextStyle(color: T.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: T.textSecondary),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPw = !_showPw),
                            child: Icon(_showPw ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined, size: 18, color: T.textSecondary),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 14),

                      // Remember + Forgot
                      Row(children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: _remember,
                            onChanged: (v) => setState(() => _remember = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember me',
                          style: TextStyle(color: T.textSecondary, fontSize: 13)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ForgotScreen())),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0)),
                          child: const Text('Forgot password?',
                            style: TextStyle(color: T.primary, fontSize: 13,
                              fontWeight: FontWeight.w500)),
                        ),
                      ]).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 28),

                      // Submit
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: T.primary,
                            disabledBackgroundColor: T.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: busy
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 24),

                      // Register link
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("Don't have an account? ",
                          style: TextStyle(color: T.textSecondary, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('Create one',
                            style: TextStyle(color: T.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]).animate().fadeIn(delay: 350.ms),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [T.primary, T.secondary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: T.primary.withOpacity(0.45), blurRadius: 28, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 38),
    ),
    const SizedBox(height: 16),
    const Text('FamilyTree',
      style: TextStyle(color: T.textPrimary, fontSize: 30,
        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
    const SizedBox(height: 4),
    const Text('Connect every branch of your family',
      style: TextStyle(color: T.textSecondary, fontSize: 13)),
  ]);
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: const TextStyle(color: T.textSecondary, fontSize: 12,
        fontWeight: FontWeight.w500, letterSpacing: 0.2)),
  );
}
