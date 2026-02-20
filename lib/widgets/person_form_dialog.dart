// lib/widgets/person_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/family_provider.dart';
import '../utils/theme.dart';

class PersonFormDialog extends StatefulWidget {
  final Person? existing;
  const PersonFormDialog({super.key, this.existing});

  @override
  State<PersonFormDialog> createState() => _PersonFormDialogState();
}

class _PersonFormDialogState extends State<PersonFormDialog>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  late TabController _tabs;

  // Controllers
  late final TextEditingController
      _first, _last, _middle, _place, _nation, _occ, _religion, _edu, _bio, _phone, _emailCtrl;

  late Gender _gender;
  late bool _alive;
  DateTime? _birth, _death;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final p = widget.existing;
    _first     = TextEditingController(text: p?.firstName   ?? '');
    _last      = TextEditingController(text: p?.lastName    ?? '');
    _middle    = TextEditingController(text: p?.middleName  ?? '');
    _place     = TextEditingController(text: p?.birthPlace  ?? '');
    _nation    = TextEditingController(text: p?.nationality ?? '');
    _occ       = TextEditingController(text: p?.occupation  ?? '');
    _religion  = TextEditingController(text: p?.religion    ?? '');
    _edu       = TextEditingController(text: p?.education   ?? '');
    _bio       = TextEditingController(text: p?.bio         ?? '');
    _phone     = TextEditingController(text: p?.phone       ?? '');
    _emailCtrl = TextEditingController(text: p?.email       ?? '');
    _gender    = p?.gender  ?? Gender.other;
    _alive     = p?.isAlive ?? true;
    _birth     = p?.birthDate;
    _death     = p?.deathDate;
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_first, _last, _middle, _place, _nation, _occ, _religion, _edu, _bio, _phone, _emailCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isBirth}) async {
    final initial = isBirth ? (_birth ?? DateTime(1970)) : (_death ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: T.primary, surface: T.card),
          dialogBackgroundColor: T.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isBirth ? _birth = picked : _death = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      _tabs.animateTo(0);
      return;
    }
    setState(() => _saving = true);
    final fp = context.read<FamilyProvider>();

    if (widget.existing == null) {
      await fp.addPerson(
        firstName:   _first.text,
        lastName:    _last.text,
        middleName:  _middle.text,
        gender:      _gender,
        birthDate:   _birth,
        deathDate:   _death,
        isAlive:     _alive,
        birthPlace:  _place.text,
        nationality: _nation.text,
        occupation:  _occ.text,
        religion:    _religion.text,
        education:   _edu.text,
        bio:         _bio.text,
        phone:       _phone.text,
        email:       _emailCtrl.text,
      );
    } else {
      final updated = widget.existing!.copyWith(
        firstName:   _first.text,
        lastName:    _last.text,
        middleName:  _middle.text,
        gender:      _gender,
        birthDate:   _birth,
        deathDate:   _death,
        isAlive:     _alive,
        birthPlace:  _place.text,
        nationality: _nation.text,
        occupation:  _occ.text,
        religion:    _religion.text,
        education:   _edu.text,
        bio:         _bio.text,
        phone:       _phone.text,
        email:       _emailCtrl.text,
      );
      await fp.updatePerson(updated);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final title  = isEdit ? 'Edit Person' : 'Add Person';

    return Dialog(
      backgroundColor: T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            _Header(title: title, isEdit: isEdit, onClose: () => Navigator.pop(context)),

            // ── Tabs ───────────────────────────────────────────────────────
            Container(
              color: T.card,
              child: TabBar(
                controller: _tabs,
                indicatorColor: T.primary,
                indicatorWeight: 2,
                labelColor: T.primary,
                unselectedLabelColor: T.textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'BASIC INFO'),
                  Tab(text: 'DETAILS'),
                  Tab(text: 'CONTACT'),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _form,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _BasicTab(
                      first: _first, last: _last, middle: _middle,
                      gender: _gender,
                      alive: _alive,
                      birth: _birth,
                      death: _death,
                      onGender: (g) => setState(() => _gender = g),
                      onAliveTap: () => setState(() {
                        _alive = !_alive;
                        if (_alive) _death = null;
                      }),
                      onPickBirth: () => _pickDate(isBirth: true),
                      onPickDeath: () => _pickDate(isBirth: false),
                      onClearBirth: () => setState(() => _birth = null),
                      onClearDeath: () => setState(() => _death = null),
                    ),
                    _DetailsTab(
                      place: _place, nation: _nation,
                      occ: _occ, religion: _religion,
                      edu: _edu, bio: _bio,
                    ),
                    _ContactTab(phone: _phone, email: _emailCtrl),
                  ],
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            _Footer(
              saving: _saving,
              isEdit: isEdit,
              onCancel: () => Navigator.pop(context),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final bool isEdit;
  final VoidCallback onClose;
  const _Header({required this.title, required this.isEdit, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [T.primary.withOpacity(0.18), T.secondary.withOpacity(0.08)],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      border: const Border(bottom: BorderSide(color: T.border)),
    ),
    child: Row(
      children: [
        Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
            color: T.primary, size: 20),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: T.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: const Icon(Icons.close, color: T.textSecondary, size: 20),
        ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  final bool saving, isEdit;
  final VoidCallback onCancel, onSave;
  const _Footer(
      {required this.saving, required this.isEdit, required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: T.border)),
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: T.textSecondary,
              side: const BorderSide(color: T.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
            label: Text(isEdit ? 'Save Changes' : 'Add Person'),
          ),
        ),
      ],
    ),
  );
}

// ── Tab 1: Basic Info ─────────────────────────────────────────────────────────
class _BasicTab extends StatelessWidget {
  final TextEditingController first, last, middle;
  final Gender gender;
  final bool alive;
  final DateTime? birth, death;
  final ValueChanged<Gender> onGender;
  final VoidCallback onAliveTap, onPickBirth, onPickDeath, onClearBirth, onClearDeath;

  const _BasicTab({
    required this.first, required this.last, required this.middle,
    required this.gender, required this.alive,
    required this.birth, required this.death,
    required this.onGender, required this.onAliveTap,
    required this.onPickBirth, required this.onPickDeath,
    required this.onClearBirth, required this.onClearDeath,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Gender selector
      _sec('Gender'),
      Row(
        children: Gender.values.map((g) {
          final sel    = gender == g;
          final labels = ['Male', 'Female', 'Other'];
          final icons  = [Icons.male_rounded, Icons.female_rounded, Icons.person_outline_rounded];
          final colors = [T.maleColor, T.femaleColor, T.neutralColor];
          return Expanded(
            child: GestureDetector(
              onTap: () => onGender(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: g != Gender.other ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? colors[g.index].withOpacity(0.14) : T.cardAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? colors[g.index] : T.border,
                    width: sel ? 1.8 : 1,
                  ),
                ),
                child: Column(children: [
                  Icon(icons[g.index],
                      color: sel ? colors[g.index] : T.textDim, size: 22),
                  const SizedBox(height: 4),
                  Text(labels[g.index],
                      style: TextStyle(
                        color: sel ? colors[g.index] : T.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Names
      _sec('Name'),
      Row(children: [
        Expanded(child: _field(first, 'First name *', required: true)),
        const SizedBox(width: 10),
        Expanded(child: _field(middle, 'Middle name')),
      ]),
      const SizedBox(height: 10),
      _field(last, 'Last name *', required: true),
      const SizedBox(height: 20),

      // Dates
      _sec('Life Dates'),
      Row(children: [
        Expanded(child: _DatePickerField(
          label: 'Birth Date',
          date: birth,
          onTap: onPickBirth,
          onClear: onClearBirth,
        )),
        const SizedBox(width: 10),
        Expanded(child: _DatePickerField(
          label: 'Death Date',
          date: death,
          onTap: onPickDeath,
          onClear: onClearDeath,
          enabled: !alive,
        )),
      ]),
      const SizedBox(height: 12),

      // Still living toggle
      GestureDetector(
        onTap: onAliveTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: alive ? T.success.withOpacity(0.07) : T.cardAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: alive ? T.success.withOpacity(0.35) : T.border),
          ),
          child: Row(children: [
            _Toggle(value: alive),
            const SizedBox(width: 12),
            Text(alive ? 'Currently living' : 'Deceased',
                style: TextStyle(
                  color: alive ? T.success : T.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(alive ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                color: alive ? T.success : T.textDim, size: 18),
          ]),
        ),
      ),
    ]),
  );
}

// ── Tab 2: Details ────────────────────────────────────────────────────────────
class _DetailsTab extends StatelessWidget {
  final TextEditingController place, nation, occ, religion, edu, bio;
  const _DetailsTab({
    required this.place, required this.nation, required this.occ,
    required this.religion, required this.edu, required this.bio,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sec('Location & Origin'),
      _field(place,  'Birth place',  icon: Icons.place_outlined),
      const SizedBox(height: 10),
      _field(nation, 'Nationality', icon: Icons.flag_outlined),
      const SizedBox(height: 20),
      _sec('Background'),
      _field(occ,      'Occupation',  icon: Icons.work_outline_rounded),
      const SizedBox(height: 10),
      _field(religion, 'Religion',    icon: Icons.church_outlined),
      const SizedBox(height: 10),
      _field(edu,      'Education',   icon: Icons.school_outlined),
      const SizedBox(height: 20),
      _sec('Biography'),
      TextFormField(
        controller: bio,
        maxLines: 4,
        style: const TextStyle(color: T.textPrimary, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Write a short biography…',
          alignLabelWithHint: true,
        ),
      ),
    ]),
  );
}

// ── Tab 3: Contact ────────────────────────────────────────────────────────────
class _ContactTab extends StatelessWidget {
  final TextEditingController phone, email;
  const _ContactTab({required this.phone, required this.email});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sec('Contact Information'),
      _field(phone, 'Phone number', icon: Icons.phone_outlined,
          keyboard: TextInputType.phone),
      const SizedBox(height: 10),
      _field(email, 'Email address', icon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: T.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: T.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: T.primary, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Contact details are stored locally on your device and never shared.',
              style: TextStyle(color: T.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ]),
      ),
    ]),
  );
}

// ── Shared helpers ────────────────────────────────────────────────────────────
Widget _sec(String label) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(label,
    style: const TextStyle(color: T.textSecondary, fontSize: 10.5,
        fontWeight: FontWeight.w700, letterSpacing: 0.9)),
);

Widget _field(TextEditingController ctrl, String hint, {
  bool required = false,
  IconData? icon,
  TextInputType? keyboard,
}) =>
    TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: T.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 17, color: T.textSecondary)
            : null,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? '${hint.replaceAll(' *', '')} is required'
              : null
          : null,
    );

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap, onClear;
  final bool enabled;

  const _DatePickerField({
    required this.label, required this.date,
    required this.onTap, required this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = date != null ? DateFormat('d MMM yyyy').format(date!) : null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? T.cardAlt : T.cardAlt.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? T.primary.withOpacity(0.5) : T.border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 15,
              color: enabled ? T.textSecondary : T.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(fmt ?? label,
                style: TextStyle(
                  color: fmt != null ? T.textPrimary : T.textDim,
                  fontSize: 13)),
          ),
          if (date != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 14, color: T.textSecondary),
            ),
        ]),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  const _Toggle({required this.value});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 40, height: 22,
    decoration: BoxDecoration(
      color: value ? T.success.withOpacity(0.25) : T.cardAlt,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: value ? T.success : T.border),
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(3),
        width: 16, height: 16,
        decoration: BoxDecoration(
          color: value ? T.success : T.textDim,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
