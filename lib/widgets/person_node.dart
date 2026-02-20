// lib/widgets/person_node.dart
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../utils/theme.dart';

// ── Avatar ─────────────────────────────────────────────────────────────────────
class PersonAvatar extends StatelessWidget {
  final Person person;
  final double radius;
  final bool selected;
  const PersonAvatar({super.key, required this.person, this.radius = 22, this.selected = false});

  Color get _color => person.gender == Gender.male ? T.maleColor
    : person.gender == Gender.female ? T.femaleColor : T.neutralColor;

  Color get _bg => person.gender == Gender.male
    ? const Color(0xFF0F2040)
    : person.gender == Gender.female
      ? const Color(0xFF2A0F20)
      : const Color(0xFF1A1F2E);

  @override
  Widget build(BuildContext context) => Container(
    width: radius * 2, height: radius * 2,
    decoration: BoxDecoration(
      color: _bg,
      shape: BoxShape.circle,
      border: Border.all(color: selected ? T.primary : _color.withOpacity(0.6),
        width: selected ? 2.2 : 1.4),
      boxShadow: selected ? [BoxShadow(color: T.primary.withOpacity(0.4), blurRadius: 10)] : null,
    ),
    child: Center(
      child: Text(person.initials,
        style: TextStyle(color: _color, fontSize: radius * 0.52, fontWeight: FontWeight.w800)),
    ),
  );
}

// ── Tree node card ─────────────────────────────────────────────────────────────
class PersonNode extends StatefulWidget {
  final Person person;
  final bool selected;
  final VoidCallback onTap;
  const PersonNode({super.key, required this.person, required this.selected, required this.onTap});

  @override State<PersonNode> createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double>   _sc;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _sc = Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override void dispose() { _ac.dispose(); super.dispose(); }

  Color get _borderColor {
    if (widget.selected) return T.primary;
    final p = widget.person;
    return p.gender == Gender.male ? T.maleColor
      : p.gender == Gender.female ? T.femaleColor : T.border;
  }

  Color get _bgColor {
    if (widget.selected) return T.primaryGlow;
    final p = widget.person;
    return p.gender == Gender.male ? const Color(0xFF0D1B33)
      : p.gender == Gender.female ? const Color(0xFF25101E)
      : T.card;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return MouseRegion(
      onEnter: (_) { setState(() => _hovered = true);  _ac.forward(); },
      onExit:  (_) { setState(() => _hovered = false); _ac.reverse(); },
      child: ScaleTransition(
        scale: _sc,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 152, height: 88,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor, width: widget.selected ? 2.2 : 1.3),
              boxShadow: widget.selected
                ? [BoxShadow(color: T.primary.withOpacity(0.45), blurRadius: 20, spreadRadius: 1)]
                : _hovered
                  ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                PersonAvatar(person: p, radius: 24, selected: widget.selected),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.firstName,
                        style: TextStyle(
                          color: widget.selected ? T.textPrimary : T.textPrimary,
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                      Text(p.lastName,
                        style: TextStyle(
                          color: _borderColor.withOpacity(0.8),
                          fontSize: 11.5),
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        if (p.age != null) _chip('${p.age}y'),
                        if (p.occupation != null) _chip(p.occupation!),
                      ]),
                    ],
                  ),
                ),
                // Deceased indicator
                if (!p.isAlive)
                  const Icon(Icons.close, size: 10, color: T.textDim),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: T.border.withOpacity(0.5),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(t, style: const TextStyle(color: T.textSecondary, fontSize: 8.5),
      overflow: TextOverflow.ellipsis),
  );
}
