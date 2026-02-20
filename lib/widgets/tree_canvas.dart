// lib/widgets/tree_canvas.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/person.dart';
import '../providers/family_provider.dart';
import '../utils/theme.dart';
import 'person_node.dart';

// ── Layout constants ─────────────────────────────────────────────────────────
const double kNodeW   = 152;
const double kNodeH   = 88;
const double kColGap  = 64;   // horizontal gap between generations
const double kRowGap  = 28;   // vertical gap between siblings
const double kPadX    = 60;
const double kPadY    = 60;

class TreeCanvas extends StatefulWidget {
  final FamilyProvider fp;
  const TreeCanvas({super.key, required this.fp});

  @override State<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> {
  final TransformationController _ctrl = TransformationController();

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  // ── BFS layout (left = root, right = children) ─────────────────────────────
  Map<String, Offset> _layout() {
    final fp   = widget.fp;
    final all  = fp.persons;
    if (all.isEmpty) return {};

    // Assign generation depth via BFS from roots
    final depthMap = <String, int>{};
    final queue    = <String>[];

    for (final r in fp.roots.isEmpty ? [all.first] : fp.roots) {
      if (!depthMap.containsKey(r.id)) { depthMap[r.id] = 0; queue.add(r.id); }
    }
    // Include any unvisited (disconnected) at depth 0
    for (final p in all) { if (!depthMap.containsKey(p.id)) { depthMap[p.id] = 0; queue.add(p.id); } }

    while (queue.isNotEmpty) {
      final id    = queue.removeAt(0);
      final p     = fp.byId(id);
      if (p == null) continue;
      final depth = depthMap[id]!;
      for (final cid in p.childIds) {
        if (!depthMap.containsKey(cid) || depthMap[cid]! < depth + 1) {
          depthMap[cid] = depth + 1;
          queue.add(cid);
        }
      }
    }

    // Group by depth column
    final byDepth = <int, List<String>>{};
    for (final e in depthMap.entries) {
      byDepth.putIfAbsent(e.value, () => []).add(e.key);
    }

    // Assign x,y positions
    final pos = <String, Offset>{};
    final depths = byDepth.keys.toList()..sort();
    for (final depth in depths) {
      final ids = byDepth[depth]!;
      final x   = kPadX + depth * (kNodeW + kColGap);
      for (var i = 0; i < ids.length; i++) {
        final y = kPadY + i * (kNodeH + kRowGap);
        pos[ids[i]] = Offset(x, y);
      }
    }
    return pos;
  }

  Size _canvasSize(Map<String, Offset> pos) {
    if (pos.isEmpty) return const Size(900, 600);
    double mxX = 0, mxY = 0;
    for (final o in pos.values) {
      if (o.dx > mxX) mxX = o.dx;
      if (o.dy > mxY) mxY = o.dy;
    }
    return Size(mxX + kNodeW + kPadX, mxY + kNodeH + kPadY);
  }

  @override
  Widget build(BuildContext context) {
    final pos  = _layout();
    final size = _canvasSize(pos);
    final fp   = widget.fp;

    return InteractiveViewer(
      transformationController: _ctrl,
      minScale: 0.25,
      maxScale: 2.5,
      constrained: false,
      child: SizedBox(
        width:  size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Connection lines
            Positioned.fill(
              child: CustomPaint(
                painter: _ConnPainter(persons: fp.persons, pos: pos),
              ),
            ),
            // Nodes
            for (final p in fp.persons)
              if (pos.containsKey(p.id))
                Positioned(
                  left: pos[p.id]!.dx,
                  top:  pos[p.id]!.dy,
                  child: PersonNode(
                    person: p,
                    selected: fp.selectedId == p.id,
                    onTap: () => fp.select(fp.selectedId == p.id ? null : p.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ── Connection painter ─────────────────────────────────────────────────────────
class _ConnPainter extends CustomPainter {
  final List<Person> persons;
  final Map<String, Offset> pos;

  _ConnPainter({required this.persons, required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    // Parent → child: blue solid curve
    final parentPaint = Paint()
      ..color = T.maleColor.withOpacity(0.4)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Spouse: rose dashed
    final spousePaint = Paint()
      ..color = T.femaleColor.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Sibling: teal dashed
    final sibPaint = Paint()
      ..color = T.teal.withOpacity(0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final drawn = <String>{};

    for (final p in persons) {
      final fp = pos[p.id];
      if (fp == null) continue;

      // Parent → child (horizontal: right edge → left edge)
      for (final cid in p.childIds) {
        final tp = pos[cid];
        if (tp == null) continue;
        final key = '${p.id}→$cid';
        if (drawn.contains(key)) continue;
        drawn.add(key);

        final from = fp + Offset(kNodeW, kNodeH / 2);
        final to   = tp + Offset(0, kNodeH / 2);
        _bezier(canvas, from, to, parentPaint, horizontal: true);
        _arrowHead(canvas, to, const Offset(-1, 0), parentPaint);
      }

      // Spouse: bottom edge → top edge of spouse (if same depth, draw vertically)
      for (final sid in p.spouseIds) {
        final tp = pos[sid];
        if (tp == null) continue;
        final key = [p.id, sid]..sort();
        final keyStr = key.join('↔');
        if (drawn.contains(keyStr)) continue;
        drawn.add(keyStr);
        final from = fp + Offset(kNodeW / 2, kNodeH);
        final to   = tp + Offset(kNodeW / 2, 0);
        _dashed(canvas, from, to, spousePaint);
        // Heart midpoint
        final mid = (from + to) / 2;
        _drawHeart(canvas, mid);
      }

      // Siblings
      for (final bid in p.siblingIds) {
        final tp = pos[bid];
        if (tp == null) continue;
        final key = [p.id, bid]..sort();
        final keyStr = key.join('~');
        if (drawn.contains(keyStr)) continue;
        drawn.add(keyStr);
        final from = fp + Offset(0, kNodeH / 2);
        final to   = tp + Offset(0, kNodeH / 2);
        _dashed(canvas, from, to, sibPaint);
      }
    }
  }

  void _bezier(Canvas canvas, Offset from, Offset to, Paint paint, {bool horizontal = true}) {
    final path = Path();
    path.moveTo(from.dx, from.dy);
    if (horizontal) {
      final mx = (from.dx + to.dx) / 2;
      path.cubicTo(mx, from.dy, mx, to.dy, to.dx, to.dy);
    } else {
      final my = (from.dy + to.dy) / 2;
      path.cubicTo(from.dx, my, to.dx, my, to.dx, to.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _arrowHead(Canvas canvas, Offset tip, Offset dir, Paint paint) {
    const len = 7.0;
    final perp = Offset(-dir.dy, dir.dx);
    final p = Paint()..color = paint.color..strokeWidth = 1.4..style = PaintingStyle.stroke;
    canvas.drawLine(tip, tip - dir * len + perp * 4, p);
    canvas.drawLine(tip, tip - dir * len - perp * 4, p);
  }

  void _dashed(Canvas canvas, Offset from, Offset to, Paint paint,
      {double dash = 6, double gap = 4}) {
    final d   = to - from;
    final len = d.distance;
    if (len == 0) return;
    final dir = d / len;
    double p  = 0;
    while (p < len) {
      final end = (p + dash).clamp(0.0, len);
      canvas.drawLine(from + dir * p, from + dir * end, paint);
      p += dash + gap;
    }
  }

  void _drawHeart(Canvas canvas, Offset center) {
    final tp = TextPainter(
      text: const TextSpan(text: '♥', style: TextStyle(color: Color(0x55FF6B8A), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override bool shouldRepaint(covariant CustomPainter _) => true;
}
