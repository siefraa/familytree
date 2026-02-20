// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';

enum AuthStatus { unknown, guest, authenticated, loading }

class AuthProvider extends ChangeNotifier {
  AppUser?    _user;
  AuthStatus  _status = AuthStatus.unknown;
  String      _error  = '';
  bool        _rememberMe = false;

  AppUser?   get user       => _user;
  AuthStatus get status     => _status;
  String     get error      => _error;
  bool       get loggedIn   => _user != null;
  bool       get rememberMe => _rememberMe;
  bool       get loading    => _status == AuthStatus.loading;

  static const _kUsers   = 'ft2_users';
  static const _kSession = 'ft2_session';
  static const _kRemember= 'ft2_remember';

  String _hash(String pw) =>
    sha256.convert(utf8.encode('FT_SALT_v2_$pw')).toString();

  // ── Boot: restore saved session ──────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_kRemember) ?? false;
    if (_rememberMe) {
      final s = prefs.getString(_kSession);
      if (s != null) {
        try {
          _user   = AppUser.fromJson(jsonDecode(s));
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        } catch (_) {}
      }
    }
    _status = AuthStatus.guest;
    notifyListeners();
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
    await _delay();

    final prefs   = await SharedPreferences.getInstance();
    final users   = _loadUsers(prefs);
    final emailLc = email.toLowerCase().trim();

    if (users.any((u) => u.email == emailLc)) {
      return _fail('An account with this email already exists.');
    }
    if (password.length < 6) {
      return _fail('Password must be at least 6 characters.');
    }

    final user = AppUser(
      id: const Uuid().v4(),
      email: emailLc,
      name: name.trim(),
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    );
    users.add(user);
    await _saveUsers(prefs, users);
    await _startSession(prefs, user);
    return true;
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    _setLoading();
    await _delay();

    final prefs   = await SharedPreferences.getInstance();
    final users   = _loadUsers(prefs);
    final emailLc = email.toLowerCase().trim();
    final match   = users.cast<AppUser?>().firstWhere(
      (u) => u!.email == emailLc && u.passwordHash == _hash(password),
      orElse: () => null,
    );

    if (match == null) return _fail('Incorrect email or password.');

    _rememberMe = remember;
    await prefs.setBool(_kRemember, remember);
    await _startSession(prefs, match);
    return true;
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _user   = null;
    _status = AuthStatus.guest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    notifyListeners();
  }

  // ── Change password ──────────────────────────────────────────────────────
  Future<bool> changePassword(String oldPw, String newPw) async {
    if (_user == null) return false;
    if (_user!.passwordHash != _hash(oldPw)) {
      _error = 'Current password is incorrect.';
      notifyListeners();
      return false;
    }
    if (newPw.length < 6) {
      _error = 'New password must be at least 6 characters.';
      notifyListeners();
      return false;
    }
    final prefs  = await SharedPreferences.getInstance();
    final users  = _loadUsers(prefs);
    final idx    = users.indexWhere((u) => u.id == _user!.id);
    if (idx < 0) return false;

    final updated = AppUser(
      id: _user!.id, email: _user!.email, name: _user!.name,
      passwordHash: _hash(newPw), createdAt: _user!.createdAt,
    );
    users[idx] = updated;
    _user = updated;
    await _saveUsers(prefs, users);
    await _startSession(prefs, updated);
    _error = '';
    notifyListeners();
    return true;
  }

  // ── Forgot password (simulated) ──────────────────────────────────────────
  Future<bool> checkEmailExists(String email) async {
    await _delay(ms: 800);
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    return users.any((u) => u.email == email.toLowerCase().trim());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  void clearError() { _error = ''; notifyListeners(); }

  void _setLoading() { _status = AuthStatus.loading; _error = ''; notifyListeners(); }

  bool _fail(String msg) {
    _error = msg; _status = AuthStatus.guest; notifyListeners(); return false;
  }

  Future<void> _delay({int ms = 600}) => Future.delayed(Duration(milliseconds: ms));

  List<AppUser> _loadUsers(SharedPreferences p) {
    final s = p.getString(_kUsers);
    if (s == null) return [];
    return (jsonDecode(s) as List).map((e) => AppUser.fromJson(e)).toList();
  }

  Future<void> _saveUsers(SharedPreferences p, List<AppUser> users) =>
    p.setString(_kUsers, jsonEncode(users.map((u) => u.toJson()).toList()));

  Future<void> _startSession(SharedPreferences p, AppUser user) async {
    _user   = user;
    _status = AuthStatus.authenticated;
    if (_rememberMe) await p.setString(_kSession, jsonEncode(user.toJson()));
    notifyListeners();
  }
}
