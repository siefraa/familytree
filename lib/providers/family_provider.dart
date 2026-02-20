// lib/providers/family_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';

class FamilyProvider extends ChangeNotifier {
  List<Person> _persons    = [];
  String?      _selectedId;
  String       _search     = '';
  bool         _loading    = false;
  String       _ownerId    = '';

  List<Person> get persons      => _persons;
  String?      get selectedId   => _selectedId;
  String       get search       => _search;
  bool         get loading      => _loading;
  Person?      get selected     => _selectedId == null ? null : byId(_selectedId!);

  List<Person> get filtered {
    if (_search.trim().isEmpty) return _persons;
    final q = _search.toLowerCase();
    return _persons.where((p) =>
      p.fullName.toLowerCase().contains(q) ||
      (p.occupation?.toLowerCase().contains(q) ?? false) ||
      (p.birthPlace?.toLowerCase().contains(q) ?? false) ||
      (p.email?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  String get _key => 'ft2_family_$_ownerId';

  // ── Init / reset ─────────────────────────────────────────────────────────
  Future<void> init(String uid) async {
    _ownerId = uid;
    _loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    if (raw != null) {
      try {
        _persons = (jsonDecode(raw) as List).map((e) => Person.fromJson(e)).toList();
      } catch (_) { _persons = []; }
    }
    _loading = false;
    notifyListeners();
  }

  void reset() {
    _persons = []; _selectedId = null; _search = ''; _ownerId = '';
    notifyListeners();
  }

  Future<void> _save() async {
    if (_ownerId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_persons.map((p) => p.toJson()).toList()));
  }

  // ── Select / search ──────────────────────────────────────────────────────
  void select(String? id) { _selectedId = id; notifyListeners(); }
  void setSearch(String q) { _search = q; notifyListeners(); }

  // ── Lookup ───────────────────────────────────────────────────────────────
  Person? byId(String id) {
    try { return _persons.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  Future<Person> addPerson({
    required String firstName,
    required String lastName,
    String? middleName,
    Gender gender = Gender.other,
    DateTime? birthDate,
    DateTime? deathDate,
    bool isAlive = true,
    String? birthPlace,
    String? nationality,
    String? occupation,
    String? religion,
    String? education,
    String? bio,
    String? phone,
    String? email,
  }) async {
    final p = Person(
      id: const Uuid().v4(),
      firstName: firstName.trim(),
      lastName:  lastName.trim(),
      middleName: middleName?.trim().isNotEmpty == true ? middleName!.trim() : null,
      gender: gender,
      birthDate: birthDate, deathDate: deathDate, isAlive: isAlive,
      birthPlace: birthPlace?.trim().isNotEmpty == true ? birthPlace!.trim() : null,
      nationality: nationality?.trim().isNotEmpty == true ? nationality!.trim() : null,
      occupation: occupation?.trim().isNotEmpty == true ? occupation!.trim() : null,
      religion: religion?.trim().isNotEmpty == true ? religion!.trim() : null,
      education: education?.trim().isNotEmpty == true ? education!.trim() : null,
      bio: bio?.trim().isNotEmpty == true ? bio!.trim() : null,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
    );
    _persons.add(p);
    await _save();
    notifyListeners();
    return p;
  }

  Future<void> updatePerson(Person updated) async {
    final i = _persons.indexWhere((p) => p.id == updated.id);
    if (i < 0) return;
    _persons[i] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> deletePerson(String id) async {
    for (final p in _persons) {
      p.parentIds.remove(id);  p.childIds.remove(id);
      p.spouseIds.remove(id);  p.siblingIds.remove(id);
    }
    _persons.removeWhere((p) => p.id == id);
    if (_selectedId == id) _selectedId = null;
    await _save();
    notifyListeners();
  }

  // ── Relationship operations ───────────────────────────────────────────────

  // Parent ↔ Child
  Future<void> linkParentChild(String parentId, String childId) async {
    final parent = byId(parentId), child = byId(childId);
    if (parent == null || child == null) return;
    if (!parent.childIds.contains(childId))  parent.childIds.add(childId);
    if (!child.parentIds.contains(parentId)) child.parentIds.add(parentId);
    await _save(); notifyListeners();
  }

  Future<void> unlinkParentChild(String parentId, String childId) async {
    byId(parentId)?.childIds.remove(childId);
    byId(childId)?.parentIds.remove(parentId);
    await _save(); notifyListeners();
  }

  // Spouse (bidirectional)
  Future<void> linkSpouse(String a, String b) async {
    final pa = byId(a), pb = byId(b);
    if (pa == null || pb == null) return;
    if (!pa.spouseIds.contains(b)) pa.spouseIds.add(b);
    if (!pb.spouseIds.contains(a)) pb.spouseIds.add(a);
    await _save(); notifyListeners();
  }

  Future<void> unlinkSpouse(String a, String b) async {
    byId(a)?.spouseIds.remove(b);
    byId(b)?.spouseIds.remove(a);
    await _save(); notifyListeners();
  }

  // Sibling (bidirectional)
  Future<void> linkSibling(String a, String b) async {
    final pa = byId(a), pb = byId(b);
    if (pa == null || pb == null) return;
    if (!pa.siblingIds.contains(b)) pa.siblingIds.add(b);
    if (!pb.siblingIds.contains(a)) pb.siblingIds.add(a);
    await _save(); notifyListeners();
  }

  Future<void> unlinkSibling(String a, String b) async {
    byId(a)?.siblingIds.remove(b);
    byId(b)?.siblingIds.remove(a);
    await _save(); notifyListeners();
  }

  // Generic unlink — removes any relationship between two people
  Future<void> unlinkAny(String id1, String id2) async {
    byId(id1)?.parentIds.remove(id2);
    byId(id1)?.childIds.remove(id2);
    byId(id1)?.spouseIds.remove(id2);
    byId(id1)?.siblingIds.remove(id2);
    byId(id2)?.parentIds.remove(id1);
    byId(id2)?.childIds.remove(id1);
    byId(id2)?.spouseIds.remove(id1);
    byId(id2)?.siblingIds.remove(id1);
    await _save(); notifyListeners();
  }

  bool areLinked(String a, String b) {
    final pa = byId(a);
    if (pa == null) return false;
    return pa.parentIds.contains(b)  || pa.childIds.contains(b) ||
           pa.spouseIds.contains(b)  || pa.siblingIds.contains(b);
  }

  // ── Quick-add helpers ─────────────────────────────────────────────────────
  Future<Person> addAndLinkChild(String parentId, {
    required String firstName, required String lastName,
    Gender gender = Gender.other, DateTime? birthDate, String? occupation,
  }) async {
    final child = await addPerson(
      firstName: firstName, lastName: lastName,
      gender: gender, birthDate: birthDate, occupation: occupation,
    );
    await linkParentChild(parentId, child.id);
    return child;
  }

  Future<Person> addAndLinkParent(String childId, {
    required String firstName, required String lastName,
    Gender gender = Gender.other, DateTime? birthDate, String? occupation,
  }) async {
    final parent = await addPerson(
      firstName: firstName, lastName: lastName,
      gender: gender, birthDate: birthDate, occupation: occupation,
    );
    await linkParentChild(parent.id, childId);
    return parent;
  }

  Future<Person> addAndLinkSpouse(String personId, {
    required String firstName, required String lastName,
    Gender gender = Gender.other, DateTime? birthDate, String? occupation,
  }) async {
    final spouse = await addPerson(
      firstName: firstName, lastName: lastName,
      gender: gender, birthDate: birthDate, occupation: occupation,
    );
    await linkSpouse(personId, spouse.id);
    return spouse;
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get total      => _persons.length;
  int get living     => _persons.where((p) => p.isAlive).length;
  int get deceased   => _persons.where((p) => !p.isAlive).length;
  int get maleCount  => _persons.where((p) => p.gender == Gender.male).length;
  int get femaleCount=> _persons.where((p) => p.gender == Gender.female).length;

  List<Person> get roots =>
    _persons.where((p) => p.parentIds.isEmpty).toList();

  int get generations {
    if (_persons.isEmpty) return 0;
    int max = 0;
    for (final r in roots) { final d = _depth(r, 0); if (d > max) max = d; }
    return max + 1;
  }

  int _depth(Person p, int d) {
    if (p.childIds.isEmpty) return d;
    int m = d;
    for (final cid in p.childIds) {
      final c = byId(cid);
      if (c != null) { final nd = _depth(c, d+1); if (nd > m) m = nd; }
    }
    return m;
  }
}
