// lib/widgets/detail_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/family_provider.dart';
import '../utils/theme.dart';
import 'person_node.dart';
import 'person_form_dialog.dart';
import 'link_dialog.dart';

class DetailPanel extends StatelessWidget {
  final Person person;
  const DetailPanel({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FamilyProvider>();
    final p  = fp.byId(person.id) ?? person; // always fresh

    final accentColor = p.gender == Gender.male ? T.maleColor
        : p.gender == Gender.female ? T.femaleColor : T.primary;

    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        border: Border(left: BorderSide(color: T.border)),
      ),
      child: Column(
        children: [
          // ── Profile header ──────────────────────────────────────────────
          _ProfileHeader(person: p, accentColor: accentColor, fp: fp)
              .animate().fadeIn(duration: 280.ms),

          // ── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Action grid
                _SectionLabel('ACTIONS'),
                const SizedBox(height: 8),
                _ActionGrid(person: p),
                const SizedBox(height: 20),

                // Vitals
                if (p.birthDate != null || p.birthPlace != null ||
                    p.nationality != null || p.occupation != null)
                  _InfoCard(person: p),

                // Bio
                if (p.bio != null && p.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionLabel('BIOGRAPHY'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: T.cardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: T.border),
                    ),
                    child: Text(p.bio!,
                        style: const TextStyle(
                            color: T.textSecondary, fontSize: 12.5, height: 1.6)),
                  ),
                ],

                // Relationships
                const SizedBox(height: 18),
                _RelationGroup('PARENTS',  Icons.supervisor_account_rounded, T.gold,      p.parentIds,  fp),
                _RelationGroup('SPOUSES',  Icons.favorite_rounded,           T.rose,      p.spouseIds,  fp),
                _RelationGroup('CHILDREN', Icons.child_care_rounded,         T.teal,      p.childIds,   fp),
                _RelationGroup('SIBLINGS', Icons.people_rounded,             T.amber,     p.siblingIds, fp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final Person person;
  final Color accentColor;
  final FamilyProvider fp;
  const _ProfileHeader(
      {required this.person, required this.accentColor, required this.fp});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [accentColor.withOpacity(0.1), Colors.transparent],
      ),
      border: const Border(bottom: BorderSide(color: T.border)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () => fp.select(null),
              child: const Icon(Icons.close, color: T.textSecondary, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        PersonAvatar(person: person, radius: 34, selected: true),
        const SizedBox(height: 10),
        Text(person.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(color: T.textPrimary, fontSize: 16,
              fontWeight: FontWeight.w700)),
        if (person.occupation != null) ...[
          const SizedBox(height: 3),
          Text(person.occupation!,
              style: const TextStyle(color: T.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: [
          _badge(person.isAlive ? 'Living' : 'Deceased',
              person.isAlive ? T.teal : T.textSecondary),
          if (person.age != null) _badge('${person.age} yrs', accentColor),
          _badge(person.genderLabel, accentColor),
          if (person.nationality != null) _badge(person.nationality!, T.textSecondary),
        ]),
      ],
    ),
  );

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.3)),
    ),
    child: Text(t, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w600)),
  );
}

// ── Action grid ────────────────────────────────────────────────────────────────
class _ActionGrid extends StatelessWidget {
  final Person person;
  const _ActionGrid({required this.person});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action('Edit',         Icons.edit_rounded,                 T.primary,   () => _edit(context)),
      _Action('Add Parent',   Icons.supervisor_account_rounded,   T.gold,      () => _link(context, LinkMode.parent)),
      _Action('Add Child',    Icons.child_care_rounded,           T.teal,      () => _link(context, LinkMode.child)),
      _Action('Add Spouse',   Icons.favorite_rounded,             T.rose,      () => _link(context, LinkMode.spouse)),
      _Action('Add Sibling',  Icons.people_rounded,               T.amber,     () => _link(context, LinkMode.sibling)),
      _Action('Link',         Icons.link_rounded,                 T.secondary, () => _showAddNew(context)),
      _Action('Unlink',       Icons.link_off_rounded,             T.textSecondary, () => _link(context, LinkMode.unlink)),
      _Action('Update',       Icons.update_rounded,               T.teal,      () => _edit(context)),
      _Action('Delete',       Icons.delete_outline_rounded,       T.error,     () => _delete(context)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: actions.map(_ActionBtn.new).toList(),
    );
  }

  void _edit(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => PersonFormDialog(existing: person),
  );

  void _link(BuildContext ctx, LinkMode mode) => showDialog(
    context: ctx,
    builder: (_) => LinkDialog(source: person, mode: mode),
  );

  void _delete(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: T.error, size: 20),
          SizedBox(width: 8),
          Text('Delete Person', style: TextStyle(color: T.textPrimary, fontSize: 16)),
        ]),
        content: Text(
          'Remove ${person.fullName} from the tree?\nAll connections will be unlinked.',
          style: const TextStyle(color: T.textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: T.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: T.error),
            child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      ctx.read<FamilyProvider>().deletePerson(person.id);
    }
  }

  void _showAddNew(BuildContext ctx) async {
    // Open person form then let user pick what role it is
    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => const PersonFormDialog(),
    );
    if (result == true && ctx.mounted) {
      final fp = ctx.read<FamilyProvider>();
      if (fp.persons.isNotEmpty) {
        final newest = fp.persons.last;
        showDialog(
          context: ctx,
          builder: (_) => _PickRoleDialog(
            source: person, target: newest, fp: fp,
          ),
        );
      }
    }
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.label, this.icon, this.color, this.onTap);
}

class _ActionBtn extends StatefulWidget {
  final _Action action;
  const _ActionBtn(this.action, {super.key});
  @override State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: a.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered ? a.color.withOpacity(0.16) : T.cardAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? a.color.withOpacity(0.5) : T.border,
              width: _hovered ? 1.4 : 1,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(a.icon,
                color: _hovered ? a.color : T.textSecondary, size: 22),
            const SizedBox(height: 5),
            Text(a.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hovered ? a.color : T.textSecondary,
                fontSize: 10, fontWeight: FontWeight.w500, height: 1.2)),
          ]),
        ),
      ),
    );
  }
}

// ── Info card ──────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Person person;
  const _InfoCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final p = person;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel('DETAILS'),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: T.cardAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: T.border),
        ),
        child: Column(children: [
          if (p.birthDate != null)
            _Row(Icons.cake_outlined, 'Born',
                DateFormat('d MMMM yyyy').format(p.birthDate!)),
          if (!p.isAlive && p.deathDate != null)
            _Row(Icons.sentiment_dissatisfied_outlined, 'Died',
                DateFormat('d MMMM yyyy').format(p.deathDate!)),
          if (p.birthPlace != null)
            _Row(Icons.place_outlined, 'Birthplace', p.birthPlace!),
          if (p.nationality != null)
            _Row(Icons.flag_outlined, 'Nationality', p.nationality!),
          if (p.occupation != null)
            _Row(Icons.work_outline, 'Occupation', p.occupation!),
          if (p.religion != null)
            _Row(Icons.church_outlined, 'Religion', p.religion!),
          if (p.education != null)
            _Row(Icons.school_outlined, 'Education', p.education!),
          if (p.phone != null)
            _Row(Icons.phone_outlined, 'Phone', p.phone!),
          if (p.email != null)
            _Row(Icons.email_outlined, 'Email', p.email!),
        ]),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Icon(icon, size: 14, color: T.textSecondary),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: T.textSecondary, fontSize: 12)),
      const Spacer(),
      Flexible(
        child: Text(value,
          textAlign: TextAlign.right,
          style: const TextStyle(color: T.textPrimary, fontSize: 12,
              fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}

// ── Relation group ─────────────────────────────────────────────────────────────
class _RelationGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> ids;
  final FamilyProvider fp;

  const _RelationGroup(this.title, this.icon, this.color, this.ids, this.fp);

  @override
  Widget build(BuildContext context) {
    final members = ids.map(fp.byId).whereType<Person>().toList();
    if (members.isEmpty) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(title,
          style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ]),
      const SizedBox(height: 6),
      ...members.map((m) => GestureDetector(
        onTap: () => fp.select(m.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: T.cardAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: T.border),
          ),
          child: Row(children: [
            PersonAvatar(person: m, radius: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(m.fullName,
                style: const TextStyle(color: T.textPrimary, fontSize: 12.5))),
            const Icon(Icons.chevron_right, size: 14, color: T.textDim),
          ]),
        ),
      )),
      const SizedBox(height: 14),
    ]);
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: T.textSecondary, fontSize: 10,
        fontWeight: FontWeight.w700, letterSpacing: 1.1));
}

// ── Pick role dialog (for "Link" new person flow) ─────────────────────────────
class _PickRoleDialog extends StatelessWidget {
  final Person source, target;
  final FamilyProvider fp;
  const _PickRoleDialog(
      {required this.source, required this.target, required this.fp});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Link ${target.firstName} to ${source.firstName}',
          style: const TextStyle(color: T.textPrimary, fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('What is their relationship?',
            style: TextStyle(color: T.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        ...['Parent', 'Child', 'Spouse', 'Sibling'].map((role) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                switch (role) {
                  case 'Parent':  await fp.linkParentChild(target.id, source.id); break;
                  case 'Child':   await fp.linkParentChild(source.id, target.id); break;
                  case 'Spouse':  await fp.linkSpouse(source.id, target.id); break;
                  case 'Sibling': await fp.linkSibling(source.id, target.id); break;
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: T.textPrimary,
                side: const BorderSide(color: T.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(role),
            ),
          ),
        )),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: T.textSecondary))),
      ],
    );
  }
}
