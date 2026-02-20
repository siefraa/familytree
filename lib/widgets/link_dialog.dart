// lib/widgets/link_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/family_provider.dart';
import '../utils/theme.dart';
import 'person_node.dart';

enum LinkMode { parent, child, spouse, sibling, unlink }

class LinkDialog extends StatefulWidget {
  final Person source;
  final LinkMode mode;
  const LinkDialog({super.key, required this.source, required this.mode});

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  String? _picked;
  String  _q = '';
  bool    _busy = false;

  static const _cfg = {
    LinkMode.parent:  ('Link as Parent',  Icons.supervisor_account_rounded, T.gold),
    LinkMode.child:   ('Link as Child',   Icons.child_care_rounded,         T.teal),
    LinkMode.spouse:  ('Link as Spouse',  Icons.favorite_rounded,           T.rose),
    LinkMode.sibling: ('Link as Sibling', Icons.people_rounded,             T.amber),
    LinkMode.unlink:  ('Unlink Person',   Icons.link_off_rounded,           T.error),
  };

  (String, IconData, Color) get _info => _cfg[widget.mode]!;

  List<Person> _candidates(FamilyProvider fp) {
    final src = widget.source;
    final q   = _q.toLowerCase();

    List<Person> pool;
    if (widget.mode == LinkMode.unlink) {
      pool = fp.persons.where((p) =>
        p.id != src.id && fp.areLinked(src.id, p.id)
      ).toList();
    } else {
      final linked = {
        ...src.parentIds, ...src.childIds,
        ...src.spouseIds, ...src.siblingIds,
      };
      pool = fp.persons.where((p) => p.id != src.id && !linked.contains(p.id)).toList();
    }

    if (q.isNotEmpty) {
      pool = pool.where((p) => p.fullName.toLowerCase().contains(q)).toList();
    }
    return pool;
  }

  Future<void> _confirm(FamilyProvider fp) async {
    if (_picked == null) return;
    setState(() => _busy = true);
    final sid = widget.source.id;

    switch (widget.mode) {
      case LinkMode.parent:   await fp.linkParentChild(_picked!, sid); break;
      case LinkMode.child:    await fp.linkParentChild(sid, _picked!); break;
      case LinkMode.spouse:   await fp.linkSpouse(sid, _picked!);      break;
      case LinkMode.sibling:  await fp.linkSibling(sid, _picked!);     break;
      case LinkMode.unlink:   await fp.unlinkAny(sid, _picked!);       break;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final fp   = context.watch<FamilyProvider>();
    final info = _info;
    final list = _candidates(fp);

    return Dialog(
      backgroundColor: T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: info.$3.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(bottom: BorderSide(color: T.border)),
              ),
              child: Row(children: [
                Icon(info.$2, color: info.$3, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(info.$1,
                        style: TextStyle(color: info.$3, fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('for ${widget.source.fullName}',
                        style: const TextStyle(color: T.textSecondary, fontSize: 12)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: T.textSecondary, size: 20),
                ),
              ]),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                style: const TextStyle(color: T.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search members…',
                  prefixIcon: Icon(Icons.search, size: 18, color: T.textSecondary),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ),

            // List
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline, color: T.textDim, size: 42),
                        const SizedBox(height: 10),
                        Text(
                          widget.mode == LinkMode.unlink
                              ? 'No connections to unlink'
                              : 'No eligible members found',
                          style: const TextStyle(color: T.textSecondary, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p   = list[i];
                        final sel = p.id == _picked;
                        return GestureDetector(
                          onTap: () => setState(() => _picked = sel ? null : p.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? info.$3.withOpacity(0.1) : T.cardAlt,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: sel ? info.$3 : T.border,
                                width: sel ? 1.6 : 1,
                              ),
                            ),
                            child: Row(children: [
                              PersonAvatar(person: p, radius: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.fullName,
                                        style: const TextStyle(color: T.textPrimary,
                                            fontSize: 13, fontWeight: FontWeight.w600)),
                                    if (p.age != null || p.occupation != null)
                                      Text(
                                        [if (p.age != null) '${p.age} yrs',
                                          if (p.occupation != null) p.occupation!]
                                            .join(' · '),
                                        style: const TextStyle(color: T.textSecondary, fontSize: 11)),
                                  ]),
                              ),
                              if (sel)
                                Icon(Icons.check_circle_rounded, color: info.$3, size: 22),
                            ]),
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: T.border))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: T.border),
                      foregroundColor: T.textSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (_picked == null || _busy) ? null : () => _confirm(fp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: info.$3.withOpacity(0.85),
                      disabledBackgroundColor: T.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: _busy
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(info.$2, size: 16),
                    label: Text(info.$1),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
