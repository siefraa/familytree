// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPw  = TextEditingController();
  final _newPw  = TextEditingController();
  final _cnfPw  = TextEditingController();
  bool _s1 = true, _s2 = true, _s3 = true;
  bool _saving = false;

  @override
  void dispose() { _oldPw.dispose(); _newPw.dispose(); _cnfPw.dispose(); super.dispose(); }

  Future<void> _changePw() async {
    if (_newPw.text.length < 6) { _snack('At least 6 characters required.', T.warning); return; }
    if (_newPw.text != _cnfPw.text) { _snack('Passwords do not match.', T.error); return; }
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().changePassword(_oldPw.text, _newPw.text);
    setState(() => _saving = false);
    if (ok) {
      _oldPw.clear(); _newPw.clear(); _cnfPw.clear();
      _snack('Password updated successfully!', T.teal);
    } else {
      _snack(context.read<AuthProvider>().error, T.error);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: c,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  ));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fp   = context.read<FamilyProvider>();

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        foregroundColor: T.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: T.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Account info ───────────────────────────────────────────────
            _secLabel('ACCOUNT'),
            _InfoCard(rows: [
              _InfoRow(Icons.badge_outlined,    'Name',         auth.user?.name ?? '–'),
              _InfoRow(Icons.alternate_email,   'Email',        auth.user?.email ?? '–'),
              _InfoRow(Icons.calendar_today_outlined, 'Member since',
                auth.user?.createdAt != null
                  ? _fmtDate(auth.user!.createdAt)
                  : '–'),
            ]),
            const SizedBox(height: 24),

            // ── Family stats ───────────────────────────────────────────────
            _secLabel('FAMILY TREE'),
            _InfoCard(rows: [
              _InfoRow(Icons.people_rounded,          'Total members',  '${fp.total}'),
              _InfoRow(Icons.favorite_outline,        'Living members', '${fp.living}'),
              _InfoRow(Icons.heart_broken_outlined,   'Deceased',       '${fp.deceased}'),
              _InfoRow(Icons.male_rounded,            'Male',           '${fp.maleCount}'),
              _InfoRow(Icons.female_rounded,          'Female',         '${fp.femaleCount}'),
              _InfoRow(Icons.account_tree_outlined,   'Generations',    '${fp.generations}'),
            ]),
            const SizedBox(height: 24),

            // ── Change password ────────────────────────────────────────────
            _secLabel('SECURITY'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: glassBox(border: T.primary.withOpacity(0.2)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.lock_outline, color: T.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Change Password',
                    style: TextStyle(color: T.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 18),
                _pwField(_oldPw, 'Current password', _s1,
                  () => setState(() => _s1 = !_s1)),
                const SizedBox(height: 12),
                _pwField(_newPw, 'New password', _s2,
                  () => setState(() => _s2 = !_s2)),
                const SizedBox(height: 12),
                _pwField(_cnfPw, 'Confirm new password', _s3,
                  () => setState(() => _s3 = !_s3)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _changePw,
                    child: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Danger zone ────────────────────────────────────────────────
            _secLabel('DANGER ZONE'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: glassBox(border: T.error.withOpacity(0.3)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.warning_rounded, color: T.error, size: 18),
                  SizedBox(width: 8),
                  Text('Danger Zone',
                    style: TextStyle(color: T.error, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                const Text(
                  'Clearing the tree permanently deletes all family members and relationships. '
                  'This action cannot be undone.',
                  style: TextStyle(color: T.textSecondary, fontSize: 13, height: 1.5)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _confirmClear(context, fp),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Clear All Family Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: T.error,
                    side: const BorderSide(color: T.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _secLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(
      color: T.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
  );

  Widget _pwField(TextEditingController c, String hint, bool obscure, VoidCallback toggle) =>
    TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: T.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 16, color: T.textSecondary),
        suffixIcon: GestureDetector(
          onTap: toggle,
          child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 16, color: T.textSecondary),
        ),
      ),
    );

  Future<void> _confirmClear(BuildContext ctx, FamilyProvider fp) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data?', style: TextStyle(color: T.textPrimary, fontSize: 16)),
        content: const Text('This will permanently delete all family members. Cannot be undone.',
          style: TextStyle(color: T.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: T.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: T.error),
            child: const Text('Delete All')),
        ],
      ),
    );
    if (ok == true) { fp.reset(); if (ctx.mounted) Navigator.pop(ctx); }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _InfoCard extends StatelessWidget {
  final List<Widget> rows;
  const _InfoCard({required this.rows});
  @override
  Widget build(BuildContext context) => Container(
    decoration: glassBox(),
    child: Column(children: rows),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 15, color: T.textSecondary),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: T.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: T.textPrimary, fontSize: 13,
        fontWeight: FontWeight.w600)),
    ]),
  );
}
