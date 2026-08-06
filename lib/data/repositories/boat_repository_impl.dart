import 'dart:convert';

import 'package:drift/drift.dart';
import '../../domain/repositories/boat_repository.dart';
import '../../models/models.dart';
import '../../services/polar_local_improve.dart';
import '../../services/sync_service.dart';
import '../drift/app_database.dart';

/// Boat on Drift (S1); sync-participating.
class BoatRepositoryImpl implements BoatRepository {
  final AppDatabase db;
  final SyncService syncService;

  BoatRepositoryImpl(this.db, this.syncService);

  Boat _toDomain(BoatRow r) => Boat()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..name = r.name
    ..isBought = r.isBought
    ..isHidden = r.isHidden
    ..isSynced = r.isSynced
    ..lastPurchasePrice = r.lastPurchasePrice
    ..notes = r.notes
    ..origin = r.origin
    ..photoUrl = r.photoUrl
    ..ownerId = r.ownerId
    ..shareCode = r.shareCode
    ..llmApiKeys = (jsonDecode(r.llmApiKeys) as List)
        .map((e) => LlmApiKeyEntry.fromJson(e as Map<String, dynamic>))
        .toList()
    ..activeLlmProvider = r.activeLlmProvider
    ..polar = parsePolarTable(r.polarJson)
    ..polarBySeaState = parsePolarBySeaState(r.polarBySeaStateJson)
    ..lastModified = r.lastModified;

  BoatsCompanion _toCompanion(Boat b) => BoatsCompanion(
        supabaseId: Value(b.supabaseId),
        name: Value(b.name),
        isBought: Value(b.isBought),
        isHidden: Value(b.isHidden),
        isSynced: Value(b.isSynced),
        lastPurchasePrice: Value(b.lastPurchasePrice),
        notes: Value(b.notes),
        origin: Value(b.origin),
        photoUrl: Value(b.photoUrl),
        ownerId: Value(b.ownerId),
        shareCode: Value(b.shareCode),
        llmApiKeys: Value(
            jsonEncode(b.llmApiKeys.map((e) => e.toStorageJson()).toList())),
        activeLlmProvider: Value(b.activeLlmProvider),
        polarJson: Value(encodePolarTable(b.polar)),
        polarBySeaStateJson: Value(encodePolarBySeaState(b.polarBySeaState)),
        lastModified: Value(b.lastModified),
      );

  @override
  Stream<List<Boat>> watchBoats() {
    return db.select(db.boats).watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Boat>> getBoats() async {
    final rows = await db.select(db.boats).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Boat?> getBoatById(String supabaseId) async {
    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals(supabaseId)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> addBoat(Boat boat) async {
    boat.lastModified = DateTime.now().toUtc();
    await db.into(db.boats).insert(_toCompanion(boat));
    await syncService.queueOutgoingChange('boats', boat.toJson());
  }

  @override
  Future<void> updateBoat(Boat boat) async {
    boat.lastModified = DateTime.now().toUtc();
    await (db.update(db.boats)..where((t) => t.supabaseId.equals(boat.supabaseId)))
        .write(_toCompanion(boat));
    await syncService.queueOutgoingChange('boats', boat.toJson());
  }

  @override
  Future<void> upsertLocal(Boat boat) async {
    boat.lastModified = DateTime.now().toUtc();
    final existing = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals(boat.supabaseId)))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.boats).insert(_toCompanion(boat));
    } else {
      await (db.update(db.boats)
            ..where((t) => t.supabaseId.equals(boat.supabaseId)))
          .write(_toCompanion(boat));
    }
  }

  @override
  Future<void> deleteBoat(Boat boat) async {
    await (db.delete(db.boats)..where((t) => t.supabaseId.equals(boat.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'boats',
      {'supabaseId': boat.supabaseId},
      isDelete: true,
    );
  }
}
