// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/family_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.init();           // restore session before first frame
  runApp(FamilyTreeApp(auth: auth));
}

class FamilyTreeApp extends StatelessWidget {
  final AuthProvider auth;
  const FamilyTreeApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: MaterialApp(
        title: 'FamilyTree',
        debugShowCheckedModeBanner: false,
        theme: T.theme,
        home: const _Router(),
      ),
    );
  }
}

// ── Router: watches auth state and loads family data ─────────────────────────
class _Router extends StatefulWidget {
  const _Router();
  @override State<_Router> createState() => _RouterState();
}

class _RouterState extends State<_Router> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    if (auth.loggedIn) {
      await context.read<FamilyProvider>().init(auth.user!.id);
    }
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _Splash();

    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        // When auth state changes, reload family data
        if (auth.loggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final fp = ctx.read<FamilyProvider>();
            if (fp.persons.isEmpty && !fp.loading) {
              fp.init(auth.user!.id);
            }
          });
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: T.bg,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [T.primary, T.secondary]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: T.primary.withOpacity(0.4), blurRadius: 24)],
          ),
          child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 24),
        const Text('FamilyTree',
          style: TextStyle(color: T.textPrimary, fontSize: 28,
            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        const SizedBox(width: 28, height: 28,
          child: CircularProgressIndicator(color: T.primary, strokeWidth: 2)),
      ]),
    ),
  );
}
