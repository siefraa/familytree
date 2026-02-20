// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pw    = TextEditingController();
  final _pw2   = TextEditingController();
  bool _show1  = false, _show2 = false, _agreed = false;

  @override void dispose() {
    _name.dispose(); _email.dispose(); _pw.dispose(); _pw2.dispose();
    super.dispose();
  }

  // Password strength checker
  int _pwStrength(String pw) {
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#$%^&*]'))) score++;
    return score;
  }

  Color _strengthColor(int s) {
    if (s <= 1) return T.error;
    if (s == 2) return T.warning;
    if (s == 3) return T.amber;
    return T.success;
  }

  String _strengthLabel(int s) {
    if (s <= 1) return 'Weak';
    if (s == 2) return 'Fair';
    if (s == 3) return 'Good';
    return 'Strong';
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please accept the terms to continue.'),
        backgroundColor: T.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await context.read<AuthProvider>().register(
      name: _name.text, email: _email.text, password: _pw.text,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<AuthProvider>().error),
        backgroundColor: T.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final busy = auth.loading;
    final strength = _pwStrength(_pw.text);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.8),
            radius: 1.4,
            colors: [Color(0xFF1A0E2E), Color(0xFF080C14)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                  icon: const Icon(Icons.arrow_back_ios, size: 14, color: T.textSecondary),
                  label: const Text('Back to Login',
                    style: TextStyle(color: T.textSecondary, fontSize: 13)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(height: 12),

              // Icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [T.secondary, T.primary]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: T.secondary.withOpacity(0.4), blurRadius: 20)],
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 30),
              ).animate().scale(delay: 100.ms),
              const SizedBox(height: 16),
              const Text('Create your account',
                style: TextStyle(color: T.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Start building your family legacy',
                style: TextStyle(color: T.textSecondary, fontSize: 13)),
              const SizedBox(height: 32),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: glassBox(border: T.secondary.withOpacity(0.2), r: 20),
                  child: Form(
                    key: _form,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _lbl('Full Name'),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: T.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'John Smith',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18, color: T.textSecondary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      _lbl('Email Address'),
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
                      ),
                      const SizedBox(height: 16),

                      _lbl('Password'),
                      TextFormField(
                        controller: _pw,
                        obscureText: !_show1,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: T.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'At least 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: T.textSecondary),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _show1 = !_show1),
                            child: Icon(_show1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18, color: T.textSecondary),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      // Strength bar
                      if (_pw.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: strength / 4,
                              backgroundColor: T.border,
                              valueColor: AlwaysStoppedAnimation(_strengthColor(strength)),
                              minHeight: 4,
                            ),
                          )),
                          const SizedBox(width: 10),
                          Text(_strengthLabel(strength),
                            style: TextStyle(color: _strengthColor(strength), fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ],
                      const SizedBox(height: 16),

                      _lbl('Confirm Password'),
                      TextFormField(
                        controller: _pw2,
                        obscureText: !_show2,
                        style: const TextStyle(color: T.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Repeat your password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: T.textSecondary),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _show2 = !_show2),
                            child: Icon(_show2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18, color: T.textSecondary),
                          ),
                        ),
                        validator: (v) => v != _pw.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 20),

                      // Terms
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 20, height: 20,
                          child: Checkbox(
                            value: _agreed,
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                          )),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text.rich(TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(color: T.textSecondary, fontSize: 12, height: 1.5),
                              children: [
                                TextSpan(text: 'Terms of Service',
                                  style: TextStyle(color: T.primary, fontWeight: FontWeight.w600)),
                                TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy',
                                  style: TextStyle(color: T.primary, fontWeight: FontWeight.w600)),
                              ],
                            )),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('Already have an account? ',
                          style: TextStyle(color: T.textSecondary, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen())),
                          child: const Text('Sign in',
                            style: TextStyle(color: T.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: T.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
  );
}
