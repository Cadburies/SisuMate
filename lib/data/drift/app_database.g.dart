// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GuestProfilesTable extends GuestProfiles
    with TableInfo<$GuestProfilesTable, GuestProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuestProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _allergenRestrictionsMeta =
      const VerificationMeta('allergenRestrictions');
  @override
  late final GeneratedColumn<String> allergenRestrictions =
      GeneratedColumn<String>(
        'allergen_restrictions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _dietaryRequirementsMeta =
      const VerificationMeta('dietaryRequirements');
  @override
  late final GeneratedColumn<String> dietaryRequirements =
      GeneratedColumn<String>(
        'dietary_requirements',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    allergenRestrictions,
    dietaryRequirements,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guest_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<GuestProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('allergen_restrictions')) {
      context.handle(
        _allergenRestrictionsMeta,
        allergenRestrictions.isAcceptableOrUnknown(
          data['allergen_restrictions']!,
          _allergenRestrictionsMeta,
        ),
      );
    }
    if (data.containsKey('dietary_requirements')) {
      context.handle(
        _dietaryRequirementsMeta,
        dietaryRequirements.isAcceptableOrUnknown(
          data['dietary_requirements']!,
          _dietaryRequirementsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuestProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuestProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      allergenRestrictions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergen_restrictions'],
      )!,
      dietaryRequirements: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dietary_requirements'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GuestProfilesTable createAlias(String alias) {
    return $GuestProfilesTable(attachedDatabase, alias);
  }
}

class GuestProfileRow extends DataClass implements Insertable<GuestProfileRow> {
  final int id;
  final String name;
  final String allergenRestrictions;
  final String dietaryRequirements;
  final DateTime createdAt;
  const GuestProfileRow({
    required this.id,
    required this.name,
    required this.allergenRestrictions,
    required this.dietaryRequirements,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['allergen_restrictions'] = Variable<String>(allergenRestrictions);
    map['dietary_requirements'] = Variable<String>(dietaryRequirements);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GuestProfilesCompanion toCompanion(bool nullToAbsent) {
    return GuestProfilesCompanion(
      id: Value(id),
      name: Value(name),
      allergenRestrictions: Value(allergenRestrictions),
      dietaryRequirements: Value(dietaryRequirements),
      createdAt: Value(createdAt),
    );
  }

  factory GuestProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuestProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      allergenRestrictions: serializer.fromJson<String>(
        json['allergenRestrictions'],
      ),
      dietaryRequirements: serializer.fromJson<String>(
        json['dietaryRequirements'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'allergenRestrictions': serializer.toJson<String>(allergenRestrictions),
      'dietaryRequirements': serializer.toJson<String>(dietaryRequirements),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GuestProfileRow copyWith({
    int? id,
    String? name,
    String? allergenRestrictions,
    String? dietaryRequirements,
    DateTime? createdAt,
  }) => GuestProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    allergenRestrictions: allergenRestrictions ?? this.allergenRestrictions,
    dietaryRequirements: dietaryRequirements ?? this.dietaryRequirements,
    createdAt: createdAt ?? this.createdAt,
  );
  GuestProfileRow copyWithCompanion(GuestProfilesCompanion data) {
    return GuestProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      allergenRestrictions: data.allergenRestrictions.present
          ? data.allergenRestrictions.value
          : this.allergenRestrictions,
      dietaryRequirements: data.dietaryRequirements.present
          ? data.dietaryRequirements.value
          : this.dietaryRequirements,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuestProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('allergenRestrictions: $allergenRestrictions, ')
          ..write('dietaryRequirements: $dietaryRequirements, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    allergenRestrictions,
    dietaryRequirements,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuestProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.allergenRestrictions == this.allergenRestrictions &&
          other.dietaryRequirements == this.dietaryRequirements &&
          other.createdAt == this.createdAt);
}

class GuestProfilesCompanion extends UpdateCompanion<GuestProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> allergenRestrictions;
  final Value<String> dietaryRequirements;
  final Value<DateTime> createdAt;
  const GuestProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.allergenRestrictions = const Value.absent(),
    this.dietaryRequirements = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GuestProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.allergenRestrictions = const Value.absent(),
    this.dietaryRequirements = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<GuestProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? allergenRestrictions,
    Expression<String>? dietaryRequirements,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (allergenRestrictions != null)
        'allergen_restrictions': allergenRestrictions,
      if (dietaryRequirements != null)
        'dietary_requirements': dietaryRequirements,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GuestProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? allergenRestrictions,
    Value<String>? dietaryRequirements,
    Value<DateTime>? createdAt,
  }) {
    return GuestProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      allergenRestrictions: allergenRestrictions ?? this.allergenRestrictions,
      dietaryRequirements: dietaryRequirements ?? this.dietaryRequirements,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (allergenRestrictions.present) {
      map['allergen_restrictions'] = Variable<String>(
        allergenRestrictions.value,
      );
    }
    if (dietaryRequirements.present) {
      map['dietary_requirements'] = Variable<String>(dietaryRequirements.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuestProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('allergenRestrictions: $allergenRestrictions, ')
          ..write('dietaryRequirements: $dietaryRequirements, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RecipeCollectionsTable extends RecipeCollections
    with TableInfo<$RecipeCollectionsTable, RecipeCollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recipeSupabaseIdsMeta = const VerificationMeta(
    'recipeSupabaseIds',
  );
  @override
  late final GeneratedColumn<String> recipeSupabaseIds =
      GeneratedColumn<String>(
        'recipe_supabase_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    recipeSupabaseIds,
    createdAt,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeCollectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('recipe_supabase_ids')) {
      context.handle(
        _recipeSupabaseIdsMeta,
        recipeSupabaseIds.isAcceptableOrUnknown(
          data['recipe_supabase_ids']!,
          _recipeSupabaseIdsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeCollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeCollectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      recipeSupabaseIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_supabase_ids'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $RecipeCollectionsTable createAlias(String alias) {
    return $RecipeCollectionsTable(attachedDatabase, alias);
  }
}

class RecipeCollectionRow extends DataClass
    implements Insertable<RecipeCollectionRow> {
  final int id;
  final String name;
  final String recipeSupabaseIds;
  final DateTime createdAt;
  final DateTime lastModified;
  const RecipeCollectionRow({
    required this.id,
    required this.name,
    required this.recipeSupabaseIds,
    required this.createdAt,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['recipe_supabase_ids'] = Variable<String>(recipeSupabaseIds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  RecipeCollectionsCompanion toCompanion(bool nullToAbsent) {
    return RecipeCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      recipeSupabaseIds: Value(recipeSupabaseIds),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory RecipeCollectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeCollectionRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      recipeSupabaseIds: serializer.fromJson<String>(json['recipeSupabaseIds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'recipeSupabaseIds': serializer.toJson<String>(recipeSupabaseIds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  RecipeCollectionRow copyWith({
    int? id,
    String? name,
    String? recipeSupabaseIds,
    DateTime? createdAt,
    DateTime? lastModified,
  }) => RecipeCollectionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    recipeSupabaseIds: recipeSupabaseIds ?? this.recipeSupabaseIds,
    createdAt: createdAt ?? this.createdAt,
    lastModified: lastModified ?? this.lastModified,
  );
  RecipeCollectionRow copyWithCompanion(RecipeCollectionsCompanion data) {
    return RecipeCollectionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      recipeSupabaseIds: data.recipeSupabaseIds.present
          ? data.recipeSupabaseIds.value
          : this.recipeSupabaseIds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeCollectionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('recipeSupabaseIds: $recipeSupabaseIds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, recipeSupabaseIds, createdAt, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeCollectionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.recipeSupabaseIds == this.recipeSupabaseIds &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class RecipeCollectionsCompanion extends UpdateCompanion<RecipeCollectionRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> recipeSupabaseIds;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  const RecipeCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.recipeSupabaseIds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  RecipeCollectionsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.recipeSupabaseIds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<RecipeCollectionRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? recipeSupabaseIds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (recipeSupabaseIds != null) 'recipe_supabase_ids': recipeSupabaseIds,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  RecipeCollectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? recipeSupabaseIds,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModified,
  }) {
    return RecipeCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      recipeSupabaseIds: recipeSupabaseIds ?? this.recipeSupabaseIds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (recipeSupabaseIds.present) {
      map['recipe_supabase_ids'] = Variable<String>(recipeSupabaseIds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('recipeSupabaseIds: $recipeSupabaseIds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $CrewMembersTable extends CrewMembers
    with TableInfo<$CrewMembersTable, CrewMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrewMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Crew'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iceContactMeta = const VerificationMeta(
    'iceContact',
  );
  @override
  late final GeneratedColumn<String> iceContact = GeneratedColumn<String>(
    'ice_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificationsMeta = const VerificationMeta(
    'certifications',
  );
  @override
  late final GeneratedColumn<String> certifications = GeneratedColumn<String>(
    'certifications',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    name,
    role,
    phone,
    email,
    iceContact,
    certifications,
    localPath,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crew_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<CrewMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('ice_contact')) {
      context.handle(
        _iceContactMeta,
        iceContact.isAcceptableOrUnknown(data['ice_contact']!, _iceContactMeta),
      );
    }
    if (data.containsKey('certifications')) {
      context.handle(
        _certificationsMeta,
        certifications.isAcceptableOrUnknown(
          data['certifications']!,
          _certificationsMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CrewMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CrewMemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      iceContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ice_contact'],
      ),
      certifications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certifications'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $CrewMembersTable createAlias(String alias) {
    return $CrewMembersTable(attachedDatabase, alias);
  }
}

class CrewMemberRow extends DataClass implements Insertable<CrewMemberRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String name;
  final String role;
  final String? phone;
  final String? email;
  final String? iceContact;
  final String? certifications;
  final String? localPath;
  final bool isSynced;
  final DateTime lastModified;
  const CrewMemberRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.iceContact,
    this.certifications,
    this.localPath,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || iceContact != null) {
      map['ice_contact'] = Variable<String>(iceContact);
    }
    if (!nullToAbsent || certifications != null) {
      map['certifications'] = Variable<String>(certifications);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  CrewMembersCompanion toCompanion(bool nullToAbsent) {
    return CrewMembersCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      name: Value(name),
      role: Value(role),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      iceContact: iceContact == null && nullToAbsent
          ? const Value.absent()
          : Value(iceContact),
      certifications: certifications == null && nullToAbsent
          ? const Value.absent()
          : Value(certifications),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory CrewMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CrewMemberRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      iceContact: serializer.fromJson<String?>(json['iceContact']),
      certifications: serializer.fromJson<String?>(json['certifications']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'iceContact': serializer.toJson<String?>(iceContact),
      'certifications': serializer.toJson<String?>(certifications),
      'localPath': serializer.toJson<String?>(localPath),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  CrewMemberRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? name,
    String? role,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> iceContact = const Value.absent(),
    Value<String?> certifications = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    bool? isSynced,
    DateTime? lastModified,
  }) => CrewMemberRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    name: name ?? this.name,
    role: role ?? this.role,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    iceContact: iceContact.present ? iceContact.value : this.iceContact,
    certifications: certifications.present
        ? certifications.value
        : this.certifications,
    localPath: localPath.present ? localPath.value : this.localPath,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  CrewMemberRow copyWithCompanion(CrewMembersCompanion data) {
    return CrewMemberRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      iceContact: data.iceContact.present
          ? data.iceContact.value
          : this.iceContact,
      certifications: data.certifications.present
          ? data.certifications.value
          : this.certifications,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CrewMemberRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('iceContact: $iceContact, ')
          ..write('certifications: $certifications, ')
          ..write('localPath: $localPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    name,
    role,
    phone,
    email,
    iceContact,
    certifications,
    localPath,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrewMemberRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.name == this.name &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.iceContact == this.iceContact &&
          other.certifications == this.certifications &&
          other.localPath == this.localPath &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class CrewMembersCompanion extends UpdateCompanion<CrewMemberRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> iceContact;
  final Value<String?> certifications;
  final Value<String?> localPath;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const CrewMembersCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.iceContact = const Value.absent(),
    this.certifications = const Value.absent(),
    this.localPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  CrewMembersCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.iceContact = const Value.absent(),
    this.certifications = const Value.absent(),
    this.localPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<CrewMemberRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? iceContact,
    Expression<String>? certifications,
    Expression<String>? localPath,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (iceContact != null) 'ice_contact': iceContact,
      if (certifications != null) 'certifications': certifications,
      if (localPath != null) 'local_path': localPath,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  CrewMembersCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? name,
    Value<String>? role,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? iceContact,
    Value<String?>? certifications,
    Value<String?>? localPath,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return CrewMembersCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      iceContact: iceContact ?? this.iceContact,
      certifications: certifications ?? this.certifications,
      localPath: localPath ?? this.localPath,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (iceContact.present) {
      map['ice_contact'] = Variable<String>(iceContact.value);
    }
    if (certifications.present) {
      map['certifications'] = Variable<String>(certifications.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrewMembersCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('iceContact: $iceContact, ')
          ..write('certifications: $certifications, ')
          ..write('localPath: $localPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    name,
    location,
    quantity,
    unit,
    serialNumber,
    notes,
    localPath,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItemRow extends DataClass
    implements Insertable<InventoryItemRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String name;
  final String? location;
  final double quantity;
  final String? unit;
  final String? serialNumber;
  final String? notes;
  final String? localPath;
  final bool isSynced;
  final DateTime lastModified;
  const InventoryItemRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.name,
    this.location,
    required this.quantity,
    this.unit,
    this.serialNumber,
    this.notes,
    this.localPath,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      name: Value(name),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      quantity: Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory InventoryItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItemRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String?>(json['location']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String?>(location),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'notes': serializer.toJson<String?>(notes),
      'localPath': serializer.toJson<String?>(localPath),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  InventoryItemRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? name,
    Value<String?> location = const Value.absent(),
    double? quantity,
    Value<String?> unit = const Value.absent(),
    Value<String?> serialNumber = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    bool? isSynced,
    DateTime? lastModified,
  }) => InventoryItemRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    name: name ?? this.name,
    location: location.present ? location.value : this.location,
    quantity: quantity ?? this.quantity,
    unit: unit.present ? unit.value : this.unit,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    notes: notes.present ? notes.value : this.notes,
    localPath: localPath.present ? localPath.value : this.localPath,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  InventoryItemRow copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItemRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('notes: $notes, ')
          ..write('localPath: $localPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    name,
    location,
    quantity,
    unit,
    serialNumber,
    notes,
    localPath,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItemRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.name == this.name &&
          other.location == this.location &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.serialNumber == this.serialNumber &&
          other.notes == this.notes &&
          other.localPath == this.localPath &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItemRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> name;
  final Value<String?> location;
  final Value<double> quantity;
  final Value<String?> unit;
  final Value<String?> serialNumber;
  final Value<String?> notes;
  final Value<String?> localPath;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.localPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.localPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<InventoryItemRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? serialNumber,
    Expression<String>? notes,
    Expression<String>? localPath,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (notes != null) 'notes': notes,
      if (localPath != null) 'local_path': localPath,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? name,
    Value<String?>? location,
    Value<double>? quantity,
    Value<String?>? unit,
    Value<String?>? serialNumber,
    Value<String?>? notes,
    Value<String?>? localPath,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      name: name ?? this.name,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      serialNumber: serialNumber ?? this.serialNumber,
      notes: notes ?? this.notes,
      localPath: localPath ?? this.localPath,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('notes: $notes, ')
          ..write('localPath: $localPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $FuelLogEntriesTable extends FuelLogEntries
    with TableInfo<$FuelLogEntriesTable, FuelLogEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Fuel'),
  );
  static const VerificationMeta _litersMeta = const VerificationMeta('liters');
  @override
  late final GeneratedColumn<double> liters = GeneratedColumn<double>(
    'liters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pricePerLiterMeta = const VerificationMeta(
    'pricePerLiter',
  );
  @override
  late final GeneratedColumn<double> pricePerLiter = GeneratedColumn<double>(
    'price_per_liter',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    date,
    type,
    liters,
    pricePerLiter,
    totalCost,
    notes,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelLogEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('liters')) {
      context.handle(
        _litersMeta,
        liters.isAcceptableOrUnknown(data['liters']!, _litersMeta),
      );
    }
    if (data.containsKey('price_per_liter')) {
      context.handle(
        _pricePerLiterMeta,
        pricePerLiter.isAcceptableOrUnknown(
          data['price_per_liter']!,
          _pricePerLiterMeta,
        ),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FuelLogEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelLogEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      liters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}liters'],
      )!,
      pricePerLiter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_liter'],
      )!,
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $FuelLogEntriesTable createAlias(String alias) {
    return $FuelLogEntriesTable(attachedDatabase, alias);
  }
}

class FuelLogEntryRow extends DataClass implements Insertable<FuelLogEntryRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final DateTime date;
  final String type;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final String? notes;
  final bool isSynced;
  final DateTime lastModified;
  const FuelLogEntryRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.date,
    required this.type,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.notes,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['date'] = Variable<DateTime>(date);
    map['type'] = Variable<String>(type);
    map['liters'] = Variable<double>(liters);
    map['price_per_liter'] = Variable<double>(pricePerLiter);
    map['total_cost'] = Variable<double>(totalCost);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  FuelLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return FuelLogEntriesCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      date: Value(date),
      type: Value(type),
      liters: Value(liters),
      pricePerLiter: Value(pricePerLiter),
      totalCost: Value(totalCost),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory FuelLogEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelLogEntryRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      liters: serializer.fromJson<double>(json['liters']),
      pricePerLiter: serializer.fromJson<double>(json['pricePerLiter']),
      totalCost: serializer.fromJson<double>(json['totalCost']),
      notes: serializer.fromJson<String?>(json['notes']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(type),
      'liters': serializer.toJson<double>(liters),
      'pricePerLiter': serializer.toJson<double>(pricePerLiter),
      'totalCost': serializer.toJson<double>(totalCost),
      'notes': serializer.toJson<String?>(notes),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  FuelLogEntryRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    DateTime? date,
    String? type,
    double? liters,
    double? pricePerLiter,
    double? totalCost,
    Value<String?> notes = const Value.absent(),
    bool? isSynced,
    DateTime? lastModified,
  }) => FuelLogEntryRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    date: date ?? this.date,
    type: type ?? this.type,
    liters: liters ?? this.liters,
    pricePerLiter: pricePerLiter ?? this.pricePerLiter,
    totalCost: totalCost ?? this.totalCost,
    notes: notes.present ? notes.value : this.notes,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  FuelLogEntryRow copyWithCompanion(FuelLogEntriesCompanion data) {
    return FuelLogEntryRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      liters: data.liters.present ? data.liters.value : this.liters,
      pricePerLiter: data.pricePerLiter.present
          ? data.pricePerLiter.value
          : this.pricePerLiter,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      notes: data.notes.present ? data.notes.value : this.notes,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelLogEntryRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('liters: $liters, ')
          ..write('pricePerLiter: $pricePerLiter, ')
          ..write('totalCost: $totalCost, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    date,
    type,
    liters,
    pricePerLiter,
    totalCost,
    notes,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelLogEntryRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.date == this.date &&
          other.type == this.type &&
          other.liters == this.liters &&
          other.pricePerLiter == this.pricePerLiter &&
          other.totalCost == this.totalCost &&
          other.notes == this.notes &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class FuelLogEntriesCompanion extends UpdateCompanion<FuelLogEntryRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<DateTime> date;
  final Value<String> type;
  final Value<double> liters;
  final Value<double> pricePerLiter;
  final Value<double> totalCost;
  final Value<String?> notes;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const FuelLogEntriesCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.liters = const Value.absent(),
    this.pricePerLiter = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  FuelLogEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.liters = const Value.absent(),
    this.pricePerLiter = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<FuelLogEntryRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<double>? liters,
    Expression<double>? pricePerLiter,
    Expression<double>? totalCost,
    Expression<String>? notes,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (liters != null) 'liters': liters,
      if (pricePerLiter != null) 'price_per_liter': pricePerLiter,
      if (totalCost != null) 'total_cost': totalCost,
      if (notes != null) 'notes': notes,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  FuelLogEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<DateTime>? date,
    Value<String>? type,
    Value<double>? liters,
    Value<double>? pricePerLiter,
    Value<double>? totalCost,
    Value<String?>? notes,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return FuelLogEntriesCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      date: date ?? this.date,
      type: type ?? this.type,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (liters.present) {
      map['liters'] = Variable<double>(liters.value);
    }
    if (pricePerLiter.present) {
      map['price_per_liter'] = Variable<double>(pricePerLiter.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('liters: $liters, ')
          ..write('pricePerLiter: $pricePerLiter, ')
          ..write('totalCost: $totalCost, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Other'),
  );
  static const VerificationMeta _fileUrlMeta = const VerificationMeta(
    'fileUrl',
  );
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
    'file_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryMeta = const VerificationMeta('expiry');
  @override
  late final GeneratedColumn<DateTime> expiry = GeneratedColumn<DateTime>(
    'expiry',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    title,
    type,
    fileUrl,
    localPath,
    notes,
    expiry,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('file_url')) {
      context.handle(
        _fileUrlMeta,
        fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('expiry')) {
      context.handle(
        _expiryMeta,
        expiry.isAcceptableOrUnknown(data['expiry']!, _expiryMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      fileUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_url'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      expiry: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String title;
  final String type;
  final String? fileUrl;
  final String? localPath;
  final String? notes;
  final DateTime? expiry;
  final bool isSynced;
  final DateTime lastModified;
  const DocumentRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.title,
    required this.type,
    this.fileUrl,
    this.localPath,
    this.notes,
    this.expiry,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || expiry != null) {
      map['expiry'] = Variable<DateTime>(expiry);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      title: Value(title),
      type: Value(type),
      fileUrl: fileUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fileUrl),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      expiry: expiry == null && nullToAbsent
          ? const Value.absent()
          : Value(expiry),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      expiry: serializer.fromJson<DateTime?>(json['expiry']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'localPath': serializer.toJson<String?>(localPath),
      'notes': serializer.toJson<String?>(notes),
      'expiry': serializer.toJson<DateTime?>(expiry),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  DocumentRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? title,
    String? type,
    Value<String?> fileUrl = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> expiry = const Value.absent(),
    bool? isSynced,
    DateTime? lastModified,
  }) => DocumentRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    title: title ?? this.title,
    type: type ?? this.type,
    fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
    localPath: localPath.present ? localPath.value : this.localPath,
    notes: notes.present ? notes.value : this.notes,
    expiry: expiry.present ? expiry.value : this.expiry,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      expiry: data.expiry.present ? data.expiry.value : this.expiry,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('localPath: $localPath, ')
          ..write('notes: $notes, ')
          ..write('expiry: $expiry, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    title,
    type,
    fileUrl,
    localPath,
    notes,
    expiry,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.title == this.title &&
          other.type == this.type &&
          other.fileUrl == this.fileUrl &&
          other.localPath == this.localPath &&
          other.notes == this.notes &&
          other.expiry == this.expiry &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> title;
  final Value<String> type;
  final Value<String?> fileUrl;
  final Value<String?> localPath;
  final Value<String?> notes;
  final Value<DateTime?> expiry;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.expiry = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  DocumentsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.expiry = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<DocumentRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? fileUrl,
    Expression<String>? localPath,
    Expression<String>? notes,
    Expression<DateTime>? expiry,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (fileUrl != null) 'file_url': fileUrl,
      if (localPath != null) 'local_path': localPath,
      if (notes != null) 'notes': notes,
      if (expiry != null) 'expiry': expiry,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  DocumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? title,
    Value<String>? type,
    Value<String?>? fileUrl,
    Value<String?>? localPath,
    Value<String?>? notes,
    Value<DateTime?>? expiry,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      title: title ?? this.title,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      localPath: localPath ?? this.localPath,
      notes: notes ?? this.notes,
      expiry: expiry ?? this.expiry,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (expiry.present) {
      map['expiry'] = Variable<DateTime>(expiry.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('localPath: $localPath, ')
          ..write('notes: $notes, ')
          ..write('expiry: $expiry, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $MealPlansTable extends MealPlans
    with TableInfo<$MealPlansTable, MealPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _numberOfDaysMeta = const VerificationMeta(
    'numberOfDays',
  );
  @override
  late final GeneratedColumn<int> numberOfDays = GeneratedColumn<int>(
    'number_of_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _guestCountMeta = const VerificationMeta(
    'guestCount',
  );
  @override
  late final GeneratedColumn<int> guestCount = GeneratedColumn<int>(
    'guest_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _guestProfileIdsMeta = const VerificationMeta(
    'guestProfileIds',
  );
  @override
  late final GeneratedColumn<String> guestProfileIds = GeneratedColumn<String>(
    'guest_profile_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _slotsMeta = const VerificationMeta('slots');
  @override
  late final GeneratedColumn<String> slots = GeneratedColumn<String>(
    'slots',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    numberOfDays,
    guestCount,
    guestProfileIds,
    slots,
    createdAt,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('number_of_days')) {
      context.handle(
        _numberOfDaysMeta,
        numberOfDays.isAcceptableOrUnknown(
          data['number_of_days']!,
          _numberOfDaysMeta,
        ),
      );
    }
    if (data.containsKey('guest_count')) {
      context.handle(
        _guestCountMeta,
        guestCount.isAcceptableOrUnknown(data['guest_count']!, _guestCountMeta),
      );
    }
    if (data.containsKey('guest_profile_ids')) {
      context.handle(
        _guestProfileIdsMeta,
        guestProfileIds.isAcceptableOrUnknown(
          data['guest_profile_ids']!,
          _guestProfileIdsMeta,
        ),
      );
    }
    if (data.containsKey('slots')) {
      context.handle(
        _slotsMeta,
        slots.isAcceptableOrUnknown(data['slots']!, _slotsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      numberOfDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_days'],
      )!,
      guestCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guest_count'],
      )!,
      guestProfileIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guest_profile_ids'],
      )!,
      slots: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slots'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $MealPlansTable createAlias(String alias) {
    return $MealPlansTable(attachedDatabase, alias);
  }
}

class MealPlanRow extends DataClass implements Insertable<MealPlanRow> {
  final int id;
  final String name;
  final DateTime startDate;
  final int numberOfDays;
  final int guestCount;
  final String guestProfileIds;
  final String slots;
  final DateTime createdAt;
  final DateTime lastModified;
  const MealPlanRow({
    required this.id,
    required this.name,
    required this.startDate,
    required this.numberOfDays,
    required this.guestCount,
    required this.guestProfileIds,
    required this.slots,
    required this.createdAt,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<DateTime>(startDate);
    map['number_of_days'] = Variable<int>(numberOfDays);
    map['guest_count'] = Variable<int>(guestCount);
    map['guest_profile_ids'] = Variable<String>(guestProfileIds);
    map['slots'] = Variable<String>(slots);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  MealPlansCompanion toCompanion(bool nullToAbsent) {
    return MealPlansCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      numberOfDays: Value(numberOfDays),
      guestCount: Value(guestCount),
      guestProfileIds: Value(guestProfileIds),
      slots: Value(slots),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory MealPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlanRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      numberOfDays: serializer.fromJson<int>(json['numberOfDays']),
      guestCount: serializer.fromJson<int>(json['guestCount']),
      guestProfileIds: serializer.fromJson<String>(json['guestProfileIds']),
      slots: serializer.fromJson<String>(json['slots']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<DateTime>(startDate),
      'numberOfDays': serializer.toJson<int>(numberOfDays),
      'guestCount': serializer.toJson<int>(guestCount),
      'guestProfileIds': serializer.toJson<String>(guestProfileIds),
      'slots': serializer.toJson<String>(slots),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  MealPlanRow copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    int? numberOfDays,
    int? guestCount,
    String? guestProfileIds,
    String? slots,
    DateTime? createdAt,
    DateTime? lastModified,
  }) => MealPlanRow(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    numberOfDays: numberOfDays ?? this.numberOfDays,
    guestCount: guestCount ?? this.guestCount,
    guestProfileIds: guestProfileIds ?? this.guestProfileIds,
    slots: slots ?? this.slots,
    createdAt: createdAt ?? this.createdAt,
    lastModified: lastModified ?? this.lastModified,
  );
  MealPlanRow copyWithCompanion(MealPlansCompanion data) {
    return MealPlanRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      numberOfDays: data.numberOfDays.present
          ? data.numberOfDays.value
          : this.numberOfDays,
      guestCount: data.guestCount.present
          ? data.guestCount.value
          : this.guestCount,
      guestProfileIds: data.guestProfileIds.present
          ? data.guestProfileIds.value
          : this.guestProfileIds,
      slots: data.slots.present ? data.slots.value : this.slots,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('numberOfDays: $numberOfDays, ')
          ..write('guestCount: $guestCount, ')
          ..write('guestProfileIds: $guestProfileIds, ')
          ..write('slots: $slots, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    numberOfDays,
    guestCount,
    guestProfileIds,
    slots,
    createdAt,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlanRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.numberOfDays == this.numberOfDays &&
          other.guestCount == this.guestCount &&
          other.guestProfileIds == this.guestProfileIds &&
          other.slots == this.slots &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class MealPlansCompanion extends UpdateCompanion<MealPlanRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> startDate;
  final Value<int> numberOfDays;
  final Value<int> guestCount;
  final Value<String> guestProfileIds;
  final Value<String> slots;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  const MealPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.numberOfDays = const Value.absent(),
    this.guestCount = const Value.absent(),
    this.guestProfileIds = const Value.absent(),
    this.slots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  MealPlansCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.numberOfDays = const Value.absent(),
    this.guestCount = const Value.absent(),
    this.guestProfileIds = const Value.absent(),
    this.slots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<MealPlanRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? startDate,
    Expression<int>? numberOfDays,
    Expression<int>? guestCount,
    Expression<String>? guestProfileIds,
    Expression<String>? slots,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (numberOfDays != null) 'number_of_days': numberOfDays,
      if (guestCount != null) 'guest_count': guestCount,
      if (guestProfileIds != null) 'guest_profile_ids': guestProfileIds,
      if (slots != null) 'slots': slots,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  MealPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? startDate,
    Value<int>? numberOfDays,
    Value<int>? guestCount,
    Value<String>? guestProfileIds,
    Value<String>? slots,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModified,
  }) {
    return MealPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      guestCount: guestCount ?? this.guestCount,
      guestProfileIds: guestProfileIds ?? this.guestProfileIds,
      slots: slots ?? this.slots,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (numberOfDays.present) {
      map['number_of_days'] = Variable<int>(numberOfDays.value);
    }
    if (guestCount.present) {
      map['guest_count'] = Variable<int>(guestCount.value);
    }
    if (guestProfileIds.present) {
      map['guest_profile_ids'] = Variable<String>(guestProfileIds.value);
    }
    if (slots.present) {
      map['slots'] = Variable<String>(slots.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('numberOfDays: $numberOfDays, ')
          ..write('guestCount: $guestCount, ')
          ..write('guestProfileIds: $guestProfileIds, ')
          ..write('slots: $slots, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $BoatsTable extends Boats with TableInfo<$BoatsTable, BoatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isBoughtMeta = const VerificationMeta(
    'isBought',
  );
  @override
  late final GeneratedColumn<bool> isBought = GeneratedColumn<bool>(
    'is_bought',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bought" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastPurchasePriceMeta = const VerificationMeta(
    'lastPurchasePrice',
  );
  @override
  late final GeneratedColumn<double> lastPurchasePrice =
      GeneratedColumn<double>(
        'last_purchase_price',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shareCodeMeta = const VerificationMeta(
    'shareCode',
  );
  @override
  late final GeneratedColumn<String> shareCode = GeneratedColumn<String>(
    'share_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _llmApiKeyMeta = const VerificationMeta(
    'llmApiKey',
  );
  @override
  late final GeneratedColumn<String> llmApiKey = GeneratedColumn<String>(
    'llm_api_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _llmApiKeyProviderMeta = const VerificationMeta(
    'llmApiKeyProvider',
  );
  @override
  late final GeneratedColumn<String> llmApiKeyProvider =
      GeneratedColumn<String>(
        'llm_api_key_provider',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    name,
    isBought,
    isHidden,
    isSynced,
    lastPurchasePrice,
    notes,
    origin,
    photoUrl,
    ownerId,
    shareCode,
    llmApiKey,
    llmApiKeyProvider,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boats';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('is_bought')) {
      context.handle(
        _isBoughtMeta,
        isBought.isAcceptableOrUnknown(data['is_bought']!, _isBoughtMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_purchase_price')) {
      context.handle(
        _lastPurchasePriceMeta,
        lastPurchasePrice.isAcceptableOrUnknown(
          data['last_purchase_price']!,
          _lastPurchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('share_code')) {
      context.handle(
        _shareCodeMeta,
        shareCode.isAcceptableOrUnknown(data['share_code']!, _shareCodeMeta),
      );
    }
    if (data.containsKey('llm_api_key')) {
      context.handle(
        _llmApiKeyMeta,
        llmApiKey.isAcceptableOrUnknown(data['llm_api_key']!, _llmApiKeyMeta),
      );
    }
    if (data.containsKey('llm_api_key_provider')) {
      context.handle(
        _llmApiKeyProviderMeta,
        llmApiKeyProvider.isAcceptableOrUnknown(
          data['llm_api_key_provider']!,
          _llmApiKeyProviderMeta,
        ),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoatRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isBought: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bought'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastPurchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_purchase_price'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      shareCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_code'],
      ),
      llmApiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}llm_api_key'],
      ),
      llmApiKeyProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}llm_api_key_provider'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $BoatsTable createAlias(String alias) {
    return $BoatsTable(attachedDatabase, alias);
  }
}

class BoatRow extends DataClass implements Insertable<BoatRow> {
  final int id;
  final String supabaseId;
  final String name;
  final bool isBought;
  final bool isHidden;
  final bool isSynced;
  final double? lastPurchasePrice;
  final String? notes;
  final String? origin;
  final String? photoUrl;
  final String? ownerId;
  final String? shareCode;
  final String? llmApiKey;
  final String? llmApiKeyProvider;
  final DateTime lastModified;
  const BoatRow({
    required this.id,
    required this.supabaseId,
    required this.name,
    required this.isBought,
    required this.isHidden,
    required this.isSynced,
    this.lastPurchasePrice,
    this.notes,
    this.origin,
    this.photoUrl,
    this.ownerId,
    this.shareCode,
    this.llmApiKey,
    this.llmApiKeyProvider,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['name'] = Variable<String>(name);
    map['is_bought'] = Variable<bool>(isBought);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastPurchasePrice != null) {
      map['last_purchase_price'] = Variable<double>(lastPurchasePrice);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || shareCode != null) {
      map['share_code'] = Variable<String>(shareCode);
    }
    if (!nullToAbsent || llmApiKey != null) {
      map['llm_api_key'] = Variable<String>(llmApiKey);
    }
    if (!nullToAbsent || llmApiKeyProvider != null) {
      map['llm_api_key_provider'] = Variable<String>(llmApiKeyProvider);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  BoatsCompanion toCompanion(bool nullToAbsent) {
    return BoatsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      name: Value(name),
      isBought: Value(isBought),
      isHidden: Value(isHidden),
      isSynced: Value(isSynced),
      lastPurchasePrice: lastPurchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchasePrice),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      shareCode: shareCode == null && nullToAbsent
          ? const Value.absent()
          : Value(shareCode),
      llmApiKey: llmApiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(llmApiKey),
      llmApiKeyProvider: llmApiKeyProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(llmApiKeyProvider),
      lastModified: Value(lastModified),
    );
  }

  factory BoatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoatRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      name: serializer.fromJson<String>(json['name']),
      isBought: serializer.fromJson<bool>(json['isBought']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastPurchasePrice: serializer.fromJson<double?>(
        json['lastPurchasePrice'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      origin: serializer.fromJson<String?>(json['origin']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      shareCode: serializer.fromJson<String?>(json['shareCode']),
      llmApiKey: serializer.fromJson<String?>(json['llmApiKey']),
      llmApiKeyProvider: serializer.fromJson<String?>(
        json['llmApiKeyProvider'],
      ),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'name': serializer.toJson<String>(name),
      'isBought': serializer.toJson<bool>(isBought),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastPurchasePrice': serializer.toJson<double?>(lastPurchasePrice),
      'notes': serializer.toJson<String?>(notes),
      'origin': serializer.toJson<String?>(origin),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'ownerId': serializer.toJson<String?>(ownerId),
      'shareCode': serializer.toJson<String?>(shareCode),
      'llmApiKey': serializer.toJson<String?>(llmApiKey),
      'llmApiKeyProvider': serializer.toJson<String?>(llmApiKeyProvider),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  BoatRow copyWith({
    int? id,
    String? supabaseId,
    String? name,
    bool? isBought,
    bool? isHidden,
    bool? isSynced,
    Value<double?> lastPurchasePrice = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> origin = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> shareCode = const Value.absent(),
    Value<String?> llmApiKey = const Value.absent(),
    Value<String?> llmApiKeyProvider = const Value.absent(),
    DateTime? lastModified,
  }) => BoatRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    name: name ?? this.name,
    isBought: isBought ?? this.isBought,
    isHidden: isHidden ?? this.isHidden,
    isSynced: isSynced ?? this.isSynced,
    lastPurchasePrice: lastPurchasePrice.present
        ? lastPurchasePrice.value
        : this.lastPurchasePrice,
    notes: notes.present ? notes.value : this.notes,
    origin: origin.present ? origin.value : this.origin,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    shareCode: shareCode.present ? shareCode.value : this.shareCode,
    llmApiKey: llmApiKey.present ? llmApiKey.value : this.llmApiKey,
    llmApiKeyProvider: llmApiKeyProvider.present
        ? llmApiKeyProvider.value
        : this.llmApiKeyProvider,
    lastModified: lastModified ?? this.lastModified,
  );
  BoatRow copyWithCompanion(BoatsCompanion data) {
    return BoatRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      name: data.name.present ? data.name.value : this.name,
      isBought: data.isBought.present ? data.isBought.value : this.isBought,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastPurchasePrice: data.lastPurchasePrice.present
          ? data.lastPurchasePrice.value
          : this.lastPurchasePrice,
      notes: data.notes.present ? data.notes.value : this.notes,
      origin: data.origin.present ? data.origin.value : this.origin,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      shareCode: data.shareCode.present ? data.shareCode.value : this.shareCode,
      llmApiKey: data.llmApiKey.present ? data.llmApiKey.value : this.llmApiKey,
      llmApiKeyProvider: data.llmApiKeyProvider.present
          ? data.llmApiKeyProvider.value
          : this.llmApiKeyProvider,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoatRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('name: $name, ')
          ..write('isBought: $isBought, ')
          ..write('isHidden: $isHidden, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastPurchasePrice: $lastPurchasePrice, ')
          ..write('notes: $notes, ')
          ..write('origin: $origin, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('ownerId: $ownerId, ')
          ..write('shareCode: $shareCode, ')
          ..write('llmApiKey: $llmApiKey, ')
          ..write('llmApiKeyProvider: $llmApiKeyProvider, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    name,
    isBought,
    isHidden,
    isSynced,
    lastPurchasePrice,
    notes,
    origin,
    photoUrl,
    ownerId,
    shareCode,
    llmApiKey,
    llmApiKeyProvider,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoatRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.name == this.name &&
          other.isBought == this.isBought &&
          other.isHidden == this.isHidden &&
          other.isSynced == this.isSynced &&
          other.lastPurchasePrice == this.lastPurchasePrice &&
          other.notes == this.notes &&
          other.origin == this.origin &&
          other.photoUrl == this.photoUrl &&
          other.ownerId == this.ownerId &&
          other.shareCode == this.shareCode &&
          other.llmApiKey == this.llmApiKey &&
          other.llmApiKeyProvider == this.llmApiKeyProvider &&
          other.lastModified == this.lastModified);
}

class BoatsCompanion extends UpdateCompanion<BoatRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> name;
  final Value<bool> isBought;
  final Value<bool> isHidden;
  final Value<bool> isSynced;
  final Value<double?> lastPurchasePrice;
  final Value<String?> notes;
  final Value<String?> origin;
  final Value<String?> photoUrl;
  final Value<String?> ownerId;
  final Value<String?> shareCode;
  final Value<String?> llmApiKey;
  final Value<String?> llmApiKeyProvider;
  final Value<DateTime> lastModified;
  const BoatsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastPurchasePrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.origin = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.shareCode = const Value.absent(),
    this.llmApiKey = const Value.absent(),
    this.llmApiKeyProvider = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  BoatsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastPurchasePrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.origin = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.shareCode = const Value.absent(),
    this.llmApiKey = const Value.absent(),
    this.llmApiKeyProvider = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<BoatRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? name,
    Expression<bool>? isBought,
    Expression<bool>? isHidden,
    Expression<bool>? isSynced,
    Expression<double>? lastPurchasePrice,
    Expression<String>? notes,
    Expression<String>? origin,
    Expression<String>? photoUrl,
    Expression<String>? ownerId,
    Expression<String>? shareCode,
    Expression<String>? llmApiKey,
    Expression<String>? llmApiKeyProvider,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (name != null) 'name': name,
      if (isBought != null) 'is_bought': isBought,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastPurchasePrice != null) 'last_purchase_price': lastPurchasePrice,
      if (notes != null) 'notes': notes,
      if (origin != null) 'origin': origin,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (ownerId != null) 'owner_id': ownerId,
      if (shareCode != null) 'share_code': shareCode,
      if (llmApiKey != null) 'llm_api_key': llmApiKey,
      if (llmApiKeyProvider != null) 'llm_api_key_provider': llmApiKeyProvider,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  BoatsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? name,
    Value<bool>? isBought,
    Value<bool>? isHidden,
    Value<bool>? isSynced,
    Value<double?>? lastPurchasePrice,
    Value<String?>? notes,
    Value<String?>? origin,
    Value<String?>? photoUrl,
    Value<String?>? ownerId,
    Value<String?>? shareCode,
    Value<String?>? llmApiKey,
    Value<String?>? llmApiKeyProvider,
    Value<DateTime>? lastModified,
  }) {
    return BoatsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      name: name ?? this.name,
      isBought: isBought ?? this.isBought,
      isHidden: isHidden ?? this.isHidden,
      isSynced: isSynced ?? this.isSynced,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      notes: notes ?? this.notes,
      origin: origin ?? this.origin,
      photoUrl: photoUrl ?? this.photoUrl,
      ownerId: ownerId ?? this.ownerId,
      shareCode: shareCode ?? this.shareCode,
      llmApiKey: llmApiKey ?? this.llmApiKey,
      llmApiKeyProvider: llmApiKeyProvider ?? this.llmApiKeyProvider,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isBought.present) {
      map['is_bought'] = Variable<bool>(isBought.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastPurchasePrice.present) {
      map['last_purchase_price'] = Variable<double>(lastPurchasePrice.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (shareCode.present) {
      map['share_code'] = Variable<String>(shareCode.value);
    }
    if (llmApiKey.present) {
      map['llm_api_key'] = Variable<String>(llmApiKey.value);
    }
    if (llmApiKeyProvider.present) {
      map['llm_api_key_provider'] = Variable<String>(llmApiKeyProvider.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoatsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('name: $name, ')
          ..write('isBought: $isBought, ')
          ..write('isHidden: $isHidden, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastPurchasePrice: $lastPurchasePrice, ')
          ..write('notes: $notes, ')
          ..write('origin: $origin, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('ownerId: $ownerId, ')
          ..write('shareCode: $shareCode, ')
          ..write('llmApiKey: $llmApiKey, ')
          ..write('llmApiKeyProvider: $llmApiKeyProvider, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $CaptainLogEntriesTable extends CaptainLogEntries
    with TableInfo<$CaptainLogEntriesTable, CaptainLogEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaptainLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _logDateMeta = const VerificationMeta(
    'logDate',
  );
  @override
  late final GeneratedColumn<DateTime> logDate = GeneratedColumn<DateTime>(
    'log_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _logTimeMeta = const VerificationMeta(
    'logTime',
  );
  @override
  late final GeneratedColumn<String> logTime = GeneratedColumn<String>(
    'log_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionLatMeta = const VerificationMeta(
    'positionLat',
  );
  @override
  late final GeneratedColumn<double> positionLat = GeneratedColumn<double>(
    'position_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionLngMeta = const VerificationMeta(
    'positionLng',
  );
  @override
  late final GeneratedColumn<double> positionLng = GeneratedColumn<double>(
    'position_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weatherMeta = const VerificationMeta(
    'weather',
  );
  @override
  late final GeneratedColumn<String> weather = GeneratedColumn<String>(
    'weather',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windSpeedKtMeta = const VerificationMeta(
    'windSpeedKt',
  );
  @override
  late final GeneratedColumn<int> windSpeedKt = GeneratedColumn<int>(
    'wind_speed_kt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windDirMeta = const VerificationMeta(
    'windDir',
  );
  @override
  late final GeneratedColumn<String> windDir = GeneratedColumn<String>(
    'wind_dir',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crewOnBoardMeta = const VerificationMeta(
    'crewOnBoard',
  );
  @override
  late final GeneratedColumn<String> crewOnBoard = GeneratedColumn<String>(
    'crew_on_board',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photosMeta = const VerificationMeta('photos');
  @override
  late final GeneratedColumn<String> photos = GeneratedColumn<String>(
    'photos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    logDate,
    title,
    logTime,
    positionLat,
    positionLng,
    weather,
    windSpeedKt,
    windDir,
    crewOnBoard,
    notes,
    photos,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'captain_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaptainLogEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('log_date')) {
      context.handle(
        _logDateMeta,
        logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('log_time')) {
      context.handle(
        _logTimeMeta,
        logTime.isAcceptableOrUnknown(data['log_time']!, _logTimeMeta),
      );
    }
    if (data.containsKey('position_lat')) {
      context.handle(
        _positionLatMeta,
        positionLat.isAcceptableOrUnknown(
          data['position_lat']!,
          _positionLatMeta,
        ),
      );
    }
    if (data.containsKey('position_lng')) {
      context.handle(
        _positionLngMeta,
        positionLng.isAcceptableOrUnknown(
          data['position_lng']!,
          _positionLngMeta,
        ),
      );
    }
    if (data.containsKey('weather')) {
      context.handle(
        _weatherMeta,
        weather.isAcceptableOrUnknown(data['weather']!, _weatherMeta),
      );
    }
    if (data.containsKey('wind_speed_kt')) {
      context.handle(
        _windSpeedKtMeta,
        windSpeedKt.isAcceptableOrUnknown(
          data['wind_speed_kt']!,
          _windSpeedKtMeta,
        ),
      );
    }
    if (data.containsKey('wind_dir')) {
      context.handle(
        _windDirMeta,
        windDir.isAcceptableOrUnknown(data['wind_dir']!, _windDirMeta),
      );
    }
    if (data.containsKey('crew_on_board')) {
      context.handle(
        _crewOnBoardMeta,
        crewOnBoard.isAcceptableOrUnknown(
          data['crew_on_board']!,
          _crewOnBoardMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photos')) {
      context.handle(
        _photosMeta,
        photos.isAcceptableOrUnknown(data['photos']!, _photosMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaptainLogEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaptainLogEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      logDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}log_date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      logTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_time'],
      ),
      positionLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position_lat'],
      ),
      positionLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position_lng'],
      ),
      weather: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather'],
      ),
      windSpeedKt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wind_speed_kt'],
      ),
      windDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wind_dir'],
      ),
      crewOnBoard: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crew_on_board'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      photos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photos'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $CaptainLogEntriesTable createAlias(String alias) {
    return $CaptainLogEntriesTable(attachedDatabase, alias);
  }
}

class CaptainLogEntryRow extends DataClass
    implements Insertable<CaptainLogEntryRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final DateTime logDate;
  final String title;
  final String? logTime;
  final double? positionLat;
  final double? positionLng;
  final String? weather;
  final int? windSpeedKt;
  final String? windDir;
  final String crewOnBoard;
  final String? notes;
  final String photos;
  final bool isSynced;
  final DateTime lastModified;
  const CaptainLogEntryRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.logDate,
    required this.title,
    this.logTime,
    this.positionLat,
    this.positionLng,
    this.weather,
    this.windSpeedKt,
    this.windDir,
    required this.crewOnBoard,
    this.notes,
    required this.photos,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['log_date'] = Variable<DateTime>(logDate);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || logTime != null) {
      map['log_time'] = Variable<String>(logTime);
    }
    if (!nullToAbsent || positionLat != null) {
      map['position_lat'] = Variable<double>(positionLat);
    }
    if (!nullToAbsent || positionLng != null) {
      map['position_lng'] = Variable<double>(positionLng);
    }
    if (!nullToAbsent || weather != null) {
      map['weather'] = Variable<String>(weather);
    }
    if (!nullToAbsent || windSpeedKt != null) {
      map['wind_speed_kt'] = Variable<int>(windSpeedKt);
    }
    if (!nullToAbsent || windDir != null) {
      map['wind_dir'] = Variable<String>(windDir);
    }
    map['crew_on_board'] = Variable<String>(crewOnBoard);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['photos'] = Variable<String>(photos);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  CaptainLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return CaptainLogEntriesCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      logDate: Value(logDate),
      title: Value(title),
      logTime: logTime == null && nullToAbsent
          ? const Value.absent()
          : Value(logTime),
      positionLat: positionLat == null && nullToAbsent
          ? const Value.absent()
          : Value(positionLat),
      positionLng: positionLng == null && nullToAbsent
          ? const Value.absent()
          : Value(positionLng),
      weather: weather == null && nullToAbsent
          ? const Value.absent()
          : Value(weather),
      windSpeedKt: windSpeedKt == null && nullToAbsent
          ? const Value.absent()
          : Value(windSpeedKt),
      windDir: windDir == null && nullToAbsent
          ? const Value.absent()
          : Value(windDir),
      crewOnBoard: Value(crewOnBoard),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      photos: Value(photos),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory CaptainLogEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaptainLogEntryRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      logDate: serializer.fromJson<DateTime>(json['logDate']),
      title: serializer.fromJson<String>(json['title']),
      logTime: serializer.fromJson<String?>(json['logTime']),
      positionLat: serializer.fromJson<double?>(json['positionLat']),
      positionLng: serializer.fromJson<double?>(json['positionLng']),
      weather: serializer.fromJson<String?>(json['weather']),
      windSpeedKt: serializer.fromJson<int?>(json['windSpeedKt']),
      windDir: serializer.fromJson<String?>(json['windDir']),
      crewOnBoard: serializer.fromJson<String>(json['crewOnBoard']),
      notes: serializer.fromJson<String?>(json['notes']),
      photos: serializer.fromJson<String>(json['photos']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'logDate': serializer.toJson<DateTime>(logDate),
      'title': serializer.toJson<String>(title),
      'logTime': serializer.toJson<String?>(logTime),
      'positionLat': serializer.toJson<double?>(positionLat),
      'positionLng': serializer.toJson<double?>(positionLng),
      'weather': serializer.toJson<String?>(weather),
      'windSpeedKt': serializer.toJson<int?>(windSpeedKt),
      'windDir': serializer.toJson<String?>(windDir),
      'crewOnBoard': serializer.toJson<String>(crewOnBoard),
      'notes': serializer.toJson<String?>(notes),
      'photos': serializer.toJson<String>(photos),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  CaptainLogEntryRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    DateTime? logDate,
    String? title,
    Value<String?> logTime = const Value.absent(),
    Value<double?> positionLat = const Value.absent(),
    Value<double?> positionLng = const Value.absent(),
    Value<String?> weather = const Value.absent(),
    Value<int?> windSpeedKt = const Value.absent(),
    Value<String?> windDir = const Value.absent(),
    String? crewOnBoard,
    Value<String?> notes = const Value.absent(),
    String? photos,
    bool? isSynced,
    DateTime? lastModified,
  }) => CaptainLogEntryRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    logDate: logDate ?? this.logDate,
    title: title ?? this.title,
    logTime: logTime.present ? logTime.value : this.logTime,
    positionLat: positionLat.present ? positionLat.value : this.positionLat,
    positionLng: positionLng.present ? positionLng.value : this.positionLng,
    weather: weather.present ? weather.value : this.weather,
    windSpeedKt: windSpeedKt.present ? windSpeedKt.value : this.windSpeedKt,
    windDir: windDir.present ? windDir.value : this.windDir,
    crewOnBoard: crewOnBoard ?? this.crewOnBoard,
    notes: notes.present ? notes.value : this.notes,
    photos: photos ?? this.photos,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  CaptainLogEntryRow copyWithCompanion(CaptainLogEntriesCompanion data) {
    return CaptainLogEntryRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      title: data.title.present ? data.title.value : this.title,
      logTime: data.logTime.present ? data.logTime.value : this.logTime,
      positionLat: data.positionLat.present
          ? data.positionLat.value
          : this.positionLat,
      positionLng: data.positionLng.present
          ? data.positionLng.value
          : this.positionLng,
      weather: data.weather.present ? data.weather.value : this.weather,
      windSpeedKt: data.windSpeedKt.present
          ? data.windSpeedKt.value
          : this.windSpeedKt,
      windDir: data.windDir.present ? data.windDir.value : this.windDir,
      crewOnBoard: data.crewOnBoard.present
          ? data.crewOnBoard.value
          : this.crewOnBoard,
      notes: data.notes.present ? data.notes.value : this.notes,
      photos: data.photos.present ? data.photos.value : this.photos,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptainLogEntryRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('logDate: $logDate, ')
          ..write('title: $title, ')
          ..write('logTime: $logTime, ')
          ..write('positionLat: $positionLat, ')
          ..write('positionLng: $positionLng, ')
          ..write('weather: $weather, ')
          ..write('windSpeedKt: $windSpeedKt, ')
          ..write('windDir: $windDir, ')
          ..write('crewOnBoard: $crewOnBoard, ')
          ..write('notes: $notes, ')
          ..write('photos: $photos, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    logDate,
    title,
    logTime,
    positionLat,
    positionLng,
    weather,
    windSpeedKt,
    windDir,
    crewOnBoard,
    notes,
    photos,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptainLogEntryRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.logDate == this.logDate &&
          other.title == this.title &&
          other.logTime == this.logTime &&
          other.positionLat == this.positionLat &&
          other.positionLng == this.positionLng &&
          other.weather == this.weather &&
          other.windSpeedKt == this.windSpeedKt &&
          other.windDir == this.windDir &&
          other.crewOnBoard == this.crewOnBoard &&
          other.notes == this.notes &&
          other.photos == this.photos &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class CaptainLogEntriesCompanion extends UpdateCompanion<CaptainLogEntryRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<DateTime> logDate;
  final Value<String> title;
  final Value<String?> logTime;
  final Value<double?> positionLat;
  final Value<double?> positionLng;
  final Value<String?> weather;
  final Value<int?> windSpeedKt;
  final Value<String?> windDir;
  final Value<String> crewOnBoard;
  final Value<String?> notes;
  final Value<String> photos;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const CaptainLogEntriesCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.title = const Value.absent(),
    this.logTime = const Value.absent(),
    this.positionLat = const Value.absent(),
    this.positionLng = const Value.absent(),
    this.weather = const Value.absent(),
    this.windSpeedKt = const Value.absent(),
    this.windDir = const Value.absent(),
    this.crewOnBoard = const Value.absent(),
    this.notes = const Value.absent(),
    this.photos = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  CaptainLogEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.title = const Value.absent(),
    this.logTime = const Value.absent(),
    this.positionLat = const Value.absent(),
    this.positionLng = const Value.absent(),
    this.weather = const Value.absent(),
    this.windSpeedKt = const Value.absent(),
    this.windDir = const Value.absent(),
    this.crewOnBoard = const Value.absent(),
    this.notes = const Value.absent(),
    this.photos = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<CaptainLogEntryRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<DateTime>? logDate,
    Expression<String>? title,
    Expression<String>? logTime,
    Expression<double>? positionLat,
    Expression<double>? positionLng,
    Expression<String>? weather,
    Expression<int>? windSpeedKt,
    Expression<String>? windDir,
    Expression<String>? crewOnBoard,
    Expression<String>? notes,
    Expression<String>? photos,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (logDate != null) 'log_date': logDate,
      if (title != null) 'title': title,
      if (logTime != null) 'log_time': logTime,
      if (positionLat != null) 'position_lat': positionLat,
      if (positionLng != null) 'position_lng': positionLng,
      if (weather != null) 'weather': weather,
      if (windSpeedKt != null) 'wind_speed_kt': windSpeedKt,
      if (windDir != null) 'wind_dir': windDir,
      if (crewOnBoard != null) 'crew_on_board': crewOnBoard,
      if (notes != null) 'notes': notes,
      if (photos != null) 'photos': photos,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  CaptainLogEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<DateTime>? logDate,
    Value<String>? title,
    Value<String?>? logTime,
    Value<double?>? positionLat,
    Value<double?>? positionLng,
    Value<String?>? weather,
    Value<int?>? windSpeedKt,
    Value<String?>? windDir,
    Value<String>? crewOnBoard,
    Value<String?>? notes,
    Value<String>? photos,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return CaptainLogEntriesCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      logDate: logDate ?? this.logDate,
      title: title ?? this.title,
      logTime: logTime ?? this.logTime,
      positionLat: positionLat ?? this.positionLat,
      positionLng: positionLng ?? this.positionLng,
      weather: weather ?? this.weather,
      windSpeedKt: windSpeedKt ?? this.windSpeedKt,
      windDir: windDir ?? this.windDir,
      crewOnBoard: crewOnBoard ?? this.crewOnBoard,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<DateTime>(logDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (logTime.present) {
      map['log_time'] = Variable<String>(logTime.value);
    }
    if (positionLat.present) {
      map['position_lat'] = Variable<double>(positionLat.value);
    }
    if (positionLng.present) {
      map['position_lng'] = Variable<double>(positionLng.value);
    }
    if (weather.present) {
      map['weather'] = Variable<String>(weather.value);
    }
    if (windSpeedKt.present) {
      map['wind_speed_kt'] = Variable<int>(windSpeedKt.value);
    }
    if (windDir.present) {
      map['wind_dir'] = Variable<String>(windDir.value);
    }
    if (crewOnBoard.present) {
      map['crew_on_board'] = Variable<String>(crewOnBoard.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photos.present) {
      map['photos'] = Variable<String>(photos.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaptainLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('logDate: $logDate, ')
          ..write('title: $title, ')
          ..write('logTime: $logTime, ')
          ..write('positionLat: $positionLat, ')
          ..write('positionLng: $positionLng, ')
          ..write('weather: $weather, ')
          ..write('windSpeedKt: $windSpeedKt, ')
          ..write('windDir: $windDir, ')
          ..write('crewOnBoard: $crewOnBoard, ')
          ..write('notes: $notes, ')
          ..write('photos: $photos, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceTasksTable extends MaintenanceTasks
    with TableInfo<$MaintenanceTasksTable, MaintenanceTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _intervalHoursMeta = const VerificationMeta(
    'intervalHours',
  );
  @override
  late final GeneratedColumn<int> intervalHours = GeneratedColumn<int>(
    'interval_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalMonthsMeta = const VerificationMeta(
    'intervalMonths',
  );
  @override
  late final GeneratedColumn<int> intervalMonths = GeneratedColumn<int>(
    'interval_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDoneHoursMeta = const VerificationMeta(
    'lastDoneHours',
  );
  @override
  late final GeneratedColumn<int> lastDoneHours = GeneratedColumn<int>(
    'last_done_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDoneDateMeta = const VerificationMeta(
    'lastDoneDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastDoneDate = GeneratedColumn<DateTime>(
    'last_done_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneByMeta = const VerificationMeta('doneBy');
  @override
  late final GeneratedColumn<String> doneBy = GeneratedColumn<String>(
    'done_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    description,
    intervalHours,
    intervalMonths,
    lastDoneHours,
    lastDoneDate,
    doneBy,
    notes,
    isHidden,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('interval_hours')) {
      context.handle(
        _intervalHoursMeta,
        intervalHours.isAcceptableOrUnknown(
          data['interval_hours']!,
          _intervalHoursMeta,
        ),
      );
    }
    if (data.containsKey('interval_months')) {
      context.handle(
        _intervalMonthsMeta,
        intervalMonths.isAcceptableOrUnknown(
          data['interval_months']!,
          _intervalMonthsMeta,
        ),
      );
    }
    if (data.containsKey('last_done_hours')) {
      context.handle(
        _lastDoneHoursMeta,
        lastDoneHours.isAcceptableOrUnknown(
          data['last_done_hours']!,
          _lastDoneHoursMeta,
        ),
      );
    }
    if (data.containsKey('last_done_date')) {
      context.handle(
        _lastDoneDateMeta,
        lastDoneDate.isAcceptableOrUnknown(
          data['last_done_date']!,
          _lastDoneDateMeta,
        ),
      );
    }
    if (data.containsKey('done_by')) {
      context.handle(
        _doneByMeta,
        doneBy.isAcceptableOrUnknown(data['done_by']!, _doneByMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      intervalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_hours'],
      ),
      intervalMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_months'],
      ),
      lastDoneHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_done_hours'],
      ),
      lastDoneDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_done_date'],
      ),
      doneBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done_by'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $MaintenanceTasksTable createAlias(String alias) {
    return $MaintenanceTasksTable(attachedDatabase, alias);
  }
}

class MaintenanceTaskRow extends DataClass
    implements Insertable<MaintenanceTaskRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String description;
  final int? intervalHours;
  final int? intervalMonths;
  final int? lastDoneHours;
  final DateTime? lastDoneDate;
  final String? doneBy;
  final String? notes;
  final bool isHidden;
  final bool isSynced;
  final DateTime lastModified;
  const MaintenanceTaskRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.description,
    this.intervalHours,
    this.intervalMonths,
    this.lastDoneHours,
    this.lastDoneDate,
    this.doneBy,
    this.notes,
    required this.isHidden,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || intervalHours != null) {
      map['interval_hours'] = Variable<int>(intervalHours);
    }
    if (!nullToAbsent || intervalMonths != null) {
      map['interval_months'] = Variable<int>(intervalMonths);
    }
    if (!nullToAbsent || lastDoneHours != null) {
      map['last_done_hours'] = Variable<int>(lastDoneHours);
    }
    if (!nullToAbsent || lastDoneDate != null) {
      map['last_done_date'] = Variable<DateTime>(lastDoneDate);
    }
    if (!nullToAbsent || doneBy != null) {
      map['done_by'] = Variable<String>(doneBy);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  MaintenanceTasksCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceTasksCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      description: Value(description),
      intervalHours: intervalHours == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalHours),
      intervalMonths: intervalMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalMonths),
      lastDoneHours: lastDoneHours == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDoneHours),
      lastDoneDate: lastDoneDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDoneDate),
      doneBy: doneBy == null && nullToAbsent
          ? const Value.absent()
          : Value(doneBy),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isHidden: Value(isHidden),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory MaintenanceTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceTaskRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      description: serializer.fromJson<String>(json['description']),
      intervalHours: serializer.fromJson<int?>(json['intervalHours']),
      intervalMonths: serializer.fromJson<int?>(json['intervalMonths']),
      lastDoneHours: serializer.fromJson<int?>(json['lastDoneHours']),
      lastDoneDate: serializer.fromJson<DateTime?>(json['lastDoneDate']),
      doneBy: serializer.fromJson<String?>(json['doneBy']),
      notes: serializer.fromJson<String?>(json['notes']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'description': serializer.toJson<String>(description),
      'intervalHours': serializer.toJson<int?>(intervalHours),
      'intervalMonths': serializer.toJson<int?>(intervalMonths),
      'lastDoneHours': serializer.toJson<int?>(lastDoneHours),
      'lastDoneDate': serializer.toJson<DateTime?>(lastDoneDate),
      'doneBy': serializer.toJson<String?>(doneBy),
      'notes': serializer.toJson<String?>(notes),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  MaintenanceTaskRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? description,
    Value<int?> intervalHours = const Value.absent(),
    Value<int?> intervalMonths = const Value.absent(),
    Value<int?> lastDoneHours = const Value.absent(),
    Value<DateTime?> lastDoneDate = const Value.absent(),
    Value<String?> doneBy = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isHidden,
    bool? isSynced,
    DateTime? lastModified,
  }) => MaintenanceTaskRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    description: description ?? this.description,
    intervalHours: intervalHours.present
        ? intervalHours.value
        : this.intervalHours,
    intervalMonths: intervalMonths.present
        ? intervalMonths.value
        : this.intervalMonths,
    lastDoneHours: lastDoneHours.present
        ? lastDoneHours.value
        : this.lastDoneHours,
    lastDoneDate: lastDoneDate.present ? lastDoneDate.value : this.lastDoneDate,
    doneBy: doneBy.present ? doneBy.value : this.doneBy,
    notes: notes.present ? notes.value : this.notes,
    isHidden: isHidden ?? this.isHidden,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  MaintenanceTaskRow copyWithCompanion(MaintenanceTasksCompanion data) {
    return MaintenanceTaskRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      description: data.description.present
          ? data.description.value
          : this.description,
      intervalHours: data.intervalHours.present
          ? data.intervalHours.value
          : this.intervalHours,
      intervalMonths: data.intervalMonths.present
          ? data.intervalMonths.value
          : this.intervalMonths,
      lastDoneHours: data.lastDoneHours.present
          ? data.lastDoneHours.value
          : this.lastDoneHours,
      lastDoneDate: data.lastDoneDate.present
          ? data.lastDoneDate.value
          : this.lastDoneDate,
      doneBy: data.doneBy.present ? data.doneBy.value : this.doneBy,
      notes: data.notes.present ? data.notes.value : this.notes,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceTaskRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('description: $description, ')
          ..write('intervalHours: $intervalHours, ')
          ..write('intervalMonths: $intervalMonths, ')
          ..write('lastDoneHours: $lastDoneHours, ')
          ..write('lastDoneDate: $lastDoneDate, ')
          ..write('doneBy: $doneBy, ')
          ..write('notes: $notes, ')
          ..write('isHidden: $isHidden, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    description,
    intervalHours,
    intervalMonths,
    lastDoneHours,
    lastDoneDate,
    doneBy,
    notes,
    isHidden,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceTaskRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.description == this.description &&
          other.intervalHours == this.intervalHours &&
          other.intervalMonths == this.intervalMonths &&
          other.lastDoneHours == this.lastDoneHours &&
          other.lastDoneDate == this.lastDoneDate &&
          other.doneBy == this.doneBy &&
          other.notes == this.notes &&
          other.isHidden == this.isHidden &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class MaintenanceTasksCompanion extends UpdateCompanion<MaintenanceTaskRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> description;
  final Value<int?> intervalHours;
  final Value<int?> intervalMonths;
  final Value<int?> lastDoneHours;
  final Value<DateTime?> lastDoneDate;
  final Value<String?> doneBy;
  final Value<String?> notes;
  final Value<bool> isHidden;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const MaintenanceTasksCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.description = const Value.absent(),
    this.intervalHours = const Value.absent(),
    this.intervalMonths = const Value.absent(),
    this.lastDoneHours = const Value.absent(),
    this.lastDoneDate = const Value.absent(),
    this.doneBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  MaintenanceTasksCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.description = const Value.absent(),
    this.intervalHours = const Value.absent(),
    this.intervalMonths = const Value.absent(),
    this.lastDoneHours = const Value.absent(),
    this.lastDoneDate = const Value.absent(),
    this.doneBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<MaintenanceTaskRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? description,
    Expression<int>? intervalHours,
    Expression<int>? intervalMonths,
    Expression<int>? lastDoneHours,
    Expression<DateTime>? lastDoneDate,
    Expression<String>? doneBy,
    Expression<String>? notes,
    Expression<bool>? isHidden,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (description != null) 'description': description,
      if (intervalHours != null) 'interval_hours': intervalHours,
      if (intervalMonths != null) 'interval_months': intervalMonths,
      if (lastDoneHours != null) 'last_done_hours': lastDoneHours,
      if (lastDoneDate != null) 'last_done_date': lastDoneDate,
      if (doneBy != null) 'done_by': doneBy,
      if (notes != null) 'notes': notes,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  MaintenanceTasksCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? description,
    Value<int?>? intervalHours,
    Value<int?>? intervalMonths,
    Value<int?>? lastDoneHours,
    Value<DateTime?>? lastDoneDate,
    Value<String?>? doneBy,
    Value<String?>? notes,
    Value<bool>? isHidden,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return MaintenanceTasksCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      description: description ?? this.description,
      intervalHours: intervalHours ?? this.intervalHours,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      lastDoneHours: lastDoneHours ?? this.lastDoneHours,
      lastDoneDate: lastDoneDate ?? this.lastDoneDate,
      doneBy: doneBy ?? this.doneBy,
      notes: notes ?? this.notes,
      isHidden: isHidden ?? this.isHidden,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (intervalHours.present) {
      map['interval_hours'] = Variable<int>(intervalHours.value);
    }
    if (intervalMonths.present) {
      map['interval_months'] = Variable<int>(intervalMonths.value);
    }
    if (lastDoneHours.present) {
      map['last_done_hours'] = Variable<int>(lastDoneHours.value);
    }
    if (lastDoneDate.present) {
      map['last_done_date'] = Variable<DateTime>(lastDoneDate.value);
    }
    if (doneBy.present) {
      map['done_by'] = Variable<String>(doneBy.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceTasksCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('description: $description, ')
          ..write('intervalHours: $intervalHours, ')
          ..write('intervalMonths: $intervalMonths, ')
          ..write('lastDoneHours: $lastDoneHours, ')
          ..write('lastDoneDate: $lastDoneDate, ')
          ..write('doneBy: $doneBy, ')
          ..write('notes: $notes, ')
          ..write('isHidden: $isHidden, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $ShoppingCategoriesTable extends ShoppingCategories
    with TableInfo<$ShoppingCategoriesTable, ShoppingCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    name,
    sortOrder,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $ShoppingCategoriesTable createAlias(String alias) {
    return $ShoppingCategoriesTable(attachedDatabase, alias);
  }
}

class ShoppingCategoryRow extends DataClass
    implements Insertable<ShoppingCategoryRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String name;
  final int sortOrder;
  final bool isSynced;
  final DateTime lastModified;
  const ShoppingCategoryRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.name,
    required this.sortOrder,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  ShoppingCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ShoppingCategoriesCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory ShoppingCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingCategoryRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  ShoppingCategoryRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? name,
    int? sortOrder,
    bool? isSynced,
    DateTime? lastModified,
  }) => ShoppingCategoryRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  ShoppingCategoryRow copyWithCompanion(ShoppingCategoriesCompanion data) {
    return ShoppingCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingCategoryRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    name,
    sortOrder,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingCategoryRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class ShoppingCategoriesCompanion extends UpdateCompanion<ShoppingCategoryRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const ShoppingCategoriesCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  ShoppingCategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<ShoppingCategoryRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  ShoppingCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return ShoppingCategoriesCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $ShoppingItemsTable extends ShoppingItems
    with TableInfo<$ShoppingItemsTable, ShoppingItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categorySupabaseIdMeta =
      const VerificationMeta('categorySupabaseId');
  @override
  late final GeneratedColumn<String> categorySupabaseId =
      GeneratedColumn<String>(
        'category_supabase_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBoughtMeta = const VerificationMeta(
    'isBought',
  );
  @override
  late final GeneratedColumn<bool> isBought = GeneratedColumn<bool>(
    'is_bought',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bought" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBundledMeta = const VerificationMeta(
    'isBundled',
  );
  @override
  late final GeneratedColumn<bool> isBundled = GeneratedColumn<bool>(
    'is_bundled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bundled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('spares'),
  );
  static const VerificationMeta _lastPurchasePriceMeta = const VerificationMeta(
    'lastPurchasePrice',
  );
  @override
  late final GeneratedColumn<double> lastPurchasePrice =
      GeneratedColumn<double>(
        'last_purchase_price',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPurchasePlaceMeta = const VerificationMeta(
    'lastPurchasePlace',
  );
  @override
  late final GeneratedColumn<String> lastPurchasePlace =
      GeneratedColumn<String>(
        'last_purchase_place',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _userPhotoUrlMeta = const VerificationMeta(
    'userPhotoUrl',
  );
  @override
  late final GeneratedColumn<String> userPhotoUrl = GeneratedColumn<String>(
    'user_photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    categorySupabaseId,
    name,
    quantity,
    unit,
    isBought,
    isBundled,
    isSynced,
    isHidden,
    notes,
    origin,
    lastPurchasePrice,
    lastPurchasePlace,
    userPhotoUrl,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('category_supabase_id')) {
      context.handle(
        _categorySupabaseIdMeta,
        categorySupabaseId.isAcceptableOrUnknown(
          data['category_supabase_id']!,
          _categorySupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_bought')) {
      context.handle(
        _isBoughtMeta,
        isBought.isAcceptableOrUnknown(data['is_bought']!, _isBoughtMeta),
      );
    }
    if (data.containsKey('is_bundled')) {
      context.handle(
        _isBundledMeta,
        isBundled.isAcceptableOrUnknown(data['is_bundled']!, _isBundledMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('last_purchase_price')) {
      context.handle(
        _lastPurchasePriceMeta,
        lastPurchasePrice.isAcceptableOrUnknown(
          data['last_purchase_price']!,
          _lastPurchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('last_purchase_place')) {
      context.handle(
        _lastPurchasePlaceMeta,
        lastPurchasePlace.isAcceptableOrUnknown(
          data['last_purchase_place']!,
          _lastPurchasePlaceMeta,
        ),
      );
    }
    if (data.containsKey('user_photo_url')) {
      context.handle(
        _userPhotoUrlMeta,
        userPhotoUrl.isAcceptableOrUnknown(
          data['user_photo_url']!,
          _userPhotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      ),
      categorySupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      isBought: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bought'],
      )!,
      isBundled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bundled'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      lastPurchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_purchase_price'],
      ),
      lastPurchasePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_purchase_place'],
      ),
      userPhotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_photo_url'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $ShoppingItemsTable createAlias(String alias) {
    return $ShoppingItemsTable(attachedDatabase, alias);
  }
}

class ShoppingItemRow extends DataClass implements Insertable<ShoppingItemRow> {
  final int id;
  final String supabaseId;
  final String? boatSupabaseId;
  final String categorySupabaseId;
  final String name;
  final int quantity;
  final String? unit;
  final bool isBought;
  final bool isBundled;
  final bool isSynced;
  final bool isHidden;
  final String? notes;
  final String origin;
  final double? lastPurchasePrice;
  final String? lastPurchasePlace;
  final String? userPhotoUrl;
  final DateTime lastModified;
  const ShoppingItemRow({
    required this.id,
    required this.supabaseId,
    this.boatSupabaseId,
    required this.categorySupabaseId,
    required this.name,
    required this.quantity,
    this.unit,
    required this.isBought,
    required this.isBundled,
    required this.isSynced,
    required this.isHidden,
    this.notes,
    required this.origin,
    this.lastPurchasePrice,
    this.lastPurchasePlace,
    this.userPhotoUrl,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    if (!nullToAbsent || boatSupabaseId != null) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    }
    map['category_supabase_id'] = Variable<String>(categorySupabaseId);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['is_bought'] = Variable<bool>(isBought);
    map['is_bundled'] = Variable<bool>(isBundled);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_hidden'] = Variable<bool>(isHidden);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || lastPurchasePrice != null) {
      map['last_purchase_price'] = Variable<double>(lastPurchasePrice);
    }
    if (!nullToAbsent || lastPurchasePlace != null) {
      map['last_purchase_place'] = Variable<String>(lastPurchasePlace);
    }
    if (!nullToAbsent || userPhotoUrl != null) {
      map['user_photo_url'] = Variable<String>(userPhotoUrl);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  ShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingItemsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: boatSupabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(boatSupabaseId),
      categorySupabaseId: Value(categorySupabaseId),
      name: Value(name),
      quantity: Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      isBought: Value(isBought),
      isBundled: Value(isBundled),
      isSynced: Value(isSynced),
      isHidden: Value(isHidden),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      origin: Value(origin),
      lastPurchasePrice: lastPurchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchasePrice),
      lastPurchasePlace: lastPurchasePlace == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchasePlace),
      userPhotoUrl: userPhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(userPhotoUrl),
      lastModified: Value(lastModified),
    );
  }

  factory ShoppingItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingItemRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String?>(json['boatSupabaseId']),
      categorySupabaseId: serializer.fromJson<String>(
        json['categorySupabaseId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      isBought: serializer.fromJson<bool>(json['isBought']),
      isBundled: serializer.fromJson<bool>(json['isBundled']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      notes: serializer.fromJson<String?>(json['notes']),
      origin: serializer.fromJson<String>(json['origin']),
      lastPurchasePrice: serializer.fromJson<double?>(
        json['lastPurchasePrice'],
      ),
      lastPurchasePlace: serializer.fromJson<String?>(
        json['lastPurchasePlace'],
      ),
      userPhotoUrl: serializer.fromJson<String?>(json['userPhotoUrl']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String?>(boatSupabaseId),
      'categorySupabaseId': serializer.toJson<String>(categorySupabaseId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'isBought': serializer.toJson<bool>(isBought),
      'isBundled': serializer.toJson<bool>(isBundled),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isHidden': serializer.toJson<bool>(isHidden),
      'notes': serializer.toJson<String?>(notes),
      'origin': serializer.toJson<String>(origin),
      'lastPurchasePrice': serializer.toJson<double?>(lastPurchasePrice),
      'lastPurchasePlace': serializer.toJson<String?>(lastPurchasePlace),
      'userPhotoUrl': serializer.toJson<String?>(userPhotoUrl),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  ShoppingItemRow copyWith({
    int? id,
    String? supabaseId,
    Value<String?> boatSupabaseId = const Value.absent(),
    String? categorySupabaseId,
    String? name,
    int? quantity,
    Value<String?> unit = const Value.absent(),
    bool? isBought,
    bool? isBundled,
    bool? isSynced,
    bool? isHidden,
    Value<String?> notes = const Value.absent(),
    String? origin,
    Value<double?> lastPurchasePrice = const Value.absent(),
    Value<String?> lastPurchasePlace = const Value.absent(),
    Value<String?> userPhotoUrl = const Value.absent(),
    DateTime? lastModified,
  }) => ShoppingItemRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId.present
        ? boatSupabaseId.value
        : this.boatSupabaseId,
    categorySupabaseId: categorySupabaseId ?? this.categorySupabaseId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit.present ? unit.value : this.unit,
    isBought: isBought ?? this.isBought,
    isBundled: isBundled ?? this.isBundled,
    isSynced: isSynced ?? this.isSynced,
    isHidden: isHidden ?? this.isHidden,
    notes: notes.present ? notes.value : this.notes,
    origin: origin ?? this.origin,
    lastPurchasePrice: lastPurchasePrice.present
        ? lastPurchasePrice.value
        : this.lastPurchasePrice,
    lastPurchasePlace: lastPurchasePlace.present
        ? lastPurchasePlace.value
        : this.lastPurchasePlace,
    userPhotoUrl: userPhotoUrl.present ? userPhotoUrl.value : this.userPhotoUrl,
    lastModified: lastModified ?? this.lastModified,
  );
  ShoppingItemRow copyWithCompanion(ShoppingItemsCompanion data) {
    return ShoppingItemRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      categorySupabaseId: data.categorySupabaseId.present
          ? data.categorySupabaseId.value
          : this.categorySupabaseId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      isBought: data.isBought.present ? data.isBought.value : this.isBought,
      isBundled: data.isBundled.present ? data.isBundled.value : this.isBundled,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      notes: data.notes.present ? data.notes.value : this.notes,
      origin: data.origin.present ? data.origin.value : this.origin,
      lastPurchasePrice: data.lastPurchasePrice.present
          ? data.lastPurchasePrice.value
          : this.lastPurchasePrice,
      lastPurchasePlace: data.lastPurchasePlace.present
          ? data.lastPurchasePlace.value
          : this.lastPurchasePlace,
      userPhotoUrl: data.userPhotoUrl.present
          ? data.userPhotoUrl.value
          : this.userPhotoUrl,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('categorySupabaseId: $categorySupabaseId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isBought: $isBought, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('isHidden: $isHidden, ')
          ..write('notes: $notes, ')
          ..write('origin: $origin, ')
          ..write('lastPurchasePrice: $lastPurchasePrice, ')
          ..write('lastPurchasePlace: $lastPurchasePlace, ')
          ..write('userPhotoUrl: $userPhotoUrl, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    categorySupabaseId,
    name,
    quantity,
    unit,
    isBought,
    isBundled,
    isSynced,
    isHidden,
    notes,
    origin,
    lastPurchasePrice,
    lastPurchasePlace,
    userPhotoUrl,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingItemRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.categorySupabaseId == this.categorySupabaseId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.isBought == this.isBought &&
          other.isBundled == this.isBundled &&
          other.isSynced == this.isSynced &&
          other.isHidden == this.isHidden &&
          other.notes == this.notes &&
          other.origin == this.origin &&
          other.lastPurchasePrice == this.lastPurchasePrice &&
          other.lastPurchasePlace == this.lastPurchasePlace &&
          other.userPhotoUrl == this.userPhotoUrl &&
          other.lastModified == this.lastModified);
}

class ShoppingItemsCompanion extends UpdateCompanion<ShoppingItemRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String?> boatSupabaseId;
  final Value<String> categorySupabaseId;
  final Value<String> name;
  final Value<int> quantity;
  final Value<String?> unit;
  final Value<bool> isBought;
  final Value<bool> isBundled;
  final Value<bool> isSynced;
  final Value<bool> isHidden;
  final Value<String?> notes;
  final Value<String> origin;
  final Value<double?> lastPurchasePrice;
  final Value<String?> lastPurchasePlace;
  final Value<String?> userPhotoUrl;
  final Value<DateTime> lastModified;
  const ShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.categorySupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.notes = const Value.absent(),
    this.origin = const Value.absent(),
    this.lastPurchasePrice = const Value.absent(),
    this.lastPurchasePlace = const Value.absent(),
    this.userPhotoUrl = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  ShoppingItemsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.categorySupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.notes = const Value.absent(),
    this.origin = const Value.absent(),
    this.lastPurchasePrice = const Value.absent(),
    this.lastPurchasePlace = const Value.absent(),
    this.userPhotoUrl = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<ShoppingItemRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? categorySupabaseId,
    Expression<String>? name,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<bool>? isBought,
    Expression<bool>? isBundled,
    Expression<bool>? isSynced,
    Expression<bool>? isHidden,
    Expression<String>? notes,
    Expression<String>? origin,
    Expression<double>? lastPurchasePrice,
    Expression<String>? lastPurchasePlace,
    Expression<String>? userPhotoUrl,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (categorySupabaseId != null)
        'category_supabase_id': categorySupabaseId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (isBought != null) 'is_bought': isBought,
      if (isBundled != null) 'is_bundled': isBundled,
      if (isSynced != null) 'is_synced': isSynced,
      if (isHidden != null) 'is_hidden': isHidden,
      if (notes != null) 'notes': notes,
      if (origin != null) 'origin': origin,
      if (lastPurchasePrice != null) 'last_purchase_price': lastPurchasePrice,
      if (lastPurchasePlace != null) 'last_purchase_place': lastPurchasePlace,
      if (userPhotoUrl != null) 'user_photo_url': userPhotoUrl,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  ShoppingItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String?>? boatSupabaseId,
    Value<String>? categorySupabaseId,
    Value<String>? name,
    Value<int>? quantity,
    Value<String?>? unit,
    Value<bool>? isBought,
    Value<bool>? isBundled,
    Value<bool>? isSynced,
    Value<bool>? isHidden,
    Value<String?>? notes,
    Value<String>? origin,
    Value<double?>? lastPurchasePrice,
    Value<String?>? lastPurchasePlace,
    Value<String?>? userPhotoUrl,
    Value<DateTime>? lastModified,
  }) {
    return ShoppingItemsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      categorySupabaseId: categorySupabaseId ?? this.categorySupabaseId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isBought: isBought ?? this.isBought,
      isBundled: isBundled ?? this.isBundled,
      isSynced: isSynced ?? this.isSynced,
      isHidden: isHidden ?? this.isHidden,
      notes: notes ?? this.notes,
      origin: origin ?? this.origin,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      lastPurchasePlace: lastPurchasePlace ?? this.lastPurchasePlace,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (categorySupabaseId.present) {
      map['category_supabase_id'] = Variable<String>(categorySupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isBought.present) {
      map['is_bought'] = Variable<bool>(isBought.value);
    }
    if (isBundled.present) {
      map['is_bundled'] = Variable<bool>(isBundled.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (lastPurchasePrice.present) {
      map['last_purchase_price'] = Variable<double>(lastPurchasePrice.value);
    }
    if (lastPurchasePlace.present) {
      map['last_purchase_place'] = Variable<String>(lastPurchasePlace.value);
    }
    if (userPhotoUrl.present) {
      map['user_photo_url'] = Variable<String>(userPhotoUrl.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('categorySupabaseId: $categorySupabaseId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isBought: $isBought, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('isHidden: $isHidden, ')
          ..write('notes: $notes, ')
          ..write('origin: $origin, ')
          ..write('lastPurchasePrice: $lastPurchasePrice, ')
          ..write('lastPurchasePlace: $lastPurchasePlace, ')
          ..write('userPhotoUrl: $userPhotoUrl, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $ChecklistGroupsTable extends ChecklistGroups
    with TableInfo<$ChecklistGroupsTable, ChecklistGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _appTypeMeta = const VerificationMeta(
    'appType',
  );
  @override
  late final GeneratedColumn<String> appType = GeneratedColumn<String>(
    'app_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isBoughtMeta = const VerificationMeta(
    'isBought',
  );
  @override
  late final GeneratedColumn<bool> isBought = GeneratedColumn<bool>(
    'is_bought',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bought" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBundledMeta = const VerificationMeta(
    'isBundled',
  );
  @override
  late final GeneratedColumn<bool> isBundled = GeneratedColumn<bool>(
    'is_bundled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bundled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isExpandedMeta = const VerificationMeta(
    'isExpanded',
  );
  @override
  late final GeneratedColumn<bool> isExpanded = GeneratedColumn<bool>(
    'is_expanded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expanded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastPurchasePriceMeta = const VerificationMeta(
    'lastPurchasePrice',
  );
  @override
  late final GeneratedColumn<double> lastPurchasePrice =
      GeneratedColumn<double>(
        'last_purchase_price',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _communityTemplateIdMeta =
      const VerificationMeta('communityTemplateId');
  @override
  late final GeneratedColumn<String> communityTemplateId =
      GeneratedColumn<String>(
        'community_template_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _communityTemplateVersionMeta =
      const VerificationMeta('communityTemplateVersion');
  @override
  late final GeneratedColumn<int> communityTemplateVersion =
      GeneratedColumn<int>(
        'community_template_version',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    appType,
    title,
    description,
    iconName,
    isBought,
    isBundled,
    isExpanded,
    isHidden,
    isSynced,
    lastPurchasePrice,
    notes,
    origin,
    sortOrder,
    lastModified,
    communityTemplateId,
    communityTemplateVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('app_type')) {
      context.handle(
        _appTypeMeta,
        appType.isAcceptableOrUnknown(data['app_type']!, _appTypeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('is_bought')) {
      context.handle(
        _isBoughtMeta,
        isBought.isAcceptableOrUnknown(data['is_bought']!, _isBoughtMeta),
      );
    }
    if (data.containsKey('is_bundled')) {
      context.handle(
        _isBundledMeta,
        isBundled.isAcceptableOrUnknown(data['is_bundled']!, _isBundledMeta),
      );
    }
    if (data.containsKey('is_expanded')) {
      context.handle(
        _isExpandedMeta,
        isExpanded.isAcceptableOrUnknown(data['is_expanded']!, _isExpandedMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_purchase_price')) {
      context.handle(
        _lastPurchasePriceMeta,
        lastPurchasePrice.isAcceptableOrUnknown(
          data['last_purchase_price']!,
          _lastPurchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('community_template_id')) {
      context.handle(
        _communityTemplateIdMeta,
        communityTemplateId.isAcceptableOrUnknown(
          data['community_template_id']!,
          _communityTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('community_template_version')) {
      context.handle(
        _communityTemplateVersionMeta,
        communityTemplateVersion.isAcceptableOrUnknown(
          data['community_template_version']!,
          _communityTemplateVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      appType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      isBought: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bought'],
      )!,
      isBundled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bundled'],
      )!,
      isExpanded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expanded'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastPurchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_purchase_price'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      communityTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}community_template_id'],
      ),
      communityTemplateVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}community_template_version'],
      ),
    );
  }

  @override
  $ChecklistGroupsTable createAlias(String alias) {
    return $ChecklistGroupsTable(attachedDatabase, alias);
  }
}

class ChecklistGroupRow extends DataClass
    implements Insertable<ChecklistGroupRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String appType;
  final String title;
  final String? description;
  final String iconName;
  final bool isBought;
  final bool isBundled;
  final bool isExpanded;
  final bool isHidden;
  final bool isSynced;
  final double? lastPurchasePrice;
  final String notes;
  final String origin;
  final int sortOrder;
  final DateTime lastModified;
  final String? communityTemplateId;
  final int? communityTemplateVersion;
  const ChecklistGroupRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.appType,
    required this.title,
    this.description,
    required this.iconName,
    required this.isBought,
    required this.isBundled,
    required this.isExpanded,
    required this.isHidden,
    required this.isSynced,
    this.lastPurchasePrice,
    required this.notes,
    required this.origin,
    required this.sortOrder,
    required this.lastModified,
    this.communityTemplateId,
    this.communityTemplateVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['app_type'] = Variable<String>(appType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['icon_name'] = Variable<String>(iconName);
    map['is_bought'] = Variable<bool>(isBought);
    map['is_bundled'] = Variable<bool>(isBundled);
    map['is_expanded'] = Variable<bool>(isExpanded);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastPurchasePrice != null) {
      map['last_purchase_price'] = Variable<double>(lastPurchasePrice);
    }
    map['notes'] = Variable<String>(notes);
    map['origin'] = Variable<String>(origin);
    map['sort_order'] = Variable<int>(sortOrder);
    map['last_modified'] = Variable<DateTime>(lastModified);
    if (!nullToAbsent || communityTemplateId != null) {
      map['community_template_id'] = Variable<String>(communityTemplateId);
    }
    if (!nullToAbsent || communityTemplateVersion != null) {
      map['community_template_version'] = Variable<int>(
        communityTemplateVersion,
      );
    }
    return map;
  }

  ChecklistGroupsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistGroupsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      appType: Value(appType),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      iconName: Value(iconName),
      isBought: Value(isBought),
      isBundled: Value(isBundled),
      isExpanded: Value(isExpanded),
      isHidden: Value(isHidden),
      isSynced: Value(isSynced),
      lastPurchasePrice: lastPurchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchasePrice),
      notes: Value(notes),
      origin: Value(origin),
      sortOrder: Value(sortOrder),
      lastModified: Value(lastModified),
      communityTemplateId: communityTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(communityTemplateId),
      communityTemplateVersion: communityTemplateVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(communityTemplateVersion),
    );
  }

  factory ChecklistGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistGroupRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      appType: serializer.fromJson<String>(json['appType']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      iconName: serializer.fromJson<String>(json['iconName']),
      isBought: serializer.fromJson<bool>(json['isBought']),
      isBundled: serializer.fromJson<bool>(json['isBundled']),
      isExpanded: serializer.fromJson<bool>(json['isExpanded']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastPurchasePrice: serializer.fromJson<double?>(
        json['lastPurchasePrice'],
      ),
      notes: serializer.fromJson<String>(json['notes']),
      origin: serializer.fromJson<String>(json['origin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      communityTemplateId: serializer.fromJson<String?>(
        json['communityTemplateId'],
      ),
      communityTemplateVersion: serializer.fromJson<int?>(
        json['communityTemplateVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'appType': serializer.toJson<String>(appType),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'iconName': serializer.toJson<String>(iconName),
      'isBought': serializer.toJson<bool>(isBought),
      'isBundled': serializer.toJson<bool>(isBundled),
      'isExpanded': serializer.toJson<bool>(isExpanded),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastPurchasePrice': serializer.toJson<double?>(lastPurchasePrice),
      'notes': serializer.toJson<String>(notes),
      'origin': serializer.toJson<String>(origin),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'communityTemplateId': serializer.toJson<String?>(communityTemplateId),
      'communityTemplateVersion': serializer.toJson<int?>(
        communityTemplateVersion,
      ),
    };
  }

  ChecklistGroupRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? appType,
    String? title,
    Value<String?> description = const Value.absent(),
    String? iconName,
    bool? isBought,
    bool? isBundled,
    bool? isExpanded,
    bool? isHidden,
    bool? isSynced,
    Value<double?> lastPurchasePrice = const Value.absent(),
    String? notes,
    String? origin,
    int? sortOrder,
    DateTime? lastModified,
    Value<String?> communityTemplateId = const Value.absent(),
    Value<int?> communityTemplateVersion = const Value.absent(),
  }) => ChecklistGroupRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    appType: appType ?? this.appType,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    iconName: iconName ?? this.iconName,
    isBought: isBought ?? this.isBought,
    isBundled: isBundled ?? this.isBundled,
    isExpanded: isExpanded ?? this.isExpanded,
    isHidden: isHidden ?? this.isHidden,
    isSynced: isSynced ?? this.isSynced,
    lastPurchasePrice: lastPurchasePrice.present
        ? lastPurchasePrice.value
        : this.lastPurchasePrice,
    notes: notes ?? this.notes,
    origin: origin ?? this.origin,
    sortOrder: sortOrder ?? this.sortOrder,
    lastModified: lastModified ?? this.lastModified,
    communityTemplateId: communityTemplateId.present
        ? communityTemplateId.value
        : this.communityTemplateId,
    communityTemplateVersion: communityTemplateVersion.present
        ? communityTemplateVersion.value
        : this.communityTemplateVersion,
  );
  ChecklistGroupRow copyWithCompanion(ChecklistGroupsCompanion data) {
    return ChecklistGroupRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      appType: data.appType.present ? data.appType.value : this.appType,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      isBought: data.isBought.present ? data.isBought.value : this.isBought,
      isBundled: data.isBundled.present ? data.isBundled.value : this.isBundled,
      isExpanded: data.isExpanded.present
          ? data.isExpanded.value
          : this.isExpanded,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastPurchasePrice: data.lastPurchasePrice.present
          ? data.lastPurchasePrice.value
          : this.lastPurchasePrice,
      notes: data.notes.present ? data.notes.value : this.notes,
      origin: data.origin.present ? data.origin.value : this.origin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      communityTemplateId: data.communityTemplateId.present
          ? data.communityTemplateId.value
          : this.communityTemplateId,
      communityTemplateVersion: data.communityTemplateVersion.present
          ? data.communityTemplateVersion.value
          : this.communityTemplateVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistGroupRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('appType: $appType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconName: $iconName, ')
          ..write('isBought: $isBought, ')
          ..write('isBundled: $isBundled, ')
          ..write('isExpanded: $isExpanded, ')
          ..write('isHidden: $isHidden, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastPurchasePrice: $lastPurchasePrice, ')
          ..write('notes: $notes, ')
          ..write('origin: $origin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastModified: $lastModified, ')
          ..write('communityTemplateId: $communityTemplateId, ')
          ..write('communityTemplateVersion: $communityTemplateVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    boatSupabaseId,
    appType,
    title,
    description,
    iconName,
    isBought,
    isBundled,
    isExpanded,
    isHidden,
    isSynced,
    lastPurchasePrice,
    notes,
    origin,
    sortOrder,
    lastModified,
    communityTemplateId,
    communityTemplateVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistGroupRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.appType == this.appType &&
          other.title == this.title &&
          other.description == this.description &&
          other.iconName == this.iconName &&
          other.isBought == this.isBought &&
          other.isBundled == this.isBundled &&
          other.isExpanded == this.isExpanded &&
          other.isHidden == this.isHidden &&
          other.isSynced == this.isSynced &&
          other.lastPurchasePrice == this.lastPurchasePrice &&
          other.notes == this.notes &&
          other.origin == this.origin &&
          other.sortOrder == this.sortOrder &&
          other.lastModified == this.lastModified &&
          other.communityTemplateId == this.communityTemplateId &&
          other.communityTemplateVersion == this.communityTemplateVersion);
}

class ChecklistGroupsCompanion extends UpdateCompanion<ChecklistGroupRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> appType;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> iconName;
  final Value<bool> isBought;
  final Value<bool> isBundled;
  final Value<bool> isExpanded;
  final Value<bool> isHidden;
  final Value<bool> isSynced;
  final Value<double?> lastPurchasePrice;
  final Value<String> notes;
  final Value<String> origin;
  final Value<int> sortOrder;
  final Value<DateTime> lastModified;
  final Value<String?> communityTemplateId;
  final Value<int?> communityTemplateVersion;
  const ChecklistGroupsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.appType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.iconName = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isExpanded = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastPurchasePrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.origin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.communityTemplateId = const Value.absent(),
    this.communityTemplateVersion = const Value.absent(),
  });
  ChecklistGroupsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.appType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.iconName = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isExpanded = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastPurchasePrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.origin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.communityTemplateId = const Value.absent(),
    this.communityTemplateVersion = const Value.absent(),
  });
  static Insertable<ChecklistGroupRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? appType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? iconName,
    Expression<bool>? isBought,
    Expression<bool>? isBundled,
    Expression<bool>? isExpanded,
    Expression<bool>? isHidden,
    Expression<bool>? isSynced,
    Expression<double>? lastPurchasePrice,
    Expression<String>? notes,
    Expression<String>? origin,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastModified,
    Expression<String>? communityTemplateId,
    Expression<int>? communityTemplateVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (appType != null) 'app_type': appType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (iconName != null) 'icon_name': iconName,
      if (isBought != null) 'is_bought': isBought,
      if (isBundled != null) 'is_bundled': isBundled,
      if (isExpanded != null) 'is_expanded': isExpanded,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastPurchasePrice != null) 'last_purchase_price': lastPurchasePrice,
      if (notes != null) 'notes': notes,
      if (origin != null) 'origin': origin,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastModified != null) 'last_modified': lastModified,
      if (communityTemplateId != null)
        'community_template_id': communityTemplateId,
      if (communityTemplateVersion != null)
        'community_template_version': communityTemplateVersion,
    });
  }

  ChecklistGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? appType,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? iconName,
    Value<bool>? isBought,
    Value<bool>? isBundled,
    Value<bool>? isExpanded,
    Value<bool>? isHidden,
    Value<bool>? isSynced,
    Value<double?>? lastPurchasePrice,
    Value<String>? notes,
    Value<String>? origin,
    Value<int>? sortOrder,
    Value<DateTime>? lastModified,
    Value<String?>? communityTemplateId,
    Value<int?>? communityTemplateVersion,
  }) {
    return ChecklistGroupsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      appType: appType ?? this.appType,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isBought: isBought ?? this.isBought,
      isBundled: isBundled ?? this.isBundled,
      isExpanded: isExpanded ?? this.isExpanded,
      isHidden: isHidden ?? this.isHidden,
      isSynced: isSynced ?? this.isSynced,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      notes: notes ?? this.notes,
      origin: origin ?? this.origin,
      sortOrder: sortOrder ?? this.sortOrder,
      lastModified: lastModified ?? this.lastModified,
      communityTemplateId: communityTemplateId ?? this.communityTemplateId,
      communityTemplateVersion:
          communityTemplateVersion ?? this.communityTemplateVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (appType.present) {
      map['app_type'] = Variable<String>(appType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (isBought.present) {
      map['is_bought'] = Variable<bool>(isBought.value);
    }
    if (isBundled.present) {
      map['is_bundled'] = Variable<bool>(isBundled.value);
    }
    if (isExpanded.present) {
      map['is_expanded'] = Variable<bool>(isExpanded.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastPurchasePrice.present) {
      map['last_purchase_price'] = Variable<double>(lastPurchasePrice.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (communityTemplateId.present) {
      map['community_template_id'] = Variable<String>(
        communityTemplateId.value,
      );
    }
    if (communityTemplateVersion.present) {
      map['community_template_version'] = Variable<int>(
        communityTemplateVersion.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistGroupsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('appType: $appType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconName: $iconName, ')
          ..write('isBought: $isBought, ')
          ..write('isBundled: $isBundled, ')
          ..write('isExpanded: $isExpanded, ')
          ..write('isHidden: $isHidden, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastPurchasePrice: $lastPurchasePrice, ')
          ..write('notes: $notes, ')
          ..write('origin: $origin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastModified: $lastModified, ')
          ..write('communityTemplateId: $communityTemplateId, ')
          ..write('communityTemplateVersion: $communityTemplateVersion')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems
    with TableInfo<$ChecklistItemsTable, ChecklistItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _groupSupabaseIdMeta = const VerificationMeta(
    'groupSupabaseId',
  );
  @override
  late final GeneratedColumn<String> groupSupabaseId = GeneratedColumn<String>(
    'group_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetNameMeta = const VerificationMeta(
    'assetName',
  );
  @override
  late final GeneratedColumn<String> assetName = GeneratedColumn<String>(
    'asset_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userPhotoUrlMeta = const VerificationMeta(
    'userPhotoUrl',
  );
  @override
  late final GeneratedColumn<String> userPhotoUrl = GeneratedColumn<String>(
    'user_photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userPhotoPathMeta = const VerificationMeta(
    'userPhotoPath',
  );
  @override
  late final GeneratedColumn<String> userPhotoPath = GeneratedColumn<String>(
    'user_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionHistoryMeta = const VerificationMeta(
    'completionHistory',
  );
  @override
  late final GeneratedColumn<String> completionHistory =
      GeneratedColumn<String>(
        'completion_history',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _isBundledMeta = const VerificationMeta(
    'isBundled',
  );
  @override
  late final GeneratedColumn<bool> isBundled = GeneratedColumn<bool>(
    'is_bundled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bundled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPermanentlyDeletedMeta =
      const VerificationMeta('isPermanentlyDeleted');
  @override
  late final GeneratedColumn<bool> isPermanentlyDeleted = GeneratedColumn<bool>(
    'is_permanently_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_permanently_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    groupSupabaseId,
    title,
    name,
    description,
    assetName,
    photoUrl,
    userPhotoUrl,
    userPhotoPath,
    notes,
    isCompleted,
    completedAt,
    completionHistory,
    isBundled,
    isHidden,
    isPermanentlyDeleted,
    isSynced,
    createdAt,
    sortOrder,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('group_supabase_id')) {
      context.handle(
        _groupSupabaseIdMeta,
        groupSupabaseId.isAcceptableOrUnknown(
          data['group_supabase_id']!,
          _groupSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('asset_name')) {
      context.handle(
        _assetNameMeta,
        assetName.isAcceptableOrUnknown(data['asset_name']!, _assetNameMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('user_photo_url')) {
      context.handle(
        _userPhotoUrlMeta,
        userPhotoUrl.isAcceptableOrUnknown(
          data['user_photo_url']!,
          _userPhotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('user_photo_path')) {
      context.handle(
        _userPhotoPathMeta,
        userPhotoPath.isAcceptableOrUnknown(
          data['user_photo_path']!,
          _userPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completion_history')) {
      context.handle(
        _completionHistoryMeta,
        completionHistory.isAcceptableOrUnknown(
          data['completion_history']!,
          _completionHistoryMeta,
        ),
      );
    }
    if (data.containsKey('is_bundled')) {
      context.handle(
        _isBundledMeta,
        isBundled.isAcceptableOrUnknown(data['is_bundled']!, _isBundledMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_permanently_deleted')) {
      context.handle(
        _isPermanentlyDeletedMeta,
        isPermanentlyDeleted.isAcceptableOrUnknown(
          data['is_permanently_deleted']!,
          _isPermanentlyDeletedMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      groupSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_supabase_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      assetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_name'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      userPhotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_photo_url'],
      ),
      userPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_photo_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      completionHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_history'],
      )!,
      isBundled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bundled'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isPermanentlyDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_permanently_deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItemRow extends DataClass
    implements Insertable<ChecklistItemRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String groupSupabaseId;
  final String title;
  final String name;
  final String? description;
  final String? assetName;
  final String? photoUrl;
  final String? userPhotoUrl;
  final String? userPhotoPath;
  final String? notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final String completionHistory;
  final bool isBundled;
  final bool isHidden;
  final bool isPermanentlyDeleted;
  final bool isSynced;
  final DateTime createdAt;
  final int sortOrder;
  final DateTime lastModified;
  const ChecklistItemRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.groupSupabaseId,
    required this.title,
    required this.name,
    this.description,
    this.assetName,
    this.photoUrl,
    this.userPhotoUrl,
    this.userPhotoPath,
    this.notes,
    required this.isCompleted,
    this.completedAt,
    required this.completionHistory,
    required this.isBundled,
    required this.isHidden,
    required this.isPermanentlyDeleted,
    required this.isSynced,
    required this.createdAt,
    required this.sortOrder,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['group_supabase_id'] = Variable<String>(groupSupabaseId);
    map['title'] = Variable<String>(title);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || assetName != null) {
      map['asset_name'] = Variable<String>(assetName);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || userPhotoUrl != null) {
      map['user_photo_url'] = Variable<String>(userPhotoUrl);
    }
    if (!nullToAbsent || userPhotoPath != null) {
      map['user_photo_path'] = Variable<String>(userPhotoPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['completion_history'] = Variable<String>(completionHistory);
    map['is_bundled'] = Variable<bool>(isBundled);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_permanently_deleted'] = Variable<bool>(isPermanentlyDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      groupSupabaseId: Value(groupSupabaseId),
      title: Value(title),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      assetName: assetName == null && nullToAbsent
          ? const Value.absent()
          : Value(assetName),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      userPhotoUrl: userPhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(userPhotoUrl),
      userPhotoPath: userPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(userPhotoPath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completionHistory: Value(completionHistory),
      isBundled: Value(isBundled),
      isHidden: Value(isHidden),
      isPermanentlyDeleted: Value(isPermanentlyDeleted),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
      lastModified: Value(lastModified),
    );
  }

  factory ChecklistItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItemRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      groupSupabaseId: serializer.fromJson<String>(json['groupSupabaseId']),
      title: serializer.fromJson<String>(json['title']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      assetName: serializer.fromJson<String?>(json['assetName']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      userPhotoUrl: serializer.fromJson<String?>(json['userPhotoUrl']),
      userPhotoPath: serializer.fromJson<String?>(json['userPhotoPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completionHistory: serializer.fromJson<String>(json['completionHistory']),
      isBundled: serializer.fromJson<bool>(json['isBundled']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isPermanentlyDeleted: serializer.fromJson<bool>(
        json['isPermanentlyDeleted'],
      ),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'groupSupabaseId': serializer.toJson<String>(groupSupabaseId),
      'title': serializer.toJson<String>(title),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'assetName': serializer.toJson<String?>(assetName),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'userPhotoUrl': serializer.toJson<String?>(userPhotoUrl),
      'userPhotoPath': serializer.toJson<String?>(userPhotoPath),
      'notes': serializer.toJson<String?>(notes),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completionHistory': serializer.toJson<String>(completionHistory),
      'isBundled': serializer.toJson<bool>(isBundled),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isPermanentlyDeleted': serializer.toJson<bool>(isPermanentlyDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  ChecklistItemRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? groupSupabaseId,
    String? title,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> assetName = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> userPhotoUrl = const Value.absent(),
    Value<String?> userPhotoPath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    String? completionHistory,
    bool? isBundled,
    bool? isHidden,
    bool? isPermanentlyDeleted,
    bool? isSynced,
    DateTime? createdAt,
    int? sortOrder,
    DateTime? lastModified,
  }) => ChecklistItemRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    groupSupabaseId: groupSupabaseId ?? this.groupSupabaseId,
    title: title ?? this.title,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    assetName: assetName.present ? assetName.value : this.assetName,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    userPhotoUrl: userPhotoUrl.present ? userPhotoUrl.value : this.userPhotoUrl,
    userPhotoPath: userPhotoPath.present
        ? userPhotoPath.value
        : this.userPhotoPath,
    notes: notes.present ? notes.value : this.notes,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completionHistory: completionHistory ?? this.completionHistory,
    isBundled: isBundled ?? this.isBundled,
    isHidden: isHidden ?? this.isHidden,
    isPermanentlyDeleted: isPermanentlyDeleted ?? this.isPermanentlyDeleted,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
    lastModified: lastModified ?? this.lastModified,
  );
  ChecklistItemRow copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItemRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      groupSupabaseId: data.groupSupabaseId.present
          ? data.groupSupabaseId.value
          : this.groupSupabaseId,
      title: data.title.present ? data.title.value : this.title,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      assetName: data.assetName.present ? data.assetName.value : this.assetName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      userPhotoUrl: data.userPhotoUrl.present
          ? data.userPhotoUrl.value
          : this.userPhotoUrl,
      userPhotoPath: data.userPhotoPath.present
          ? data.userPhotoPath.value
          : this.userPhotoPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completionHistory: data.completionHistory.present
          ? data.completionHistory.value
          : this.completionHistory,
      isBundled: data.isBundled.present ? data.isBundled.value : this.isBundled,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isPermanentlyDeleted: data.isPermanentlyDeleted.present
          ? data.isPermanentlyDeleted.value
          : this.isPermanentlyDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('groupSupabaseId: $groupSupabaseId, ')
          ..write('title: $title, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('assetName: $assetName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('userPhotoUrl: $userPhotoUrl, ')
          ..write('userPhotoPath: $userPhotoPath, ')
          ..write('notes: $notes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionHistory: $completionHistory, ')
          ..write('isBundled: $isBundled, ')
          ..write('isHidden: $isHidden, ')
          ..write('isPermanentlyDeleted: $isPermanentlyDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    supabaseId,
    boatSupabaseId,
    groupSupabaseId,
    title,
    name,
    description,
    assetName,
    photoUrl,
    userPhotoUrl,
    userPhotoPath,
    notes,
    isCompleted,
    completedAt,
    completionHistory,
    isBundled,
    isHidden,
    isPermanentlyDeleted,
    isSynced,
    createdAt,
    sortOrder,
    lastModified,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItemRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.groupSupabaseId == this.groupSupabaseId &&
          other.title == this.title &&
          other.name == this.name &&
          other.description == this.description &&
          other.assetName == this.assetName &&
          other.photoUrl == this.photoUrl &&
          other.userPhotoUrl == this.userPhotoUrl &&
          other.userPhotoPath == this.userPhotoPath &&
          other.notes == this.notes &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.completionHistory == this.completionHistory &&
          other.isBundled == this.isBundled &&
          other.isHidden == this.isHidden &&
          other.isPermanentlyDeleted == this.isPermanentlyDeleted &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder &&
          other.lastModified == this.lastModified);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItemRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> groupSupabaseId;
  final Value<String> title;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> assetName;
  final Value<String?> photoUrl;
  final Value<String?> userPhotoUrl;
  final Value<String?> userPhotoPath;
  final Value<String?> notes;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<String> completionHistory;
  final Value<bool> isBundled;
  final Value<bool> isHidden;
  final Value<bool> isPermanentlyDeleted;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<DateTime> lastModified;
  const ChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.groupSupabaseId = const Value.absent(),
    this.title = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.assetName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.userPhotoUrl = const Value.absent(),
    this.userPhotoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionHistory = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isPermanentlyDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.groupSupabaseId = const Value.absent(),
    this.title = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.assetName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.userPhotoUrl = const Value.absent(),
    this.userPhotoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionHistory = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isPermanentlyDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<ChecklistItemRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? groupSupabaseId,
    Expression<String>? title,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? assetName,
    Expression<String>? photoUrl,
    Expression<String>? userPhotoUrl,
    Expression<String>? userPhotoPath,
    Expression<String>? notes,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<String>? completionHistory,
    Expression<bool>? isBundled,
    Expression<bool>? isHidden,
    Expression<bool>? isPermanentlyDeleted,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (groupSupabaseId != null) 'group_supabase_id': groupSupabaseId,
      if (title != null) 'title': title,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (assetName != null) 'asset_name': assetName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (userPhotoUrl != null) 'user_photo_url': userPhotoUrl,
      if (userPhotoPath != null) 'user_photo_path': userPhotoPath,
      if (notes != null) 'notes': notes,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (completionHistory != null) 'completion_history': completionHistory,
      if (isBundled != null) 'is_bundled': isBundled,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isPermanentlyDeleted != null)
        'is_permanently_deleted': isPermanentlyDeleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  ChecklistItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? groupSupabaseId,
    Value<String>? title,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? assetName,
    Value<String?>? photoUrl,
    Value<String?>? userPhotoUrl,
    Value<String?>? userPhotoPath,
    Value<String?>? notes,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<String>? completionHistory,
    Value<bool>? isBundled,
    Value<bool>? isHidden,
    Value<bool>? isPermanentlyDeleted,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<DateTime>? lastModified,
  }) {
    return ChecklistItemsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      groupSupabaseId: groupSupabaseId ?? this.groupSupabaseId,
      title: title ?? this.title,
      name: name ?? this.name,
      description: description ?? this.description,
      assetName: assetName ?? this.assetName,
      photoUrl: photoUrl ?? this.photoUrl,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userPhotoPath: userPhotoPath ?? this.userPhotoPath,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completionHistory: completionHistory ?? this.completionHistory,
      isBundled: isBundled ?? this.isBundled,
      isHidden: isHidden ?? this.isHidden,
      isPermanentlyDeleted: isPermanentlyDeleted ?? this.isPermanentlyDeleted,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (groupSupabaseId.present) {
      map['group_supabase_id'] = Variable<String>(groupSupabaseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (assetName.present) {
      map['asset_name'] = Variable<String>(assetName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (userPhotoUrl.present) {
      map['user_photo_url'] = Variable<String>(userPhotoUrl.value);
    }
    if (userPhotoPath.present) {
      map['user_photo_path'] = Variable<String>(userPhotoPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completionHistory.present) {
      map['completion_history'] = Variable<String>(completionHistory.value);
    }
    if (isBundled.present) {
      map['is_bundled'] = Variable<bool>(isBundled.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isPermanentlyDeleted.present) {
      map['is_permanently_deleted'] = Variable<bool>(
        isPermanentlyDeleted.value,
      );
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('groupSupabaseId: $groupSupabaseId, ')
          ..write('title: $title, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('assetName: $assetName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('userPhotoUrl: $userPhotoUrl, ')
          ..write('userPhotoPath: $userPhotoPath, ')
          ..write('notes: $notes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionHistory: $completionHistory, ')
          ..write('isBundled: $isBundled, ')
          ..write('isHidden: $isHidden, ')
          ..write('isPermanentlyDeleted: $isPermanentlyDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeTypeMeta = const VerificationMeta(
    'recipeType',
  );
  @override
  late final GeneratedColumn<String> recipeType = GeneratedColumn<String>(
    'recipe_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isBundledMeta = const VerificationMeta(
    'isBundled',
  );
  @override
  late final GeneratedColumn<bool> isBundled = GeneratedColumn<bool>(
    'is_bundled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bundled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _missingIngredientCountMeta =
      const VerificationMeta('missingIngredientCount');
  @override
  late final GeneratedColumn<int> missingIngredientCount = GeneratedColumn<int>(
    'missing_ingredient_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavouriteMeta = const VerificationMeta(
    'isFavourite',
  );
  @override
  late final GeneratedColumn<bool> isFavourite = GeneratedColumn<bool>(
    'is_favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favourite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _glasswareMeta = const VerificationMeta(
    'glassware',
  );
  @override
  late final GeneratedColumn<String> glassware = GeneratedColumn<String>(
    'glassware',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prepMinutesMeta = const VerificationMeta(
    'prepMinutes',
  );
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
    'prep_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cookMinutesMeta = const VerificationMeta(
    'cookMinutes',
  );
  @override
  late final GeneratedColumn<int> cookMinutes = GeneratedColumn<int>(
    'cook_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storyMeta = const VerificationMeta('story');
  @override
  late final GeneratedColumn<String> story = GeneratedColumn<String>(
    'story',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tastingLogMeta = const VerificationMeta(
    'tastingLog',
  );
  @override
  late final GeneratedColumn<String> tastingLog = GeneratedColumn<String>(
    'tasting_log',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cuisineMeta = const VerificationMeta(
    'cuisine',
  );
  @override
  late final GeneratedColumn<String> cuisine = GeneratedColumn<String>(
    'cuisine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _flavorProfilesMeta = const VerificationMeta(
    'flavorProfiles',
  );
  @override
  late final GeneratedColumn<String> flavorProfiles = GeneratedColumn<String>(
    'flavor_profiles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cookingMethodMeta = const VerificationMeta(
    'cookingMethod',
  );
  @override
  late final GeneratedColumn<String> cookingMethod = GeneratedColumn<String>(
    'cooking_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageAssetMeta = const VerificationMeta(
    'imageAsset',
  );
  @override
  late final GeneratedColumn<String> imageAsset = GeneratedColumn<String>(
    'image_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    name,
    description,
    instructions,
    recipeType,
    createdAt,
    isBundled,
    isSynced,
    missingIngredientCount,
    isFavourite,
    glassware,
    prepMinutes,
    cookMinutes,
    story,
    tastingLog,
    cuisine,
    flavorProfiles,
    cookingMethod,
    imageAsset,
    localPath,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('recipe_type')) {
      context.handle(
        _recipeTypeMeta,
        recipeType.isAcceptableOrUnknown(data['recipe_type']!, _recipeTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_bundled')) {
      context.handle(
        _isBundledMeta,
        isBundled.isAcceptableOrUnknown(data['is_bundled']!, _isBundledMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('missing_ingredient_count')) {
      context.handle(
        _missingIngredientCountMeta,
        missingIngredientCount.isAcceptableOrUnknown(
          data['missing_ingredient_count']!,
          _missingIngredientCountMeta,
        ),
      );
    }
    if (data.containsKey('is_favourite')) {
      context.handle(
        _isFavouriteMeta,
        isFavourite.isAcceptableOrUnknown(
          data['is_favourite']!,
          _isFavouriteMeta,
        ),
      );
    }
    if (data.containsKey('glassware')) {
      context.handle(
        _glasswareMeta,
        glassware.isAcceptableOrUnknown(data['glassware']!, _glasswareMeta),
      );
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
        _prepMinutesMeta,
        prepMinutes.isAcceptableOrUnknown(
          data['prep_minutes']!,
          _prepMinutesMeta,
        ),
      );
    }
    if (data.containsKey('cook_minutes')) {
      context.handle(
        _cookMinutesMeta,
        cookMinutes.isAcceptableOrUnknown(
          data['cook_minutes']!,
          _cookMinutesMeta,
        ),
      );
    }
    if (data.containsKey('story')) {
      context.handle(
        _storyMeta,
        story.isAcceptableOrUnknown(data['story']!, _storyMeta),
      );
    }
    if (data.containsKey('tasting_log')) {
      context.handle(
        _tastingLogMeta,
        tastingLog.isAcceptableOrUnknown(data['tasting_log']!, _tastingLogMeta),
      );
    }
    if (data.containsKey('cuisine')) {
      context.handle(
        _cuisineMeta,
        cuisine.isAcceptableOrUnknown(data['cuisine']!, _cuisineMeta),
      );
    }
    if (data.containsKey('flavor_profiles')) {
      context.handle(
        _flavorProfilesMeta,
        flavorProfiles.isAcceptableOrUnknown(
          data['flavor_profiles']!,
          _flavorProfilesMeta,
        ),
      );
    }
    if (data.containsKey('cooking_method')) {
      context.handle(
        _cookingMethodMeta,
        cookingMethod.isAcceptableOrUnknown(
          data['cooking_method']!,
          _cookingMethodMeta,
        ),
      );
    }
    if (data.containsKey('image_asset')) {
      context.handle(
        _imageAssetMeta,
        imageAsset.isAcceptableOrUnknown(data['image_asset']!, _imageAssetMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      recipeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isBundled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bundled'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      missingIngredientCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}missing_ingredient_count'],
      )!,
      isFavourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favourite'],
      )!,
      glassware: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glassware'],
      ),
      prepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_minutes'],
      ),
      cookMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cook_minutes'],
      ),
      story: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story'],
      ),
      tastingLog: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tasting_log'],
      )!,
      cuisine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuisine'],
      )!,
      flavorProfiles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flavor_profiles'],
      )!,
      cookingMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooking_method'],
      ),
      imageAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_asset'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class RecipeRow extends DataClass implements Insertable<RecipeRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String name;
  final String? description;
  final String? instructions;
  final String recipeType;
  final DateTime createdAt;
  final bool isBundled;
  final bool isSynced;
  final int missingIngredientCount;
  final bool isFavourite;
  final String? glassware;
  final int? prepMinutes;
  final int? cookMinutes;
  final String? story;
  final String tastingLog;

  /// JSON string list, e.g. `["Tiki","Classic"]`. Pre-v2 rows may hold a
  /// plain string; repositories coerce both shapes.
  final String cuisine;
  final String flavorProfiles;
  final String? cookingMethod;

  /// Bundled asset path under `assets/` (offline). e.g. `cocktails/mai_tai.jpg`.
  final String? imageAsset;

  /// User photo on device (app documents path).
  final String? localPath;
  final DateTime lastModified;
  const RecipeRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.name,
    this.description,
    this.instructions,
    required this.recipeType,
    required this.createdAt,
    required this.isBundled,
    required this.isSynced,
    required this.missingIngredientCount,
    required this.isFavourite,
    this.glassware,
    this.prepMinutes,
    this.cookMinutes,
    this.story,
    required this.tastingLog,
    required this.cuisine,
    required this.flavorProfiles,
    this.cookingMethod,
    this.imageAsset,
    this.localPath,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    map['recipe_type'] = Variable<String>(recipeType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_bundled'] = Variable<bool>(isBundled);
    map['is_synced'] = Variable<bool>(isSynced);
    map['missing_ingredient_count'] = Variable<int>(missingIngredientCount);
    map['is_favourite'] = Variable<bool>(isFavourite);
    if (!nullToAbsent || glassware != null) {
      map['glassware'] = Variable<String>(glassware);
    }
    if (!nullToAbsent || prepMinutes != null) {
      map['prep_minutes'] = Variable<int>(prepMinutes);
    }
    if (!nullToAbsent || cookMinutes != null) {
      map['cook_minutes'] = Variable<int>(cookMinutes);
    }
    if (!nullToAbsent || story != null) {
      map['story'] = Variable<String>(story);
    }
    map['tasting_log'] = Variable<String>(tastingLog);
    map['cuisine'] = Variable<String>(cuisine);
    map['flavor_profiles'] = Variable<String>(flavorProfiles);
    if (!nullToAbsent || cookingMethod != null) {
      map['cooking_method'] = Variable<String>(cookingMethod);
    }
    if (!nullToAbsent || imageAsset != null) {
      map['image_asset'] = Variable<String>(imageAsset);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      recipeType: Value(recipeType),
      createdAt: Value(createdAt),
      isBundled: Value(isBundled),
      isSynced: Value(isSynced),
      missingIngredientCount: Value(missingIngredientCount),
      isFavourite: Value(isFavourite),
      glassware: glassware == null && nullToAbsent
          ? const Value.absent()
          : Value(glassware),
      prepMinutes: prepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(prepMinutes),
      cookMinutes: cookMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(cookMinutes),
      story: story == null && nullToAbsent
          ? const Value.absent()
          : Value(story),
      tastingLog: Value(tastingLog),
      cuisine: Value(cuisine),
      flavorProfiles: Value(flavorProfiles),
      cookingMethod: cookingMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(cookingMethod),
      imageAsset: imageAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(imageAsset),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      lastModified: Value(lastModified),
    );
  }

  factory RecipeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      recipeType: serializer.fromJson<String>(json['recipeType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isBundled: serializer.fromJson<bool>(json['isBundled']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      missingIngredientCount: serializer.fromJson<int>(
        json['missingIngredientCount'],
      ),
      isFavourite: serializer.fromJson<bool>(json['isFavourite']),
      glassware: serializer.fromJson<String?>(json['glassware']),
      prepMinutes: serializer.fromJson<int?>(json['prepMinutes']),
      cookMinutes: serializer.fromJson<int?>(json['cookMinutes']),
      story: serializer.fromJson<String?>(json['story']),
      tastingLog: serializer.fromJson<String>(json['tastingLog']),
      cuisine: serializer.fromJson<String>(json['cuisine']),
      flavorProfiles: serializer.fromJson<String>(json['flavorProfiles']),
      cookingMethod: serializer.fromJson<String?>(json['cookingMethod']),
      imageAsset: serializer.fromJson<String?>(json['imageAsset']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'instructions': serializer.toJson<String?>(instructions),
      'recipeType': serializer.toJson<String>(recipeType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isBundled': serializer.toJson<bool>(isBundled),
      'isSynced': serializer.toJson<bool>(isSynced),
      'missingIngredientCount': serializer.toJson<int>(missingIngredientCount),
      'isFavourite': serializer.toJson<bool>(isFavourite),
      'glassware': serializer.toJson<String?>(glassware),
      'prepMinutes': serializer.toJson<int?>(prepMinutes),
      'cookMinutes': serializer.toJson<int?>(cookMinutes),
      'story': serializer.toJson<String?>(story),
      'tastingLog': serializer.toJson<String>(tastingLog),
      'cuisine': serializer.toJson<String>(cuisine),
      'flavorProfiles': serializer.toJson<String>(flavorProfiles),
      'cookingMethod': serializer.toJson<String?>(cookingMethod),
      'imageAsset': serializer.toJson<String?>(imageAsset),
      'localPath': serializer.toJson<String?>(localPath),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  RecipeRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> instructions = const Value.absent(),
    String? recipeType,
    DateTime? createdAt,
    bool? isBundled,
    bool? isSynced,
    int? missingIngredientCount,
    bool? isFavourite,
    Value<String?> glassware = const Value.absent(),
    Value<int?> prepMinutes = const Value.absent(),
    Value<int?> cookMinutes = const Value.absent(),
    Value<String?> story = const Value.absent(),
    String? tastingLog,
    String? cuisine,
    String? flavorProfiles,
    Value<String?> cookingMethod = const Value.absent(),
    Value<String?> imageAsset = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    DateTime? lastModified,
  }) => RecipeRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    instructions: instructions.present ? instructions.value : this.instructions,
    recipeType: recipeType ?? this.recipeType,
    createdAt: createdAt ?? this.createdAt,
    isBundled: isBundled ?? this.isBundled,
    isSynced: isSynced ?? this.isSynced,
    missingIngredientCount:
        missingIngredientCount ?? this.missingIngredientCount,
    isFavourite: isFavourite ?? this.isFavourite,
    glassware: glassware.present ? glassware.value : this.glassware,
    prepMinutes: prepMinutes.present ? prepMinutes.value : this.prepMinutes,
    cookMinutes: cookMinutes.present ? cookMinutes.value : this.cookMinutes,
    story: story.present ? story.value : this.story,
    tastingLog: tastingLog ?? this.tastingLog,
    cuisine: cuisine ?? this.cuisine,
    flavorProfiles: flavorProfiles ?? this.flavorProfiles,
    cookingMethod: cookingMethod.present
        ? cookingMethod.value
        : this.cookingMethod,
    imageAsset: imageAsset.present ? imageAsset.value : this.imageAsset,
    localPath: localPath.present ? localPath.value : this.localPath,
    lastModified: lastModified ?? this.lastModified,
  );
  RecipeRow copyWithCompanion(RecipesCompanion data) {
    return RecipeRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      recipeType: data.recipeType.present
          ? data.recipeType.value
          : this.recipeType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isBundled: data.isBundled.present ? data.isBundled.value : this.isBundled,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      missingIngredientCount: data.missingIngredientCount.present
          ? data.missingIngredientCount.value
          : this.missingIngredientCount,
      isFavourite: data.isFavourite.present
          ? data.isFavourite.value
          : this.isFavourite,
      glassware: data.glassware.present ? data.glassware.value : this.glassware,
      prepMinutes: data.prepMinutes.present
          ? data.prepMinutes.value
          : this.prepMinutes,
      cookMinutes: data.cookMinutes.present
          ? data.cookMinutes.value
          : this.cookMinutes,
      story: data.story.present ? data.story.value : this.story,
      tastingLog: data.tastingLog.present
          ? data.tastingLog.value
          : this.tastingLog,
      cuisine: data.cuisine.present ? data.cuisine.value : this.cuisine,
      flavorProfiles: data.flavorProfiles.present
          ? data.flavorProfiles.value
          : this.flavorProfiles,
      cookingMethod: data.cookingMethod.present
          ? data.cookingMethod.value
          : this.cookingMethod,
      imageAsset: data.imageAsset.present
          ? data.imageAsset.value
          : this.imageAsset,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('instructions: $instructions, ')
          ..write('recipeType: $recipeType, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('missingIngredientCount: $missingIngredientCount, ')
          ..write('isFavourite: $isFavourite, ')
          ..write('glassware: $glassware, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('story: $story, ')
          ..write('tastingLog: $tastingLog, ')
          ..write('cuisine: $cuisine, ')
          ..write('flavorProfiles: $flavorProfiles, ')
          ..write('cookingMethod: $cookingMethod, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('localPath: $localPath, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    supabaseId,
    boatSupabaseId,
    name,
    description,
    instructions,
    recipeType,
    createdAt,
    isBundled,
    isSynced,
    missingIngredientCount,
    isFavourite,
    glassware,
    prepMinutes,
    cookMinutes,
    story,
    tastingLog,
    cuisine,
    flavorProfiles,
    cookingMethod,
    imageAsset,
    localPath,
    lastModified,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.name == this.name &&
          other.description == this.description &&
          other.instructions == this.instructions &&
          other.recipeType == this.recipeType &&
          other.createdAt == this.createdAt &&
          other.isBundled == this.isBundled &&
          other.isSynced == this.isSynced &&
          other.missingIngredientCount == this.missingIngredientCount &&
          other.isFavourite == this.isFavourite &&
          other.glassware == this.glassware &&
          other.prepMinutes == this.prepMinutes &&
          other.cookMinutes == this.cookMinutes &&
          other.story == this.story &&
          other.tastingLog == this.tastingLog &&
          other.cuisine == this.cuisine &&
          other.flavorProfiles == this.flavorProfiles &&
          other.cookingMethod == this.cookingMethod &&
          other.imageAsset == this.imageAsset &&
          other.localPath == this.localPath &&
          other.lastModified == this.lastModified);
}

class RecipesCompanion extends UpdateCompanion<RecipeRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> instructions;
  final Value<String> recipeType;
  final Value<DateTime> createdAt;
  final Value<bool> isBundled;
  final Value<bool> isSynced;
  final Value<int> missingIngredientCount;
  final Value<bool> isFavourite;
  final Value<String?> glassware;
  final Value<int?> prepMinutes;
  final Value<int?> cookMinutes;
  final Value<String?> story;
  final Value<String> tastingLog;
  final Value<String> cuisine;
  final Value<String> flavorProfiles;
  final Value<String?> cookingMethod;
  final Value<String?> imageAsset;
  final Value<String?> localPath;
  final Value<DateTime> lastModified;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.instructions = const Value.absent(),
    this.recipeType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.missingIngredientCount = const Value.absent(),
    this.isFavourite = const Value.absent(),
    this.glassware = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.story = const Value.absent(),
    this.tastingLog = const Value.absent(),
    this.cuisine = const Value.absent(),
    this.flavorProfiles = const Value.absent(),
    this.cookingMethod = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.localPath = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.instructions = const Value.absent(),
    this.recipeType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.missingIngredientCount = const Value.absent(),
    this.isFavourite = const Value.absent(),
    this.glassware = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.story = const Value.absent(),
    this.tastingLog = const Value.absent(),
    this.cuisine = const Value.absent(),
    this.flavorProfiles = const Value.absent(),
    this.cookingMethod = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.localPath = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<RecipeRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? instructions,
    Expression<String>? recipeType,
    Expression<DateTime>? createdAt,
    Expression<bool>? isBundled,
    Expression<bool>? isSynced,
    Expression<int>? missingIngredientCount,
    Expression<bool>? isFavourite,
    Expression<String>? glassware,
    Expression<int>? prepMinutes,
    Expression<int>? cookMinutes,
    Expression<String>? story,
    Expression<String>? tastingLog,
    Expression<String>? cuisine,
    Expression<String>? flavorProfiles,
    Expression<String>? cookingMethod,
    Expression<String>? imageAsset,
    Expression<String>? localPath,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (recipeType != null) 'recipe_type': recipeType,
      if (createdAt != null) 'created_at': createdAt,
      if (isBundled != null) 'is_bundled': isBundled,
      if (isSynced != null) 'is_synced': isSynced,
      if (missingIngredientCount != null)
        'missing_ingredient_count': missingIngredientCount,
      if (isFavourite != null) 'is_favourite': isFavourite,
      if (glassware != null) 'glassware': glassware,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (cookMinutes != null) 'cook_minutes': cookMinutes,
      if (story != null) 'story': story,
      if (tastingLog != null) 'tasting_log': tastingLog,
      if (cuisine != null) 'cuisine': cuisine,
      if (flavorProfiles != null) 'flavor_profiles': flavorProfiles,
      if (cookingMethod != null) 'cooking_method': cookingMethod,
      if (imageAsset != null) 'image_asset': imageAsset,
      if (localPath != null) 'local_path': localPath,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  RecipesCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? instructions,
    Value<String>? recipeType,
    Value<DateTime>? createdAt,
    Value<bool>? isBundled,
    Value<bool>? isSynced,
    Value<int>? missingIngredientCount,
    Value<bool>? isFavourite,
    Value<String?>? glassware,
    Value<int?>? prepMinutes,
    Value<int?>? cookMinutes,
    Value<String?>? story,
    Value<String>? tastingLog,
    Value<String>? cuisine,
    Value<String>? flavorProfiles,
    Value<String?>? cookingMethod,
    Value<String?>? imageAsset,
    Value<String?>? localPath,
    Value<DateTime>? lastModified,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      recipeType: recipeType ?? this.recipeType,
      createdAt: createdAt ?? this.createdAt,
      isBundled: isBundled ?? this.isBundled,
      isSynced: isSynced ?? this.isSynced,
      missingIngredientCount:
          missingIngredientCount ?? this.missingIngredientCount,
      isFavourite: isFavourite ?? this.isFavourite,
      glassware: glassware ?? this.glassware,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      story: story ?? this.story,
      tastingLog: tastingLog ?? this.tastingLog,
      cuisine: cuisine ?? this.cuisine,
      flavorProfiles: flavorProfiles ?? this.flavorProfiles,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      imageAsset: imageAsset ?? this.imageAsset,
      localPath: localPath ?? this.localPath,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (recipeType.present) {
      map['recipe_type'] = Variable<String>(recipeType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isBundled.present) {
      map['is_bundled'] = Variable<bool>(isBundled.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (missingIngredientCount.present) {
      map['missing_ingredient_count'] = Variable<int>(
        missingIngredientCount.value,
      );
    }
    if (isFavourite.present) {
      map['is_favourite'] = Variable<bool>(isFavourite.value);
    }
    if (glassware.present) {
      map['glassware'] = Variable<String>(glassware.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (cookMinutes.present) {
      map['cook_minutes'] = Variable<int>(cookMinutes.value);
    }
    if (story.present) {
      map['story'] = Variable<String>(story.value);
    }
    if (tastingLog.present) {
      map['tasting_log'] = Variable<String>(tastingLog.value);
    }
    if (cuisine.present) {
      map['cuisine'] = Variable<String>(cuisine.value);
    }
    if (flavorProfiles.present) {
      map['flavor_profiles'] = Variable<String>(flavorProfiles.value);
    }
    if (cookingMethod.present) {
      map['cooking_method'] = Variable<String>(cookingMethod.value);
    }
    if (imageAsset.present) {
      map['image_asset'] = Variable<String>(imageAsset.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('instructions: $instructions, ')
          ..write('recipeType: $recipeType, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('missingIngredientCount: $missingIngredientCount, ')
          ..write('isFavourite: $isFavourite, ')
          ..write('glassware: $glassware, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('story: $story, ')
          ..write('tastingLog: $tastingLog, ')
          ..write('cuisine: $cuisine, ')
          ..write('flavorProfiles: $flavorProfiles, ')
          ..write('cookingMethod: $cookingMethod, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('localPath: $localPath, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $RecipeIngredientsTable extends RecipeIngredients
    with TableInfo<$RecipeIngredientsTable, RecipeIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recipeSupabaseIdMeta = const VerificationMeta(
    'recipeSupabaseId',
  );
  @override
  late final GeneratedColumn<String> recipeSupabaseId = GeneratedColumn<String>(
    'recipe_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _substituteMeta = const VerificationMeta(
    'substitute',
  );
  @override
  late final GeneratedColumn<String> substitute = GeneratedColumn<String>(
    'substitute',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGarnishMeta = const VerificationMeta(
    'isGarnish',
  );
  @override
  late final GeneratedColumn<bool> isGarnish = GeneratedColumn<bool>(
    'is_garnish',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_garnish" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _garnishNotesMeta = const VerificationMeta(
    'garnishNotes',
  );
  @override
  late final GeneratedColumn<String> garnishNotes = GeneratedColumn<String>(
    'garnish_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOptionalMeta = const VerificationMeta(
    'isOptional',
  );
  @override
  late final GeneratedColumn<bool> isOptional = GeneratedColumn<bool>(
    'is_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_optional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    recipeSupabaseId,
    name,
    quantity,
    unit,
    substitute,
    isGarnish,
    garnishNotes,
    isOptional,
    photoUrl,
    sortOrder,
    isSynced,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('recipe_supabase_id')) {
      context.handle(
        _recipeSupabaseIdMeta,
        recipeSupabaseId.isAcceptableOrUnknown(
          data['recipe_supabase_id']!,
          _recipeSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('substitute')) {
      context.handle(
        _substituteMeta,
        substitute.isAcceptableOrUnknown(data['substitute']!, _substituteMeta),
      );
    }
    if (data.containsKey('is_garnish')) {
      context.handle(
        _isGarnishMeta,
        isGarnish.isAcceptableOrUnknown(data['is_garnish']!, _isGarnishMeta),
      );
    }
    if (data.containsKey('garnish_notes')) {
      context.handle(
        _garnishNotesMeta,
        garnishNotes.isAcceptableOrUnknown(
          data['garnish_notes']!,
          _garnishNotesMeta,
        ),
      );
    }
    if (data.containsKey('is_optional')) {
      context.handle(
        _isOptionalMeta,
        isOptional.isAcceptableOrUnknown(data['is_optional']!, _isOptionalMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      recipeSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      substitute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute'],
      ),
      isGarnish: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_garnish'],
      )!,
      garnishNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}garnish_notes'],
      ),
      isOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_optional'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $RecipeIngredientsTable createAlias(String alias) {
    return $RecipeIngredientsTable(attachedDatabase, alias);
  }
}

class RecipeIngredientRow extends DataClass
    implements Insertable<RecipeIngredientRow> {
  final int id;
  final String supabaseId;
  final String recipeSupabaseId;
  final String name;
  final double? quantity;
  final String? unit;
  final String? substitute;
  final bool isGarnish;
  final String? garnishNotes;
  final bool isOptional;
  final String? photoUrl;
  final int sortOrder;
  final bool isSynced;
  final DateTime lastModified;
  const RecipeIngredientRow({
    required this.id,
    required this.supabaseId,
    required this.recipeSupabaseId,
    required this.name,
    this.quantity,
    this.unit,
    this.substitute,
    required this.isGarnish,
    this.garnishNotes,
    required this.isOptional,
    this.photoUrl,
    required this.sortOrder,
    required this.isSynced,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['recipe_supabase_id'] = Variable<String>(recipeSupabaseId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || substitute != null) {
      map['substitute'] = Variable<String>(substitute);
    }
    map['is_garnish'] = Variable<bool>(isGarnish);
    if (!nullToAbsent || garnishNotes != null) {
      map['garnish_notes'] = Variable<String>(garnishNotes);
    }
    map['is_optional'] = Variable<bool>(isOptional);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      recipeSupabaseId: Value(recipeSupabaseId),
      name: Value(name),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      substitute: substitute == null && nullToAbsent
          ? const Value.absent()
          : Value(substitute),
      isGarnish: Value(isGarnish),
      garnishNotes: garnishNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(garnishNotes),
      isOptional: Value(isOptional),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      sortOrder: Value(sortOrder),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory RecipeIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredientRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      recipeSupabaseId: serializer.fromJson<String>(json['recipeSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      substitute: serializer.fromJson<String?>(json['substitute']),
      isGarnish: serializer.fromJson<bool>(json['isGarnish']),
      garnishNotes: serializer.fromJson<String?>(json['garnishNotes']),
      isOptional: serializer.fromJson<bool>(json['isOptional']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'recipeSupabaseId': serializer.toJson<String>(recipeSupabaseId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'substitute': serializer.toJson<String?>(substitute),
      'isGarnish': serializer.toJson<bool>(isGarnish),
      'garnishNotes': serializer.toJson<String?>(garnishNotes),
      'isOptional': serializer.toJson<bool>(isOptional),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  RecipeIngredientRow copyWith({
    int? id,
    String? supabaseId,
    String? recipeSupabaseId,
    String? name,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> substitute = const Value.absent(),
    bool? isGarnish,
    Value<String?> garnishNotes = const Value.absent(),
    bool? isOptional,
    Value<String?> photoUrl = const Value.absent(),
    int? sortOrder,
    bool? isSynced,
    DateTime? lastModified,
  }) => RecipeIngredientRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    recipeSupabaseId: recipeSupabaseId ?? this.recipeSupabaseId,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    substitute: substitute.present ? substitute.value : this.substitute,
    isGarnish: isGarnish ?? this.isGarnish,
    garnishNotes: garnishNotes.present ? garnishNotes.value : this.garnishNotes,
    isOptional: isOptional ?? this.isOptional,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    sortOrder: sortOrder ?? this.sortOrder,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
  );
  RecipeIngredientRow copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredientRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      recipeSupabaseId: data.recipeSupabaseId.present
          ? data.recipeSupabaseId.value
          : this.recipeSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      substitute: data.substitute.present
          ? data.substitute.value
          : this.substitute,
      isGarnish: data.isGarnish.present ? data.isGarnish.value : this.isGarnish,
      garnishNotes: data.garnishNotes.present
          ? data.garnishNotes.value
          : this.garnishNotes,
      isOptional: data.isOptional.present
          ? data.isOptional.value
          : this.isOptional,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('recipeSupabaseId: $recipeSupabaseId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('substitute: $substitute, ')
          ..write('isGarnish: $isGarnish, ')
          ..write('garnishNotes: $garnishNotes, ')
          ..write('isOptional: $isOptional, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    recipeSupabaseId,
    name,
    quantity,
    unit,
    substitute,
    isGarnish,
    garnishNotes,
    isOptional,
    photoUrl,
    sortOrder,
    isSynced,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredientRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.recipeSupabaseId == this.recipeSupabaseId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.substitute == this.substitute &&
          other.isGarnish == this.isGarnish &&
          other.garnishNotes == this.garnishNotes &&
          other.isOptional == this.isOptional &&
          other.photoUrl == this.photoUrl &&
          other.sortOrder == this.sortOrder &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredientRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> recipeSupabaseId;
  final Value<String> name;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<String?> substitute;
  final Value<bool> isGarnish;
  final Value<String?> garnishNotes;
  final Value<bool> isOptional;
  final Value<String?> photoUrl;
  final Value<int> sortOrder;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  const RecipeIngredientsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.recipeSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.substitute = const Value.absent(),
    this.isGarnish = const Value.absent(),
    this.garnishNotes = const Value.absent(),
    this.isOptional = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.recipeSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.substitute = const Value.absent(),
    this.isGarnish = const Value.absent(),
    this.garnishNotes = const Value.absent(),
    this.isOptional = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<RecipeIngredientRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? recipeSupabaseId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? substitute,
    Expression<bool>? isGarnish,
    Expression<String>? garnishNotes,
    Expression<bool>? isOptional,
    Expression<String>? photoUrl,
    Expression<int>? sortOrder,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (recipeSupabaseId != null) 'recipe_supabase_id': recipeSupabaseId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (substitute != null) 'substitute': substitute,
      if (isGarnish != null) 'is_garnish': isGarnish,
      if (garnishNotes != null) 'garnish_notes': garnishNotes,
      if (isOptional != null) 'is_optional': isOptional,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  RecipeIngredientsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? recipeSupabaseId,
    Value<String>? name,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<String?>? substitute,
    Value<bool>? isGarnish,
    Value<String?>? garnishNotes,
    Value<bool>? isOptional,
    Value<String?>? photoUrl,
    Value<int>? sortOrder,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
  }) {
    return RecipeIngredientsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      recipeSupabaseId: recipeSupabaseId ?? this.recipeSupabaseId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      substitute: substitute ?? this.substitute,
      isGarnish: isGarnish ?? this.isGarnish,
      garnishNotes: garnishNotes ?? this.garnishNotes,
      isOptional: isOptional ?? this.isOptional,
      photoUrl: photoUrl ?? this.photoUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (recipeSupabaseId.present) {
      map['recipe_supabase_id'] = Variable<String>(recipeSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (substitute.present) {
      map['substitute'] = Variable<String>(substitute.value);
    }
    if (isGarnish.present) {
      map['is_garnish'] = Variable<bool>(isGarnish.value);
    }
    if (garnishNotes.present) {
      map['garnish_notes'] = Variable<String>(garnishNotes.value);
    }
    if (isOptional.present) {
      map['is_optional'] = Variable<bool>(isOptional.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('recipeSupabaseId: $recipeSupabaseId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('substitute: $substitute, ')
          ..write('isGarnish: $isGarnish, ')
          ..write('garnishNotes: $garnishNotes, ')
          ..write('isOptional: $isOptional, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $BarIngredientsTable extends BarIngredients
    with TableInfo<$BarIngredientsTable, BarIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BarIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _inMyBarMeta = const VerificationMeta(
    'inMyBar',
  );
  @override
  late final GeneratedColumn<bool> inMyBar = GeneratedColumn<bool>(
    'in_my_bar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_my_bar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isBundledMeta = const VerificationMeta(
    'isBundled',
  );
  @override
  late final GeneratedColumn<bool> isBundled = GeneratedColumn<bool>(
    'is_bundled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bundled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _flavorProfilesMeta = const VerificationMeta(
    'flavorProfiles',
  );
  @override
  late final GeneratedColumn<String> flavorProfiles = GeneratedColumn<String>(
    'flavor_profiles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _alcoholByVolumeMeta = const VerificationMeta(
    'alcoholByVolume',
  );
  @override
  late final GeneratedColumn<double> alcoholByVolume = GeneratedColumn<double>(
    'alcohol_by_volume',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _substitute1Meta = const VerificationMeta(
    'substitute1',
  );
  @override
  late final GeneratedColumn<String> substitute1 = GeneratedColumn<String>(
    'substitute1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _substitute2Meta = const VerificationMeta(
    'substitute2',
  );
  @override
  late final GeneratedColumn<String> substitute2 = GeneratedColumn<String>(
    'substitute2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPhotoPathMeta = const VerificationMeta(
    'localPhotoPath',
  );
  @override
  late final GeneratedColumn<String> localPhotoPath = GeneratedColumn<String>(
    'local_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastKnownPriceMeta = const VerificationMeta(
    'lastKnownPrice',
  );
  @override
  late final GeneratedColumn<double> lastKnownPrice = GeneratedColumn<double>(
    'last_known_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceCurrencyMeta = const VerificationMeta(
    'priceCurrency',
  );
  @override
  late final GeneratedColumn<String> priceCurrency = GeneratedColumn<String>(
    'price_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  static const VerificationMeta _lastKnownPriceUnitMeta =
      const VerificationMeta('lastKnownPriceUnit');
  @override
  late final GeneratedColumn<String> lastKnownPriceUnit =
      GeneratedColumn<String>(
        'last_known_price_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPurchasePlaceMeta = const VerificationMeta(
    'lastPurchasePlace',
  );
  @override
  late final GeneratedColumn<String> lastPurchasePlace =
      GeneratedColumn<String>(
        'last_purchase_place',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _purchaseHistoryMeta = const VerificationMeta(
    'purchaseHistory',
  );
  @override
  late final GeneratedColumn<String> purchaseHistory = GeneratedColumn<String>(
    'purchase_history',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    name,
    inMyBar,
    sortOrder,
    isBundled,
    isSynced,
    category,
    flavorProfiles,
    alcoholByVolume,
    substitute1,
    substitute2,
    localPhotoPath,
    imageUrl,
    lastKnownPrice,
    priceCurrency,
    lastKnownPriceUnit,
    lastPurchasePlace,
    purchaseHistory,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bar_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<BarIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('in_my_bar')) {
      context.handle(
        _inMyBarMeta,
        inMyBar.isAcceptableOrUnknown(data['in_my_bar']!, _inMyBarMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_bundled')) {
      context.handle(
        _isBundledMeta,
        isBundled.isAcceptableOrUnknown(data['is_bundled']!, _isBundledMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('flavor_profiles')) {
      context.handle(
        _flavorProfilesMeta,
        flavorProfiles.isAcceptableOrUnknown(
          data['flavor_profiles']!,
          _flavorProfilesMeta,
        ),
      );
    }
    if (data.containsKey('alcohol_by_volume')) {
      context.handle(
        _alcoholByVolumeMeta,
        alcoholByVolume.isAcceptableOrUnknown(
          data['alcohol_by_volume']!,
          _alcoholByVolumeMeta,
        ),
      );
    }
    if (data.containsKey('substitute1')) {
      context.handle(
        _substitute1Meta,
        substitute1.isAcceptableOrUnknown(
          data['substitute1']!,
          _substitute1Meta,
        ),
      );
    }
    if (data.containsKey('substitute2')) {
      context.handle(
        _substitute2Meta,
        substitute2.isAcceptableOrUnknown(
          data['substitute2']!,
          _substitute2Meta,
        ),
      );
    }
    if (data.containsKey('local_photo_path')) {
      context.handle(
        _localPhotoPathMeta,
        localPhotoPath.isAcceptableOrUnknown(
          data['local_photo_path']!,
          _localPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('last_known_price')) {
      context.handle(
        _lastKnownPriceMeta,
        lastKnownPrice.isAcceptableOrUnknown(
          data['last_known_price']!,
          _lastKnownPriceMeta,
        ),
      );
    }
    if (data.containsKey('price_currency')) {
      context.handle(
        _priceCurrencyMeta,
        priceCurrency.isAcceptableOrUnknown(
          data['price_currency']!,
          _priceCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('last_known_price_unit')) {
      context.handle(
        _lastKnownPriceUnitMeta,
        lastKnownPriceUnit.isAcceptableOrUnknown(
          data['last_known_price_unit']!,
          _lastKnownPriceUnitMeta,
        ),
      );
    }
    if (data.containsKey('last_purchase_place')) {
      context.handle(
        _lastPurchasePlaceMeta,
        lastPurchasePlace.isAcceptableOrUnknown(
          data['last_purchase_place']!,
          _lastPurchasePlaceMeta,
        ),
      );
    }
    if (data.containsKey('purchase_history')) {
      context.handle(
        _purchaseHistoryMeta,
        purchaseHistory.isAcceptableOrUnknown(
          data['purchase_history']!,
          _purchaseHistoryMeta,
        ),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BarIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BarIngredientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      inMyBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_my_bar'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isBundled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bundled'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      flavorProfiles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flavor_profiles'],
      )!,
      alcoholByVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alcohol_by_volume'],
      ),
      substitute1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute1'],
      ),
      substitute2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute2'],
      ),
      localPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_photo_path'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      lastKnownPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_known_price'],
      ),
      priceCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_currency'],
      )!,
      lastKnownPriceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_known_price_unit'],
      ),
      lastPurchasePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_purchase_place'],
      ),
      purchaseHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_history'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $BarIngredientsTable createAlias(String alias) {
    return $BarIngredientsTable(attachedDatabase, alias);
  }
}

class BarIngredientRow extends DataClass
    implements Insertable<BarIngredientRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String name;
  final bool inMyBar;
  final int sortOrder;
  final bool isBundled;
  final bool isSynced;
  final String category;
  final String flavorProfiles;
  final double? alcoholByVolume;
  final String? substitute1;
  final String? substitute2;
  final String? localPhotoPath;
  final String? imageUrl;
  final double? lastKnownPrice;
  final String priceCurrency;
  final String? lastKnownPriceUnit;
  final String? lastPurchasePlace;
  final String purchaseHistory;
  final DateTime lastModified;
  const BarIngredientRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.name,
    required this.inMyBar,
    required this.sortOrder,
    required this.isBundled,
    required this.isSynced,
    required this.category,
    required this.flavorProfiles,
    this.alcoholByVolume,
    this.substitute1,
    this.substitute2,
    this.localPhotoPath,
    this.imageUrl,
    this.lastKnownPrice,
    required this.priceCurrency,
    this.lastKnownPriceUnit,
    this.lastPurchasePlace,
    required this.purchaseHistory,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['name'] = Variable<String>(name);
    map['in_my_bar'] = Variable<bool>(inMyBar);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_bundled'] = Variable<bool>(isBundled);
    map['is_synced'] = Variable<bool>(isSynced);
    map['category'] = Variable<String>(category);
    map['flavor_profiles'] = Variable<String>(flavorProfiles);
    if (!nullToAbsent || alcoholByVolume != null) {
      map['alcohol_by_volume'] = Variable<double>(alcoholByVolume);
    }
    if (!nullToAbsent || substitute1 != null) {
      map['substitute1'] = Variable<String>(substitute1);
    }
    if (!nullToAbsent || substitute2 != null) {
      map['substitute2'] = Variable<String>(substitute2);
    }
    if (!nullToAbsent || localPhotoPath != null) {
      map['local_photo_path'] = Variable<String>(localPhotoPath);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || lastKnownPrice != null) {
      map['last_known_price'] = Variable<double>(lastKnownPrice);
    }
    map['price_currency'] = Variable<String>(priceCurrency);
    if (!nullToAbsent || lastKnownPriceUnit != null) {
      map['last_known_price_unit'] = Variable<String>(lastKnownPriceUnit);
    }
    if (!nullToAbsent || lastPurchasePlace != null) {
      map['last_purchase_place'] = Variable<String>(lastPurchasePlace);
    }
    map['purchase_history'] = Variable<String>(purchaseHistory);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  BarIngredientsCompanion toCompanion(bool nullToAbsent) {
    return BarIngredientsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      name: Value(name),
      inMyBar: Value(inMyBar),
      sortOrder: Value(sortOrder),
      isBundled: Value(isBundled),
      isSynced: Value(isSynced),
      category: Value(category),
      flavorProfiles: Value(flavorProfiles),
      alcoholByVolume: alcoholByVolume == null && nullToAbsent
          ? const Value.absent()
          : Value(alcoholByVolume),
      substitute1: substitute1 == null && nullToAbsent
          ? const Value.absent()
          : Value(substitute1),
      substitute2: substitute2 == null && nullToAbsent
          ? const Value.absent()
          : Value(substitute2),
      localPhotoPath: localPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPhotoPath),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      lastKnownPrice: lastKnownPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownPrice),
      priceCurrency: Value(priceCurrency),
      lastKnownPriceUnit: lastKnownPriceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownPriceUnit),
      lastPurchasePlace: lastPurchasePlace == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchasePlace),
      purchaseHistory: Value(purchaseHistory),
      lastModified: Value(lastModified),
    );
  }

  factory BarIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BarIngredientRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      inMyBar: serializer.fromJson<bool>(json['inMyBar']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isBundled: serializer.fromJson<bool>(json['isBundled']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      category: serializer.fromJson<String>(json['category']),
      flavorProfiles: serializer.fromJson<String>(json['flavorProfiles']),
      alcoholByVolume: serializer.fromJson<double?>(json['alcoholByVolume']),
      substitute1: serializer.fromJson<String?>(json['substitute1']),
      substitute2: serializer.fromJson<String?>(json['substitute2']),
      localPhotoPath: serializer.fromJson<String?>(json['localPhotoPath']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      lastKnownPrice: serializer.fromJson<double?>(json['lastKnownPrice']),
      priceCurrency: serializer.fromJson<String>(json['priceCurrency']),
      lastKnownPriceUnit: serializer.fromJson<String?>(
        json['lastKnownPriceUnit'],
      ),
      lastPurchasePlace: serializer.fromJson<String?>(
        json['lastPurchasePlace'],
      ),
      purchaseHistory: serializer.fromJson<String>(json['purchaseHistory']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'name': serializer.toJson<String>(name),
      'inMyBar': serializer.toJson<bool>(inMyBar),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isBundled': serializer.toJson<bool>(isBundled),
      'isSynced': serializer.toJson<bool>(isSynced),
      'category': serializer.toJson<String>(category),
      'flavorProfiles': serializer.toJson<String>(flavorProfiles),
      'alcoholByVolume': serializer.toJson<double?>(alcoholByVolume),
      'substitute1': serializer.toJson<String?>(substitute1),
      'substitute2': serializer.toJson<String?>(substitute2),
      'localPhotoPath': serializer.toJson<String?>(localPhotoPath),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'lastKnownPrice': serializer.toJson<double?>(lastKnownPrice),
      'priceCurrency': serializer.toJson<String>(priceCurrency),
      'lastKnownPriceUnit': serializer.toJson<String?>(lastKnownPriceUnit),
      'lastPurchasePlace': serializer.toJson<String?>(lastPurchasePlace),
      'purchaseHistory': serializer.toJson<String>(purchaseHistory),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  BarIngredientRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? name,
    bool? inMyBar,
    int? sortOrder,
    bool? isBundled,
    bool? isSynced,
    String? category,
    String? flavorProfiles,
    Value<double?> alcoholByVolume = const Value.absent(),
    Value<String?> substitute1 = const Value.absent(),
    Value<String?> substitute2 = const Value.absent(),
    Value<String?> localPhotoPath = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<double?> lastKnownPrice = const Value.absent(),
    String? priceCurrency,
    Value<String?> lastKnownPriceUnit = const Value.absent(),
    Value<String?> lastPurchasePlace = const Value.absent(),
    String? purchaseHistory,
    DateTime? lastModified,
  }) => BarIngredientRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    name: name ?? this.name,
    inMyBar: inMyBar ?? this.inMyBar,
    sortOrder: sortOrder ?? this.sortOrder,
    isBundled: isBundled ?? this.isBundled,
    isSynced: isSynced ?? this.isSynced,
    category: category ?? this.category,
    flavorProfiles: flavorProfiles ?? this.flavorProfiles,
    alcoholByVolume: alcoholByVolume.present
        ? alcoholByVolume.value
        : this.alcoholByVolume,
    substitute1: substitute1.present ? substitute1.value : this.substitute1,
    substitute2: substitute2.present ? substitute2.value : this.substitute2,
    localPhotoPath: localPhotoPath.present
        ? localPhotoPath.value
        : this.localPhotoPath,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    lastKnownPrice: lastKnownPrice.present
        ? lastKnownPrice.value
        : this.lastKnownPrice,
    priceCurrency: priceCurrency ?? this.priceCurrency,
    lastKnownPriceUnit: lastKnownPriceUnit.present
        ? lastKnownPriceUnit.value
        : this.lastKnownPriceUnit,
    lastPurchasePlace: lastPurchasePlace.present
        ? lastPurchasePlace.value
        : this.lastPurchasePlace,
    purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    lastModified: lastModified ?? this.lastModified,
  );
  BarIngredientRow copyWithCompanion(BarIngredientsCompanion data) {
    return BarIngredientRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      inMyBar: data.inMyBar.present ? data.inMyBar.value : this.inMyBar,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isBundled: data.isBundled.present ? data.isBundled.value : this.isBundled,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      category: data.category.present ? data.category.value : this.category,
      flavorProfiles: data.flavorProfiles.present
          ? data.flavorProfiles.value
          : this.flavorProfiles,
      alcoholByVolume: data.alcoholByVolume.present
          ? data.alcoholByVolume.value
          : this.alcoholByVolume,
      substitute1: data.substitute1.present
          ? data.substitute1.value
          : this.substitute1,
      substitute2: data.substitute2.present
          ? data.substitute2.value
          : this.substitute2,
      localPhotoPath: data.localPhotoPath.present
          ? data.localPhotoPath.value
          : this.localPhotoPath,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      lastKnownPrice: data.lastKnownPrice.present
          ? data.lastKnownPrice.value
          : this.lastKnownPrice,
      priceCurrency: data.priceCurrency.present
          ? data.priceCurrency.value
          : this.priceCurrency,
      lastKnownPriceUnit: data.lastKnownPriceUnit.present
          ? data.lastKnownPriceUnit.value
          : this.lastKnownPriceUnit,
      lastPurchasePlace: data.lastPurchasePlace.present
          ? data.lastPurchasePlace.value
          : this.lastPurchasePlace,
      purchaseHistory: data.purchaseHistory.present
          ? data.purchaseHistory.value
          : this.purchaseHistory,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BarIngredientRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('inMyBar: $inMyBar, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('category: $category, ')
          ..write('flavorProfiles: $flavorProfiles, ')
          ..write('alcoholByVolume: $alcoholByVolume, ')
          ..write('substitute1: $substitute1, ')
          ..write('substitute2: $substitute2, ')
          ..write('localPhotoPath: $localPhotoPath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('lastKnownPrice: $lastKnownPrice, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('lastKnownPriceUnit: $lastKnownPriceUnit, ')
          ..write('lastPurchasePlace: $lastPurchasePlace, ')
          ..write('purchaseHistory: $purchaseHistory, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    supabaseId,
    boatSupabaseId,
    name,
    inMyBar,
    sortOrder,
    isBundled,
    isSynced,
    category,
    flavorProfiles,
    alcoholByVolume,
    substitute1,
    substitute2,
    localPhotoPath,
    imageUrl,
    lastKnownPrice,
    priceCurrency,
    lastKnownPriceUnit,
    lastPurchasePlace,
    purchaseHistory,
    lastModified,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BarIngredientRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.name == this.name &&
          other.inMyBar == this.inMyBar &&
          other.sortOrder == this.sortOrder &&
          other.isBundled == this.isBundled &&
          other.isSynced == this.isSynced &&
          other.category == this.category &&
          other.flavorProfiles == this.flavorProfiles &&
          other.alcoholByVolume == this.alcoholByVolume &&
          other.substitute1 == this.substitute1 &&
          other.substitute2 == this.substitute2 &&
          other.localPhotoPath == this.localPhotoPath &&
          other.imageUrl == this.imageUrl &&
          other.lastKnownPrice == this.lastKnownPrice &&
          other.priceCurrency == this.priceCurrency &&
          other.lastKnownPriceUnit == this.lastKnownPriceUnit &&
          other.lastPurchasePlace == this.lastPurchasePlace &&
          other.purchaseHistory == this.purchaseHistory &&
          other.lastModified == this.lastModified);
}

class BarIngredientsCompanion extends UpdateCompanion<BarIngredientRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> name;
  final Value<bool> inMyBar;
  final Value<int> sortOrder;
  final Value<bool> isBundled;
  final Value<bool> isSynced;
  final Value<String> category;
  final Value<String> flavorProfiles;
  final Value<double?> alcoholByVolume;
  final Value<String?> substitute1;
  final Value<String?> substitute2;
  final Value<String?> localPhotoPath;
  final Value<String?> imageUrl;
  final Value<double?> lastKnownPrice;
  final Value<String> priceCurrency;
  final Value<String?> lastKnownPriceUnit;
  final Value<String?> lastPurchasePlace;
  final Value<String> purchaseHistory;
  final Value<DateTime> lastModified;
  const BarIngredientsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.inMyBar = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.category = const Value.absent(),
    this.flavorProfiles = const Value.absent(),
    this.alcoholByVolume = const Value.absent(),
    this.substitute1 = const Value.absent(),
    this.substitute2 = const Value.absent(),
    this.localPhotoPath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.lastKnownPrice = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.lastKnownPriceUnit = const Value.absent(),
    this.lastPurchasePlace = const Value.absent(),
    this.purchaseHistory = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  BarIngredientsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.inMyBar = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.category = const Value.absent(),
    this.flavorProfiles = const Value.absent(),
    this.alcoholByVolume = const Value.absent(),
    this.substitute1 = const Value.absent(),
    this.substitute2 = const Value.absent(),
    this.localPhotoPath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.lastKnownPrice = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.lastKnownPriceUnit = const Value.absent(),
    this.lastPurchasePlace = const Value.absent(),
    this.purchaseHistory = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<BarIngredientRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? name,
    Expression<bool>? inMyBar,
    Expression<int>? sortOrder,
    Expression<bool>? isBundled,
    Expression<bool>? isSynced,
    Expression<String>? category,
    Expression<String>? flavorProfiles,
    Expression<double>? alcoholByVolume,
    Expression<String>? substitute1,
    Expression<String>? substitute2,
    Expression<String>? localPhotoPath,
    Expression<String>? imageUrl,
    Expression<double>? lastKnownPrice,
    Expression<String>? priceCurrency,
    Expression<String>? lastKnownPriceUnit,
    Expression<String>? lastPurchasePlace,
    Expression<String>? purchaseHistory,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (name != null) 'name': name,
      if (inMyBar != null) 'in_my_bar': inMyBar,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isBundled != null) 'is_bundled': isBundled,
      if (isSynced != null) 'is_synced': isSynced,
      if (category != null) 'category': category,
      if (flavorProfiles != null) 'flavor_profiles': flavorProfiles,
      if (alcoholByVolume != null) 'alcohol_by_volume': alcoholByVolume,
      if (substitute1 != null) 'substitute1': substitute1,
      if (substitute2 != null) 'substitute2': substitute2,
      if (localPhotoPath != null) 'local_photo_path': localPhotoPath,
      if (imageUrl != null) 'image_url': imageUrl,
      if (lastKnownPrice != null) 'last_known_price': lastKnownPrice,
      if (priceCurrency != null) 'price_currency': priceCurrency,
      if (lastKnownPriceUnit != null)
        'last_known_price_unit': lastKnownPriceUnit,
      if (lastPurchasePlace != null) 'last_purchase_place': lastPurchasePlace,
      if (purchaseHistory != null) 'purchase_history': purchaseHistory,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  BarIngredientsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? name,
    Value<bool>? inMyBar,
    Value<int>? sortOrder,
    Value<bool>? isBundled,
    Value<bool>? isSynced,
    Value<String>? category,
    Value<String>? flavorProfiles,
    Value<double?>? alcoholByVolume,
    Value<String?>? substitute1,
    Value<String?>? substitute2,
    Value<String?>? localPhotoPath,
    Value<String?>? imageUrl,
    Value<double?>? lastKnownPrice,
    Value<String>? priceCurrency,
    Value<String?>? lastKnownPriceUnit,
    Value<String?>? lastPurchasePlace,
    Value<String>? purchaseHistory,
    Value<DateTime>? lastModified,
  }) {
    return BarIngredientsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      name: name ?? this.name,
      inMyBar: inMyBar ?? this.inMyBar,
      sortOrder: sortOrder ?? this.sortOrder,
      isBundled: isBundled ?? this.isBundled,
      isSynced: isSynced ?? this.isSynced,
      category: category ?? this.category,
      flavorProfiles: flavorProfiles ?? this.flavorProfiles,
      alcoholByVolume: alcoholByVolume ?? this.alcoholByVolume,
      substitute1: substitute1 ?? this.substitute1,
      substitute2: substitute2 ?? this.substitute2,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      imageUrl: imageUrl ?? this.imageUrl,
      lastKnownPrice: lastKnownPrice ?? this.lastKnownPrice,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      lastKnownPriceUnit: lastKnownPriceUnit ?? this.lastKnownPriceUnit,
      lastPurchasePlace: lastPurchasePlace ?? this.lastPurchasePlace,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (inMyBar.present) {
      map['in_my_bar'] = Variable<bool>(inMyBar.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isBundled.present) {
      map['is_bundled'] = Variable<bool>(isBundled.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (flavorProfiles.present) {
      map['flavor_profiles'] = Variable<String>(flavorProfiles.value);
    }
    if (alcoholByVolume.present) {
      map['alcohol_by_volume'] = Variable<double>(alcoholByVolume.value);
    }
    if (substitute1.present) {
      map['substitute1'] = Variable<String>(substitute1.value);
    }
    if (substitute2.present) {
      map['substitute2'] = Variable<String>(substitute2.value);
    }
    if (localPhotoPath.present) {
      map['local_photo_path'] = Variable<String>(localPhotoPath.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (lastKnownPrice.present) {
      map['last_known_price'] = Variable<double>(lastKnownPrice.value);
    }
    if (priceCurrency.present) {
      map['price_currency'] = Variable<String>(priceCurrency.value);
    }
    if (lastKnownPriceUnit.present) {
      map['last_known_price_unit'] = Variable<String>(lastKnownPriceUnit.value);
    }
    if (lastPurchasePlace.present) {
      map['last_purchase_place'] = Variable<String>(lastPurchasePlace.value);
    }
    if (purchaseHistory.present) {
      map['purchase_history'] = Variable<String>(purchaseHistory.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BarIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('inMyBar: $inMyBar, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('category: $category, ')
          ..write('flavorProfiles: $flavorProfiles, ')
          ..write('alcoholByVolume: $alcoholByVolume, ')
          ..write('substitute1: $substitute1, ')
          ..write('substitute2: $substitute2, ')
          ..write('localPhotoPath: $localPhotoPath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('lastKnownPrice: $lastKnownPrice, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('lastKnownPriceUnit: $lastKnownPriceUnit, ')
          ..write('lastPurchasePlace: $lastPurchasePlace, ')
          ..write('purchaseHistory: $purchaseHistory, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $PantryIngredientsTable extends PantryIngredients
    with TableInfo<$PantryIngredientsTable, PantryIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PantryIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _boatSupabaseIdMeta = const VerificationMeta(
    'boatSupabaseId',
  );
  @override
  late final GeneratedColumn<String> boatSupabaseId = GeneratedColumn<String>(
    'boat_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _inMyPantryMeta = const VerificationMeta(
    'inMyPantry',
  );
  @override
  late final GeneratedColumn<bool> inMyPantry = GeneratedColumn<bool>(
    'in_my_pantry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_my_pantry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isBundledMeta = const VerificationMeta(
    'isBundled',
  );
  @override
  late final GeneratedColumn<bool> isBundled = GeneratedColumn<bool>(
    'is_bundled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bundled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _flavorProfilesMeta = const VerificationMeta(
    'flavorProfiles',
  );
  @override
  late final GeneratedColumn<String> flavorProfiles = GeneratedColumn<String>(
    'flavor_profiles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cuisineTypesMeta = const VerificationMeta(
    'cuisineTypes',
  );
  @override
  late final GeneratedColumn<String> cuisineTypes = GeneratedColumn<String>(
    'cuisine_types',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _allergenTagsMeta = const VerificationMeta(
    'allergenTags',
  );
  @override
  late final GeneratedColumn<String> allergenTags = GeneratedColumn<String>(
    'allergen_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _dietaryTagsMeta = const VerificationMeta(
    'dietaryTags',
  );
  @override
  late final GeneratedColumn<String> dietaryTags = GeneratedColumn<String>(
    'dietary_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _substitute1Meta = const VerificationMeta(
    'substitute1',
  );
  @override
  late final GeneratedColumn<String> substitute1 = GeneratedColumn<String>(
    'substitute1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _substitute2Meta = const VerificationMeta(
    'substitute2',
  );
  @override
  late final GeneratedColumn<String> substitute2 = GeneratedColumn<String>(
    'substitute2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPhotoPathMeta = const VerificationMeta(
    'localPhotoPath',
  );
  @override
  late final GeneratedColumn<String> localPhotoPath = GeneratedColumn<String>(
    'local_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastKnownPriceMeta = const VerificationMeta(
    'lastKnownPrice',
  );
  @override
  late final GeneratedColumn<double> lastKnownPrice = GeneratedColumn<double>(
    'last_known_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceCurrencyMeta = const VerificationMeta(
    'priceCurrency',
  );
  @override
  late final GeneratedColumn<String> priceCurrency = GeneratedColumn<String>(
    'price_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  static const VerificationMeta _lastKnownPriceUnitMeta =
      const VerificationMeta('lastKnownPriceUnit');
  @override
  late final GeneratedColumn<String> lastKnownPriceUnit =
      GeneratedColumn<String>(
        'last_known_price_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPurchasePlaceMeta = const VerificationMeta(
    'lastPurchasePlace',
  );
  @override
  late final GeneratedColumn<String> lastPurchasePlace =
      GeneratedColumn<String>(
        'last_purchase_place',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _purchaseHistoryMeta = const VerificationMeta(
    'purchaseHistory',
  );
  @override
  late final GeneratedColumn<String> purchaseHistory = GeneratedColumn<String>(
    'purchase_history',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _caloriesPer100gMeta = const VerificationMeta(
    'caloriesPer100g',
  );
  @override
  late final GeneratedColumn<double> caloriesPer100g = GeneratedColumn<double>(
    'calories_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<double> proteinPer100g = GeneratedColumn<double>(
    'protein_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<double> fatPer100g = GeneratedColumn<double>(
    'fat_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<double> carbsPer100g = GeneratedColumn<double>(
    'carbs_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    boatSupabaseId,
    name,
    inMyPantry,
    quantity,
    unit,
    sortOrder,
    isBundled,
    isSynced,
    category,
    flavorProfiles,
    cuisineTypes,
    allergenTags,
    dietaryTags,
    substitute1,
    substitute2,
    localPhotoPath,
    imageUrl,
    expiryDate,
    lastKnownPrice,
    priceCurrency,
    lastKnownPriceUnit,
    lastPurchasePlace,
    purchaseHistory,
    caloriesPer100g,
    proteinPer100g,
    fatPer100g,
    carbsPer100g,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pantry_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<PantryIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('boat_supabase_id')) {
      context.handle(
        _boatSupabaseIdMeta,
        boatSupabaseId.isAcceptableOrUnknown(
          data['boat_supabase_id']!,
          _boatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('in_my_pantry')) {
      context.handle(
        _inMyPantryMeta,
        inMyPantry.isAcceptableOrUnknown(
          data['in_my_pantry']!,
          _inMyPantryMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_bundled')) {
      context.handle(
        _isBundledMeta,
        isBundled.isAcceptableOrUnknown(data['is_bundled']!, _isBundledMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('flavor_profiles')) {
      context.handle(
        _flavorProfilesMeta,
        flavorProfiles.isAcceptableOrUnknown(
          data['flavor_profiles']!,
          _flavorProfilesMeta,
        ),
      );
    }
    if (data.containsKey('cuisine_types')) {
      context.handle(
        _cuisineTypesMeta,
        cuisineTypes.isAcceptableOrUnknown(
          data['cuisine_types']!,
          _cuisineTypesMeta,
        ),
      );
    }
    if (data.containsKey('allergen_tags')) {
      context.handle(
        _allergenTagsMeta,
        allergenTags.isAcceptableOrUnknown(
          data['allergen_tags']!,
          _allergenTagsMeta,
        ),
      );
    }
    if (data.containsKey('dietary_tags')) {
      context.handle(
        _dietaryTagsMeta,
        dietaryTags.isAcceptableOrUnknown(
          data['dietary_tags']!,
          _dietaryTagsMeta,
        ),
      );
    }
    if (data.containsKey('substitute1')) {
      context.handle(
        _substitute1Meta,
        substitute1.isAcceptableOrUnknown(
          data['substitute1']!,
          _substitute1Meta,
        ),
      );
    }
    if (data.containsKey('substitute2')) {
      context.handle(
        _substitute2Meta,
        substitute2.isAcceptableOrUnknown(
          data['substitute2']!,
          _substitute2Meta,
        ),
      );
    }
    if (data.containsKey('local_photo_path')) {
      context.handle(
        _localPhotoPathMeta,
        localPhotoPath.isAcceptableOrUnknown(
          data['local_photo_path']!,
          _localPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('last_known_price')) {
      context.handle(
        _lastKnownPriceMeta,
        lastKnownPrice.isAcceptableOrUnknown(
          data['last_known_price']!,
          _lastKnownPriceMeta,
        ),
      );
    }
    if (data.containsKey('price_currency')) {
      context.handle(
        _priceCurrencyMeta,
        priceCurrency.isAcceptableOrUnknown(
          data['price_currency']!,
          _priceCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('last_known_price_unit')) {
      context.handle(
        _lastKnownPriceUnitMeta,
        lastKnownPriceUnit.isAcceptableOrUnknown(
          data['last_known_price_unit']!,
          _lastKnownPriceUnitMeta,
        ),
      );
    }
    if (data.containsKey('last_purchase_place')) {
      context.handle(
        _lastPurchasePlaceMeta,
        lastPurchasePlace.isAcceptableOrUnknown(
          data['last_purchase_place']!,
          _lastPurchasePlaceMeta,
        ),
      );
    }
    if (data.containsKey('purchase_history')) {
      context.handle(
        _purchaseHistoryMeta,
        purchaseHistory.isAcceptableOrUnknown(
          data['purchase_history']!,
          _purchaseHistoryMeta,
        ),
      );
    }
    if (data.containsKey('calories_per100g')) {
      context.handle(
        _caloriesPer100gMeta,
        caloriesPer100g.isAcceptableOrUnknown(
          data['calories_per100g']!,
          _caloriesPer100gMeta,
        ),
      );
    }
    if (data.containsKey('protein_per100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per100g']!,
          _proteinPer100gMeta,
        ),
      );
    }
    if (data.containsKey('fat_per100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(data['fat_per100g']!, _fatPer100gMeta),
      );
    }
    if (data.containsKey('carbs_per100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per100g']!,
          _carbsPer100gMeta,
        ),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PantryIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PantryIngredientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      boatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      inMyPantry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_my_pantry'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isBundled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bundled'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      flavorProfiles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flavor_profiles'],
      )!,
      cuisineTypes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuisine_types'],
      )!,
      allergenTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergen_tags'],
      )!,
      dietaryTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dietary_tags'],
      )!,
      substitute1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute1'],
      ),
      substitute2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute2'],
      ),
      localPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_photo_path'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      lastKnownPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_known_price'],
      ),
      priceCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_currency'],
      )!,
      lastKnownPriceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_known_price_unit'],
      ),
      lastPurchasePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_purchase_place'],
      ),
      purchaseHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_history'],
      )!,
      caloriesPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_per100g'],
      ),
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g'],
      ),
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g'],
      ),
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
    );
  }

  @override
  $PantryIngredientsTable createAlias(String alias) {
    return $PantryIngredientsTable(attachedDatabase, alias);
  }
}

class PantryIngredientRow extends DataClass
    implements Insertable<PantryIngredientRow> {
  final int id;
  final String supabaseId;
  final String boatSupabaseId;
  final String name;
  final bool inMyPantry;
  final double? quantity;
  final String? unit;
  final int sortOrder;
  final bool isBundled;
  final bool isSynced;
  final String category;
  final String flavorProfiles;
  final String cuisineTypes;
  final String allergenTags;
  final String dietaryTags;
  final String? substitute1;
  final String? substitute2;
  final String? localPhotoPath;
  final String? imageUrl;
  final DateTime? expiryDate;
  final double? lastKnownPrice;
  final String priceCurrency;
  final String? lastKnownPriceUnit;
  final String? lastPurchasePlace;
  final String purchaseHistory;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  final DateTime lastModified;
  const PantryIngredientRow({
    required this.id,
    required this.supabaseId,
    required this.boatSupabaseId,
    required this.name,
    required this.inMyPantry,
    this.quantity,
    this.unit,
    required this.sortOrder,
    required this.isBundled,
    required this.isSynced,
    required this.category,
    required this.flavorProfiles,
    required this.cuisineTypes,
    required this.allergenTags,
    required this.dietaryTags,
    this.substitute1,
    this.substitute2,
    this.localPhotoPath,
    this.imageUrl,
    this.expiryDate,
    this.lastKnownPrice,
    required this.priceCurrency,
    this.lastKnownPriceUnit,
    this.lastPurchasePlace,
    required this.purchaseHistory,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    required this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['boat_supabase_id'] = Variable<String>(boatSupabaseId);
    map['name'] = Variable<String>(name);
    map['in_my_pantry'] = Variable<bool>(inMyPantry);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_bundled'] = Variable<bool>(isBundled);
    map['is_synced'] = Variable<bool>(isSynced);
    map['category'] = Variable<String>(category);
    map['flavor_profiles'] = Variable<String>(flavorProfiles);
    map['cuisine_types'] = Variable<String>(cuisineTypes);
    map['allergen_tags'] = Variable<String>(allergenTags);
    map['dietary_tags'] = Variable<String>(dietaryTags);
    if (!nullToAbsent || substitute1 != null) {
      map['substitute1'] = Variable<String>(substitute1);
    }
    if (!nullToAbsent || substitute2 != null) {
      map['substitute2'] = Variable<String>(substitute2);
    }
    if (!nullToAbsent || localPhotoPath != null) {
      map['local_photo_path'] = Variable<String>(localPhotoPath);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || lastKnownPrice != null) {
      map['last_known_price'] = Variable<double>(lastKnownPrice);
    }
    map['price_currency'] = Variable<String>(priceCurrency);
    if (!nullToAbsent || lastKnownPriceUnit != null) {
      map['last_known_price_unit'] = Variable<String>(lastKnownPriceUnit);
    }
    if (!nullToAbsent || lastPurchasePlace != null) {
      map['last_purchase_place'] = Variable<String>(lastPurchasePlace);
    }
    map['purchase_history'] = Variable<String>(purchaseHistory);
    if (!nullToAbsent || caloriesPer100g != null) {
      map['calories_per100g'] = Variable<double>(caloriesPer100g);
    }
    if (!nullToAbsent || proteinPer100g != null) {
      map['protein_per100g'] = Variable<double>(proteinPer100g);
    }
    if (!nullToAbsent || fatPer100g != null) {
      map['fat_per100g'] = Variable<double>(fatPer100g);
    }
    if (!nullToAbsent || carbsPer100g != null) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  PantryIngredientsCompanion toCompanion(bool nullToAbsent) {
    return PantryIngredientsCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      boatSupabaseId: Value(boatSupabaseId),
      name: Value(name),
      inMyPantry: Value(inMyPantry),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      sortOrder: Value(sortOrder),
      isBundled: Value(isBundled),
      isSynced: Value(isSynced),
      category: Value(category),
      flavorProfiles: Value(flavorProfiles),
      cuisineTypes: Value(cuisineTypes),
      allergenTags: Value(allergenTags),
      dietaryTags: Value(dietaryTags),
      substitute1: substitute1 == null && nullToAbsent
          ? const Value.absent()
          : Value(substitute1),
      substitute2: substitute2 == null && nullToAbsent
          ? const Value.absent()
          : Value(substitute2),
      localPhotoPath: localPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPhotoPath),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      lastKnownPrice: lastKnownPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownPrice),
      priceCurrency: Value(priceCurrency),
      lastKnownPriceUnit: lastKnownPriceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownPriceUnit),
      lastPurchasePlace: lastPurchasePlace == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchasePlace),
      purchaseHistory: Value(purchaseHistory),
      caloriesPer100g: caloriesPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(caloriesPer100g),
      proteinPer100g: proteinPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinPer100g),
      fatPer100g: fatPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(fatPer100g),
      carbsPer100g: carbsPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsPer100g),
      lastModified: Value(lastModified),
    );
  }

  factory PantryIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PantryIngredientRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      boatSupabaseId: serializer.fromJson<String>(json['boatSupabaseId']),
      name: serializer.fromJson<String>(json['name']),
      inMyPantry: serializer.fromJson<bool>(json['inMyPantry']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isBundled: serializer.fromJson<bool>(json['isBundled']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      category: serializer.fromJson<String>(json['category']),
      flavorProfiles: serializer.fromJson<String>(json['flavorProfiles']),
      cuisineTypes: serializer.fromJson<String>(json['cuisineTypes']),
      allergenTags: serializer.fromJson<String>(json['allergenTags']),
      dietaryTags: serializer.fromJson<String>(json['dietaryTags']),
      substitute1: serializer.fromJson<String?>(json['substitute1']),
      substitute2: serializer.fromJson<String?>(json['substitute2']),
      localPhotoPath: serializer.fromJson<String?>(json['localPhotoPath']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      lastKnownPrice: serializer.fromJson<double?>(json['lastKnownPrice']),
      priceCurrency: serializer.fromJson<String>(json['priceCurrency']),
      lastKnownPriceUnit: serializer.fromJson<String?>(
        json['lastKnownPriceUnit'],
      ),
      lastPurchasePlace: serializer.fromJson<String?>(
        json['lastPurchasePlace'],
      ),
      purchaseHistory: serializer.fromJson<String>(json['purchaseHistory']),
      caloriesPer100g: serializer.fromJson<double?>(json['caloriesPer100g']),
      proteinPer100g: serializer.fromJson<double?>(json['proteinPer100g']),
      fatPer100g: serializer.fromJson<double?>(json['fatPer100g']),
      carbsPer100g: serializer.fromJson<double?>(json['carbsPer100g']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'boatSupabaseId': serializer.toJson<String>(boatSupabaseId),
      'name': serializer.toJson<String>(name),
      'inMyPantry': serializer.toJson<bool>(inMyPantry),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isBundled': serializer.toJson<bool>(isBundled),
      'isSynced': serializer.toJson<bool>(isSynced),
      'category': serializer.toJson<String>(category),
      'flavorProfiles': serializer.toJson<String>(flavorProfiles),
      'cuisineTypes': serializer.toJson<String>(cuisineTypes),
      'allergenTags': serializer.toJson<String>(allergenTags),
      'dietaryTags': serializer.toJson<String>(dietaryTags),
      'substitute1': serializer.toJson<String?>(substitute1),
      'substitute2': serializer.toJson<String?>(substitute2),
      'localPhotoPath': serializer.toJson<String?>(localPhotoPath),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'lastKnownPrice': serializer.toJson<double?>(lastKnownPrice),
      'priceCurrency': serializer.toJson<String>(priceCurrency),
      'lastKnownPriceUnit': serializer.toJson<String?>(lastKnownPriceUnit),
      'lastPurchasePlace': serializer.toJson<String?>(lastPurchasePlace),
      'purchaseHistory': serializer.toJson<String>(purchaseHistory),
      'caloriesPer100g': serializer.toJson<double?>(caloriesPer100g),
      'proteinPer100g': serializer.toJson<double?>(proteinPer100g),
      'fatPer100g': serializer.toJson<double?>(fatPer100g),
      'carbsPer100g': serializer.toJson<double?>(carbsPer100g),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  PantryIngredientRow copyWith({
    int? id,
    String? supabaseId,
    String? boatSupabaseId,
    String? name,
    bool? inMyPantry,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? sortOrder,
    bool? isBundled,
    bool? isSynced,
    String? category,
    String? flavorProfiles,
    String? cuisineTypes,
    String? allergenTags,
    String? dietaryTags,
    Value<String?> substitute1 = const Value.absent(),
    Value<String?> substitute2 = const Value.absent(),
    Value<String?> localPhotoPath = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<double?> lastKnownPrice = const Value.absent(),
    String? priceCurrency,
    Value<String?> lastKnownPriceUnit = const Value.absent(),
    Value<String?> lastPurchasePlace = const Value.absent(),
    String? purchaseHistory,
    Value<double?> caloriesPer100g = const Value.absent(),
    Value<double?> proteinPer100g = const Value.absent(),
    Value<double?> fatPer100g = const Value.absent(),
    Value<double?> carbsPer100g = const Value.absent(),
    DateTime? lastModified,
  }) => PantryIngredientRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
    name: name ?? this.name,
    inMyPantry: inMyPantry ?? this.inMyPantry,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    sortOrder: sortOrder ?? this.sortOrder,
    isBundled: isBundled ?? this.isBundled,
    isSynced: isSynced ?? this.isSynced,
    category: category ?? this.category,
    flavorProfiles: flavorProfiles ?? this.flavorProfiles,
    cuisineTypes: cuisineTypes ?? this.cuisineTypes,
    allergenTags: allergenTags ?? this.allergenTags,
    dietaryTags: dietaryTags ?? this.dietaryTags,
    substitute1: substitute1.present ? substitute1.value : this.substitute1,
    substitute2: substitute2.present ? substitute2.value : this.substitute2,
    localPhotoPath: localPhotoPath.present
        ? localPhotoPath.value
        : this.localPhotoPath,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    lastKnownPrice: lastKnownPrice.present
        ? lastKnownPrice.value
        : this.lastKnownPrice,
    priceCurrency: priceCurrency ?? this.priceCurrency,
    lastKnownPriceUnit: lastKnownPriceUnit.present
        ? lastKnownPriceUnit.value
        : this.lastKnownPriceUnit,
    lastPurchasePlace: lastPurchasePlace.present
        ? lastPurchasePlace.value
        : this.lastPurchasePlace,
    purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    caloriesPer100g: caloriesPer100g.present
        ? caloriesPer100g.value
        : this.caloriesPer100g,
    proteinPer100g: proteinPer100g.present
        ? proteinPer100g.value
        : this.proteinPer100g,
    fatPer100g: fatPer100g.present ? fatPer100g.value : this.fatPer100g,
    carbsPer100g: carbsPer100g.present ? carbsPer100g.value : this.carbsPer100g,
    lastModified: lastModified ?? this.lastModified,
  );
  PantryIngredientRow copyWithCompanion(PantryIngredientsCompanion data) {
    return PantryIngredientRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      boatSupabaseId: data.boatSupabaseId.present
          ? data.boatSupabaseId.value
          : this.boatSupabaseId,
      name: data.name.present ? data.name.value : this.name,
      inMyPantry: data.inMyPantry.present
          ? data.inMyPantry.value
          : this.inMyPantry,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isBundled: data.isBundled.present ? data.isBundled.value : this.isBundled,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      category: data.category.present ? data.category.value : this.category,
      flavorProfiles: data.flavorProfiles.present
          ? data.flavorProfiles.value
          : this.flavorProfiles,
      cuisineTypes: data.cuisineTypes.present
          ? data.cuisineTypes.value
          : this.cuisineTypes,
      allergenTags: data.allergenTags.present
          ? data.allergenTags.value
          : this.allergenTags,
      dietaryTags: data.dietaryTags.present
          ? data.dietaryTags.value
          : this.dietaryTags,
      substitute1: data.substitute1.present
          ? data.substitute1.value
          : this.substitute1,
      substitute2: data.substitute2.present
          ? data.substitute2.value
          : this.substitute2,
      localPhotoPath: data.localPhotoPath.present
          ? data.localPhotoPath.value
          : this.localPhotoPath,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      lastKnownPrice: data.lastKnownPrice.present
          ? data.lastKnownPrice.value
          : this.lastKnownPrice,
      priceCurrency: data.priceCurrency.present
          ? data.priceCurrency.value
          : this.priceCurrency,
      lastKnownPriceUnit: data.lastKnownPriceUnit.present
          ? data.lastKnownPriceUnit.value
          : this.lastKnownPriceUnit,
      lastPurchasePlace: data.lastPurchasePlace.present
          ? data.lastPurchasePlace.value
          : this.lastPurchasePlace,
      purchaseHistory: data.purchaseHistory.present
          ? data.purchaseHistory.value
          : this.purchaseHistory,
      caloriesPer100g: data.caloriesPer100g.present
          ? data.caloriesPer100g.value
          : this.caloriesPer100g,
      proteinPer100g: data.proteinPer100g.present
          ? data.proteinPer100g.value
          : this.proteinPer100g,
      fatPer100g: data.fatPer100g.present
          ? data.fatPer100g.value
          : this.fatPer100g,
      carbsPer100g: data.carbsPer100g.present
          ? data.carbsPer100g.value
          : this.carbsPer100g,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PantryIngredientRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('inMyPantry: $inMyPantry, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('category: $category, ')
          ..write('flavorProfiles: $flavorProfiles, ')
          ..write('cuisineTypes: $cuisineTypes, ')
          ..write('allergenTags: $allergenTags, ')
          ..write('dietaryTags: $dietaryTags, ')
          ..write('substitute1: $substitute1, ')
          ..write('substitute2: $substitute2, ')
          ..write('localPhotoPath: $localPhotoPath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('lastKnownPrice: $lastKnownPrice, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('lastKnownPriceUnit: $lastKnownPriceUnit, ')
          ..write('lastPurchasePlace: $lastPurchasePlace, ')
          ..write('purchaseHistory: $purchaseHistory, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    supabaseId,
    boatSupabaseId,
    name,
    inMyPantry,
    quantity,
    unit,
    sortOrder,
    isBundled,
    isSynced,
    category,
    flavorProfiles,
    cuisineTypes,
    allergenTags,
    dietaryTags,
    substitute1,
    substitute2,
    localPhotoPath,
    imageUrl,
    expiryDate,
    lastKnownPrice,
    priceCurrency,
    lastKnownPriceUnit,
    lastPurchasePlace,
    purchaseHistory,
    caloriesPer100g,
    proteinPer100g,
    fatPer100g,
    carbsPer100g,
    lastModified,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PantryIngredientRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.boatSupabaseId == this.boatSupabaseId &&
          other.name == this.name &&
          other.inMyPantry == this.inMyPantry &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.sortOrder == this.sortOrder &&
          other.isBundled == this.isBundled &&
          other.isSynced == this.isSynced &&
          other.category == this.category &&
          other.flavorProfiles == this.flavorProfiles &&
          other.cuisineTypes == this.cuisineTypes &&
          other.allergenTags == this.allergenTags &&
          other.dietaryTags == this.dietaryTags &&
          other.substitute1 == this.substitute1 &&
          other.substitute2 == this.substitute2 &&
          other.localPhotoPath == this.localPhotoPath &&
          other.imageUrl == this.imageUrl &&
          other.expiryDate == this.expiryDate &&
          other.lastKnownPrice == this.lastKnownPrice &&
          other.priceCurrency == this.priceCurrency &&
          other.lastKnownPriceUnit == this.lastKnownPriceUnit &&
          other.lastPurchasePlace == this.lastPurchasePlace &&
          other.purchaseHistory == this.purchaseHistory &&
          other.caloriesPer100g == this.caloriesPer100g &&
          other.proteinPer100g == this.proteinPer100g &&
          other.fatPer100g == this.fatPer100g &&
          other.carbsPer100g == this.carbsPer100g &&
          other.lastModified == this.lastModified);
}

class PantryIngredientsCompanion extends UpdateCompanion<PantryIngredientRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> boatSupabaseId;
  final Value<String> name;
  final Value<bool> inMyPantry;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<int> sortOrder;
  final Value<bool> isBundled;
  final Value<bool> isSynced;
  final Value<String> category;
  final Value<String> flavorProfiles;
  final Value<String> cuisineTypes;
  final Value<String> allergenTags;
  final Value<String> dietaryTags;
  final Value<String?> substitute1;
  final Value<String?> substitute2;
  final Value<String?> localPhotoPath;
  final Value<String?> imageUrl;
  final Value<DateTime?> expiryDate;
  final Value<double?> lastKnownPrice;
  final Value<String> priceCurrency;
  final Value<String?> lastKnownPriceUnit;
  final Value<String?> lastPurchasePlace;
  final Value<String> purchaseHistory;
  final Value<double?> caloriesPer100g;
  final Value<double?> proteinPer100g;
  final Value<double?> fatPer100g;
  final Value<double?> carbsPer100g;
  final Value<DateTime> lastModified;
  const PantryIngredientsCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.inMyPantry = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.category = const Value.absent(),
    this.flavorProfiles = const Value.absent(),
    this.cuisineTypes = const Value.absent(),
    this.allergenTags = const Value.absent(),
    this.dietaryTags = const Value.absent(),
    this.substitute1 = const Value.absent(),
    this.substitute2 = const Value.absent(),
    this.localPhotoPath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.lastKnownPrice = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.lastKnownPriceUnit = const Value.absent(),
    this.lastPurchasePlace = const Value.absent(),
    this.purchaseHistory = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  PantryIngredientsCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.boatSupabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.inMyPantry = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isBundled = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.category = const Value.absent(),
    this.flavorProfiles = const Value.absent(),
    this.cuisineTypes = const Value.absent(),
    this.allergenTags = const Value.absent(),
    this.dietaryTags = const Value.absent(),
    this.substitute1 = const Value.absent(),
    this.substitute2 = const Value.absent(),
    this.localPhotoPath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.lastKnownPrice = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.lastKnownPriceUnit = const Value.absent(),
    this.lastPurchasePlace = const Value.absent(),
    this.purchaseHistory = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  static Insertable<PantryIngredientRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? boatSupabaseId,
    Expression<String>? name,
    Expression<bool>? inMyPantry,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<int>? sortOrder,
    Expression<bool>? isBundled,
    Expression<bool>? isSynced,
    Expression<String>? category,
    Expression<String>? flavorProfiles,
    Expression<String>? cuisineTypes,
    Expression<String>? allergenTags,
    Expression<String>? dietaryTags,
    Expression<String>? substitute1,
    Expression<String>? substitute2,
    Expression<String>? localPhotoPath,
    Expression<String>? imageUrl,
    Expression<DateTime>? expiryDate,
    Expression<double>? lastKnownPrice,
    Expression<String>? priceCurrency,
    Expression<String>? lastKnownPriceUnit,
    Expression<String>? lastPurchasePlace,
    Expression<String>? purchaseHistory,
    Expression<double>? caloriesPer100g,
    Expression<double>? proteinPer100g,
    Expression<double>? fatPer100g,
    Expression<double>? carbsPer100g,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (boatSupabaseId != null) 'boat_supabase_id': boatSupabaseId,
      if (name != null) 'name': name,
      if (inMyPantry != null) 'in_my_pantry': inMyPantry,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isBundled != null) 'is_bundled': isBundled,
      if (isSynced != null) 'is_synced': isSynced,
      if (category != null) 'category': category,
      if (flavorProfiles != null) 'flavor_profiles': flavorProfiles,
      if (cuisineTypes != null) 'cuisine_types': cuisineTypes,
      if (allergenTags != null) 'allergen_tags': allergenTags,
      if (dietaryTags != null) 'dietary_tags': dietaryTags,
      if (substitute1 != null) 'substitute1': substitute1,
      if (substitute2 != null) 'substitute2': substitute2,
      if (localPhotoPath != null) 'local_photo_path': localPhotoPath,
      if (imageUrl != null) 'image_url': imageUrl,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (lastKnownPrice != null) 'last_known_price': lastKnownPrice,
      if (priceCurrency != null) 'price_currency': priceCurrency,
      if (lastKnownPriceUnit != null)
        'last_known_price_unit': lastKnownPriceUnit,
      if (lastPurchasePlace != null) 'last_purchase_place': lastPurchasePlace,
      if (purchaseHistory != null) 'purchase_history': purchaseHistory,
      if (caloriesPer100g != null) 'calories_per100g': caloriesPer100g,
      if (proteinPer100g != null) 'protein_per100g': proteinPer100g,
      if (fatPer100g != null) 'fat_per100g': fatPer100g,
      if (carbsPer100g != null) 'carbs_per100g': carbsPer100g,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  PantryIngredientsCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? boatSupabaseId,
    Value<String>? name,
    Value<bool>? inMyPantry,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<int>? sortOrder,
    Value<bool>? isBundled,
    Value<bool>? isSynced,
    Value<String>? category,
    Value<String>? flavorProfiles,
    Value<String>? cuisineTypes,
    Value<String>? allergenTags,
    Value<String>? dietaryTags,
    Value<String?>? substitute1,
    Value<String?>? substitute2,
    Value<String?>? localPhotoPath,
    Value<String?>? imageUrl,
    Value<DateTime?>? expiryDate,
    Value<double?>? lastKnownPrice,
    Value<String>? priceCurrency,
    Value<String?>? lastKnownPriceUnit,
    Value<String?>? lastPurchasePlace,
    Value<String>? purchaseHistory,
    Value<double?>? caloriesPer100g,
    Value<double?>? proteinPer100g,
    Value<double?>? fatPer100g,
    Value<double?>? carbsPer100g,
    Value<DateTime>? lastModified,
  }) {
    return PantryIngredientsCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      boatSupabaseId: boatSupabaseId ?? this.boatSupabaseId,
      name: name ?? this.name,
      inMyPantry: inMyPantry ?? this.inMyPantry,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      sortOrder: sortOrder ?? this.sortOrder,
      isBundled: isBundled ?? this.isBundled,
      isSynced: isSynced ?? this.isSynced,
      category: category ?? this.category,
      flavorProfiles: flavorProfiles ?? this.flavorProfiles,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      allergenTags: allergenTags ?? this.allergenTags,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      substitute1: substitute1 ?? this.substitute1,
      substitute2: substitute2 ?? this.substitute2,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      lastKnownPrice: lastKnownPrice ?? this.lastKnownPrice,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      lastKnownPriceUnit: lastKnownPriceUnit ?? this.lastKnownPriceUnit,
      lastPurchasePlace: lastPurchasePlace ?? this.lastPurchasePlace,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (boatSupabaseId.present) {
      map['boat_supabase_id'] = Variable<String>(boatSupabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (inMyPantry.present) {
      map['in_my_pantry'] = Variable<bool>(inMyPantry.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isBundled.present) {
      map['is_bundled'] = Variable<bool>(isBundled.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (flavorProfiles.present) {
      map['flavor_profiles'] = Variable<String>(flavorProfiles.value);
    }
    if (cuisineTypes.present) {
      map['cuisine_types'] = Variable<String>(cuisineTypes.value);
    }
    if (allergenTags.present) {
      map['allergen_tags'] = Variable<String>(allergenTags.value);
    }
    if (dietaryTags.present) {
      map['dietary_tags'] = Variable<String>(dietaryTags.value);
    }
    if (substitute1.present) {
      map['substitute1'] = Variable<String>(substitute1.value);
    }
    if (substitute2.present) {
      map['substitute2'] = Variable<String>(substitute2.value);
    }
    if (localPhotoPath.present) {
      map['local_photo_path'] = Variable<String>(localPhotoPath.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (lastKnownPrice.present) {
      map['last_known_price'] = Variable<double>(lastKnownPrice.value);
    }
    if (priceCurrency.present) {
      map['price_currency'] = Variable<String>(priceCurrency.value);
    }
    if (lastKnownPriceUnit.present) {
      map['last_known_price_unit'] = Variable<String>(lastKnownPriceUnit.value);
    }
    if (lastPurchasePlace.present) {
      map['last_purchase_place'] = Variable<String>(lastPurchasePlace.value);
    }
    if (purchaseHistory.present) {
      map['purchase_history'] = Variable<String>(purchaseHistory.value);
    }
    if (caloriesPer100g.present) {
      map['calories_per100g'] = Variable<double>(caloriesPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per100g'] = Variable<double>(proteinPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per100g'] = Variable<double>(fatPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PantryIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('boatSupabaseId: $boatSupabaseId, ')
          ..write('name: $name, ')
          ..write('inMyPantry: $inMyPantry, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isBundled: $isBundled, ')
          ..write('isSynced: $isSynced, ')
          ..write('category: $category, ')
          ..write('flavorProfiles: $flavorProfiles, ')
          ..write('cuisineTypes: $cuisineTypes, ')
          ..write('allergenTags: $allergenTags, ')
          ..write('dietaryTags: $dietaryTags, ')
          ..write('substitute1: $substitute1, ')
          ..write('substitute2: $substitute2, ')
          ..write('localPhotoPath: $localPhotoPath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('lastKnownPrice: $lastKnownPrice, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('lastKnownPriceUnit: $lastKnownPriceUnit, ')
          ..write('lastPurchasePlace: $lastPurchasePlace, ')
          ..write('purchaseHistory: $purchaseHistory, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _activeBoatSupabaseIdMeta =
      const VerificationMeta('activeBoatSupabaseId');
  @override
  late final GeneratedColumn<String> activeBoatSupabaseId =
      GeneratedColumn<String>(
        'active_boat_supabase_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _showHiddenItemsMeta = const VerificationMeta(
    'showHiddenItems',
  );
  @override
  late final GeneratedColumn<bool> showHiddenItems = GeneratedColumn<bool>(
    'show_hidden_items',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_hidden_items" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isProMeta = const VerificationMeta('isPro');
  @override
  late final GeneratedColumn<bool> isPro = GeneratedColumn<bool>(
    'is_pro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pro" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _proExpiresAtMeta = const VerificationMeta(
    'proExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> proExpiresAt = GeneratedColumn<DateTime>(
    'pro_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedBoatIdMeta = const VerificationMeta(
    'selectedBoatId',
  );
  @override
  late final GeneratedColumn<String> selectedBoatId = GeneratedColumn<String>(
    'selected_boat_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDarkModeMeta = const VerificationMeta(
    'isDarkMode',
  );
  @override
  late final GeneratedColumn<bool> isDarkMode = GeneratedColumn<bool>(
    'is_dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _unitPrefsJsonMeta = const VerificationMeta(
    'unitPrefsJson',
  );
  @override
  late final GeneratedColumn<String> unitPrefsJson = GeneratedColumn<String>(
    'unit_prefs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _recentEmailsMeta = const VerificationMeta(
    'recentEmails',
  );
  @override
  late final GeneratedColumn<String> recentEmails = GeneratedColumn<String>(
    'recent_emails',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _fromNameMeta = const VerificationMeta(
    'fromName',
  );
  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
    'from_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToEmailMeta = const VerificationMeta(
    'replyToEmail',
  );
  @override
  late final GeneratedColumn<String> replyToEmail = GeneratedColumn<String>(
    'reply_to_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boatNameMeta = const VerificationMeta(
    'boatName',
  );
  @override
  late final GeneratedColumn<String> boatName = GeneratedColumn<String>(
    'boat_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freeEditsUsedMeta = const VerificationMeta(
    'freeEditsUsed',
  );
  @override
  late final GeneratedColumn<int> freeEditsUsed = GeneratedColumn<int>(
    'free_edits_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activeBoatSupabaseId,
    showHiddenItems,
    isPro,
    proExpiresAt,
    selectedBoatId,
    userId,
    isDarkMode,
    unitPrefsJson,
    isSynced,
    lastModified,
    recentEmails,
    fromName,
    replyToEmail,
    boatName,
    freeEditsUsed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('active_boat_supabase_id')) {
      context.handle(
        _activeBoatSupabaseIdMeta,
        activeBoatSupabaseId.isAcceptableOrUnknown(
          data['active_boat_supabase_id']!,
          _activeBoatSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('show_hidden_items')) {
      context.handle(
        _showHiddenItemsMeta,
        showHiddenItems.isAcceptableOrUnknown(
          data['show_hidden_items']!,
          _showHiddenItemsMeta,
        ),
      );
    }
    if (data.containsKey('is_pro')) {
      context.handle(
        _isProMeta,
        isPro.isAcceptableOrUnknown(data['is_pro']!, _isProMeta),
      );
    }
    if (data.containsKey('pro_expires_at')) {
      context.handle(
        _proExpiresAtMeta,
        proExpiresAt.isAcceptableOrUnknown(
          data['pro_expires_at']!,
          _proExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('selected_boat_id')) {
      context.handle(
        _selectedBoatIdMeta,
        selectedBoatId.isAcceptableOrUnknown(
          data['selected_boat_id']!,
          _selectedBoatIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('is_dark_mode')) {
      context.handle(
        _isDarkModeMeta,
        isDarkMode.isAcceptableOrUnknown(
          data['is_dark_mode']!,
          _isDarkModeMeta,
        ),
      );
    }
    if (data.containsKey('unit_prefs_json')) {
      context.handle(
        _unitPrefsJsonMeta,
        unitPrefsJson.isAcceptableOrUnknown(
          data['unit_prefs_json']!,
          _unitPrefsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('recent_emails')) {
      context.handle(
        _recentEmailsMeta,
        recentEmails.isAcceptableOrUnknown(
          data['recent_emails']!,
          _recentEmailsMeta,
        ),
      );
    }
    if (data.containsKey('from_name')) {
      context.handle(
        _fromNameMeta,
        fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta),
      );
    }
    if (data.containsKey('reply_to_email')) {
      context.handle(
        _replyToEmailMeta,
        replyToEmail.isAcceptableOrUnknown(
          data['reply_to_email']!,
          _replyToEmailMeta,
        ),
      );
    }
    if (data.containsKey('boat_name')) {
      context.handle(
        _boatNameMeta,
        boatName.isAcceptableOrUnknown(data['boat_name']!, _boatNameMeta),
      );
    }
    if (data.containsKey('free_edits_used')) {
      context.handle(
        _freeEditsUsedMeta,
        freeEditsUsed.isAcceptableOrUnknown(
          data['free_edits_used']!,
          _freeEditsUsedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activeBoatSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_boat_supabase_id'],
      ),
      showHiddenItems: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_hidden_items'],
      )!,
      isPro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pro'],
      )!,
      proExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pro_expires_at'],
      ),
      selectedBoatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_boat_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      isDarkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dark_mode'],
      )!,
      unitPrefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_prefs_json'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      recentEmails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recent_emails'],
      )!,
      fromName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_name'],
      ),
      replyToEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_email'],
      ),
      boatName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_name'],
      ),
      freeEditsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_edits_used'],
      )!,
    );
  }

  @override
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }
}

class UserSettingsRow extends DataClass implements Insertable<UserSettingsRow> {
  final int id;
  final String? activeBoatSupabaseId;
  final bool showHiddenItems;
  final bool isPro;
  final DateTime? proExpiresAt;
  final String? selectedBoatId;
  final String? userId;
  final bool isDarkMode;

  /// JSON [AppUnitPrefs]: volume, temperature, speed, depth, distance.
  final String unitPrefsJson;
  final bool isSynced;
  final DateTime lastModified;
  final String recentEmails;
  final String? fromName;
  final String? replyToEmail;
  final String? boatName;

  /// FREE-EDITS: how many of the free-tier's teaser edits/completions have
  /// been used. Local-only — Free never syncs. See `FreeEditGate`.
  final int freeEditsUsed;
  const UserSettingsRow({
    required this.id,
    this.activeBoatSupabaseId,
    required this.showHiddenItems,
    required this.isPro,
    this.proExpiresAt,
    this.selectedBoatId,
    this.userId,
    required this.isDarkMode,
    required this.unitPrefsJson,
    required this.isSynced,
    required this.lastModified,
    required this.recentEmails,
    this.fromName,
    this.replyToEmail,
    this.boatName,
    required this.freeEditsUsed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || activeBoatSupabaseId != null) {
      map['active_boat_supabase_id'] = Variable<String>(activeBoatSupabaseId);
    }
    map['show_hidden_items'] = Variable<bool>(showHiddenItems);
    map['is_pro'] = Variable<bool>(isPro);
    if (!nullToAbsent || proExpiresAt != null) {
      map['pro_expires_at'] = Variable<DateTime>(proExpiresAt);
    }
    if (!nullToAbsent || selectedBoatId != null) {
      map['selected_boat_id'] = Variable<String>(selectedBoatId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['is_dark_mode'] = Variable<bool>(isDarkMode);
    map['unit_prefs_json'] = Variable<String>(unitPrefsJson);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['recent_emails'] = Variable<String>(recentEmails);
    if (!nullToAbsent || fromName != null) {
      map['from_name'] = Variable<String>(fromName);
    }
    if (!nullToAbsent || replyToEmail != null) {
      map['reply_to_email'] = Variable<String>(replyToEmail);
    }
    if (!nullToAbsent || boatName != null) {
      map['boat_name'] = Variable<String>(boatName);
    }
    map['free_edits_used'] = Variable<int>(freeEditsUsed);
    return map;
  }

  UserSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsTableCompanion(
      id: Value(id),
      activeBoatSupabaseId: activeBoatSupabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeBoatSupabaseId),
      showHiddenItems: Value(showHiddenItems),
      isPro: Value(isPro),
      proExpiresAt: proExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(proExpiresAt),
      selectedBoatId: selectedBoatId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedBoatId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      isDarkMode: Value(isDarkMode),
      unitPrefsJson: Value(unitPrefsJson),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
      recentEmails: Value(recentEmails),
      fromName: fromName == null && nullToAbsent
          ? const Value.absent()
          : Value(fromName),
      replyToEmail: replyToEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToEmail),
      boatName: boatName == null && nullToAbsent
          ? const Value.absent()
          : Value(boatName),
      freeEditsUsed: Value(freeEditsUsed),
    );
  }

  factory UserSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      activeBoatSupabaseId: serializer.fromJson<String?>(
        json['activeBoatSupabaseId'],
      ),
      showHiddenItems: serializer.fromJson<bool>(json['showHiddenItems']),
      isPro: serializer.fromJson<bool>(json['isPro']),
      proExpiresAt: serializer.fromJson<DateTime?>(json['proExpiresAt']),
      selectedBoatId: serializer.fromJson<String?>(json['selectedBoatId']),
      userId: serializer.fromJson<String?>(json['userId']),
      isDarkMode: serializer.fromJson<bool>(json['isDarkMode']),
      unitPrefsJson: serializer.fromJson<String>(json['unitPrefsJson']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      recentEmails: serializer.fromJson<String>(json['recentEmails']),
      fromName: serializer.fromJson<String?>(json['fromName']),
      replyToEmail: serializer.fromJson<String?>(json['replyToEmail']),
      boatName: serializer.fromJson<String?>(json['boatName']),
      freeEditsUsed: serializer.fromJson<int>(json['freeEditsUsed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activeBoatSupabaseId': serializer.toJson<String?>(activeBoatSupabaseId),
      'showHiddenItems': serializer.toJson<bool>(showHiddenItems),
      'isPro': serializer.toJson<bool>(isPro),
      'proExpiresAt': serializer.toJson<DateTime?>(proExpiresAt),
      'selectedBoatId': serializer.toJson<String?>(selectedBoatId),
      'userId': serializer.toJson<String?>(userId),
      'isDarkMode': serializer.toJson<bool>(isDarkMode),
      'unitPrefsJson': serializer.toJson<String>(unitPrefsJson),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'recentEmails': serializer.toJson<String>(recentEmails),
      'fromName': serializer.toJson<String?>(fromName),
      'replyToEmail': serializer.toJson<String?>(replyToEmail),
      'boatName': serializer.toJson<String?>(boatName),
      'freeEditsUsed': serializer.toJson<int>(freeEditsUsed),
    };
  }

  UserSettingsRow copyWith({
    int? id,
    Value<String?> activeBoatSupabaseId = const Value.absent(),
    bool? showHiddenItems,
    bool? isPro,
    Value<DateTime?> proExpiresAt = const Value.absent(),
    Value<String?> selectedBoatId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    bool? isDarkMode,
    String? unitPrefsJson,
    bool? isSynced,
    DateTime? lastModified,
    String? recentEmails,
    Value<String?> fromName = const Value.absent(),
    Value<String?> replyToEmail = const Value.absent(),
    Value<String?> boatName = const Value.absent(),
    int? freeEditsUsed,
  }) => UserSettingsRow(
    id: id ?? this.id,
    activeBoatSupabaseId: activeBoatSupabaseId.present
        ? activeBoatSupabaseId.value
        : this.activeBoatSupabaseId,
    showHiddenItems: showHiddenItems ?? this.showHiddenItems,
    isPro: isPro ?? this.isPro,
    proExpiresAt: proExpiresAt.present ? proExpiresAt.value : this.proExpiresAt,
    selectedBoatId: selectedBoatId.present
        ? selectedBoatId.value
        : this.selectedBoatId,
    userId: userId.present ? userId.value : this.userId,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    unitPrefsJson: unitPrefsJson ?? this.unitPrefsJson,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
    recentEmails: recentEmails ?? this.recentEmails,
    fromName: fromName.present ? fromName.value : this.fromName,
    replyToEmail: replyToEmail.present ? replyToEmail.value : this.replyToEmail,
    boatName: boatName.present ? boatName.value : this.boatName,
    freeEditsUsed: freeEditsUsed ?? this.freeEditsUsed,
  );
  UserSettingsRow copyWithCompanion(UserSettingsTableCompanion data) {
    return UserSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      activeBoatSupabaseId: data.activeBoatSupabaseId.present
          ? data.activeBoatSupabaseId.value
          : this.activeBoatSupabaseId,
      showHiddenItems: data.showHiddenItems.present
          ? data.showHiddenItems.value
          : this.showHiddenItems,
      isPro: data.isPro.present ? data.isPro.value : this.isPro,
      proExpiresAt: data.proExpiresAt.present
          ? data.proExpiresAt.value
          : this.proExpiresAt,
      selectedBoatId: data.selectedBoatId.present
          ? data.selectedBoatId.value
          : this.selectedBoatId,
      userId: data.userId.present ? data.userId.value : this.userId,
      isDarkMode: data.isDarkMode.present
          ? data.isDarkMode.value
          : this.isDarkMode,
      unitPrefsJson: data.unitPrefsJson.present
          ? data.unitPrefsJson.value
          : this.unitPrefsJson,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      recentEmails: data.recentEmails.present
          ? data.recentEmails.value
          : this.recentEmails,
      fromName: data.fromName.present ? data.fromName.value : this.fromName,
      replyToEmail: data.replyToEmail.present
          ? data.replyToEmail.value
          : this.replyToEmail,
      boatName: data.boatName.present ? data.boatName.value : this.boatName,
      freeEditsUsed: data.freeEditsUsed.present
          ? data.freeEditsUsed.value
          : this.freeEditsUsed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRow(')
          ..write('id: $id, ')
          ..write('activeBoatSupabaseId: $activeBoatSupabaseId, ')
          ..write('showHiddenItems: $showHiddenItems, ')
          ..write('isPro: $isPro, ')
          ..write('proExpiresAt: $proExpiresAt, ')
          ..write('selectedBoatId: $selectedBoatId, ')
          ..write('userId: $userId, ')
          ..write('isDarkMode: $isDarkMode, ')
          ..write('unitPrefsJson: $unitPrefsJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('recentEmails: $recentEmails, ')
          ..write('fromName: $fromName, ')
          ..write('replyToEmail: $replyToEmail, ')
          ..write('boatName: $boatName, ')
          ..write('freeEditsUsed: $freeEditsUsed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activeBoatSupabaseId,
    showHiddenItems,
    isPro,
    proExpiresAt,
    selectedBoatId,
    userId,
    isDarkMode,
    unitPrefsJson,
    isSynced,
    lastModified,
    recentEmails,
    fromName,
    replyToEmail,
    boatName,
    freeEditsUsed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsRow &&
          other.id == this.id &&
          other.activeBoatSupabaseId == this.activeBoatSupabaseId &&
          other.showHiddenItems == this.showHiddenItems &&
          other.isPro == this.isPro &&
          other.proExpiresAt == this.proExpiresAt &&
          other.selectedBoatId == this.selectedBoatId &&
          other.userId == this.userId &&
          other.isDarkMode == this.isDarkMode &&
          other.unitPrefsJson == this.unitPrefsJson &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified &&
          other.recentEmails == this.recentEmails &&
          other.fromName == this.fromName &&
          other.replyToEmail == this.replyToEmail &&
          other.boatName == this.boatName &&
          other.freeEditsUsed == this.freeEditsUsed);
}

class UserSettingsTableCompanion extends UpdateCompanion<UserSettingsRow> {
  final Value<int> id;
  final Value<String?> activeBoatSupabaseId;
  final Value<bool> showHiddenItems;
  final Value<bool> isPro;
  final Value<DateTime?> proExpiresAt;
  final Value<String?> selectedBoatId;
  final Value<String?> userId;
  final Value<bool> isDarkMode;
  final Value<String> unitPrefsJson;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  final Value<String> recentEmails;
  final Value<String?> fromName;
  final Value<String?> replyToEmail;
  final Value<String?> boatName;
  final Value<int> freeEditsUsed;
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.activeBoatSupabaseId = const Value.absent(),
    this.showHiddenItems = const Value.absent(),
    this.isPro = const Value.absent(),
    this.proExpiresAt = const Value.absent(),
    this.selectedBoatId = const Value.absent(),
    this.userId = const Value.absent(),
    this.isDarkMode = const Value.absent(),
    this.unitPrefsJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.recentEmails = const Value.absent(),
    this.fromName = const Value.absent(),
    this.replyToEmail = const Value.absent(),
    this.boatName = const Value.absent(),
    this.freeEditsUsed = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.activeBoatSupabaseId = const Value.absent(),
    this.showHiddenItems = const Value.absent(),
    this.isPro = const Value.absent(),
    this.proExpiresAt = const Value.absent(),
    this.selectedBoatId = const Value.absent(),
    this.userId = const Value.absent(),
    this.isDarkMode = const Value.absent(),
    this.unitPrefsJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.recentEmails = const Value.absent(),
    this.fromName = const Value.absent(),
    this.replyToEmail = const Value.absent(),
    this.boatName = const Value.absent(),
    this.freeEditsUsed = const Value.absent(),
  });
  static Insertable<UserSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? activeBoatSupabaseId,
    Expression<bool>? showHiddenItems,
    Expression<bool>? isPro,
    Expression<DateTime>? proExpiresAt,
    Expression<String>? selectedBoatId,
    Expression<String>? userId,
    Expression<bool>? isDarkMode,
    Expression<String>? unitPrefsJson,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
    Expression<String>? recentEmails,
    Expression<String>? fromName,
    Expression<String>? replyToEmail,
    Expression<String>? boatName,
    Expression<int>? freeEditsUsed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activeBoatSupabaseId != null)
        'active_boat_supabase_id': activeBoatSupabaseId,
      if (showHiddenItems != null) 'show_hidden_items': showHiddenItems,
      if (isPro != null) 'is_pro': isPro,
      if (proExpiresAt != null) 'pro_expires_at': proExpiresAt,
      if (selectedBoatId != null) 'selected_boat_id': selectedBoatId,
      if (userId != null) 'user_id': userId,
      if (isDarkMode != null) 'is_dark_mode': isDarkMode,
      if (unitPrefsJson != null) 'unit_prefs_json': unitPrefsJson,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (recentEmails != null) 'recent_emails': recentEmails,
      if (fromName != null) 'from_name': fromName,
      if (replyToEmail != null) 'reply_to_email': replyToEmail,
      if (boatName != null) 'boat_name': boatName,
      if (freeEditsUsed != null) 'free_edits_used': freeEditsUsed,
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? activeBoatSupabaseId,
    Value<bool>? showHiddenItems,
    Value<bool>? isPro,
    Value<DateTime?>? proExpiresAt,
    Value<String?>? selectedBoatId,
    Value<String?>? userId,
    Value<bool>? isDarkMode,
    Value<String>? unitPrefsJson,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
    Value<String>? recentEmails,
    Value<String?>? fromName,
    Value<String?>? replyToEmail,
    Value<String?>? boatName,
    Value<int>? freeEditsUsed,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? this.id,
      activeBoatSupabaseId: activeBoatSupabaseId ?? this.activeBoatSupabaseId,
      showHiddenItems: showHiddenItems ?? this.showHiddenItems,
      isPro: isPro ?? this.isPro,
      proExpiresAt: proExpiresAt ?? this.proExpiresAt,
      selectedBoatId: selectedBoatId ?? this.selectedBoatId,
      userId: userId ?? this.userId,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      unitPrefsJson: unitPrefsJson ?? this.unitPrefsJson,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      recentEmails: recentEmails ?? this.recentEmails,
      fromName: fromName ?? this.fromName,
      replyToEmail: replyToEmail ?? this.replyToEmail,
      boatName: boatName ?? this.boatName,
      freeEditsUsed: freeEditsUsed ?? this.freeEditsUsed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activeBoatSupabaseId.present) {
      map['active_boat_supabase_id'] = Variable<String>(
        activeBoatSupabaseId.value,
      );
    }
    if (showHiddenItems.present) {
      map['show_hidden_items'] = Variable<bool>(showHiddenItems.value);
    }
    if (isPro.present) {
      map['is_pro'] = Variable<bool>(isPro.value);
    }
    if (proExpiresAt.present) {
      map['pro_expires_at'] = Variable<DateTime>(proExpiresAt.value);
    }
    if (selectedBoatId.present) {
      map['selected_boat_id'] = Variable<String>(selectedBoatId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isDarkMode.present) {
      map['is_dark_mode'] = Variable<bool>(isDarkMode.value);
    }
    if (unitPrefsJson.present) {
      map['unit_prefs_json'] = Variable<String>(unitPrefsJson.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (recentEmails.present) {
      map['recent_emails'] = Variable<String>(recentEmails.value);
    }
    if (fromName.present) {
      map['from_name'] = Variable<String>(fromName.value);
    }
    if (replyToEmail.present) {
      map['reply_to_email'] = Variable<String>(replyToEmail.value);
    }
    if (boatName.present) {
      map['boat_name'] = Variable<String>(boatName.value);
    }
    if (freeEditsUsed.present) {
      map['free_edits_used'] = Variable<int>(freeEditsUsed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('activeBoatSupabaseId: $activeBoatSupabaseId, ')
          ..write('showHiddenItems: $showHiddenItems, ')
          ..write('isPro: $isPro, ')
          ..write('proExpiresAt: $proExpiresAt, ')
          ..write('selectedBoatId: $selectedBoatId, ')
          ..write('userId: $userId, ')
          ..write('isDarkMode: $isDarkMode, ')
          ..write('unitPrefsJson: $unitPrefsJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('recentEmails: $recentEmails, ')
          ..write('fromName: $fromName, ')
          ..write('replyToEmail: $replyToEmail, ')
          ..write('boatName: $boatName, ')
          ..write('freeEditsUsed: $freeEditsUsed')
          ..write(')'))
        .toString();
  }
}

class $CommunityTemplatesTable extends CommunityTemplates
    with TableInfo<$CommunityTemplatesTable, CommunityTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommunityTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isApprovedMeta = const VerificationMeta(
    'isApproved',
  );
  @override
  late final GeneratedColumn<bool> isApproved = GeneratedColumn<bool>(
    'is_approved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_approved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _subcategoryMeta = const VerificationMeta(
    'subcategory',
  );
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
    'subcategory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _downloadCountMeta = const VerificationMeta(
    'downloadCount',
  );
  @override
  late final GeneratedColumn<int> downloadCount = GeneratedColumn<int>(
    'download_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avgRatingMeta = const VerificationMeta(
    'avgRating',
  );
  @override
  late final GeneratedColumn<double> avgRating = GeneratedColumn<double>(
    'avg_rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ratingCountMeta = const VerificationMeta(
    'ratingCount',
  );
  @override
  late final GeneratedColumn<int> ratingCount = GeneratedColumn<int>(
    'rating_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supabaseId,
    name,
    description,
    isApproved,
    authorId,
    title,
    category,
    subcategory,
    content,
    isSynced,
    lastModified,
    downloadCount,
    avgRating,
    ratingCount,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'community_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommunityTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_approved')) {
      context.handle(
        _isApprovedMeta,
        isApproved.isAcceptableOrUnknown(data['is_approved']!, _isApprovedMeta),
      );
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('subcategory')) {
      context.handle(
        _subcategoryMeta,
        subcategory.isAcceptableOrUnknown(
          data['subcategory']!,
          _subcategoryMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('download_count')) {
      context.handle(
        _downloadCountMeta,
        downloadCount.isAcceptableOrUnknown(
          data['download_count']!,
          _downloadCountMeta,
        ),
      );
    }
    if (data.containsKey('avg_rating')) {
      context.handle(
        _avgRatingMeta,
        avgRating.isAcceptableOrUnknown(data['avg_rating']!, _avgRatingMeta),
      );
    }
    if (data.containsKey('rating_count')) {
      context.handle(
        _ratingCountMeta,
        ratingCount.isAcceptableOrUnknown(
          data['rating_count']!,
          _ratingCountMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommunityTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommunityTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isApproved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_approved'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subcategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      downloadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download_count'],
      )!,
      avgRating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_rating'],
      )!,
      ratingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_count'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $CommunityTemplatesTable createAlias(String alias) {
    return $CommunityTemplatesTable(attachedDatabase, alias);
  }
}

class CommunityTemplateRow extends DataClass
    implements Insertable<CommunityTemplateRow> {
  final int id;
  final String supabaseId;
  final String name;
  final String description;
  final bool isApproved;
  final String authorId;
  final String title;
  final String category;
  final String subcategory;
  final String content;
  final bool isSynced;
  final DateTime lastModified;
  final int downloadCount;
  final double avgRating;
  final int ratingCount;
  final int version;
  const CommunityTemplateRow({
    required this.id,
    required this.supabaseId,
    required this.name,
    required this.description,
    required this.isApproved,
    required this.authorId,
    required this.title,
    required this.category,
    required this.subcategory,
    required this.content,
    required this.isSynced,
    required this.lastModified,
    required this.downloadCount,
    required this.avgRating,
    required this.ratingCount,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supabase_id'] = Variable<String>(supabaseId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['is_approved'] = Variable<bool>(isApproved);
    map['author_id'] = Variable<String>(authorId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['subcategory'] = Variable<String>(subcategory);
    map['content'] = Variable<String>(content);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['download_count'] = Variable<int>(downloadCount);
    map['avg_rating'] = Variable<double>(avgRating);
    map['rating_count'] = Variable<int>(ratingCount);
    map['version'] = Variable<int>(version);
    return map;
  }

  CommunityTemplatesCompanion toCompanion(bool nullToAbsent) {
    return CommunityTemplatesCompanion(
      id: Value(id),
      supabaseId: Value(supabaseId),
      name: Value(name),
      description: Value(description),
      isApproved: Value(isApproved),
      authorId: Value(authorId),
      title: Value(title),
      category: Value(category),
      subcategory: Value(subcategory),
      content: Value(content),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
      downloadCount: Value(downloadCount),
      avgRating: Value(avgRating),
      ratingCount: Value(ratingCount),
      version: Value(version),
    );
  }

  factory CommunityTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommunityTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      supabaseId: serializer.fromJson<String>(json['supabaseId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      isApproved: serializer.fromJson<bool>(json['isApproved']),
      authorId: serializer.fromJson<String>(json['authorId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<String>(json['subcategory']),
      content: serializer.fromJson<String>(json['content']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      downloadCount: serializer.fromJson<int>(json['downloadCount']),
      avgRating: serializer.fromJson<double>(json['avgRating']),
      ratingCount: serializer.fromJson<int>(json['ratingCount']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supabaseId': serializer.toJson<String>(supabaseId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'isApproved': serializer.toJson<bool>(isApproved),
      'authorId': serializer.toJson<String>(authorId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<String>(subcategory),
      'content': serializer.toJson<String>(content),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'downloadCount': serializer.toJson<int>(downloadCount),
      'avgRating': serializer.toJson<double>(avgRating),
      'ratingCount': serializer.toJson<int>(ratingCount),
      'version': serializer.toJson<int>(version),
    };
  }

  CommunityTemplateRow copyWith({
    int? id,
    String? supabaseId,
    String? name,
    String? description,
    bool? isApproved,
    String? authorId,
    String? title,
    String? category,
    String? subcategory,
    String? content,
    bool? isSynced,
    DateTime? lastModified,
    int? downloadCount,
    double? avgRating,
    int? ratingCount,
    int? version,
  }) => CommunityTemplateRow(
    id: id ?? this.id,
    supabaseId: supabaseId ?? this.supabaseId,
    name: name ?? this.name,
    description: description ?? this.description,
    isApproved: isApproved ?? this.isApproved,
    authorId: authorId ?? this.authorId,
    title: title ?? this.title,
    category: category ?? this.category,
    subcategory: subcategory ?? this.subcategory,
    content: content ?? this.content,
    isSynced: isSynced ?? this.isSynced,
    lastModified: lastModified ?? this.lastModified,
    downloadCount: downloadCount ?? this.downloadCount,
    avgRating: avgRating ?? this.avgRating,
    ratingCount: ratingCount ?? this.ratingCount,
    version: version ?? this.version,
  );
  CommunityTemplateRow copyWithCompanion(CommunityTemplatesCompanion data) {
    return CommunityTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isApproved: data.isApproved.present
          ? data.isApproved.value
          : this.isApproved,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      content: data.content.present ? data.content.value : this.content,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      downloadCount: data.downloadCount.present
          ? data.downloadCount.value
          : this.downloadCount,
      avgRating: data.avgRating.present ? data.avgRating.value : this.avgRating,
      ratingCount: data.ratingCount.present
          ? data.ratingCount.value
          : this.ratingCount,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommunityTemplateRow(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isApproved: $isApproved, ')
          ..write('authorId: $authorId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('content: $content, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('downloadCount: $downloadCount, ')
          ..write('avgRating: $avgRating, ')
          ..write('ratingCount: $ratingCount, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supabaseId,
    name,
    description,
    isApproved,
    authorId,
    title,
    category,
    subcategory,
    content,
    isSynced,
    lastModified,
    downloadCount,
    avgRating,
    ratingCount,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommunityTemplateRow &&
          other.id == this.id &&
          other.supabaseId == this.supabaseId &&
          other.name == this.name &&
          other.description == this.description &&
          other.isApproved == this.isApproved &&
          other.authorId == this.authorId &&
          other.title == this.title &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.content == this.content &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified &&
          other.downloadCount == this.downloadCount &&
          other.avgRating == this.avgRating &&
          other.ratingCount == this.ratingCount &&
          other.version == this.version);
}

class CommunityTemplatesCompanion
    extends UpdateCompanion<CommunityTemplateRow> {
  final Value<int> id;
  final Value<String> supabaseId;
  final Value<String> name;
  final Value<String> description;
  final Value<bool> isApproved;
  final Value<String> authorId;
  final Value<String> title;
  final Value<String> category;
  final Value<String> subcategory;
  final Value<String> content;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  final Value<int> downloadCount;
  final Value<double> avgRating;
  final Value<int> ratingCount;
  final Value<int> version;
  const CommunityTemplatesCompanion({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isApproved = const Value.absent(),
    this.authorId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.content = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.downloadCount = const Value.absent(),
    this.avgRating = const Value.absent(),
    this.ratingCount = const Value.absent(),
    this.version = const Value.absent(),
  });
  CommunityTemplatesCompanion.insert({
    this.id = const Value.absent(),
    this.supabaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isApproved = const Value.absent(),
    this.authorId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.content = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.downloadCount = const Value.absent(),
    this.avgRating = const Value.absent(),
    this.ratingCount = const Value.absent(),
    this.version = const Value.absent(),
  });
  static Insertable<CommunityTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? supabaseId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isApproved,
    Expression<String>? authorId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<String>? content,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
    Expression<int>? downloadCount,
    Expression<double>? avgRating,
    Expression<int>? ratingCount,
    Expression<int>? version,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supabaseId != null) 'supabase_id': supabaseId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isApproved != null) 'is_approved': isApproved,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (content != null) 'content': content,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (downloadCount != null) 'download_count': downloadCount,
      if (avgRating != null) 'avg_rating': avgRating,
      if (ratingCount != null) 'rating_count': ratingCount,
      if (version != null) 'version': version,
    });
  }

  CommunityTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? supabaseId,
    Value<String>? name,
    Value<String>? description,
    Value<bool>? isApproved,
    Value<String>? authorId,
    Value<String>? title,
    Value<String>? category,
    Value<String>? subcategory,
    Value<String>? content,
    Value<bool>? isSynced,
    Value<DateTime>? lastModified,
    Value<int>? downloadCount,
    Value<double>? avgRating,
    Value<int>? ratingCount,
    Value<int>? version,
  }) {
    return CommunityTemplatesCompanion(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      name: name ?? this.name,
      description: description ?? this.description,
      isApproved: isApproved ?? this.isApproved,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      content: content ?? this.content,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      downloadCount: downloadCount ?? this.downloadCount,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
      version: version ?? this.version,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isApproved.present) {
      map['is_approved'] = Variable<bool>(isApproved.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (downloadCount.present) {
      map['download_count'] = Variable<int>(downloadCount.value);
    }
    if (avgRating.present) {
      map['avg_rating'] = Variable<double>(avgRating.value);
    }
    if (ratingCount.present) {
      map['rating_count'] = Variable<int>(ratingCount.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommunityTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('supabaseId: $supabaseId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isApproved: $isApproved, ')
          ..write('authorId: $authorId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('content: $content, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('downloadCount: $downloadCount, ')
          ..write('avgRating: $avgRating, ')
          ..write('ratingCount: $ratingCount, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxItemsTable extends SyncOutboxItems
    with TableInfo<$SyncOutboxItemsTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('create'),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDeleteMeta = const VerificationMeta(
    'isDelete',
  );
  @override
  late final GeneratedColumn<bool> isDelete = GeneratedColumn<bool>(
    'is_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    recordId,
    operation,
    data,
    priority,
    isDelete,
    status,
    retryCount,
    createdAt,
    lastAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_delete')) {
      context.handle(
        _isDeleteMeta,
        isDelete.isAcceptableOrUnknown(data['is_delete']!, _isDeleteMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_delete'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxItemsTable createAlias(String alias) {
    return $SyncOutboxItemsTable(attachedDatabase, alias);
  }
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  final int id;
  final String targetTable;
  final String recordId;
  final String operation;
  final String data;
  final int priority;
  final bool isDelete;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? lastError;
  const SyncOutboxRow({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.priority,
    required this.isDelete,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['operation'] = Variable<String>(operation);
    map['data'] = Variable<String>(data);
    map['priority'] = Variable<int>(priority);
    map['is_delete'] = Variable<bool>(isDelete);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxItemsCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      operation: Value(operation),
      data: Value(data),
      priority: Value(priority),
      isDelete: Value(isDelete),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      data: serializer.fromJson<String>(json['data']),
      priority: serializer.fromJson<int>(json['priority']),
      isDelete: serializer.fromJson<bool>(json['isDelete']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'operation': serializer.toJson<String>(operation),
      'data': serializer.toJson<String>(data),
      'priority': serializer.toJson<int>(priority),
      'isDelete': serializer.toJson<bool>(isDelete),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxRow copyWith({
    int? id,
    String? targetTable,
    String? recordId,
    String? operation,
    String? data,
    int? priority,
    bool? isDelete,
    String? status,
    int? retryCount,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxRow(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    recordId: recordId ?? this.recordId,
    operation: operation ?? this.operation,
    data: data ?? this.data,
    priority: priority ?? this.priority,
    isDelete: isDelete ?? this.isDelete,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxItemsCompanion data) {
    return SyncOutboxRow(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      data: data.data.present ? data.data.value : this.data,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDelete: data.isDelete.present ? data.isDelete.value : this.isDelete,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('priority: $priority, ')
          ..write('isDelete: $isDelete, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    recordId,
    operation,
    data,
    priority,
    isDelete,
    status,
    retryCount,
    createdAt,
    lastAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.data == this.data &&
          other.priority == this.priority &&
          other.isDelete == this.isDelete &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError);
}

class SyncOutboxItemsCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> operation;
  final Value<String> data;
  final Value<int> priority;
  final Value<bool> isDelete;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastError;
  const SyncOutboxItemsCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.data = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDelete = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncOutboxItemsCompanion.insert({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.data = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDelete = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  static Insertable<SyncOutboxRow> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<String>? data,
    Expression<int>? priority,
    Expression<bool>? isDelete,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (data != null) 'data': data,
      if (priority != null) 'priority': priority,
      if (isDelete != null) 'is_delete': isDelete,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncOutboxItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? recordId,
    Value<String>? operation,
    Value<String>? data,
    Value<int>? priority,
    Value<bool>? isDelete,
    Value<String>? status,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastError,
  }) {
    return SyncOutboxItemsCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isDelete: isDelete ?? this.isDelete,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isDelete.present) {
      map['is_delete'] = Variable<bool>(isDelete.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxItemsCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('priority: $priority, ')
          ..write('isDelete: $isDelete, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $ConflictLogsTable extends ConflictLogs
    with TableInfo<$ConflictLogsTable, ConflictLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _localSupabaseIdMeta = const VerificationMeta(
    'localSupabaseId',
  );
  @override
  late final GeneratedColumn<String> localSupabaseId = GeneratedColumn<String>(
    'local_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remoteSupabaseIdMeta = const VerificationMeta(
    'remoteSupabaseId',
  );
  @override
  late final GeneratedColumn<String> remoteSupabaseId = GeneratedColumn<String>(
    'remote_supabase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _conflictTypeMeta = const VerificationMeta(
    'conflictType',
  );
  @override
  late final GeneratedColumn<String> conflictType = GeneratedColumn<String>(
    'conflict_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('concurrent_edit'),
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _localDataMeta = const VerificationMeta(
    'localData',
  );
  @override
  late final GeneratedColumn<String> localData = GeneratedColumn<String>(
    'local_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _remoteDataMeta = const VerificationMeta(
    'remoteData',
  );
  @override
  late final GeneratedColumn<String> remoteData = GeneratedColumn<String>(
    'remote_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    localSupabaseId,
    remoteSupabaseId,
    conflictType,
    resolution,
    localData,
    remoteData,
    timestamp,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    }
    if (data.containsKey('local_supabase_id')) {
      context.handle(
        _localSupabaseIdMeta,
        localSupabaseId.isAcceptableOrUnknown(
          data['local_supabase_id']!,
          _localSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_supabase_id')) {
      context.handle(
        _remoteSupabaseIdMeta,
        remoteSupabaseId.isAcceptableOrUnknown(
          data['remote_supabase_id']!,
          _remoteSupabaseIdMeta,
        ),
      );
    }
    if (data.containsKey('conflict_type')) {
      context.handle(
        _conflictTypeMeta,
        conflictType.isAcceptableOrUnknown(
          data['conflict_type']!,
          _conflictTypeMeta,
        ),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('local_data')) {
      context.handle(
        _localDataMeta,
        localData.isAcceptableOrUnknown(data['local_data']!, _localDataMeta),
      );
    }
    if (data.containsKey('remote_data')) {
      context.handle(
        _remoteDataMeta,
        remoteData.isAcceptableOrUnknown(data['remote_data']!, _remoteDataMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      localSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_supabase_id'],
      )!,
      remoteSupabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_supabase_id'],
      )!,
      conflictType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_type'],
      )!,
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      )!,
      localData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_data'],
      )!,
      remoteData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_data'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $ConflictLogsTable createAlias(String alias) {
    return $ConflictLogsTable(attachedDatabase, alias);
  }
}

class ConflictLogRow extends DataClass implements Insertable<ConflictLogRow> {
  final int id;
  final String targetTable;
  final String localSupabaseId;
  final String remoteSupabaseId;
  final String conflictType;
  final String resolution;
  final String localData;
  final String remoteData;
  final DateTime timestamp;
  final DateTime? resolvedAt;
  const ConflictLogRow({
    required this.id,
    required this.targetTable,
    required this.localSupabaseId,
    required this.remoteSupabaseId,
    required this.conflictType,
    required this.resolution,
    required this.localData,
    required this.remoteData,
    required this.timestamp,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['local_supabase_id'] = Variable<String>(localSupabaseId);
    map['remote_supabase_id'] = Variable<String>(remoteSupabaseId);
    map['conflict_type'] = Variable<String>(conflictType);
    map['resolution'] = Variable<String>(resolution);
    map['local_data'] = Variable<String>(localData);
    map['remote_data'] = Variable<String>(remoteData);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  ConflictLogsCompanion toCompanion(bool nullToAbsent) {
    return ConflictLogsCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      localSupabaseId: Value(localSupabaseId),
      remoteSupabaseId: Value(remoteSupabaseId),
      conflictType: Value(conflictType),
      resolution: Value(resolution),
      localData: Value(localData),
      remoteData: Value(remoteData),
      timestamp: Value(timestamp),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory ConflictLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictLogRow(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      localSupabaseId: serializer.fromJson<String>(json['localSupabaseId']),
      remoteSupabaseId: serializer.fromJson<String>(json['remoteSupabaseId']),
      conflictType: serializer.fromJson<String>(json['conflictType']),
      resolution: serializer.fromJson<String>(json['resolution']),
      localData: serializer.fromJson<String>(json['localData']),
      remoteData: serializer.fromJson<String>(json['remoteData']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'localSupabaseId': serializer.toJson<String>(localSupabaseId),
      'remoteSupabaseId': serializer.toJson<String>(remoteSupabaseId),
      'conflictType': serializer.toJson<String>(conflictType),
      'resolution': serializer.toJson<String>(resolution),
      'localData': serializer.toJson<String>(localData),
      'remoteData': serializer.toJson<String>(remoteData),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  ConflictLogRow copyWith({
    int? id,
    String? targetTable,
    String? localSupabaseId,
    String? remoteSupabaseId,
    String? conflictType,
    String? resolution,
    String? localData,
    String? remoteData,
    DateTime? timestamp,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => ConflictLogRow(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    localSupabaseId: localSupabaseId ?? this.localSupabaseId,
    remoteSupabaseId: remoteSupabaseId ?? this.remoteSupabaseId,
    conflictType: conflictType ?? this.conflictType,
    resolution: resolution ?? this.resolution,
    localData: localData ?? this.localData,
    remoteData: remoteData ?? this.remoteData,
    timestamp: timestamp ?? this.timestamp,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  ConflictLogRow copyWithCompanion(ConflictLogsCompanion data) {
    return ConflictLogRow(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      localSupabaseId: data.localSupabaseId.present
          ? data.localSupabaseId.value
          : this.localSupabaseId,
      remoteSupabaseId: data.remoteSupabaseId.present
          ? data.remoteSupabaseId.value
          : this.remoteSupabaseId,
      conflictType: data.conflictType.present
          ? data.conflictType.value
          : this.conflictType,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      localData: data.localData.present ? data.localData.value : this.localData,
      remoteData: data.remoteData.present
          ? data.remoteData.value
          : this.remoteData,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictLogRow(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('localSupabaseId: $localSupabaseId, ')
          ..write('remoteSupabaseId: $remoteSupabaseId, ')
          ..write('conflictType: $conflictType, ')
          ..write('resolution: $resolution, ')
          ..write('localData: $localData, ')
          ..write('remoteData: $remoteData, ')
          ..write('timestamp: $timestamp, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    localSupabaseId,
    remoteSupabaseId,
    conflictType,
    resolution,
    localData,
    remoteData,
    timestamp,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictLogRow &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.localSupabaseId == this.localSupabaseId &&
          other.remoteSupabaseId == this.remoteSupabaseId &&
          other.conflictType == this.conflictType &&
          other.resolution == this.resolution &&
          other.localData == this.localData &&
          other.remoteData == this.remoteData &&
          other.timestamp == this.timestamp &&
          other.resolvedAt == this.resolvedAt);
}

class ConflictLogsCompanion extends UpdateCompanion<ConflictLogRow> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> localSupabaseId;
  final Value<String> remoteSupabaseId;
  final Value<String> conflictType;
  final Value<String> resolution;
  final Value<String> localData;
  final Value<String> remoteData;
  final Value<DateTime> timestamp;
  final Value<DateTime?> resolvedAt;
  const ConflictLogsCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.localSupabaseId = const Value.absent(),
    this.remoteSupabaseId = const Value.absent(),
    this.conflictType = const Value.absent(),
    this.resolution = const Value.absent(),
    this.localData = const Value.absent(),
    this.remoteData = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  ConflictLogsCompanion.insert({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.localSupabaseId = const Value.absent(),
    this.remoteSupabaseId = const Value.absent(),
    this.conflictType = const Value.absent(),
    this.resolution = const Value.absent(),
    this.localData = const Value.absent(),
    this.remoteData = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  static Insertable<ConflictLogRow> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? localSupabaseId,
    Expression<String>? remoteSupabaseId,
    Expression<String>? conflictType,
    Expression<String>? resolution,
    Expression<String>? localData,
    Expression<String>? remoteData,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? resolvedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (localSupabaseId != null) 'local_supabase_id': localSupabaseId,
      if (remoteSupabaseId != null) 'remote_supabase_id': remoteSupabaseId,
      if (conflictType != null) 'conflict_type': conflictType,
      if (resolution != null) 'resolution': resolution,
      if (localData != null) 'local_data': localData,
      if (remoteData != null) 'remote_data': remoteData,
      if (timestamp != null) 'timestamp': timestamp,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
    });
  }

  ConflictLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? localSupabaseId,
    Value<String>? remoteSupabaseId,
    Value<String>? conflictType,
    Value<String>? resolution,
    Value<String>? localData,
    Value<String>? remoteData,
    Value<DateTime>? timestamp,
    Value<DateTime?>? resolvedAt,
  }) {
    return ConflictLogsCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      localSupabaseId: localSupabaseId ?? this.localSupabaseId,
      remoteSupabaseId: remoteSupabaseId ?? this.remoteSupabaseId,
      conflictType: conflictType ?? this.conflictType,
      resolution: resolution ?? this.resolution,
      localData: localData ?? this.localData,
      remoteData: remoteData ?? this.remoteData,
      timestamp: timestamp ?? this.timestamp,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (localSupabaseId.present) {
      map['local_supabase_id'] = Variable<String>(localSupabaseId.value);
    }
    if (remoteSupabaseId.present) {
      map['remote_supabase_id'] = Variable<String>(remoteSupabaseId.value);
    }
    if (conflictType.present) {
      map['conflict_type'] = Variable<String>(conflictType.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (localData.present) {
      map['local_data'] = Variable<String>(localData.value);
    }
    if (remoteData.present) {
      map['remote_data'] = Variable<String>(remoteData.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictLogsCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('localSupabaseId: $localSupabaseId, ')
          ..write('remoteSupabaseId: $remoteSupabaseId, ')
          ..write('conflictType: $conflictType, ')
          ..write('resolution: $resolution, ')
          ..write('localData: $localData, ')
          ..write('remoteData: $remoteData, ')
          ..write('timestamp: $timestamp, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }
}

class $ErrorLogsTable extends ErrorLogs
    with TableInfo<$ErrorLogsTable, ErrorLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ErrorLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('error'),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stackTraceMeta = const VerificationMeta(
    'stackTrace',
  );
  @override
  late final GeneratedColumn<String> stackTrace = GeneratedColumn<String>(
    'stack_trace',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceFileMeta = const VerificationMeta(
    'sourceFile',
  );
  @override
  late final GeneratedColumn<String> sourceFile = GeneratedColumn<String>(
    'source_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeHintMeta = const VerificationMeta(
    'routeHint',
  );
  @override
  late final GeneratedColumn<String> routeHint = GeneratedColumn<String>(
    'route_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isProMeta = const VerificationMeta('isPro');
  @override
  late final GeneratedColumn<bool> isPro = GeneratedColumn<bool>(
    'is_pro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pro" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _occurrencesMeta = const VerificationMeta(
    'occurrences',
  );
  @override
  late final GeneratedColumn<int> occurrences = GeneratedColumn<int>(
    'occurrences',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueUrlMeta = const VerificationMeta(
    'issueUrl',
  );
  @override
  late final GeneratedColumn<String> issueUrl = GeneratedColumn<String>(
    'issue_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debugBreadcrumbsMeta = const VerificationMeta(
    'debugBreadcrumbs',
  );
  @override
  late final GeneratedColumn<String> debugBreadcrumbs = GeneratedColumn<String>(
    'debug_breadcrumbs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    level,
    message,
    stackTrace,
    sourceFile,
    routeHint,
    appVersion,
    platform,
    isPro,
    fingerprint,
    occurrences,
    processedAt,
    issueUrl,
    debugBreadcrumbs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ErrorLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('stack_trace')) {
      context.handle(
        _stackTraceMeta,
        stackTrace.isAcceptableOrUnknown(data['stack_trace']!, _stackTraceMeta),
      );
    }
    if (data.containsKey('source_file')) {
      context.handle(
        _sourceFileMeta,
        sourceFile.isAcceptableOrUnknown(data['source_file']!, _sourceFileMeta),
      );
    }
    if (data.containsKey('route_hint')) {
      context.handle(
        _routeHintMeta,
        routeHint.isAcceptableOrUnknown(data['route_hint']!, _routeHintMeta),
      );
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('is_pro')) {
      context.handle(
        _isProMeta,
        isPro.isAcceptableOrUnknown(data['is_pro']!, _isProMeta),
      );
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    }
    if (data.containsKey('occurrences')) {
      context.handle(
        _occurrencesMeta,
        occurrences.isAcceptableOrUnknown(
          data['occurrences']!,
          _occurrencesMeta,
        ),
      );
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    if (data.containsKey('issue_url')) {
      context.handle(
        _issueUrlMeta,
        issueUrl.isAcceptableOrUnknown(data['issue_url']!, _issueUrlMeta),
      );
    }
    if (data.containsKey('debug_breadcrumbs')) {
      context.handle(
        _debugBreadcrumbsMeta,
        debugBreadcrumbs.isAcceptableOrUnknown(
          data['debug_breadcrumbs']!,
          _debugBreadcrumbsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ErrorLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      stackTrace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stack_trace'],
      ),
      sourceFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_file'],
      ),
      routeHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_hint'],
      ),
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      isPro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pro'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      occurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrences'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      ),
      issueUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_url'],
      ),
      debugBreadcrumbs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debug_breadcrumbs'],
      ),
    );
  }

  @override
  $ErrorLogsTable createAlias(String alias) {
    return $ErrorLogsTable(attachedDatabase, alias);
  }
}

class ErrorLogRow extends DataClass implements Insertable<ErrorLogRow> {
  final int id;
  final DateTime createdAt;

  /// `warning` | `error` | `exception`
  final String level;
  final String message;
  final String? stackTrace;

  /// Top app-frame parsed from the stack, e.g. `lib/services/sync_service.dart`.
  final String? sourceFile;
  final String? routeHint;
  final String appVersion;
  final String platform;
  final bool isPro;

  /// Dedupe key: hash of level + sourceFile + a digit-normalized message.
  final String fingerprint;
  final int occurrences;

  /// Set once `scripts/triage_error_logs.sh` has filed/updated a GitHub issue
  /// for this fingerprint.
  final DateTime? processedAt;
  final String? issueUrl;

  /// `exception`-level only: newline-joined recent Riverpod provider
  /// lifecycle events (see `lib/services/provider_breadcrumbs.dart`) at the
  /// moment this was captured — which provider was updating/failing right
  /// before a rare, timing-dependent crash (e.g. "setState() called during
  /// build" races). Deliberately excluded from [fingerprint]/[message] since
  /// it differs on every occurrence of the same underlying bug and would
  /// otherwise break dedupe (#147/#176 follow-up).
  final String? debugBreadcrumbs;
  const ErrorLogRow({
    required this.id,
    required this.createdAt,
    required this.level,
    required this.message,
    this.stackTrace,
    this.sourceFile,
    this.routeHint,
    required this.appVersion,
    required this.platform,
    required this.isPro,
    required this.fingerprint,
    required this.occurrences,
    this.processedAt,
    this.issueUrl,
    this.debugBreadcrumbs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['level'] = Variable<String>(level);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || stackTrace != null) {
      map['stack_trace'] = Variable<String>(stackTrace);
    }
    if (!nullToAbsent || sourceFile != null) {
      map['source_file'] = Variable<String>(sourceFile);
    }
    if (!nullToAbsent || routeHint != null) {
      map['route_hint'] = Variable<String>(routeHint);
    }
    map['app_version'] = Variable<String>(appVersion);
    map['platform'] = Variable<String>(platform);
    map['is_pro'] = Variable<bool>(isPro);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['occurrences'] = Variable<int>(occurrences);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<DateTime>(processedAt);
    }
    if (!nullToAbsent || issueUrl != null) {
      map['issue_url'] = Variable<String>(issueUrl);
    }
    if (!nullToAbsent || debugBreadcrumbs != null) {
      map['debug_breadcrumbs'] = Variable<String>(debugBreadcrumbs);
    }
    return map;
  }

  ErrorLogsCompanion toCompanion(bool nullToAbsent) {
    return ErrorLogsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      level: Value(level),
      message: Value(message),
      stackTrace: stackTrace == null && nullToAbsent
          ? const Value.absent()
          : Value(stackTrace),
      sourceFile: sourceFile == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFile),
      routeHint: routeHint == null && nullToAbsent
          ? const Value.absent()
          : Value(routeHint),
      appVersion: Value(appVersion),
      platform: Value(platform),
      isPro: Value(isPro),
      fingerprint: Value(fingerprint),
      occurrences: Value(occurrences),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
      issueUrl: issueUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(issueUrl),
      debugBreadcrumbs: debugBreadcrumbs == null && nullToAbsent
          ? const Value.absent()
          : Value(debugBreadcrumbs),
    );
  }

  factory ErrorLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorLogRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      level: serializer.fromJson<String>(json['level']),
      message: serializer.fromJson<String>(json['message']),
      stackTrace: serializer.fromJson<String?>(json['stackTrace']),
      sourceFile: serializer.fromJson<String?>(json['sourceFile']),
      routeHint: serializer.fromJson<String?>(json['routeHint']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      platform: serializer.fromJson<String>(json['platform']),
      isPro: serializer.fromJson<bool>(json['isPro']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      occurrences: serializer.fromJson<int>(json['occurrences']),
      processedAt: serializer.fromJson<DateTime?>(json['processedAt']),
      issueUrl: serializer.fromJson<String?>(json['issueUrl']),
      debugBreadcrumbs: serializer.fromJson<String?>(json['debugBreadcrumbs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'level': serializer.toJson<String>(level),
      'message': serializer.toJson<String>(message),
      'stackTrace': serializer.toJson<String?>(stackTrace),
      'sourceFile': serializer.toJson<String?>(sourceFile),
      'routeHint': serializer.toJson<String?>(routeHint),
      'appVersion': serializer.toJson<String>(appVersion),
      'platform': serializer.toJson<String>(platform),
      'isPro': serializer.toJson<bool>(isPro),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'occurrences': serializer.toJson<int>(occurrences),
      'processedAt': serializer.toJson<DateTime?>(processedAt),
      'issueUrl': serializer.toJson<String?>(issueUrl),
      'debugBreadcrumbs': serializer.toJson<String?>(debugBreadcrumbs),
    };
  }

  ErrorLogRow copyWith({
    int? id,
    DateTime? createdAt,
    String? level,
    String? message,
    Value<String?> stackTrace = const Value.absent(),
    Value<String?> sourceFile = const Value.absent(),
    Value<String?> routeHint = const Value.absent(),
    String? appVersion,
    String? platform,
    bool? isPro,
    String? fingerprint,
    int? occurrences,
    Value<DateTime?> processedAt = const Value.absent(),
    Value<String?> issueUrl = const Value.absent(),
    Value<String?> debugBreadcrumbs = const Value.absent(),
  }) => ErrorLogRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    level: level ?? this.level,
    message: message ?? this.message,
    stackTrace: stackTrace.present ? stackTrace.value : this.stackTrace,
    sourceFile: sourceFile.present ? sourceFile.value : this.sourceFile,
    routeHint: routeHint.present ? routeHint.value : this.routeHint,
    appVersion: appVersion ?? this.appVersion,
    platform: platform ?? this.platform,
    isPro: isPro ?? this.isPro,
    fingerprint: fingerprint ?? this.fingerprint,
    occurrences: occurrences ?? this.occurrences,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
    issueUrl: issueUrl.present ? issueUrl.value : this.issueUrl,
    debugBreadcrumbs: debugBreadcrumbs.present
        ? debugBreadcrumbs.value
        : this.debugBreadcrumbs,
  );
  ErrorLogRow copyWithCompanion(ErrorLogsCompanion data) {
    return ErrorLogRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      level: data.level.present ? data.level.value : this.level,
      message: data.message.present ? data.message.value : this.message,
      stackTrace: data.stackTrace.present
          ? data.stackTrace.value
          : this.stackTrace,
      sourceFile: data.sourceFile.present
          ? data.sourceFile.value
          : this.sourceFile,
      routeHint: data.routeHint.present ? data.routeHint.value : this.routeHint,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      platform: data.platform.present ? data.platform.value : this.platform,
      isPro: data.isPro.present ? data.isPro.value : this.isPro,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      occurrences: data.occurrences.present
          ? data.occurrences.value
          : this.occurrences,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      issueUrl: data.issueUrl.present ? data.issueUrl.value : this.issueUrl,
      debugBreadcrumbs: data.debugBreadcrumbs.present
          ? data.debugBreadcrumbs.value
          : this.debugBreadcrumbs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorLogRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('sourceFile: $sourceFile, ')
          ..write('routeHint: $routeHint, ')
          ..write('appVersion: $appVersion, ')
          ..write('platform: $platform, ')
          ..write('isPro: $isPro, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('occurrences: $occurrences, ')
          ..write('processedAt: $processedAt, ')
          ..write('issueUrl: $issueUrl, ')
          ..write('debugBreadcrumbs: $debugBreadcrumbs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    level,
    message,
    stackTrace,
    sourceFile,
    routeHint,
    appVersion,
    platform,
    isPro,
    fingerprint,
    occurrences,
    processedAt,
    issueUrl,
    debugBreadcrumbs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorLogRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.level == this.level &&
          other.message == this.message &&
          other.stackTrace == this.stackTrace &&
          other.sourceFile == this.sourceFile &&
          other.routeHint == this.routeHint &&
          other.appVersion == this.appVersion &&
          other.platform == this.platform &&
          other.isPro == this.isPro &&
          other.fingerprint == this.fingerprint &&
          other.occurrences == this.occurrences &&
          other.processedAt == this.processedAt &&
          other.issueUrl == this.issueUrl &&
          other.debugBreadcrumbs == this.debugBreadcrumbs);
}

class ErrorLogsCompanion extends UpdateCompanion<ErrorLogRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> level;
  final Value<String> message;
  final Value<String?> stackTrace;
  final Value<String?> sourceFile;
  final Value<String?> routeHint;
  final Value<String> appVersion;
  final Value<String> platform;
  final Value<bool> isPro;
  final Value<String> fingerprint;
  final Value<int> occurrences;
  final Value<DateTime?> processedAt;
  final Value<String?> issueUrl;
  final Value<String?> debugBreadcrumbs;
  const ErrorLogsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.level = const Value.absent(),
    this.message = const Value.absent(),
    this.stackTrace = const Value.absent(),
    this.sourceFile = const Value.absent(),
    this.routeHint = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.platform = const Value.absent(),
    this.isPro = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.issueUrl = const Value.absent(),
    this.debugBreadcrumbs = const Value.absent(),
  });
  ErrorLogsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.level = const Value.absent(),
    this.message = const Value.absent(),
    this.stackTrace = const Value.absent(),
    this.sourceFile = const Value.absent(),
    this.routeHint = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.platform = const Value.absent(),
    this.isPro = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.issueUrl = const Value.absent(),
    this.debugBreadcrumbs = const Value.absent(),
  });
  static Insertable<ErrorLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? level,
    Expression<String>? message,
    Expression<String>? stackTrace,
    Expression<String>? sourceFile,
    Expression<String>? routeHint,
    Expression<String>? appVersion,
    Expression<String>? platform,
    Expression<bool>? isPro,
    Expression<String>? fingerprint,
    Expression<int>? occurrences,
    Expression<DateTime>? processedAt,
    Expression<String>? issueUrl,
    Expression<String>? debugBreadcrumbs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (level != null) 'level': level,
      if (message != null) 'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (sourceFile != null) 'source_file': sourceFile,
      if (routeHint != null) 'route_hint': routeHint,
      if (appVersion != null) 'app_version': appVersion,
      if (platform != null) 'platform': platform,
      if (isPro != null) 'is_pro': isPro,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (occurrences != null) 'occurrences': occurrences,
      if (processedAt != null) 'processed_at': processedAt,
      if (issueUrl != null) 'issue_url': issueUrl,
      if (debugBreadcrumbs != null) 'debug_breadcrumbs': debugBreadcrumbs,
    });
  }

  ErrorLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String>? level,
    Value<String>? message,
    Value<String?>? stackTrace,
    Value<String?>? sourceFile,
    Value<String?>? routeHint,
    Value<String>? appVersion,
    Value<String>? platform,
    Value<bool>? isPro,
    Value<String>? fingerprint,
    Value<int>? occurrences,
    Value<DateTime?>? processedAt,
    Value<String?>? issueUrl,
    Value<String?>? debugBreadcrumbs,
  }) {
    return ErrorLogsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      sourceFile: sourceFile ?? this.sourceFile,
      routeHint: routeHint ?? this.routeHint,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      isPro: isPro ?? this.isPro,
      fingerprint: fingerprint ?? this.fingerprint,
      occurrences: occurrences ?? this.occurrences,
      processedAt: processedAt ?? this.processedAt,
      issueUrl: issueUrl ?? this.issueUrl,
      debugBreadcrumbs: debugBreadcrumbs ?? this.debugBreadcrumbs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (stackTrace.present) {
      map['stack_trace'] = Variable<String>(stackTrace.value);
    }
    if (sourceFile.present) {
      map['source_file'] = Variable<String>(sourceFile.value);
    }
    if (routeHint.present) {
      map['route_hint'] = Variable<String>(routeHint.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (isPro.present) {
      map['is_pro'] = Variable<bool>(isPro.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (occurrences.present) {
      map['occurrences'] = Variable<int>(occurrences.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (issueUrl.present) {
      map['issue_url'] = Variable<String>(issueUrl.value);
    }
    if (debugBreadcrumbs.present) {
      map['debug_breadcrumbs'] = Variable<String>(debugBreadcrumbs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorLogsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('sourceFile: $sourceFile, ')
          ..write('routeHint: $routeHint, ')
          ..write('appVersion: $appVersion, ')
          ..write('platform: $platform, ')
          ..write('isPro: $isPro, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('occurrences: $occurrences, ')
          ..write('processedAt: $processedAt, ')
          ..write('issueUrl: $issueUrl, ')
          ..write('debugBreadcrumbs: $debugBreadcrumbs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GuestProfilesTable guestProfiles = $GuestProfilesTable(this);
  late final $RecipeCollectionsTable recipeCollections =
      $RecipeCollectionsTable(this);
  late final $CrewMembersTable crewMembers = $CrewMembersTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $FuelLogEntriesTable fuelLogEntries = $FuelLogEntriesTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $MealPlansTable mealPlans = $MealPlansTable(this);
  late final $BoatsTable boats = $BoatsTable(this);
  late final $CaptainLogEntriesTable captainLogEntries =
      $CaptainLogEntriesTable(this);
  late final $MaintenanceTasksTable maintenanceTasks = $MaintenanceTasksTable(
    this,
  );
  late final $ShoppingCategoriesTable shoppingCategories =
      $ShoppingCategoriesTable(this);
  late final $ShoppingItemsTable shoppingItems = $ShoppingItemsTable(this);
  late final $ChecklistGroupsTable checklistGroups = $ChecklistGroupsTable(
    this,
  );
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeIngredientsTable recipeIngredients =
      $RecipeIngredientsTable(this);
  late final $BarIngredientsTable barIngredients = $BarIngredientsTable(this);
  late final $PantryIngredientsTable pantryIngredients =
      $PantryIngredientsTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  late final $CommunityTemplatesTable communityTemplates =
      $CommunityTemplatesTable(this);
  late final $SyncOutboxItemsTable syncOutboxItems = $SyncOutboxItemsTable(
    this,
  );
  late final $ConflictLogsTable conflictLogs = $ConflictLogsTable(this);
  late final $ErrorLogsTable errorLogs = $ErrorLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    guestProfiles,
    recipeCollections,
    crewMembers,
    inventoryItems,
    fuelLogEntries,
    documents,
    mealPlans,
    boats,
    captainLogEntries,
    maintenanceTasks,
    shoppingCategories,
    shoppingItems,
    checklistGroups,
    checklistItems,
    recipes,
    recipeIngredients,
    barIngredients,
    pantryIngredients,
    userSettingsTable,
    communityTemplates,
    syncOutboxItems,
    conflictLogs,
    errorLogs,
  ];
}

typedef $$GuestProfilesTableCreateCompanionBuilder =
    GuestProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> allergenRestrictions,
      Value<String> dietaryRequirements,
      Value<DateTime> createdAt,
    });
typedef $$GuestProfilesTableUpdateCompanionBuilder =
    GuestProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> allergenRestrictions,
      Value<String> dietaryRequirements,
      Value<DateTime> createdAt,
    });

class $$GuestProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $GuestProfilesTable> {
  $$GuestProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergenRestrictions => $composableBuilder(
    column: $table.allergenRestrictions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dietaryRequirements => $composableBuilder(
    column: $table.dietaryRequirements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GuestProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $GuestProfilesTable> {
  $$GuestProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergenRestrictions => $composableBuilder(
    column: $table.allergenRestrictions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dietaryRequirements => $composableBuilder(
    column: $table.dietaryRequirements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GuestProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuestProfilesTable> {
  $$GuestProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get allergenRestrictions => $composableBuilder(
    column: $table.allergenRestrictions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dietaryRequirements => $composableBuilder(
    column: $table.dietaryRequirements,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GuestProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GuestProfilesTable,
          GuestProfileRow,
          $$GuestProfilesTableFilterComposer,
          $$GuestProfilesTableOrderingComposer,
          $$GuestProfilesTableAnnotationComposer,
          $$GuestProfilesTableCreateCompanionBuilder,
          $$GuestProfilesTableUpdateCompanionBuilder,
          (
            GuestProfileRow,
            BaseReferences<_$AppDatabase, $GuestProfilesTable, GuestProfileRow>,
          ),
          GuestProfileRow,
          PrefetchHooks Function()
        > {
  $$GuestProfilesTableTableManager(_$AppDatabase db, $GuestProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuestProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuestProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuestProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> allergenRestrictions = const Value.absent(),
                Value<String> dietaryRequirements = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GuestProfilesCompanion(
                id: id,
                name: name,
                allergenRestrictions: allergenRestrictions,
                dietaryRequirements: dietaryRequirements,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> allergenRestrictions = const Value.absent(),
                Value<String> dietaryRequirements = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GuestProfilesCompanion.insert(
                id: id,
                name: name,
                allergenRestrictions: allergenRestrictions,
                dietaryRequirements: dietaryRequirements,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GuestProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GuestProfilesTable,
      GuestProfileRow,
      $$GuestProfilesTableFilterComposer,
      $$GuestProfilesTableOrderingComposer,
      $$GuestProfilesTableAnnotationComposer,
      $$GuestProfilesTableCreateCompanionBuilder,
      $$GuestProfilesTableUpdateCompanionBuilder,
      (
        GuestProfileRow,
        BaseReferences<_$AppDatabase, $GuestProfilesTable, GuestProfileRow>,
      ),
      GuestProfileRow,
      PrefetchHooks Function()
    >;
typedef $$RecipeCollectionsTableCreateCompanionBuilder =
    RecipeCollectionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> recipeSupabaseIds,
      Value<DateTime> createdAt,
      Value<DateTime> lastModified,
    });
typedef $$RecipeCollectionsTableUpdateCompanionBuilder =
    RecipeCollectionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> recipeSupabaseIds,
      Value<DateTime> createdAt,
      Value<DateTime> lastModified,
    });

class $$RecipeCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeCollectionsTable> {
  $$RecipeCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeSupabaseIds => $composableBuilder(
    column: $table.recipeSupabaseIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeCollectionsTable> {
  $$RecipeCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeSupabaseIds => $composableBuilder(
    column: $table.recipeSupabaseIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeCollectionsTable> {
  $$RecipeCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get recipeSupabaseIds => $composableBuilder(
    column: $table.recipeSupabaseIds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$RecipeCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeCollectionsTable,
          RecipeCollectionRow,
          $$RecipeCollectionsTableFilterComposer,
          $$RecipeCollectionsTableOrderingComposer,
          $$RecipeCollectionsTableAnnotationComposer,
          $$RecipeCollectionsTableCreateCompanionBuilder,
          $$RecipeCollectionsTableUpdateCompanionBuilder,
          (
            RecipeCollectionRow,
            BaseReferences<
              _$AppDatabase,
              $RecipeCollectionsTable,
              RecipeCollectionRow
            >,
          ),
          RecipeCollectionRow,
          PrefetchHooks Function()
        > {
  $$RecipeCollectionsTableTableManager(
    _$AppDatabase db,
    $RecipeCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeCollectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> recipeSupabaseIds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => RecipeCollectionsCompanion(
                id: id,
                name: name,
                recipeSupabaseIds: recipeSupabaseIds,
                createdAt: createdAt,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> recipeSupabaseIds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => RecipeCollectionsCompanion.insert(
                id: id,
                name: name,
                recipeSupabaseIds: recipeSupabaseIds,
                createdAt: createdAt,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeCollectionsTable,
      RecipeCollectionRow,
      $$RecipeCollectionsTableFilterComposer,
      $$RecipeCollectionsTableOrderingComposer,
      $$RecipeCollectionsTableAnnotationComposer,
      $$RecipeCollectionsTableCreateCompanionBuilder,
      $$RecipeCollectionsTableUpdateCompanionBuilder,
      (
        RecipeCollectionRow,
        BaseReferences<
          _$AppDatabase,
          $RecipeCollectionsTable,
          RecipeCollectionRow
        >,
      ),
      RecipeCollectionRow,
      PrefetchHooks Function()
    >;
typedef $$CrewMembersTableCreateCompanionBuilder =
    CrewMembersCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<String> role,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> iceContact,
      Value<String?> certifications,
      Value<String?> localPath,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$CrewMembersTableUpdateCompanionBuilder =
    CrewMembersCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<String> role,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> iceContact,
      Value<String?> certifications,
      Value<String?> localPath,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$CrewMembersTableFilterComposer
    extends Composer<_$AppDatabase, $CrewMembersTable> {
  $$CrewMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iceContact => $composableBuilder(
    column: $table.iceContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CrewMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $CrewMembersTable> {
  $$CrewMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iceContact => $composableBuilder(
    column: $table.iceContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CrewMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrewMembersTable> {
  $$CrewMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get iceContact => $composableBuilder(
    column: $table.iceContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$CrewMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CrewMembersTable,
          CrewMemberRow,
          $$CrewMembersTableFilterComposer,
          $$CrewMembersTableOrderingComposer,
          $$CrewMembersTableAnnotationComposer,
          $$CrewMembersTableCreateCompanionBuilder,
          $$CrewMembersTableUpdateCompanionBuilder,
          (
            CrewMemberRow,
            BaseReferences<_$AppDatabase, $CrewMembersTable, CrewMemberRow>,
          ),
          CrewMemberRow,
          PrefetchHooks Function()
        > {
  $$CrewMembersTableTableManager(_$AppDatabase db, $CrewMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrewMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrewMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CrewMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> iceContact = const Value.absent(),
                Value<String?> certifications = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => CrewMembersCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                role: role,
                phone: phone,
                email: email,
                iceContact: iceContact,
                certifications: certifications,
                localPath: localPath,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> iceContact = const Value.absent(),
                Value<String?> certifications = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => CrewMembersCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                role: role,
                phone: phone,
                email: email,
                iceContact: iceContact,
                certifications: certifications,
                localPath: localPath,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CrewMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CrewMembersTable,
      CrewMemberRow,
      $$CrewMembersTableFilterComposer,
      $$CrewMembersTableOrderingComposer,
      $$CrewMembersTableAnnotationComposer,
      $$CrewMembersTableCreateCompanionBuilder,
      $$CrewMembersTableUpdateCompanionBuilder,
      (
        CrewMemberRow,
        BaseReferences<_$AppDatabase, $CrewMembersTable, CrewMemberRow>,
      ),
      CrewMemberRow,
      PrefetchHooks Function()
    >;
typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<String?> location,
      Value<double> quantity,
      Value<String?> unit,
      Value<String?> serialNumber,
      Value<String?> notes,
      Value<String?> localPath,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<String?> location,
      Value<double> quantity,
      Value<String?> unit,
      Value<String?> serialNumber,
      Value<String?> notes,
      Value<String?> localPath,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTable,
          InventoryItemRow,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (
            InventoryItemRow,
            BaseReferences<
              _$AppDatabase,
              $InventoryItemsTable,
              InventoryItemRow
            >,
          ),
          InventoryItemRow,
          PrefetchHooks Function()
        > {
  $$InventoryItemsTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                location: location,
                quantity: quantity,
                unit: unit,
                serialNumber: serialNumber,
                notes: notes,
                localPath: localPath,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                location: location,
                quantity: quantity,
                unit: unit,
                serialNumber: serialNumber,
                notes: notes,
                localPath: localPath,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTable,
      InventoryItemRow,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (
        InventoryItemRow,
        BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItemRow>,
      ),
      InventoryItemRow,
      PrefetchHooks Function()
    >;
typedef $$FuelLogEntriesTableCreateCompanionBuilder =
    FuelLogEntriesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<DateTime> date,
      Value<String> type,
      Value<double> liters,
      Value<double> pricePerLiter,
      Value<double> totalCost,
      Value<String?> notes,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$FuelLogEntriesTableUpdateCompanionBuilder =
    FuelLogEntriesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<DateTime> date,
      Value<String> type,
      Value<double> liters,
      Value<double> pricePerLiter,
      Value<double> totalCost,
      Value<String?> notes,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$FuelLogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FuelLogEntriesTable> {
  $$FuelLogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerLiter => $composableBuilder(
    column: $table.pricePerLiter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FuelLogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelLogEntriesTable> {
  $$FuelLogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerLiter => $composableBuilder(
    column: $table.pricePerLiter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FuelLogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelLogEntriesTable> {
  $$FuelLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get liters =>
      $composableBuilder(column: $table.liters, builder: (column) => column);

  GeneratedColumn<double> get pricePerLiter => $composableBuilder(
    column: $table.pricePerLiter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$FuelLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelLogEntriesTable,
          FuelLogEntryRow,
          $$FuelLogEntriesTableFilterComposer,
          $$FuelLogEntriesTableOrderingComposer,
          $$FuelLogEntriesTableAnnotationComposer,
          $$FuelLogEntriesTableCreateCompanionBuilder,
          $$FuelLogEntriesTableUpdateCompanionBuilder,
          (
            FuelLogEntryRow,
            BaseReferences<
              _$AppDatabase,
              $FuelLogEntriesTable,
              FuelLogEntryRow
            >,
          ),
          FuelLogEntryRow,
          PrefetchHooks Function()
        > {
  $$FuelLogEntriesTableTableManager(
    _$AppDatabase db,
    $FuelLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelLogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelLogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelLogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> liters = const Value.absent(),
                Value<double> pricePerLiter = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => FuelLogEntriesCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                date: date,
                type: type,
                liters: liters,
                pricePerLiter: pricePerLiter,
                totalCost: totalCost,
                notes: notes,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> liters = const Value.absent(),
                Value<double> pricePerLiter = const Value.absent(),
                Value<double> totalCost = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => FuelLogEntriesCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                date: date,
                type: type,
                liters: liters,
                pricePerLiter: pricePerLiter,
                totalCost: totalCost,
                notes: notes,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FuelLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelLogEntriesTable,
      FuelLogEntryRow,
      $$FuelLogEntriesTableFilterComposer,
      $$FuelLogEntriesTableOrderingComposer,
      $$FuelLogEntriesTableAnnotationComposer,
      $$FuelLogEntriesTableCreateCompanionBuilder,
      $$FuelLogEntriesTableUpdateCompanionBuilder,
      (
        FuelLogEntryRow,
        BaseReferences<_$AppDatabase, $FuelLogEntriesTable, FuelLogEntryRow>,
      ),
      FuelLogEntryRow,
      PrefetchHooks Function()
    >;
typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> title,
      Value<String> type,
      Value<String?> fileUrl,
      Value<String?> localPath,
      Value<String?> notes,
      Value<DateTime?> expiry,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> title,
      Value<String> type,
      Value<String?> fileUrl,
      Value<String?> localPath,
      Value<String?> notes,
      Value<DateTime?> expiry,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiry => $composableBuilder(
    column: $table.expiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiry => $composableBuilder(
    column: $table.expiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get expiry =>
      $composableBuilder(column: $table.expiry, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (
            DocumentRow,
            BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
          ),
          DocumentRow,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> expiry = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                title: title,
                type: type,
                fileUrl: fileUrl,
                localPath: localPath,
                notes: notes,
                expiry: expiry,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> expiry = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                title: title,
                type: type,
                fileUrl: fileUrl,
                localPath: localPath,
                notes: notes,
                expiry: expiry,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (
        DocumentRow,
        BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
      ),
      DocumentRow,
      PrefetchHooks Function()
    >;
typedef $$MealPlansTableCreateCompanionBuilder =
    MealPlansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> startDate,
      Value<int> numberOfDays,
      Value<int> guestCount,
      Value<String> guestProfileIds,
      Value<String> slots,
      Value<DateTime> createdAt,
      Value<DateTime> lastModified,
    });
typedef $$MealPlansTableUpdateCompanionBuilder =
    MealPlansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> startDate,
      Value<int> numberOfDays,
      Value<int> guestCount,
      Value<String> guestProfileIds,
      Value<String> slots,
      Value<DateTime> createdAt,
      Value<DateTime> lastModified,
    });

class $$MealPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfDays => $composableBuilder(
    column: $table.numberOfDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get guestCount => $composableBuilder(
    column: $table.guestCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guestProfileIds => $composableBuilder(
    column: $table.guestProfileIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slots => $composableBuilder(
    column: $table.slots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfDays => $composableBuilder(
    column: $table.numberOfDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get guestCount => $composableBuilder(
    column: $table.guestCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestProfileIds => $composableBuilder(
    column: $table.guestProfileIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slots => $composableBuilder(
    column: $table.slots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get numberOfDays => $composableBuilder(
    column: $table.numberOfDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get guestCount => $composableBuilder(
    column: $table.guestCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guestProfileIds => $composableBuilder(
    column: $table.guestProfileIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get slots =>
      $composableBuilder(column: $table.slots, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$MealPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPlansTable,
          MealPlanRow,
          $$MealPlansTableFilterComposer,
          $$MealPlansTableOrderingComposer,
          $$MealPlansTableAnnotationComposer,
          $$MealPlansTableCreateCompanionBuilder,
          $$MealPlansTableUpdateCompanionBuilder,
          (
            MealPlanRow,
            BaseReferences<_$AppDatabase, $MealPlansTable, MealPlanRow>,
          ),
          MealPlanRow,
          PrefetchHooks Function()
        > {
  $$MealPlansTableTableManager(_$AppDatabase db, $MealPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> numberOfDays = const Value.absent(),
                Value<int> guestCount = const Value.absent(),
                Value<String> guestProfileIds = const Value.absent(),
                Value<String> slots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => MealPlansCompanion(
                id: id,
                name: name,
                startDate: startDate,
                numberOfDays: numberOfDays,
                guestCount: guestCount,
                guestProfileIds: guestProfileIds,
                slots: slots,
                createdAt: createdAt,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> numberOfDays = const Value.absent(),
                Value<int> guestCount = const Value.absent(),
                Value<String> guestProfileIds = const Value.absent(),
                Value<String> slots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => MealPlansCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                numberOfDays: numberOfDays,
                guestCount: guestCount,
                guestProfileIds: guestProfileIds,
                slots: slots,
                createdAt: createdAt,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPlansTable,
      MealPlanRow,
      $$MealPlansTableFilterComposer,
      $$MealPlansTableOrderingComposer,
      $$MealPlansTableAnnotationComposer,
      $$MealPlansTableCreateCompanionBuilder,
      $$MealPlansTableUpdateCompanionBuilder,
      (
        MealPlanRow,
        BaseReferences<_$AppDatabase, $MealPlansTable, MealPlanRow>,
      ),
      MealPlanRow,
      PrefetchHooks Function()
    >;
typedef $$BoatsTableCreateCompanionBuilder =
    BoatsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> name,
      Value<bool> isBought,
      Value<bool> isHidden,
      Value<bool> isSynced,
      Value<double?> lastPurchasePrice,
      Value<String?> notes,
      Value<String?> origin,
      Value<String?> photoUrl,
      Value<String?> ownerId,
      Value<String?> shareCode,
      Value<String?> llmApiKey,
      Value<String?> llmApiKeyProvider,
      Value<DateTime> lastModified,
    });
typedef $$BoatsTableUpdateCompanionBuilder =
    BoatsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> name,
      Value<bool> isBought,
      Value<bool> isHidden,
      Value<bool> isSynced,
      Value<double?> lastPurchasePrice,
      Value<String?> notes,
      Value<String?> origin,
      Value<String?> photoUrl,
      Value<String?> ownerId,
      Value<String?> shareCode,
      Value<String?> llmApiKey,
      Value<String?> llmApiKeyProvider,
      Value<DateTime> lastModified,
    });

class $$BoatsTableFilterComposer extends Composer<_$AppDatabase, $BoatsTable> {
  $$BoatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBought => $composableBuilder(
    column: $table.isBought,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareCode => $composableBuilder(
    column: $table.shareCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get llmApiKey => $composableBuilder(
    column: $table.llmApiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get llmApiKeyProvider => $composableBuilder(
    column: $table.llmApiKeyProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoatsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoatsTable> {
  $$BoatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBought => $composableBuilder(
    column: $table.isBought,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareCode => $composableBuilder(
    column: $table.shareCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get llmApiKey => $composableBuilder(
    column: $table.llmApiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get llmApiKeyProvider => $composableBuilder(
    column: $table.llmApiKeyProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoatsTable> {
  $$BoatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isBought =>
      $composableBuilder(column: $table.isBought, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get shareCode =>
      $composableBuilder(column: $table.shareCode, builder: (column) => column);

  GeneratedColumn<String> get llmApiKey =>
      $composableBuilder(column: $table.llmApiKey, builder: (column) => column);

  GeneratedColumn<String> get llmApiKeyProvider => $composableBuilder(
    column: $table.llmApiKeyProvider,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$BoatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoatsTable,
          BoatRow,
          $$BoatsTableFilterComposer,
          $$BoatsTableOrderingComposer,
          $$BoatsTableAnnotationComposer,
          $$BoatsTableCreateCompanionBuilder,
          $$BoatsTableUpdateCompanionBuilder,
          (BoatRow, BaseReferences<_$AppDatabase, $BoatsTable, BoatRow>),
          BoatRow,
          PrefetchHooks Function()
        > {
  $$BoatsTableTableManager(_$AppDatabase db, $BoatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isBought = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<double?> lastPurchasePrice = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> shareCode = const Value.absent(),
                Value<String?> llmApiKey = const Value.absent(),
                Value<String?> llmApiKeyProvider = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => BoatsCompanion(
                id: id,
                supabaseId: supabaseId,
                name: name,
                isBought: isBought,
                isHidden: isHidden,
                isSynced: isSynced,
                lastPurchasePrice: lastPurchasePrice,
                notes: notes,
                origin: origin,
                photoUrl: photoUrl,
                ownerId: ownerId,
                shareCode: shareCode,
                llmApiKey: llmApiKey,
                llmApiKeyProvider: llmApiKeyProvider,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isBought = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<double?> lastPurchasePrice = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> shareCode = const Value.absent(),
                Value<String?> llmApiKey = const Value.absent(),
                Value<String?> llmApiKeyProvider = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => BoatsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                name: name,
                isBought: isBought,
                isHidden: isHidden,
                isSynced: isSynced,
                lastPurchasePrice: lastPurchasePrice,
                notes: notes,
                origin: origin,
                photoUrl: photoUrl,
                ownerId: ownerId,
                shareCode: shareCode,
                llmApiKey: llmApiKey,
                llmApiKeyProvider: llmApiKeyProvider,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoatsTable,
      BoatRow,
      $$BoatsTableFilterComposer,
      $$BoatsTableOrderingComposer,
      $$BoatsTableAnnotationComposer,
      $$BoatsTableCreateCompanionBuilder,
      $$BoatsTableUpdateCompanionBuilder,
      (BoatRow, BaseReferences<_$AppDatabase, $BoatsTable, BoatRow>),
      BoatRow,
      PrefetchHooks Function()
    >;
typedef $$CaptainLogEntriesTableCreateCompanionBuilder =
    CaptainLogEntriesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<DateTime> logDate,
      Value<String> title,
      Value<String?> logTime,
      Value<double?> positionLat,
      Value<double?> positionLng,
      Value<String?> weather,
      Value<int?> windSpeedKt,
      Value<String?> windDir,
      Value<String> crewOnBoard,
      Value<String?> notes,
      Value<String> photos,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$CaptainLogEntriesTableUpdateCompanionBuilder =
    CaptainLogEntriesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<DateTime> logDate,
      Value<String> title,
      Value<String?> logTime,
      Value<double?> positionLat,
      Value<double?> positionLng,
      Value<String?> weather,
      Value<int?> windSpeedKt,
      Value<String?> windDir,
      Value<String> crewOnBoard,
      Value<String?> notes,
      Value<String> photos,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$CaptainLogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CaptainLogEntriesTable> {
  $$CaptainLogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logTime => $composableBuilder(
    column: $table.logTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get positionLat => $composableBuilder(
    column: $table.positionLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get positionLng => $composableBuilder(
    column: $table.positionLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weather => $composableBuilder(
    column: $table.weather,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windSpeedKt => $composableBuilder(
    column: $table.windSpeedKt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get windDir => $composableBuilder(
    column: $table.windDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crewOnBoard => $composableBuilder(
    column: $table.crewOnBoard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photos => $composableBuilder(
    column: $table.photos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CaptainLogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CaptainLogEntriesTable> {
  $$CaptainLogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logTime => $composableBuilder(
    column: $table.logTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get positionLat => $composableBuilder(
    column: $table.positionLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get positionLng => $composableBuilder(
    column: $table.positionLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weather => $composableBuilder(
    column: $table.weather,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windSpeedKt => $composableBuilder(
    column: $table.windSpeedKt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get windDir => $composableBuilder(
    column: $table.windDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crewOnBoard => $composableBuilder(
    column: $table.crewOnBoard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photos => $composableBuilder(
    column: $table.photos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CaptainLogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CaptainLogEntriesTable> {
  $$CaptainLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get logTime =>
      $composableBuilder(column: $table.logTime, builder: (column) => column);

  GeneratedColumn<double> get positionLat => $composableBuilder(
    column: $table.positionLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get positionLng => $composableBuilder(
    column: $table.positionLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weather =>
      $composableBuilder(column: $table.weather, builder: (column) => column);

  GeneratedColumn<int> get windSpeedKt => $composableBuilder(
    column: $table.windSpeedKt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get windDir =>
      $composableBuilder(column: $table.windDir, builder: (column) => column);

  GeneratedColumn<String> get crewOnBoard => $composableBuilder(
    column: $table.crewOnBoard,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photos =>
      $composableBuilder(column: $table.photos, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$CaptainLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CaptainLogEntriesTable,
          CaptainLogEntryRow,
          $$CaptainLogEntriesTableFilterComposer,
          $$CaptainLogEntriesTableOrderingComposer,
          $$CaptainLogEntriesTableAnnotationComposer,
          $$CaptainLogEntriesTableCreateCompanionBuilder,
          $$CaptainLogEntriesTableUpdateCompanionBuilder,
          (
            CaptainLogEntryRow,
            BaseReferences<
              _$AppDatabase,
              $CaptainLogEntriesTable,
              CaptainLogEntryRow
            >,
          ),
          CaptainLogEntryRow,
          PrefetchHooks Function()
        > {
  $$CaptainLogEntriesTableTableManager(
    _$AppDatabase db,
    $CaptainLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaptainLogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CaptainLogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CaptainLogEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<DateTime> logDate = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> logTime = const Value.absent(),
                Value<double?> positionLat = const Value.absent(),
                Value<double?> positionLng = const Value.absent(),
                Value<String?> weather = const Value.absent(),
                Value<int?> windSpeedKt = const Value.absent(),
                Value<String?> windDir = const Value.absent(),
                Value<String> crewOnBoard = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> photos = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => CaptainLogEntriesCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                logDate: logDate,
                title: title,
                logTime: logTime,
                positionLat: positionLat,
                positionLng: positionLng,
                weather: weather,
                windSpeedKt: windSpeedKt,
                windDir: windDir,
                crewOnBoard: crewOnBoard,
                notes: notes,
                photos: photos,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<DateTime> logDate = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> logTime = const Value.absent(),
                Value<double?> positionLat = const Value.absent(),
                Value<double?> positionLng = const Value.absent(),
                Value<String?> weather = const Value.absent(),
                Value<int?> windSpeedKt = const Value.absent(),
                Value<String?> windDir = const Value.absent(),
                Value<String> crewOnBoard = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> photos = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => CaptainLogEntriesCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                logDate: logDate,
                title: title,
                logTime: logTime,
                positionLat: positionLat,
                positionLng: positionLng,
                weather: weather,
                windSpeedKt: windSpeedKt,
                windDir: windDir,
                crewOnBoard: crewOnBoard,
                notes: notes,
                photos: photos,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CaptainLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CaptainLogEntriesTable,
      CaptainLogEntryRow,
      $$CaptainLogEntriesTableFilterComposer,
      $$CaptainLogEntriesTableOrderingComposer,
      $$CaptainLogEntriesTableAnnotationComposer,
      $$CaptainLogEntriesTableCreateCompanionBuilder,
      $$CaptainLogEntriesTableUpdateCompanionBuilder,
      (
        CaptainLogEntryRow,
        BaseReferences<
          _$AppDatabase,
          $CaptainLogEntriesTable,
          CaptainLogEntryRow
        >,
      ),
      CaptainLogEntryRow,
      PrefetchHooks Function()
    >;
typedef $$MaintenanceTasksTableCreateCompanionBuilder =
    MaintenanceTasksCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> description,
      Value<int?> intervalHours,
      Value<int?> intervalMonths,
      Value<int?> lastDoneHours,
      Value<DateTime?> lastDoneDate,
      Value<String?> doneBy,
      Value<String?> notes,
      Value<bool> isHidden,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$MaintenanceTasksTableUpdateCompanionBuilder =
    MaintenanceTasksCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> description,
      Value<int?> intervalHours,
      Value<int?> intervalMonths,
      Value<int?> lastDoneHours,
      Value<DateTime?> lastDoneDate,
      Value<String?> doneBy,
      Value<String?> notes,
      Value<bool> isHidden,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$MaintenanceTasksTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenanceTasksTable> {
  $$MaintenanceTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastDoneHours => $composableBuilder(
    column: $table.lastDoneHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastDoneDate => $composableBuilder(
    column: $table.lastDoneDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doneBy => $composableBuilder(
    column: $table.doneBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaintenanceTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenanceTasksTable> {
  $$MaintenanceTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDoneHours => $composableBuilder(
    column: $table.lastDoneHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastDoneDate => $composableBuilder(
    column: $table.lastDoneDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneBy => $composableBuilder(
    column: $table.doneBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaintenanceTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenanceTasksTable> {
  $$MaintenanceTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastDoneHours => $composableBuilder(
    column: $table.lastDoneHours,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastDoneDate => $composableBuilder(
    column: $table.lastDoneDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doneBy =>
      $composableBuilder(column: $table.doneBy, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$MaintenanceTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenanceTasksTable,
          MaintenanceTaskRow,
          $$MaintenanceTasksTableFilterComposer,
          $$MaintenanceTasksTableOrderingComposer,
          $$MaintenanceTasksTableAnnotationComposer,
          $$MaintenanceTasksTableCreateCompanionBuilder,
          $$MaintenanceTasksTableUpdateCompanionBuilder,
          (
            MaintenanceTaskRow,
            BaseReferences<
              _$AppDatabase,
              $MaintenanceTasksTable,
              MaintenanceTaskRow
            >,
          ),
          MaintenanceTaskRow,
          PrefetchHooks Function()
        > {
  $$MaintenanceTasksTableTableManager(
    _$AppDatabase db,
    $MaintenanceTasksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> intervalHours = const Value.absent(),
                Value<int?> intervalMonths = const Value.absent(),
                Value<int?> lastDoneHours = const Value.absent(),
                Value<DateTime?> lastDoneDate = const Value.absent(),
                Value<String?> doneBy = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => MaintenanceTasksCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                description: description,
                intervalHours: intervalHours,
                intervalMonths: intervalMonths,
                lastDoneHours: lastDoneHours,
                lastDoneDate: lastDoneDate,
                doneBy: doneBy,
                notes: notes,
                isHidden: isHidden,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> intervalHours = const Value.absent(),
                Value<int?> intervalMonths = const Value.absent(),
                Value<int?> lastDoneHours = const Value.absent(),
                Value<DateTime?> lastDoneDate = const Value.absent(),
                Value<String?> doneBy = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => MaintenanceTasksCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                description: description,
                intervalHours: intervalHours,
                intervalMonths: intervalMonths,
                lastDoneHours: lastDoneHours,
                lastDoneDate: lastDoneDate,
                doneBy: doneBy,
                notes: notes,
                isHidden: isHidden,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaintenanceTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenanceTasksTable,
      MaintenanceTaskRow,
      $$MaintenanceTasksTableFilterComposer,
      $$MaintenanceTasksTableOrderingComposer,
      $$MaintenanceTasksTableAnnotationComposer,
      $$MaintenanceTasksTableCreateCompanionBuilder,
      $$MaintenanceTasksTableUpdateCompanionBuilder,
      (
        MaintenanceTaskRow,
        BaseReferences<
          _$AppDatabase,
          $MaintenanceTasksTable,
          MaintenanceTaskRow
        >,
      ),
      MaintenanceTaskRow,
      PrefetchHooks Function()
    >;
typedef $$ShoppingCategoriesTableCreateCompanionBuilder =
    ShoppingCategoriesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<int> sortOrder,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$ShoppingCategoriesTableUpdateCompanionBuilder =
    ShoppingCategoriesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<int> sortOrder,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$ShoppingCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingCategoriesTable> {
  $$ShoppingCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingCategoriesTable> {
  $$ShoppingCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingCategoriesTable> {
  $$ShoppingCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$ShoppingCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingCategoriesTable,
          ShoppingCategoryRow,
          $$ShoppingCategoriesTableFilterComposer,
          $$ShoppingCategoriesTableOrderingComposer,
          $$ShoppingCategoriesTableAnnotationComposer,
          $$ShoppingCategoriesTableCreateCompanionBuilder,
          $$ShoppingCategoriesTableUpdateCompanionBuilder,
          (
            ShoppingCategoryRow,
            BaseReferences<
              _$AppDatabase,
              $ShoppingCategoriesTable,
              ShoppingCategoryRow
            >,
          ),
          ShoppingCategoryRow,
          PrefetchHooks Function()
        > {
  $$ShoppingCategoriesTableTableManager(
    _$AppDatabase db,
    $ShoppingCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => ShoppingCategoriesCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                sortOrder: sortOrder,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => ShoppingCategoriesCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                sortOrder: sortOrder,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingCategoriesTable,
      ShoppingCategoryRow,
      $$ShoppingCategoriesTableFilterComposer,
      $$ShoppingCategoriesTableOrderingComposer,
      $$ShoppingCategoriesTableAnnotationComposer,
      $$ShoppingCategoriesTableCreateCompanionBuilder,
      $$ShoppingCategoriesTableUpdateCompanionBuilder,
      (
        ShoppingCategoryRow,
        BaseReferences<
          _$AppDatabase,
          $ShoppingCategoriesTable,
          ShoppingCategoryRow
        >,
      ),
      ShoppingCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$ShoppingItemsTableCreateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String?> boatSupabaseId,
      Value<String> categorySupabaseId,
      Value<String> name,
      Value<int> quantity,
      Value<String?> unit,
      Value<bool> isBought,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<bool> isHidden,
      Value<String?> notes,
      Value<String> origin,
      Value<double?> lastPurchasePrice,
      Value<String?> lastPurchasePlace,
      Value<String?> userPhotoUrl,
      Value<DateTime> lastModified,
    });
typedef $$ShoppingItemsTableUpdateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String?> boatSupabaseId,
      Value<String> categorySupabaseId,
      Value<String> name,
      Value<int> quantity,
      Value<String?> unit,
      Value<bool> isBought,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<bool> isHidden,
      Value<String?> notes,
      Value<String> origin,
      Value<double?> lastPurchasePrice,
      Value<String?> lastPurchasePlace,
      Value<String?> userPhotoUrl,
      Value<DateTime> lastModified,
    });

class $$ShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorySupabaseId => $composableBuilder(
    column: $table.categorySupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBought => $composableBuilder(
    column: $table.isBought,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userPhotoUrl => $composableBuilder(
    column: $table.userPhotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorySupabaseId => $composableBuilder(
    column: $table.categorySupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBought => $composableBuilder(
    column: $table.isBought,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userPhotoUrl => $composableBuilder(
    column: $table.userPhotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categorySupabaseId => $composableBuilder(
    column: $table.categorySupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isBought =>
      $composableBuilder(column: $table.isBought, builder: (column) => column);

  GeneratedColumn<bool> get isBundled =>
      $composableBuilder(column: $table.isBundled, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userPhotoUrl => $composableBuilder(
    column: $table.userPhotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$ShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingItemsTable,
          ShoppingItemRow,
          $$ShoppingItemsTableFilterComposer,
          $$ShoppingItemsTableOrderingComposer,
          $$ShoppingItemsTableAnnotationComposer,
          $$ShoppingItemsTableCreateCompanionBuilder,
          $$ShoppingItemsTableUpdateCompanionBuilder,
          (
            ShoppingItemRow,
            BaseReferences<_$AppDatabase, $ShoppingItemsTable, ShoppingItemRow>,
          ),
          ShoppingItemRow,
          PrefetchHooks Function()
        > {
  $$ShoppingItemsTableTableManager(_$AppDatabase db, $ShoppingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String?> boatSupabaseId = const Value.absent(),
                Value<String> categorySupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isBought = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<double?> lastPurchasePrice = const Value.absent(),
                Value<String?> lastPurchasePlace = const Value.absent(),
                Value<String?> userPhotoUrl = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => ShoppingItemsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                categorySupabaseId: categorySupabaseId,
                name: name,
                quantity: quantity,
                unit: unit,
                isBought: isBought,
                isBundled: isBundled,
                isSynced: isSynced,
                isHidden: isHidden,
                notes: notes,
                origin: origin,
                lastPurchasePrice: lastPurchasePrice,
                lastPurchasePlace: lastPurchasePlace,
                userPhotoUrl: userPhotoUrl,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String?> boatSupabaseId = const Value.absent(),
                Value<String> categorySupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isBought = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<double?> lastPurchasePrice = const Value.absent(),
                Value<String?> lastPurchasePlace = const Value.absent(),
                Value<String?> userPhotoUrl = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => ShoppingItemsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                categorySupabaseId: categorySupabaseId,
                name: name,
                quantity: quantity,
                unit: unit,
                isBought: isBought,
                isBundled: isBundled,
                isSynced: isSynced,
                isHidden: isHidden,
                notes: notes,
                origin: origin,
                lastPurchasePrice: lastPurchasePrice,
                lastPurchasePlace: lastPurchasePlace,
                userPhotoUrl: userPhotoUrl,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingItemsTable,
      ShoppingItemRow,
      $$ShoppingItemsTableFilterComposer,
      $$ShoppingItemsTableOrderingComposer,
      $$ShoppingItemsTableAnnotationComposer,
      $$ShoppingItemsTableCreateCompanionBuilder,
      $$ShoppingItemsTableUpdateCompanionBuilder,
      (
        ShoppingItemRow,
        BaseReferences<_$AppDatabase, $ShoppingItemsTable, ShoppingItemRow>,
      ),
      ShoppingItemRow,
      PrefetchHooks Function()
    >;
typedef $$ChecklistGroupsTableCreateCompanionBuilder =
    ChecklistGroupsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> appType,
      Value<String> title,
      Value<String?> description,
      Value<String> iconName,
      Value<bool> isBought,
      Value<bool> isBundled,
      Value<bool> isExpanded,
      Value<bool> isHidden,
      Value<bool> isSynced,
      Value<double?> lastPurchasePrice,
      Value<String> notes,
      Value<String> origin,
      Value<int> sortOrder,
      Value<DateTime> lastModified,
      Value<String?> communityTemplateId,
      Value<int?> communityTemplateVersion,
    });
typedef $$ChecklistGroupsTableUpdateCompanionBuilder =
    ChecklistGroupsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> appType,
      Value<String> title,
      Value<String?> description,
      Value<String> iconName,
      Value<bool> isBought,
      Value<bool> isBundled,
      Value<bool> isExpanded,
      Value<bool> isHidden,
      Value<bool> isSynced,
      Value<double?> lastPurchasePrice,
      Value<String> notes,
      Value<String> origin,
      Value<int> sortOrder,
      Value<DateTime> lastModified,
      Value<String?> communityTemplateId,
      Value<int?> communityTemplateVersion,
    });

class $$ChecklistGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistGroupsTable> {
  $$ChecklistGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appType => $composableBuilder(
    column: $table.appType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBought => $composableBuilder(
    column: $table.isBought,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExpanded => $composableBuilder(
    column: $table.isExpanded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get communityTemplateId => $composableBuilder(
    column: $table.communityTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get communityTemplateVersion => $composableBuilder(
    column: $table.communityTemplateVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChecklistGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistGroupsTable> {
  $$ChecklistGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appType => $composableBuilder(
    column: $table.appType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBought => $composableBuilder(
    column: $table.isBought,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExpanded => $composableBuilder(
    column: $table.isExpanded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get communityTemplateId => $composableBuilder(
    column: $table.communityTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get communityTemplateVersion => $composableBuilder(
    column: $table.communityTemplateVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChecklistGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistGroupsTable> {
  $$ChecklistGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appType =>
      $composableBuilder(column: $table.appType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<bool> get isBought =>
      $composableBuilder(column: $table.isBought, builder: (column) => column);

  GeneratedColumn<bool> get isBundled =>
      $composableBuilder(column: $table.isBundled, builder: (column) => column);

  GeneratedColumn<bool> get isExpanded => $composableBuilder(
    column: $table.isExpanded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<double> get lastPurchasePrice => $composableBuilder(
    column: $table.lastPurchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get communityTemplateId => $composableBuilder(
    column: $table.communityTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get communityTemplateVersion => $composableBuilder(
    column: $table.communityTemplateVersion,
    builder: (column) => column,
  );
}

class $$ChecklistGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistGroupsTable,
          ChecklistGroupRow,
          $$ChecklistGroupsTableFilterComposer,
          $$ChecklistGroupsTableOrderingComposer,
          $$ChecklistGroupsTableAnnotationComposer,
          $$ChecklistGroupsTableCreateCompanionBuilder,
          $$ChecklistGroupsTableUpdateCompanionBuilder,
          (
            ChecklistGroupRow,
            BaseReferences<
              _$AppDatabase,
              $ChecklistGroupsTable,
              ChecklistGroupRow
            >,
          ),
          ChecklistGroupRow,
          PrefetchHooks Function()
        > {
  $$ChecklistGroupsTableTableManager(
    _$AppDatabase db,
    $ChecklistGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> appType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<bool> isBought = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isExpanded = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<double?> lastPurchasePrice = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> communityTemplateId = const Value.absent(),
                Value<int?> communityTemplateVersion = const Value.absent(),
              }) => ChecklistGroupsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                appType: appType,
                title: title,
                description: description,
                iconName: iconName,
                isBought: isBought,
                isBundled: isBundled,
                isExpanded: isExpanded,
                isHidden: isHidden,
                isSynced: isSynced,
                lastPurchasePrice: lastPurchasePrice,
                notes: notes,
                origin: origin,
                sortOrder: sortOrder,
                lastModified: lastModified,
                communityTemplateId: communityTemplateId,
                communityTemplateVersion: communityTemplateVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> appType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<bool> isBought = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isExpanded = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<double?> lastPurchasePrice = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> communityTemplateId = const Value.absent(),
                Value<int?> communityTemplateVersion = const Value.absent(),
              }) => ChecklistGroupsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                appType: appType,
                title: title,
                description: description,
                iconName: iconName,
                isBought: isBought,
                isBundled: isBundled,
                isExpanded: isExpanded,
                isHidden: isHidden,
                isSynced: isSynced,
                lastPurchasePrice: lastPurchasePrice,
                notes: notes,
                origin: origin,
                sortOrder: sortOrder,
                lastModified: lastModified,
                communityTemplateId: communityTemplateId,
                communityTemplateVersion: communityTemplateVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChecklistGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistGroupsTable,
      ChecklistGroupRow,
      $$ChecklistGroupsTableFilterComposer,
      $$ChecklistGroupsTableOrderingComposer,
      $$ChecklistGroupsTableAnnotationComposer,
      $$ChecklistGroupsTableCreateCompanionBuilder,
      $$ChecklistGroupsTableUpdateCompanionBuilder,
      (
        ChecklistGroupRow,
        BaseReferences<_$AppDatabase, $ChecklistGroupsTable, ChecklistGroupRow>,
      ),
      ChecklistGroupRow,
      PrefetchHooks Function()
    >;
typedef $$ChecklistItemsTableCreateCompanionBuilder =
    ChecklistItemsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> groupSupabaseId,
      Value<String> title,
      Value<String> name,
      Value<String?> description,
      Value<String?> assetName,
      Value<String?> photoUrl,
      Value<String?> userPhotoUrl,
      Value<String?> userPhotoPath,
      Value<String?> notes,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String> completionHistory,
      Value<bool> isBundled,
      Value<bool> isHidden,
      Value<bool> isPermanentlyDeleted,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
      Value<DateTime> lastModified,
    });
typedef $$ChecklistItemsTableUpdateCompanionBuilder =
    ChecklistItemsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> groupSupabaseId,
      Value<String> title,
      Value<String> name,
      Value<String?> description,
      Value<String?> assetName,
      Value<String?> photoUrl,
      Value<String?> userPhotoUrl,
      Value<String?> userPhotoPath,
      Value<String?> notes,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String> completionHistory,
      Value<bool> isBundled,
      Value<bool> isHidden,
      Value<bool> isPermanentlyDeleted,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
      Value<DateTime> lastModified,
    });

class $$ChecklistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupSupabaseId => $composableBuilder(
    column: $table.groupSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userPhotoUrl => $composableBuilder(
    column: $table.userPhotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userPhotoPath => $composableBuilder(
    column: $table.userPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionHistory => $composableBuilder(
    column: $table.completionHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPermanentlyDeleted => $composableBuilder(
    column: $table.isPermanentlyDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChecklistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupSupabaseId => $composableBuilder(
    column: $table.groupSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userPhotoUrl => $composableBuilder(
    column: $table.userPhotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userPhotoPath => $composableBuilder(
    column: $table.userPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionHistory => $composableBuilder(
    column: $table.completionHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPermanentlyDeleted => $composableBuilder(
    column: $table.isPermanentlyDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChecklistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupSupabaseId => $composableBuilder(
    column: $table.groupSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetName =>
      $composableBuilder(column: $table.assetName, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get userPhotoUrl => $composableBuilder(
    column: $table.userPhotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userPhotoPath => $composableBuilder(
    column: $table.userPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completionHistory => $composableBuilder(
    column: $table.completionHistory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBundled =>
      $composableBuilder(column: $table.isBundled, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isPermanentlyDeleted => $composableBuilder(
    column: $table.isPermanentlyDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$ChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistItemsTable,
          ChecklistItemRow,
          $$ChecklistItemsTableFilterComposer,
          $$ChecklistItemsTableOrderingComposer,
          $$ChecklistItemsTableAnnotationComposer,
          $$ChecklistItemsTableCreateCompanionBuilder,
          $$ChecklistItemsTableUpdateCompanionBuilder,
          (
            ChecklistItemRow,
            BaseReferences<
              _$AppDatabase,
              $ChecklistItemsTable,
              ChecklistItemRow
            >,
          ),
          ChecklistItemRow,
          PrefetchHooks Function()
        > {
  $$ChecklistItemsTableTableManager(
    _$AppDatabase db,
    $ChecklistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> groupSupabaseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> assetName = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> userPhotoUrl = const Value.absent(),
                Value<String?> userPhotoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> completionHistory = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isPermanentlyDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => ChecklistItemsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                groupSupabaseId: groupSupabaseId,
                title: title,
                name: name,
                description: description,
                assetName: assetName,
                photoUrl: photoUrl,
                userPhotoUrl: userPhotoUrl,
                userPhotoPath: userPhotoPath,
                notes: notes,
                isCompleted: isCompleted,
                completedAt: completedAt,
                completionHistory: completionHistory,
                isBundled: isBundled,
                isHidden: isHidden,
                isPermanentlyDeleted: isPermanentlyDeleted,
                isSynced: isSynced,
                createdAt: createdAt,
                sortOrder: sortOrder,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> groupSupabaseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> assetName = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> userPhotoUrl = const Value.absent(),
                Value<String?> userPhotoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> completionHistory = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isPermanentlyDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => ChecklistItemsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                groupSupabaseId: groupSupabaseId,
                title: title,
                name: name,
                description: description,
                assetName: assetName,
                photoUrl: photoUrl,
                userPhotoUrl: userPhotoUrl,
                userPhotoPath: userPhotoPath,
                notes: notes,
                isCompleted: isCompleted,
                completedAt: completedAt,
                completionHistory: completionHistory,
                isBundled: isBundled,
                isHidden: isHidden,
                isPermanentlyDeleted: isPermanentlyDeleted,
                isSynced: isSynced,
                createdAt: createdAt,
                sortOrder: sortOrder,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistItemsTable,
      ChecklistItemRow,
      $$ChecklistItemsTableFilterComposer,
      $$ChecklistItemsTableOrderingComposer,
      $$ChecklistItemsTableAnnotationComposer,
      $$ChecklistItemsTableCreateCompanionBuilder,
      $$ChecklistItemsTableUpdateCompanionBuilder,
      (
        ChecklistItemRow,
        BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItemRow>,
      ),
      ChecklistItemRow,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<String?> description,
      Value<String?> instructions,
      Value<String> recipeType,
      Value<DateTime> createdAt,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<int> missingIngredientCount,
      Value<bool> isFavourite,
      Value<String?> glassware,
      Value<int?> prepMinutes,
      Value<int?> cookMinutes,
      Value<String?> story,
      Value<String> tastingLog,
      Value<String> cuisine,
      Value<String> flavorProfiles,
      Value<String?> cookingMethod,
      Value<String?> imageAsset,
      Value<String?> localPath,
      Value<DateTime> lastModified,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<String?> description,
      Value<String?> instructions,
      Value<String> recipeType,
      Value<DateTime> createdAt,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<int> missingIngredientCount,
      Value<bool> isFavourite,
      Value<String?> glassware,
      Value<int?> prepMinutes,
      Value<int?> cookMinutes,
      Value<String?> story,
      Value<String> tastingLog,
      Value<String> cuisine,
      Value<String> flavorProfiles,
      Value<String?> cookingMethod,
      Value<String?> imageAsset,
      Value<String?> localPath,
      Value<DateTime> lastModified,
    });

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeType => $composableBuilder(
    column: $table.recipeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missingIngredientCount => $composableBuilder(
    column: $table.missingIngredientCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavourite => $composableBuilder(
    column: $table.isFavourite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glassware => $composableBuilder(
    column: $table.glassware,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get story => $composableBuilder(
    column: $table.story,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tastingLog => $composableBuilder(
    column: $table.tastingLog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookingMethod => $composableBuilder(
    column: $table.cookingMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeType => $composableBuilder(
    column: $table.recipeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missingIngredientCount => $composableBuilder(
    column: $table.missingIngredientCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavourite => $composableBuilder(
    column: $table.isFavourite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glassware => $composableBuilder(
    column: $table.glassware,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get story => $composableBuilder(
    column: $table.story,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tastingLog => $composableBuilder(
    column: $table.tastingLog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookingMethod => $composableBuilder(
    column: $table.cookingMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipeType => $composableBuilder(
    column: $table.recipeType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isBundled =>
      $composableBuilder(column: $table.isBundled, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get missingIngredientCount => $composableBuilder(
    column: $table.missingIngredientCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavourite => $composableBuilder(
    column: $table.isFavourite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get glassware =>
      $composableBuilder(column: $table.glassware, builder: (column) => column);

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get story =>
      $composableBuilder(column: $table.story, builder: (column) => column);

  GeneratedColumn<String> get tastingLog => $composableBuilder(
    column: $table.tastingLog,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cuisine =>
      $composableBuilder(column: $table.cuisine, builder: (column) => column);

  GeneratedColumn<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cookingMethod => $composableBuilder(
    column: $table.cookingMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          RecipeRow,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (RecipeRow, BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow>),
          RecipeRow,
          PrefetchHooks Function()
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String> recipeType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> missingIngredientCount = const Value.absent(),
                Value<bool> isFavourite = const Value.absent(),
                Value<String?> glassware = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<String?> story = const Value.absent(),
                Value<String> tastingLog = const Value.absent(),
                Value<String> cuisine = const Value.absent(),
                Value<String> flavorProfiles = const Value.absent(),
                Value<String?> cookingMethod = const Value.absent(),
                Value<String?> imageAsset = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                description: description,
                instructions: instructions,
                recipeType: recipeType,
                createdAt: createdAt,
                isBundled: isBundled,
                isSynced: isSynced,
                missingIngredientCount: missingIngredientCount,
                isFavourite: isFavourite,
                glassware: glassware,
                prepMinutes: prepMinutes,
                cookMinutes: cookMinutes,
                story: story,
                tastingLog: tastingLog,
                cuisine: cuisine,
                flavorProfiles: flavorProfiles,
                cookingMethod: cookingMethod,
                imageAsset: imageAsset,
                localPath: localPath,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String> recipeType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> missingIngredientCount = const Value.absent(),
                Value<bool> isFavourite = const Value.absent(),
                Value<String?> glassware = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<String?> story = const Value.absent(),
                Value<String> tastingLog = const Value.absent(),
                Value<String> cuisine = const Value.absent(),
                Value<String> flavorProfiles = const Value.absent(),
                Value<String?> cookingMethod = const Value.absent(),
                Value<String?> imageAsset = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                description: description,
                instructions: instructions,
                recipeType: recipeType,
                createdAt: createdAt,
                isBundled: isBundled,
                isSynced: isSynced,
                missingIngredientCount: missingIngredientCount,
                isFavourite: isFavourite,
                glassware: glassware,
                prepMinutes: prepMinutes,
                cookMinutes: cookMinutes,
                story: story,
                tastingLog: tastingLog,
                cuisine: cuisine,
                flavorProfiles: flavorProfiles,
                cookingMethod: cookingMethod,
                imageAsset: imageAsset,
                localPath: localPath,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      RecipeRow,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (RecipeRow, BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow>),
      RecipeRow,
      PrefetchHooks Function()
    >;
typedef $$RecipeIngredientsTableCreateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> recipeSupabaseId,
      Value<String> name,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String?> substitute,
      Value<bool> isGarnish,
      Value<String?> garnishNotes,
      Value<bool> isOptional,
      Value<String?> photoUrl,
      Value<int> sortOrder,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });
typedef $$RecipeIngredientsTableUpdateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> recipeSupabaseId,
      Value<String> name,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String?> substitute,
      Value<bool> isGarnish,
      Value<String?> garnishNotes,
      Value<bool> isOptional,
      Value<String?> photoUrl,
      Value<int> sortOrder,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
    });

class $$RecipeIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeSupabaseId => $composableBuilder(
    column: $table.recipeSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substitute => $composableBuilder(
    column: $table.substitute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGarnish => $composableBuilder(
    column: $table.isGarnish,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get garnishNotes => $composableBuilder(
    column: $table.garnishNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeSupabaseId => $composableBuilder(
    column: $table.recipeSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substitute => $composableBuilder(
    column: $table.substitute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGarnish => $composableBuilder(
    column: $table.isGarnish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get garnishNotes => $composableBuilder(
    column: $table.garnishNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipeSupabaseId => $composableBuilder(
    column: $table.recipeSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get substitute => $composableBuilder(
    column: $table.substitute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGarnish =>
      $composableBuilder(column: $table.isGarnish, builder: (column) => column);

  GeneratedColumn<String> get garnishNotes => $composableBuilder(
    column: $table.garnishNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$RecipeIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredientRow,
          $$RecipeIngredientsTableFilterComposer,
          $$RecipeIngredientsTableOrderingComposer,
          $$RecipeIngredientsTableAnnotationComposer,
          $$RecipeIngredientsTableCreateCompanionBuilder,
          $$RecipeIngredientsTableUpdateCompanionBuilder,
          (
            RecipeIngredientRow,
            BaseReferences<
              _$AppDatabase,
              $RecipeIngredientsTable,
              RecipeIngredientRow
            >,
          ),
          RecipeIngredientRow,
          PrefetchHooks Function()
        > {
  $$RecipeIngredientsTableTableManager(
    _$AppDatabase db,
    $RecipeIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> recipeSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> substitute = const Value.absent(),
                Value<bool> isGarnish = const Value.absent(),
                Value<String?> garnishNotes = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => RecipeIngredientsCompanion(
                id: id,
                supabaseId: supabaseId,
                recipeSupabaseId: recipeSupabaseId,
                name: name,
                quantity: quantity,
                unit: unit,
                substitute: substitute,
                isGarnish: isGarnish,
                garnishNotes: garnishNotes,
                isOptional: isOptional,
                photoUrl: photoUrl,
                sortOrder: sortOrder,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> recipeSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> substitute = const Value.absent(),
                Value<bool> isGarnish = const Value.absent(),
                Value<String?> garnishNotes = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => RecipeIngredientsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                recipeSupabaseId: recipeSupabaseId,
                name: name,
                quantity: quantity,
                unit: unit,
                substitute: substitute,
                isGarnish: isGarnish,
                garnishNotes: garnishNotes,
                isOptional: isOptional,
                photoUrl: photoUrl,
                sortOrder: sortOrder,
                isSynced: isSynced,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeIngredientsTable,
      RecipeIngredientRow,
      $$RecipeIngredientsTableFilterComposer,
      $$RecipeIngredientsTableOrderingComposer,
      $$RecipeIngredientsTableAnnotationComposer,
      $$RecipeIngredientsTableCreateCompanionBuilder,
      $$RecipeIngredientsTableUpdateCompanionBuilder,
      (
        RecipeIngredientRow,
        BaseReferences<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredientRow
        >,
      ),
      RecipeIngredientRow,
      PrefetchHooks Function()
    >;
typedef $$BarIngredientsTableCreateCompanionBuilder =
    BarIngredientsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<bool> inMyBar,
      Value<int> sortOrder,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<String> category,
      Value<String> flavorProfiles,
      Value<double?> alcoholByVolume,
      Value<String?> substitute1,
      Value<String?> substitute2,
      Value<String?> localPhotoPath,
      Value<String?> imageUrl,
      Value<double?> lastKnownPrice,
      Value<String> priceCurrency,
      Value<String?> lastKnownPriceUnit,
      Value<String?> lastPurchasePlace,
      Value<String> purchaseHistory,
      Value<DateTime> lastModified,
    });
typedef $$BarIngredientsTableUpdateCompanionBuilder =
    BarIngredientsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<bool> inMyBar,
      Value<int> sortOrder,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<String> category,
      Value<String> flavorProfiles,
      Value<double?> alcoholByVolume,
      Value<String?> substitute1,
      Value<String?> substitute2,
      Value<String?> localPhotoPath,
      Value<String?> imageUrl,
      Value<double?> lastKnownPrice,
      Value<String> priceCurrency,
      Value<String?> lastKnownPriceUnit,
      Value<String?> lastPurchasePlace,
      Value<String> purchaseHistory,
      Value<DateTime> lastModified,
    });

class $$BarIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $BarIngredientsTable> {
  $$BarIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inMyBar => $composableBuilder(
    column: $table.inMyBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alcoholByVolume => $composableBuilder(
    column: $table.alcoholByVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substitute1 => $composableBuilder(
    column: $table.substitute1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substitute2 => $composableBuilder(
    column: $table.substitute2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPhotoPath => $composableBuilder(
    column: $table.localPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastKnownPrice => $composableBuilder(
    column: $table.lastKnownPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priceCurrency => $composableBuilder(
    column: $table.priceCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastKnownPriceUnit => $composableBuilder(
    column: $table.lastKnownPriceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseHistory => $composableBuilder(
    column: $table.purchaseHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BarIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $BarIngredientsTable> {
  $$BarIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inMyBar => $composableBuilder(
    column: $table.inMyBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alcoholByVolume => $composableBuilder(
    column: $table.alcoholByVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substitute1 => $composableBuilder(
    column: $table.substitute1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substitute2 => $composableBuilder(
    column: $table.substitute2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPhotoPath => $composableBuilder(
    column: $table.localPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastKnownPrice => $composableBuilder(
    column: $table.lastKnownPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priceCurrency => $composableBuilder(
    column: $table.priceCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastKnownPriceUnit => $composableBuilder(
    column: $table.lastKnownPriceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseHistory => $composableBuilder(
    column: $table.purchaseHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BarIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BarIngredientsTable> {
  $$BarIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get inMyBar =>
      $composableBuilder(column: $table.inMyBar, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isBundled =>
      $composableBuilder(column: $table.isBundled, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => column,
  );

  GeneratedColumn<double> get alcoholByVolume => $composableBuilder(
    column: $table.alcoholByVolume,
    builder: (column) => column,
  );

  GeneratedColumn<String> get substitute1 => $composableBuilder(
    column: $table.substitute1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get substitute2 => $composableBuilder(
    column: $table.substitute2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPhotoPath => $composableBuilder(
    column: $table.localPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<double> get lastKnownPrice => $composableBuilder(
    column: $table.lastKnownPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priceCurrency => $composableBuilder(
    column: $table.priceCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastKnownPriceUnit => $composableBuilder(
    column: $table.lastKnownPriceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseHistory => $composableBuilder(
    column: $table.purchaseHistory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$BarIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BarIngredientsTable,
          BarIngredientRow,
          $$BarIngredientsTableFilterComposer,
          $$BarIngredientsTableOrderingComposer,
          $$BarIngredientsTableAnnotationComposer,
          $$BarIngredientsTableCreateCompanionBuilder,
          $$BarIngredientsTableUpdateCompanionBuilder,
          (
            BarIngredientRow,
            BaseReferences<
              _$AppDatabase,
              $BarIngredientsTable,
              BarIngredientRow
            >,
          ),
          BarIngredientRow,
          PrefetchHooks Function()
        > {
  $$BarIngredientsTableTableManager(
    _$AppDatabase db,
    $BarIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BarIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BarIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BarIngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> inMyBar = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> flavorProfiles = const Value.absent(),
                Value<double?> alcoholByVolume = const Value.absent(),
                Value<String?> substitute1 = const Value.absent(),
                Value<String?> substitute2 = const Value.absent(),
                Value<String?> localPhotoPath = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<double?> lastKnownPrice = const Value.absent(),
                Value<String> priceCurrency = const Value.absent(),
                Value<String?> lastKnownPriceUnit = const Value.absent(),
                Value<String?> lastPurchasePlace = const Value.absent(),
                Value<String> purchaseHistory = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => BarIngredientsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                inMyBar: inMyBar,
                sortOrder: sortOrder,
                isBundled: isBundled,
                isSynced: isSynced,
                category: category,
                flavorProfiles: flavorProfiles,
                alcoholByVolume: alcoholByVolume,
                substitute1: substitute1,
                substitute2: substitute2,
                localPhotoPath: localPhotoPath,
                imageUrl: imageUrl,
                lastKnownPrice: lastKnownPrice,
                priceCurrency: priceCurrency,
                lastKnownPriceUnit: lastKnownPriceUnit,
                lastPurchasePlace: lastPurchasePlace,
                purchaseHistory: purchaseHistory,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> inMyBar = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> flavorProfiles = const Value.absent(),
                Value<double?> alcoholByVolume = const Value.absent(),
                Value<String?> substitute1 = const Value.absent(),
                Value<String?> substitute2 = const Value.absent(),
                Value<String?> localPhotoPath = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<double?> lastKnownPrice = const Value.absent(),
                Value<String> priceCurrency = const Value.absent(),
                Value<String?> lastKnownPriceUnit = const Value.absent(),
                Value<String?> lastPurchasePlace = const Value.absent(),
                Value<String> purchaseHistory = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => BarIngredientsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                inMyBar: inMyBar,
                sortOrder: sortOrder,
                isBundled: isBundled,
                isSynced: isSynced,
                category: category,
                flavorProfiles: flavorProfiles,
                alcoholByVolume: alcoholByVolume,
                substitute1: substitute1,
                substitute2: substitute2,
                localPhotoPath: localPhotoPath,
                imageUrl: imageUrl,
                lastKnownPrice: lastKnownPrice,
                priceCurrency: priceCurrency,
                lastKnownPriceUnit: lastKnownPriceUnit,
                lastPurchasePlace: lastPurchasePlace,
                purchaseHistory: purchaseHistory,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BarIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BarIngredientsTable,
      BarIngredientRow,
      $$BarIngredientsTableFilterComposer,
      $$BarIngredientsTableOrderingComposer,
      $$BarIngredientsTableAnnotationComposer,
      $$BarIngredientsTableCreateCompanionBuilder,
      $$BarIngredientsTableUpdateCompanionBuilder,
      (
        BarIngredientRow,
        BaseReferences<_$AppDatabase, $BarIngredientsTable, BarIngredientRow>,
      ),
      BarIngredientRow,
      PrefetchHooks Function()
    >;
typedef $$PantryIngredientsTableCreateCompanionBuilder =
    PantryIngredientsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<bool> inMyPantry,
      Value<double?> quantity,
      Value<String?> unit,
      Value<int> sortOrder,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<String> category,
      Value<String> flavorProfiles,
      Value<String> cuisineTypes,
      Value<String> allergenTags,
      Value<String> dietaryTags,
      Value<String?> substitute1,
      Value<String?> substitute2,
      Value<String?> localPhotoPath,
      Value<String?> imageUrl,
      Value<DateTime?> expiryDate,
      Value<double?> lastKnownPrice,
      Value<String> priceCurrency,
      Value<String?> lastKnownPriceUnit,
      Value<String?> lastPurchasePlace,
      Value<String> purchaseHistory,
      Value<double?> caloriesPer100g,
      Value<double?> proteinPer100g,
      Value<double?> fatPer100g,
      Value<double?> carbsPer100g,
      Value<DateTime> lastModified,
    });
typedef $$PantryIngredientsTableUpdateCompanionBuilder =
    PantryIngredientsCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> boatSupabaseId,
      Value<String> name,
      Value<bool> inMyPantry,
      Value<double?> quantity,
      Value<String?> unit,
      Value<int> sortOrder,
      Value<bool> isBundled,
      Value<bool> isSynced,
      Value<String> category,
      Value<String> flavorProfiles,
      Value<String> cuisineTypes,
      Value<String> allergenTags,
      Value<String> dietaryTags,
      Value<String?> substitute1,
      Value<String?> substitute2,
      Value<String?> localPhotoPath,
      Value<String?> imageUrl,
      Value<DateTime?> expiryDate,
      Value<double?> lastKnownPrice,
      Value<String> priceCurrency,
      Value<String?> lastKnownPriceUnit,
      Value<String?> lastPurchasePlace,
      Value<String> purchaseHistory,
      Value<double?> caloriesPer100g,
      Value<double?> proteinPer100g,
      Value<double?> fatPer100g,
      Value<double?> carbsPer100g,
      Value<DateTime> lastModified,
    });

class $$PantryIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $PantryIngredientsTable> {
  $$PantryIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inMyPantry => $composableBuilder(
    column: $table.inMyPantry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuisineTypes => $composableBuilder(
    column: $table.cuisineTypes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergenTags => $composableBuilder(
    column: $table.allergenTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dietaryTags => $composableBuilder(
    column: $table.dietaryTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substitute1 => $composableBuilder(
    column: $table.substitute1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substitute2 => $composableBuilder(
    column: $table.substitute2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPhotoPath => $composableBuilder(
    column: $table.localPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastKnownPrice => $composableBuilder(
    column: $table.lastKnownPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priceCurrency => $composableBuilder(
    column: $table.priceCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastKnownPriceUnit => $composableBuilder(
    column: $table.lastKnownPriceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseHistory => $composableBuilder(
    column: $table.purchaseHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PantryIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PantryIngredientsTable> {
  $$PantryIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inMyPantry => $composableBuilder(
    column: $table.inMyPantry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBundled => $composableBuilder(
    column: $table.isBundled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisineTypes => $composableBuilder(
    column: $table.cuisineTypes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergenTags => $composableBuilder(
    column: $table.allergenTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dietaryTags => $composableBuilder(
    column: $table.dietaryTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substitute1 => $composableBuilder(
    column: $table.substitute1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substitute2 => $composableBuilder(
    column: $table.substitute2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPhotoPath => $composableBuilder(
    column: $table.localPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastKnownPrice => $composableBuilder(
    column: $table.lastKnownPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priceCurrency => $composableBuilder(
    column: $table.priceCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastKnownPriceUnit => $composableBuilder(
    column: $table.lastKnownPriceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseHistory => $composableBuilder(
    column: $table.purchaseHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PantryIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PantryIngredientsTable> {
  $$PantryIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatSupabaseId => $composableBuilder(
    column: $table.boatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get inMyPantry => $composableBuilder(
    column: $table.inMyPantry,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isBundled =>
      $composableBuilder(column: $table.isBundled, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get flavorProfiles => $composableBuilder(
    column: $table.flavorProfiles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cuisineTypes => $composableBuilder(
    column: $table.cuisineTypes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allergenTags => $composableBuilder(
    column: $table.allergenTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dietaryTags => $composableBuilder(
    column: $table.dietaryTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get substitute1 => $composableBuilder(
    column: $table.substitute1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get substitute2 => $composableBuilder(
    column: $table.substitute2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPhotoPath => $composableBuilder(
    column: $table.localPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastKnownPrice => $composableBuilder(
    column: $table.lastKnownPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priceCurrency => $composableBuilder(
    column: $table.priceCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastKnownPriceUnit => $composableBuilder(
    column: $table.lastKnownPriceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastPurchasePlace => $composableBuilder(
    column: $table.lastPurchasePlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseHistory => $composableBuilder(
    column: $table.purchaseHistory,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$PantryIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PantryIngredientsTable,
          PantryIngredientRow,
          $$PantryIngredientsTableFilterComposer,
          $$PantryIngredientsTableOrderingComposer,
          $$PantryIngredientsTableAnnotationComposer,
          $$PantryIngredientsTableCreateCompanionBuilder,
          $$PantryIngredientsTableUpdateCompanionBuilder,
          (
            PantryIngredientRow,
            BaseReferences<
              _$AppDatabase,
              $PantryIngredientsTable,
              PantryIngredientRow
            >,
          ),
          PantryIngredientRow,
          PrefetchHooks Function()
        > {
  $$PantryIngredientsTableTableManager(
    _$AppDatabase db,
    $PantryIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PantryIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PantryIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PantryIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> inMyPantry = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> flavorProfiles = const Value.absent(),
                Value<String> cuisineTypes = const Value.absent(),
                Value<String> allergenTags = const Value.absent(),
                Value<String> dietaryTags = const Value.absent(),
                Value<String?> substitute1 = const Value.absent(),
                Value<String?> substitute2 = const Value.absent(),
                Value<String?> localPhotoPath = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<double?> lastKnownPrice = const Value.absent(),
                Value<String> priceCurrency = const Value.absent(),
                Value<String?> lastKnownPriceUnit = const Value.absent(),
                Value<String?> lastPurchasePlace = const Value.absent(),
                Value<String> purchaseHistory = const Value.absent(),
                Value<double?> caloriesPer100g = const Value.absent(),
                Value<double?> proteinPer100g = const Value.absent(),
                Value<double?> fatPer100g = const Value.absent(),
                Value<double?> carbsPer100g = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => PantryIngredientsCompanion(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                inMyPantry: inMyPantry,
                quantity: quantity,
                unit: unit,
                sortOrder: sortOrder,
                isBundled: isBundled,
                isSynced: isSynced,
                category: category,
                flavorProfiles: flavorProfiles,
                cuisineTypes: cuisineTypes,
                allergenTags: allergenTags,
                dietaryTags: dietaryTags,
                substitute1: substitute1,
                substitute2: substitute2,
                localPhotoPath: localPhotoPath,
                imageUrl: imageUrl,
                expiryDate: expiryDate,
                lastKnownPrice: lastKnownPrice,
                priceCurrency: priceCurrency,
                lastKnownPriceUnit: lastKnownPriceUnit,
                lastPurchasePlace: lastPurchasePlace,
                purchaseHistory: purchaseHistory,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                fatPer100g: fatPer100g,
                carbsPer100g: carbsPer100g,
                lastModified: lastModified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> boatSupabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> inMyPantry = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isBundled = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> flavorProfiles = const Value.absent(),
                Value<String> cuisineTypes = const Value.absent(),
                Value<String> allergenTags = const Value.absent(),
                Value<String> dietaryTags = const Value.absent(),
                Value<String?> substitute1 = const Value.absent(),
                Value<String?> substitute2 = const Value.absent(),
                Value<String?> localPhotoPath = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<double?> lastKnownPrice = const Value.absent(),
                Value<String> priceCurrency = const Value.absent(),
                Value<String?> lastKnownPriceUnit = const Value.absent(),
                Value<String?> lastPurchasePlace = const Value.absent(),
                Value<String> purchaseHistory = const Value.absent(),
                Value<double?> caloriesPer100g = const Value.absent(),
                Value<double?> proteinPer100g = const Value.absent(),
                Value<double?> fatPer100g = const Value.absent(),
                Value<double?> carbsPer100g = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
              }) => PantryIngredientsCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                boatSupabaseId: boatSupabaseId,
                name: name,
                inMyPantry: inMyPantry,
                quantity: quantity,
                unit: unit,
                sortOrder: sortOrder,
                isBundled: isBundled,
                isSynced: isSynced,
                category: category,
                flavorProfiles: flavorProfiles,
                cuisineTypes: cuisineTypes,
                allergenTags: allergenTags,
                dietaryTags: dietaryTags,
                substitute1: substitute1,
                substitute2: substitute2,
                localPhotoPath: localPhotoPath,
                imageUrl: imageUrl,
                expiryDate: expiryDate,
                lastKnownPrice: lastKnownPrice,
                priceCurrency: priceCurrency,
                lastKnownPriceUnit: lastKnownPriceUnit,
                lastPurchasePlace: lastPurchasePlace,
                purchaseHistory: purchaseHistory,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                fatPer100g: fatPer100g,
                carbsPer100g: carbsPer100g,
                lastModified: lastModified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PantryIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PantryIngredientsTable,
      PantryIngredientRow,
      $$PantryIngredientsTableFilterComposer,
      $$PantryIngredientsTableOrderingComposer,
      $$PantryIngredientsTableAnnotationComposer,
      $$PantryIngredientsTableCreateCompanionBuilder,
      $$PantryIngredientsTableUpdateCompanionBuilder,
      (
        PantryIngredientRow,
        BaseReferences<
          _$AppDatabase,
          $PantryIngredientsTable,
          PantryIngredientRow
        >,
      ),
      PantryIngredientRow,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableTableCreateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String?> activeBoatSupabaseId,
      Value<bool> showHiddenItems,
      Value<bool> isPro,
      Value<DateTime?> proExpiresAt,
      Value<String?> selectedBoatId,
      Value<String?> userId,
      Value<bool> isDarkMode,
      Value<String> unitPrefsJson,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
      Value<String> recentEmails,
      Value<String?> fromName,
      Value<String?> replyToEmail,
      Value<String?> boatName,
      Value<int> freeEditsUsed,
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String?> activeBoatSupabaseId,
      Value<bool> showHiddenItems,
      Value<bool> isPro,
      Value<DateTime?> proExpiresAt,
      Value<String?> selectedBoatId,
      Value<String?> userId,
      Value<bool> isDarkMode,
      Value<String> unitPrefsJson,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
      Value<String> recentEmails,
      Value<String?> fromName,
      Value<String?> replyToEmail,
      Value<String?> boatName,
      Value<int> freeEditsUsed,
    });

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeBoatSupabaseId => $composableBuilder(
    column: $table.activeBoatSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showHiddenItems => $composableBuilder(
    column: $table.showHiddenItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPro => $composableBuilder(
    column: $table.isPro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get proExpiresAt => $composableBuilder(
    column: $table.proExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedBoatId => $composableBuilder(
    column: $table.selectedBoatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPrefsJson => $composableBuilder(
    column: $table.unitPrefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recentEmails => $composableBuilder(
    column: $table.recentEmails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToEmail => $composableBuilder(
    column: $table.replyToEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatName => $composableBuilder(
    column: $table.boatName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeEditsUsed => $composableBuilder(
    column: $table.freeEditsUsed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeBoatSupabaseId => $composableBuilder(
    column: $table.activeBoatSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showHiddenItems => $composableBuilder(
    column: $table.showHiddenItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPro => $composableBuilder(
    column: $table.isPro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get proExpiresAt => $composableBuilder(
    column: $table.proExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedBoatId => $composableBuilder(
    column: $table.selectedBoatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrefsJson => $composableBuilder(
    column: $table.unitPrefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recentEmails => $composableBuilder(
    column: $table.recentEmails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToEmail => $composableBuilder(
    column: $table.replyToEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatName => $composableBuilder(
    column: $table.boatName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeEditsUsed => $composableBuilder(
    column: $table.freeEditsUsed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activeBoatSupabaseId => $composableBuilder(
    column: $table.activeBoatSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showHiddenItems => $composableBuilder(
    column: $table.showHiddenItems,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPro =>
      $composableBuilder(column: $table.isPro, builder: (column) => column);

  GeneratedColumn<DateTime> get proExpiresAt => $composableBuilder(
    column: $table.proExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedBoatId => $composableBuilder(
    column: $table.selectedBoatId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitPrefsJson => $composableBuilder(
    column: $table.unitPrefsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recentEmails => $composableBuilder(
    column: $table.recentEmails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromName =>
      $composableBuilder(column: $table.fromName, builder: (column) => column);

  GeneratedColumn<String> get replyToEmail => $composableBuilder(
    column: $table.replyToEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boatName =>
      $composableBuilder(column: $table.boatName, builder: (column) => column);

  GeneratedColumn<int> get freeEditsUsed => $composableBuilder(
    column: $table.freeEditsUsed,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsRow,
          $$UserSettingsTableTableFilterComposer,
          $$UserSettingsTableTableOrderingComposer,
          $$UserSettingsTableTableAnnotationComposer,
          $$UserSettingsTableTableCreateCompanionBuilder,
          $$UserSettingsTableTableUpdateCompanionBuilder,
          (
            UserSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $UserSettingsTableTable,
              UserSettingsRow
            >,
          ),
          UserSettingsRow,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableTableManager(
    _$AppDatabase db,
    $UserSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> activeBoatSupabaseId = const Value.absent(),
                Value<bool> showHiddenItems = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<DateTime?> proExpiresAt = const Value.absent(),
                Value<String?> selectedBoatId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<bool> isDarkMode = const Value.absent(),
                Value<String> unitPrefsJson = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> recentEmails = const Value.absent(),
                Value<String?> fromName = const Value.absent(),
                Value<String?> replyToEmail = const Value.absent(),
                Value<String?> boatName = const Value.absent(),
                Value<int> freeEditsUsed = const Value.absent(),
              }) => UserSettingsTableCompanion(
                id: id,
                activeBoatSupabaseId: activeBoatSupabaseId,
                showHiddenItems: showHiddenItems,
                isPro: isPro,
                proExpiresAt: proExpiresAt,
                selectedBoatId: selectedBoatId,
                userId: userId,
                isDarkMode: isDarkMode,
                unitPrefsJson: unitPrefsJson,
                isSynced: isSynced,
                lastModified: lastModified,
                recentEmails: recentEmails,
                fromName: fromName,
                replyToEmail: replyToEmail,
                boatName: boatName,
                freeEditsUsed: freeEditsUsed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> activeBoatSupabaseId = const Value.absent(),
                Value<bool> showHiddenItems = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<DateTime?> proExpiresAt = const Value.absent(),
                Value<String?> selectedBoatId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<bool> isDarkMode = const Value.absent(),
                Value<String> unitPrefsJson = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> recentEmails = const Value.absent(),
                Value<String?> fromName = const Value.absent(),
                Value<String?> replyToEmail = const Value.absent(),
                Value<String?> boatName = const Value.absent(),
                Value<int> freeEditsUsed = const Value.absent(),
              }) => UserSettingsTableCompanion.insert(
                id: id,
                activeBoatSupabaseId: activeBoatSupabaseId,
                showHiddenItems: showHiddenItems,
                isPro: isPro,
                proExpiresAt: proExpiresAt,
                selectedBoatId: selectedBoatId,
                userId: userId,
                isDarkMode: isDarkMode,
                unitPrefsJson: unitPrefsJson,
                isSynced: isSynced,
                lastModified: lastModified,
                recentEmails: recentEmails,
                fromName: fromName,
                replyToEmail: replyToEmail,
                boatName: boatName,
                freeEditsUsed: freeEditsUsed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTableTable,
      UserSettingsRow,
      $$UserSettingsTableTableFilterComposer,
      $$UserSettingsTableTableOrderingComposer,
      $$UserSettingsTableTableAnnotationComposer,
      $$UserSettingsTableTableCreateCompanionBuilder,
      $$UserSettingsTableTableUpdateCompanionBuilder,
      (
        UserSettingsRow,
        BaseReferences<_$AppDatabase, $UserSettingsTableTable, UserSettingsRow>,
      ),
      UserSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$CommunityTemplatesTableCreateCompanionBuilder =
    CommunityTemplatesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> name,
      Value<String> description,
      Value<bool> isApproved,
      Value<String> authorId,
      Value<String> title,
      Value<String> category,
      Value<String> subcategory,
      Value<String> content,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
      Value<int> downloadCount,
      Value<double> avgRating,
      Value<int> ratingCount,
      Value<int> version,
    });
typedef $$CommunityTemplatesTableUpdateCompanionBuilder =
    CommunityTemplatesCompanion Function({
      Value<int> id,
      Value<String> supabaseId,
      Value<String> name,
      Value<String> description,
      Value<bool> isApproved,
      Value<String> authorId,
      Value<String> title,
      Value<String> category,
      Value<String> subcategory,
      Value<String> content,
      Value<bool> isSynced,
      Value<DateTime> lastModified,
      Value<int> downloadCount,
      Value<double> avgRating,
      Value<int> ratingCount,
      Value<int> version,
    });

class $$CommunityTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $CommunityTemplatesTable> {
  $$CommunityTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isApproved => $composableBuilder(
    column: $table.isApproved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadCount => $composableBuilder(
    column: $table.downloadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgRating => $composableBuilder(
    column: $table.avgRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingCount => $composableBuilder(
    column: $table.ratingCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommunityTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CommunityTemplatesTable> {
  $$CommunityTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isApproved => $composableBuilder(
    column: $table.isApproved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadCount => $composableBuilder(
    column: $table.downloadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgRating => $composableBuilder(
    column: $table.avgRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingCount => $composableBuilder(
    column: $table.ratingCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommunityTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommunityTemplatesTable> {
  $$CommunityTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isApproved => $composableBuilder(
    column: $table.isApproved,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadCount => $composableBuilder(
    column: $table.downloadCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgRating =>
      $composableBuilder(column: $table.avgRating, builder: (column) => column);

  GeneratedColumn<int> get ratingCount => $composableBuilder(
    column: $table.ratingCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$CommunityTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommunityTemplatesTable,
          CommunityTemplateRow,
          $$CommunityTemplatesTableFilterComposer,
          $$CommunityTemplatesTableOrderingComposer,
          $$CommunityTemplatesTableAnnotationComposer,
          $$CommunityTemplatesTableCreateCompanionBuilder,
          $$CommunityTemplatesTableUpdateCompanionBuilder,
          (
            CommunityTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $CommunityTemplatesTable,
              CommunityTemplateRow
            >,
          ),
          CommunityTemplateRow,
          PrefetchHooks Function()
        > {
  $$CommunityTemplatesTableTableManager(
    _$AppDatabase db,
    $CommunityTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommunityTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommunityTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommunityTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isApproved = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> subcategory = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<int> downloadCount = const Value.absent(),
                Value<double> avgRating = const Value.absent(),
                Value<int> ratingCount = const Value.absent(),
                Value<int> version = const Value.absent(),
              }) => CommunityTemplatesCompanion(
                id: id,
                supabaseId: supabaseId,
                name: name,
                description: description,
                isApproved: isApproved,
                authorId: authorId,
                title: title,
                category: category,
                subcategory: subcategory,
                content: content,
                isSynced: isSynced,
                lastModified: lastModified,
                downloadCount: downloadCount,
                avgRating: avgRating,
                ratingCount: ratingCount,
                version: version,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> supabaseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isApproved = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> subcategory = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<int> downloadCount = const Value.absent(),
                Value<double> avgRating = const Value.absent(),
                Value<int> ratingCount = const Value.absent(),
                Value<int> version = const Value.absent(),
              }) => CommunityTemplatesCompanion.insert(
                id: id,
                supabaseId: supabaseId,
                name: name,
                description: description,
                isApproved: isApproved,
                authorId: authorId,
                title: title,
                category: category,
                subcategory: subcategory,
                content: content,
                isSynced: isSynced,
                lastModified: lastModified,
                downloadCount: downloadCount,
                avgRating: avgRating,
                ratingCount: ratingCount,
                version: version,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommunityTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommunityTemplatesTable,
      CommunityTemplateRow,
      $$CommunityTemplatesTableFilterComposer,
      $$CommunityTemplatesTableOrderingComposer,
      $$CommunityTemplatesTableAnnotationComposer,
      $$CommunityTemplatesTableCreateCompanionBuilder,
      $$CommunityTemplatesTableUpdateCompanionBuilder,
      (
        CommunityTemplateRow,
        BaseReferences<
          _$AppDatabase,
          $CommunityTemplatesTable,
          CommunityTemplateRow
        >,
      ),
      CommunityTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxItemsTableCreateCompanionBuilder =
    SyncOutboxItemsCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> recordId,
      Value<String> operation,
      Value<String> data,
      Value<int> priority,
      Value<bool> isDelete,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
    });
typedef $$SyncOutboxItemsTableUpdateCompanionBuilder =
    SyncOutboxItemsCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> recordId,
      Value<String> operation,
      Value<String> data,
      Value<int> priority,
      Value<bool> isDelete,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
    });

class $$SyncOutboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxItemsTable> {
  $$SyncOutboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDelete => $composableBuilder(
    column: $table.isDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxItemsTable> {
  $$SyncOutboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDelete => $composableBuilder(
    column: $table.isDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxItemsTable> {
  $$SyncOutboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDelete =>
      $composableBuilder(column: $table.isDelete, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxItemsTable,
          SyncOutboxRow,
          $$SyncOutboxItemsTableFilterComposer,
          $$SyncOutboxItemsTableOrderingComposer,
          $$SyncOutboxItemsTableAnnotationComposer,
          $$SyncOutboxItemsTableCreateCompanionBuilder,
          $$SyncOutboxItemsTableUpdateCompanionBuilder,
          (
            SyncOutboxRow,
            BaseReferences<_$AppDatabase, $SyncOutboxItemsTable, SyncOutboxRow>,
          ),
          SyncOutboxRow,
          PrefetchHooks Function()
        > {
  $$SyncOutboxItemsTableTableManager(
    _$AppDatabase db,
    $SyncOutboxItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isDelete = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxItemsCompanion(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                data: data,
                priority: priority,
                isDelete: isDelete,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isDelete = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxItemsCompanion.insert(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                data: data,
                priority: priority,
                isDelete: isDelete,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxItemsTable,
      SyncOutboxRow,
      $$SyncOutboxItemsTableFilterComposer,
      $$SyncOutboxItemsTableOrderingComposer,
      $$SyncOutboxItemsTableAnnotationComposer,
      $$SyncOutboxItemsTableCreateCompanionBuilder,
      $$SyncOutboxItemsTableUpdateCompanionBuilder,
      (
        SyncOutboxRow,
        BaseReferences<_$AppDatabase, $SyncOutboxItemsTable, SyncOutboxRow>,
      ),
      SyncOutboxRow,
      PrefetchHooks Function()
    >;
typedef $$ConflictLogsTableCreateCompanionBuilder =
    ConflictLogsCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> localSupabaseId,
      Value<String> remoteSupabaseId,
      Value<String> conflictType,
      Value<String> resolution,
      Value<String> localData,
      Value<String> remoteData,
      Value<DateTime> timestamp,
      Value<DateTime?> resolvedAt,
    });
typedef $$ConflictLogsTableUpdateCompanionBuilder =
    ConflictLogsCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> localSupabaseId,
      Value<String> remoteSupabaseId,
      Value<String> conflictType,
      Value<String> resolution,
      Value<String> localData,
      Value<String> remoteData,
      Value<DateTime> timestamp,
      Value<DateTime?> resolvedAt,
    });

class $$ConflictLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ConflictLogsTable> {
  $$ConflictLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localSupabaseId => $composableBuilder(
    column: $table.localSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteSupabaseId => $composableBuilder(
    column: $table.remoteSupabaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictType => $composableBuilder(
    column: $table.conflictType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localData => $composableBuilder(
    column: $table.localData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteData => $composableBuilder(
    column: $table.remoteData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConflictLogsTable> {
  $$ConflictLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localSupabaseId => $composableBuilder(
    column: $table.localSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteSupabaseId => $composableBuilder(
    column: $table.remoteSupabaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictType => $composableBuilder(
    column: $table.conflictType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localData => $composableBuilder(
    column: $table.localData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteData => $composableBuilder(
    column: $table.remoteData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConflictLogsTable> {
  $$ConflictLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localSupabaseId => $composableBuilder(
    column: $table.localSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteSupabaseId => $composableBuilder(
    column: $table.remoteSupabaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflictType => $composableBuilder(
    column: $table.conflictType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localData =>
      $composableBuilder(column: $table.localData, builder: (column) => column);

  GeneratedColumn<String> get remoteData => $composableBuilder(
    column: $table.remoteData,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$ConflictLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConflictLogsTable,
          ConflictLogRow,
          $$ConflictLogsTableFilterComposer,
          $$ConflictLogsTableOrderingComposer,
          $$ConflictLogsTableAnnotationComposer,
          $$ConflictLogsTableCreateCompanionBuilder,
          $$ConflictLogsTableUpdateCompanionBuilder,
          (
            ConflictLogRow,
            BaseReferences<_$AppDatabase, $ConflictLogsTable, ConflictLogRow>,
          ),
          ConflictLogRow,
          PrefetchHooks Function()
        > {
  $$ConflictLogsTableTableManager(_$AppDatabase db, $ConflictLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> localSupabaseId = const Value.absent(),
                Value<String> remoteSupabaseId = const Value.absent(),
                Value<String> conflictType = const Value.absent(),
                Value<String> resolution = const Value.absent(),
                Value<String> localData = const Value.absent(),
                Value<String> remoteData = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
              }) => ConflictLogsCompanion(
                id: id,
                targetTable: targetTable,
                localSupabaseId: localSupabaseId,
                remoteSupabaseId: remoteSupabaseId,
                conflictType: conflictType,
                resolution: resolution,
                localData: localData,
                remoteData: remoteData,
                timestamp: timestamp,
                resolvedAt: resolvedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> localSupabaseId = const Value.absent(),
                Value<String> remoteSupabaseId = const Value.absent(),
                Value<String> conflictType = const Value.absent(),
                Value<String> resolution = const Value.absent(),
                Value<String> localData = const Value.absent(),
                Value<String> remoteData = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
              }) => ConflictLogsCompanion.insert(
                id: id,
                targetTable: targetTable,
                localSupabaseId: localSupabaseId,
                remoteSupabaseId: remoteSupabaseId,
                conflictType: conflictType,
                resolution: resolution,
                localData: localData,
                remoteData: remoteData,
                timestamp: timestamp,
                resolvedAt: resolvedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConflictLogsTable,
      ConflictLogRow,
      $$ConflictLogsTableFilterComposer,
      $$ConflictLogsTableOrderingComposer,
      $$ConflictLogsTableAnnotationComposer,
      $$ConflictLogsTableCreateCompanionBuilder,
      $$ConflictLogsTableUpdateCompanionBuilder,
      (
        ConflictLogRow,
        BaseReferences<_$AppDatabase, $ConflictLogsTable, ConflictLogRow>,
      ),
      ConflictLogRow,
      PrefetchHooks Function()
    >;
typedef $$ErrorLogsTableCreateCompanionBuilder =
    ErrorLogsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String> level,
      Value<String> message,
      Value<String?> stackTrace,
      Value<String?> sourceFile,
      Value<String?> routeHint,
      Value<String> appVersion,
      Value<String> platform,
      Value<bool> isPro,
      Value<String> fingerprint,
      Value<int> occurrences,
      Value<DateTime?> processedAt,
      Value<String?> issueUrl,
      Value<String?> debugBreadcrumbs,
    });
typedef $$ErrorLogsTableUpdateCompanionBuilder =
    ErrorLogsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String> level,
      Value<String> message,
      Value<String?> stackTrace,
      Value<String?> sourceFile,
      Value<String?> routeHint,
      Value<String> appVersion,
      Value<String> platform,
      Value<bool> isPro,
      Value<String> fingerprint,
      Value<int> occurrences,
      Value<DateTime?> processedAt,
      Value<String?> issueUrl,
      Value<String?> debugBreadcrumbs,
    });

class $$ErrorLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ErrorLogsTable> {
  $$ErrorLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFile => $composableBuilder(
    column: $table.sourceFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeHint => $composableBuilder(
    column: $table.routeHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPro => $composableBuilder(
    column: $table.isPro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueUrl => $composableBuilder(
    column: $table.issueUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debugBreadcrumbs => $composableBuilder(
    column: $table.debugBreadcrumbs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ErrorLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ErrorLogsTable> {
  $$ErrorLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFile => $composableBuilder(
    column: $table.sourceFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeHint => $composableBuilder(
    column: $table.routeHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPro => $composableBuilder(
    column: $table.isPro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueUrl => $composableBuilder(
    column: $table.issueUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debugBreadcrumbs => $composableBuilder(
    column: $table.debugBreadcrumbs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ErrorLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ErrorLogsTable> {
  $$ErrorLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFile => $composableBuilder(
    column: $table.sourceFile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeHint =>
      $composableBuilder(column: $table.routeHint, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<bool> get isPro =>
      $composableBuilder(column: $table.isPro, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueUrl =>
      $composableBuilder(column: $table.issueUrl, builder: (column) => column);

  GeneratedColumn<String> get debugBreadcrumbs => $composableBuilder(
    column: $table.debugBreadcrumbs,
    builder: (column) => column,
  );
}

class $$ErrorLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ErrorLogsTable,
          ErrorLogRow,
          $$ErrorLogsTableFilterComposer,
          $$ErrorLogsTableOrderingComposer,
          $$ErrorLogsTableAnnotationComposer,
          $$ErrorLogsTableCreateCompanionBuilder,
          $$ErrorLogsTableUpdateCompanionBuilder,
          (
            ErrorLogRow,
            BaseReferences<_$AppDatabase, $ErrorLogsTable, ErrorLogRow>,
          ),
          ErrorLogRow,
          PrefetchHooks Function()
        > {
  $$ErrorLogsTableTableManager(_$AppDatabase db, $ErrorLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ErrorLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ErrorLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ErrorLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> stackTrace = const Value.absent(),
                Value<String?> sourceFile = const Value.absent(),
                Value<String?> routeHint = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<int> occurrences = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<String?> issueUrl = const Value.absent(),
                Value<String?> debugBreadcrumbs = const Value.absent(),
              }) => ErrorLogsCompanion(
                id: id,
                createdAt: createdAt,
                level: level,
                message: message,
                stackTrace: stackTrace,
                sourceFile: sourceFile,
                routeHint: routeHint,
                appVersion: appVersion,
                platform: platform,
                isPro: isPro,
                fingerprint: fingerprint,
                occurrences: occurrences,
                processedAt: processedAt,
                issueUrl: issueUrl,
                debugBreadcrumbs: debugBreadcrumbs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> stackTrace = const Value.absent(),
                Value<String?> sourceFile = const Value.absent(),
                Value<String?> routeHint = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<int> occurrences = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<String?> issueUrl = const Value.absent(),
                Value<String?> debugBreadcrumbs = const Value.absent(),
              }) => ErrorLogsCompanion.insert(
                id: id,
                createdAt: createdAt,
                level: level,
                message: message,
                stackTrace: stackTrace,
                sourceFile: sourceFile,
                routeHint: routeHint,
                appVersion: appVersion,
                platform: platform,
                isPro: isPro,
                fingerprint: fingerprint,
                occurrences: occurrences,
                processedAt: processedAt,
                issueUrl: issueUrl,
                debugBreadcrumbs: debugBreadcrumbs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ErrorLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ErrorLogsTable,
      ErrorLogRow,
      $$ErrorLogsTableFilterComposer,
      $$ErrorLogsTableOrderingComposer,
      $$ErrorLogsTableAnnotationComposer,
      $$ErrorLogsTableCreateCompanionBuilder,
      $$ErrorLogsTableUpdateCompanionBuilder,
      (
        ErrorLogRow,
        BaseReferences<_$AppDatabase, $ErrorLogsTable, ErrorLogRow>,
      ),
      ErrorLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GuestProfilesTableTableManager get guestProfiles =>
      $$GuestProfilesTableTableManager(_db, _db.guestProfiles);
  $$RecipeCollectionsTableTableManager get recipeCollections =>
      $$RecipeCollectionsTableTableManager(_db, _db.recipeCollections);
  $$CrewMembersTableTableManager get crewMembers =>
      $$CrewMembersTableTableManager(_db, _db.crewMembers);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$FuelLogEntriesTableTableManager get fuelLogEntries =>
      $$FuelLogEntriesTableTableManager(_db, _db.fuelLogEntries);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$MealPlansTableTableManager get mealPlans =>
      $$MealPlansTableTableManager(_db, _db.mealPlans);
  $$BoatsTableTableManager get boats =>
      $$BoatsTableTableManager(_db, _db.boats);
  $$CaptainLogEntriesTableTableManager get captainLogEntries =>
      $$CaptainLogEntriesTableTableManager(_db, _db.captainLogEntries);
  $$MaintenanceTasksTableTableManager get maintenanceTasks =>
      $$MaintenanceTasksTableTableManager(_db, _db.maintenanceTasks);
  $$ShoppingCategoriesTableTableManager get shoppingCategories =>
      $$ShoppingCategoriesTableTableManager(_db, _db.shoppingCategories);
  $$ShoppingItemsTableTableManager get shoppingItems =>
      $$ShoppingItemsTableTableManager(_db, _db.shoppingItems);
  $$ChecklistGroupsTableTableManager get checklistGroups =>
      $$ChecklistGroupsTableTableManager(_db, _db.checklistGroups);
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(_db, _db.checklistItems);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(_db, _db.recipeIngredients);
  $$BarIngredientsTableTableManager get barIngredients =>
      $$BarIngredientsTableTableManager(_db, _db.barIngredients);
  $$PantryIngredientsTableTableManager get pantryIngredients =>
      $$PantryIngredientsTableTableManager(_db, _db.pantryIngredients);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
  $$CommunityTemplatesTableTableManager get communityTemplates =>
      $$CommunityTemplatesTableTableManager(_db, _db.communityTemplates);
  $$SyncOutboxItemsTableTableManager get syncOutboxItems =>
      $$SyncOutboxItemsTableTableManager(_db, _db.syncOutboxItems);
  $$ConflictLogsTableTableManager get conflictLogs =>
      $$ConflictLogsTableTableManager(_db, _db.conflictLogs);
  $$ErrorLogsTableTableManager get errorLogs =>
      $$ErrorLogsTableTableManager(_db, _db.errorLogs);
}
