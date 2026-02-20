// lib/models/person.dart
import 'dart:convert';

enum Gender { male, female, other }

class Person {
  final String id;
  String firstName;
  String lastName;
  String? middleName;
  Gender gender;
  DateTime? birthDate;
  DateTime? deathDate;
  bool isAlive;
  String? birthPlace;
  String? nationality;
  String? occupation;
  String? religion;
  String? education;
  String? bio;
  String? phone;
  String? email;

  // Relationship id lists
  List<String> parentIds;
  List<String> childIds;
  List<String> spouseIds;
  List<String> siblingIds;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.gender = Gender.other,
    this.birthDate,
    this.deathDate,
    this.isAlive = true,
    this.birthPlace,
    this.nationality,
    this.occupation,
    this.religion,
    this.education,
    this.bio,
    this.phone,
    this.email,
    List<String>? parentIds,
    List<String>? childIds,
    List<String>? spouseIds,
    List<String>? siblingIds,
  })  : parentIds  = parentIds  ?? [],
        childIds   = childIds   ?? [],
        spouseIds  = spouseIds  ?? [],
        siblingIds = siblingIds ?? [];

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty  ? lastName[0]  : '';
    return '$f$l'.toUpperCase();
  }

  int? get age {
    if (birthDate == null) return null;
    final end = deathDate ?? DateTime.now();
    var a = end.year - birthDate!.year;
    if (end.month < birthDate!.month ||
        (end.month == birthDate!.month && end.day < birthDate!.day)) a--;
    return a < 0 ? 0 : a;
  }

  String get genderLabel => gender == Gender.male ? 'Male'
    : gender == Gender.female ? 'Female' : 'Other';

  Map<String, dynamic> toJson() => {
    'id': id, 'firstName': firstName, 'lastName': lastName,
    'middleName': middleName, 'gender': gender.index,
    'birthDate': birthDate?.toIso8601String(),
    'deathDate': deathDate?.toIso8601String(),
    'isAlive': isAlive, 'birthPlace': birthPlace,
    'nationality': nationality, 'occupation': occupation,
    'religion': religion, 'education': education,
    'bio': bio, 'phone': phone, 'email': email,
    'parentIds': parentIds, 'childIds': childIds,
    'spouseIds': spouseIds, 'siblingIds': siblingIds,
  };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
    id: j['id'], firstName: j['firstName'], lastName: j['lastName'],
    middleName: j['middleName'], gender: Gender.values[j['gender'] ?? 2],
    birthDate: j['birthDate'] != null ? DateTime.tryParse(j['birthDate']) : null,
    deathDate: j['deathDate'] != null ? DateTime.tryParse(j['deathDate']) : null,
    isAlive: j['isAlive'] ?? true, birthPlace: j['birthPlace'],
    nationality: j['nationality'], occupation: j['occupation'],
    religion: j['religion'], education: j['education'],
    bio: j['bio'], phone: j['phone'], email: j['email'],
    parentIds:  List<String>.from(j['parentIds']  ?? []),
    childIds:   List<String>.from(j['childIds']   ?? []),
    spouseIds:  List<String>.from(j['spouseIds']  ?? []),
    siblingIds: List<String>.from(j['siblingIds'] ?? []),
  );

  Person copyWith({
    String? firstName, String? lastName, String? middleName,
    Gender? gender, DateTime? birthDate, DateTime? deathDate, bool? isAlive,
    String? birthPlace, String? nationality, String? occupation,
    String? religion, String? education, String? bio,
    String? phone, String? email,
    List<String>? parentIds, List<String>? childIds,
    List<String>? spouseIds, List<String>? siblingIds,
  }) => Person(
    id: id,
    firstName:   firstName   ?? this.firstName,
    lastName:    lastName    ?? this.lastName,
    middleName:  middleName  ?? this.middleName,
    gender:      gender      ?? this.gender,
    birthDate:   birthDate   ?? this.birthDate,
    deathDate:   deathDate   ?? this.deathDate,
    isAlive:     isAlive     ?? this.isAlive,
    birthPlace:  birthPlace  ?? this.birthPlace,
    nationality: nationality ?? this.nationality,
    occupation:  occupation  ?? this.occupation,
    religion:    religion    ?? this.religion,
    education:   education   ?? this.education,
    bio:         bio         ?? this.bio,
    phone:       phone       ?? this.phone,
    email:       email       ?? this.email,
    parentIds:   parentIds   ?? List.from(this.parentIds),
    childIds:    childIds    ?? List.from(this.childIds),
    spouseIds:   spouseIds   ?? List.from(this.spouseIds),
    siblingIds:  siblingIds  ?? List.from(this.siblingIds),
  );
}
