// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../utils/theme.dart';
import '../widgets/person_form_dialog.dart';
import '../widgets/tree_canvas.dart';
import '../widgets/detail_panel.dart';
import '../widgets/person_node.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _navIdx = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _navIdx = _tabs.index));
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _addPerson() => showDialog(
    context: context,
    builder: (_) => const PersonFormDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final fp       = context.watch<FamilyProvider>();
    final auth     = context.read<AuthProvider>();
    final w        = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    final selected = fp.selected;

    return Scaffold(
      backgroundColor: T.bg,
      drawer: isMobile ? _Drawer(auth: auth, fp: fp) : null,
      body: Row(
        children: [
          // Desktop sidebar
          if (!isMobile) _Sidebar(navIdx: _navIdx, auth: auth, fp: fp,
            onNav: (i) {
              if (i == 2) {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else {
                _tabs.animateTo(i);
              }
            },
          ),

          // Main area
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  isMobile: isMobile,
                  fp: fp,
                  onAdd: _addPerson,
                ),
                Expanded(
                  child: fp.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: T.primary, strokeWidth: 2))
                    : Row(
                        children: [
                          Expanded(
                            child: _Body(tabs: _tabs, fp: fp, isMobile: isMobile),
                          ),
                          // Desktop detail panel
                          if (!isMobile && selected != null)
                            SizedBox(
                              width: 310,
                              child: DetailPanel(person: selected),
                            ).animate().slideX(begin: 0.25, duration: 250.ms,
                              curve: Curves.easeOut),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: isMobile
        ? FloatingActionButton.extended(
            onPressed: _addPerson,
            backgroundColor: T.primary,
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text('Add Person',
              style: TextStyle(fontWeight: FontWeight.w600)),
          )
        : null,

      bottomNavigationBar: isMobile
        ? NavigationBar(
            selectedIndex: _navIdx,
            onDestinationSelected: (i) {
              setState(() => _navIdx = i);
              _tabs.animateTo(i);
            },
            backgroundColor: T.surface,
            indicatorColor: T.primary.withOpacity(0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.account_tree_outlined, color: T.textSecondary),
                selectedIcon: Icon(Icons.account_tree_rounded, color: T.primary),
                label: 'Tree'),
              NavigationDestination(
                icon: Icon(Icons.people_outline, color: T.textSecondary),
                selectedIcon: Icon(Icons.people_rounded, color: T.primary),
                label: 'Members'),
            ],
          )
        : null,
    );
  }
}

// ── Body (tabs) ────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final TabController tabs;
  final FamilyProvider fp;
  final bool isMobile;
  const _Body({required this.tabs, required this.fp, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (fp.persons.isEmpty) return _EmptyState();

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: const BoxDecoration(
            color: T.surface,
            border: Border(bottom: BorderSide(color: T.border)),
          ),
          child: TabBar(
            controller: tabs,
            indicatorColor: T.primary,
            indicatorWeight: 2,
            labelColor: T.primary,
            unselectedLabelColor: T.textSecondary,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.account_tree_rounded, size: 15), text: 'Tree View'),
              Tab(icon: Icon(Icons.people_rounded,       size: 15), text: 'Members'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Tree view
              TreeCanvas(fp: fp),

              // Members list
              _MemberList(fp: fp, isMobile: isMobile),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isMobile;
  final FamilyProvider fp;
  final VoidCallback onAdd;
  const _TopBar({required this.isMobile, required this.fp, required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: const BoxDecoration(
      color: T.surface,
      border: Border(bottom: BorderSide(color: T.border)),
    ),
    child: Row(children: [
      // Hamburger on mobile
      if (isMobile)
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: T.textSecondary, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),

      // Search
      Expanded(
        child: TextField(
          onChanged: fp.setSearch,
          style: const TextStyle(color: T.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Search family members…',
            prefixIcon: Icon(Icons.search, size: 16, color: T.textSecondary),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ),

      const SizedBox(width: 10),

      // Stats chips
      if (!isMobile) ...[
        _statChip('${fp.total}', 'members', T.primary),
        const SizedBox(width: 8),
        _statChip('${fp.generations}', 'gen', T.gold),
        const SizedBox(width: 12),
      ],

      // Add button (desktop)
      if (!isMobile)
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add Person', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
        ),
    ]),
  );

  Widget _statChip(String n, String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(n, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: T.textSecondary, fontSize: 11)),
    ]),
  );
}

// ── Sidebar (desktop) ──────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int navIdx;
  final AuthProvider auth;
  final FamilyProvider fp;
  final ValueChanged<int> onNav;
  const _Sidebar(
      {required this.navIdx, required this.auth, required this.fp, required this.onNav});

  @override
  Widget build(BuildContext context) => Container(
    width: 228,
    decoration: const BoxDecoration(
      color: T.surface,
      border: Border(right: BorderSide(color: T.border)),
    ),
    child: Column(children: [
      // Logo
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [T.primary, T.secondary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [BoxShadow(color: T.primary.withOpacity(0.4), blurRadius: 12)],
            ),
            child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FamilyTree',
              style: TextStyle(color: T.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Horizontal View',
              style: TextStyle(color: T.textSecondary, fontSize: 10)),
          ]),
        ]),
      ),

      // Stats
      _StatsBlock(fp: fp),
      const Divider(color: T.border, height: 1),
      const SizedBox(height: 12),

      // Nav items
      _NavItem(idx: 0, cur: navIdx, icon: Icons.account_tree_rounded, label: 'Tree View',   onTap: onNav),
      _NavItem(idx: 1, cur: navIdx, icon: Icons.people_rounded,       label: 'Members',     onTap: onNav),
      _NavItem(idx: 2, cur: navIdx, icon: Icons.settings_rounded,     label: 'Settings',    onTap: onNav),

      const Spacer(),
      const Divider(color: T.border),

      // User footer
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        child: Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: T.primary.withOpacity(0.18),
            child: Text(
              auth.user?.name.substring(0,1).toUpperCase() ?? '?',
              style: const TextStyle(color: T.primary, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auth.user?.name ?? '',
              style: const TextStyle(color: T.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
            const Text('Family Admin',
              style: TextStyle(color: T.textSecondary, fontSize: 10)),
          ])),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 17, color: T.textSecondary),
            tooltip: 'Sign out',
            onPressed: () => _logout(context, auth, fp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    ]),
  );

  void _logout(BuildContext ctx, AuthProvider auth, FamilyProvider fp) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(color: T.textPrimary)),
        content: const Text('You will be returned to the login screen.',
          style: TextStyle(color: T.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: T.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: T.error),
            child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok == true) { fp.reset(); await auth.logout(); }
  }
}

class _NavItem extends StatefulWidget {
  final int idx, cur;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;
  const _NavItem({required this.idx, required this.cur,
    required this.icon, required this.label, required this.onTap});
  @override State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.idx == widget.cur;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: active ? T.primary.withOpacity(0.12) : _hov ? T.cardAlt : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: active ? Border.all(color: T.primary.withOpacity(0.28)) : null,
          ),
          child: Row(children: [
            Icon(widget.icon,
              size: 18, color: active ? T.primary : T.textSecondary),
            const SizedBox(width: 10),
            Text(widget.label, style: TextStyle(
              color: active ? T.primary : T.textSecondary,
              fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}

// ── Stats block ────────────────────────────────────────────────────────────────
class _StatsBlock extends StatelessWidget {
  final FamilyProvider fp;
  const _StatsBlock({required this.fp});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    child: Row(children: [
      _s('${fp.total}',   'Members',  T.primary),
      _s('${fp.living}',  'Living',   T.teal),
      _s('${fp.generations}', 'Gen',  T.gold),
    ]),
  );

  Widget _s(String n, String l, Color c) => Expanded(
    child: Column(children: [
      Text(n, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.w800)),
      Text(l, style: const TextStyle(color: T.textSecondary, fontSize: 9.5, letterSpacing: 0.4)),
    ]),
  );
}

// ── Drawer (mobile) ────────────────────────────────────────────────────────────
class _Drawer extends StatelessWidget {
  final AuthProvider auth;
  final FamilyProvider fp;
  const _Drawer({required this.auth, required this.fp});

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: T.surface,
    child: SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [T.primary, T.secondary]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('FamilyTree',
              style: TextStyle(color: T.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(auth.user?.email ?? '',
              style: const TextStyle(color: T.textSecondary, fontSize: 11)),
          ]),
        ]),
      ),
      _StatsBlock(fp: fp),
      const Divider(color: T.border),
      ListTile(
        leading: const Icon(Icons.settings_rounded, color: T.textSecondary, size: 20),
        title: const Text('Settings', style: TextStyle(color: T.textPrimary, fontSize: 14)),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),
      ListTile(
        leading: const Icon(Icons.logout_rounded, color: T.error, size: 20),
        title: const Text('Sign Out', style: TextStyle(color: T.error, fontSize: 14)),
        onTap: () async {
          Navigator.pop(context);
          fp.reset();
          await auth.logout();
        },
      ),
    ])),
  );
}

// ── Members list ───────────────────────────────────────────────────────────────
class _MemberList extends StatelessWidget {
  final FamilyProvider fp;
  final bool isMobile;
  const _MemberList({required this.fp, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final list = fp.filtered;
    if (list.isEmpty) {
      return const Center(child: Text('No members match your search.',
        style: TextStyle(color: T.textSecondary, fontSize: 13)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final p   = list[i];
        final sel = fp.selectedId == p.id;
        return GestureDetector(
          onTap: () {
            fp.select(sel ? null : p.id);
            if (isMobile && !sel) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.72,
                  maxChildSize: 0.96,
                  minChildSize: 0.3,
                  builder: (_, sc) => Container(
                    decoration: const BoxDecoration(
                      color: T.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: DetailPanel(person: p),
                  ),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? T.primary.withOpacity(0.07) : T.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: sel ? T.primary.withOpacity(0.4) : T.border,
                width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              PersonAvatar(person: p, radius: 22, selected: sel),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.fullName,
                  style: TextStyle(
                    color: sel ? T.primary : T.textPrimary,
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (p.age != null) '${p.age} yrs',
                    if (p.occupation != null) p.occupation!,
                    p.isAlive ? 'Living' : 'Deceased',
                  ].join(' · '),
                  style: const TextStyle(color: T.textSecondary, fontSize: 11.5)),
              ])),
              // Relationship count badge
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _relBadge('${p.parentIds.length}P', T.gold),
                const SizedBox(height: 3),
                _relBadge('${p.childIds.length}C · ${p.spouseIds.length}S', T.teal),
              ]),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: T.textDim),
            ]),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 25));
      },
    );
  }

  Widget _relBadge(String t, Color c) => Text(t,
    style: TextStyle(color: c.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600));
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: T.primary.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: T.primary.withOpacity(0.2)),
        ),
        child: const Icon(Icons.account_tree_outlined, size: 44, color: T.primary),
      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
      const SizedBox(height: 22),
      const Text('Your family tree is empty',
        style: TextStyle(color: T.textPrimary, fontSize: 20, fontWeight: FontWeight.w700))
        .animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 8),
      const Text('Tap "Add Person" to plant your first branch',
        textAlign: TextAlign.center,
        style: TextStyle(color: T.textSecondary, fontSize: 13, height: 1.5))
        .animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 30),
      ElevatedButton.icon(
        onPressed: () => showDialog(
          context: context, builder: (_) => const PersonFormDialog()),
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: const Text('Add First Member'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
    ]),
  );
}
