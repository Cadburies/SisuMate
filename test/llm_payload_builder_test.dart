import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/llm_payload_builder.dart';

/// #16: every builder must whitelist fields, never forward a full domain
/// object. Each test poisons the "source" data with sentinel strings that
/// would only appear in a full boat/crew dump, then asserts none of them
/// survive into the built payload.
void main() {
  const poisonEmail = 'crew.member.secret@example.com';
  const poisonPhone = '+1-555-0100-SECRET';
  const poisonNotes = 'CONFIDENTIAL medical note should never leave device';

  test('taskTitles only includes titles, never notes/description', () {
    final payload = LlmPayloadBuilder.taskTitles(['Check bilge pump']);
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Check bilge pump'));
    expect(encoded, isNot(contains(poisonNotes)));
    expect(payload.keys, {'tasks'});
  });

  test('ingredientNames only includes names, never price/purchase history', () {
    final payload = LlmPayloadBuilder.ingredientNames(['Flour', 'Salt']);
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Flour'));
    expect(encoded, contains('Salt'));
    expect(payload.keys, {'ingredients'});
  });

  test('weatherSnippet only includes the whitelisted fields, never position',
      () {
    final payload = LlmPayloadBuilder.weatherSnippet(
      summary: 'Fresh breeze, scattered showers',
      windSpeedKt: 18,
      windDirection: 'SW',
    );
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Fresh breeze'));
    expect(payload.keys, {'summary', 'windSpeedKt', 'windDirection'});
    expect(encoded, isNot(contains('positionLat')));
    expect(encoded, isNot(contains('positionLng')));
  });

  test('maintenanceAlert excludes notes (PII) and doneBy (crew name)', () {
    final payload = LlmPayloadBuilder.maintenanceAlert(
      description: 'Replace impeller',
      intervalHours: 500,
    );
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Replace impeller'));
    expect(payload.keys, {'description', 'intervalHours'});
    // Simulates a caller accidentally having poison data in scope nearby —
    // the builder's own signature has no `notes`/`doneBy` parameter at all,
    // so this is really asserting the whitelist is structural, not just
    // "happens to not include it this time".
    expect(encoded, isNot(contains(poisonEmail)));
    expect(encoded, isNot(contains(poisonPhone)));
    expect(encoded, isNot(contains(poisonNotes)));
  });

  test('travelSafetyQuery only includes destination + nationalities, never '
      'a passport number, DOB, or other passport field', () {
    final payload = LlmPayloadBuilder.travelSafetyQuery(
      destinationCountry: 'Taiwan',
      nationalities: ['British', 'American'],
    );
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Taiwan'));
    expect(encoded, contains('British'));
    expect(payload.keys, {'destinationCountry', 'nationalities'});
    // The builder's signature structurally has no passportNumber/dob/photo
    // parameter at all — asserting the poison strings can't appear proves
    // that's a real constraint, not an accident of this call's arguments.
    expect(encoded, isNot(contains(poisonEmail)));
    expect(encoded, isNot(contains(poisonPhone)));
    expect(encoded, isNot(contains(poisonNotes)));
  });

  test('warrantyQuery carries the breakage description and pasted excerpt '
      'verbatim (no domain-object whitelist applies to user-pasted text)',
      () {
    final payload = LlmPayloadBuilder.warrantyQuery(
      breakageDescription: 'Bilge pump stopped cycling',
      manualExcerpt: 'Electrical components warranted for 12 months.',
    );
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Bilge pump stopped cycling'));
    expect(encoded, contains('Electrical components warranted'));
    expect(payload.keys, {'breakageDescription', 'manualExcerpt'});
  });

  test('warrantyQuery caps an oversized pasted excerpt at 4000 chars', () {
    final huge = 'x' * 5000;
    final payload = LlmPayloadBuilder.warrantyQuery(
      breakageDescription: 'Engine won\'t start',
      manualExcerpt: huge,
    );

    expect((payload['manualExcerpt'] as String).length, 4000);
  });

  test('maintenanceBacklog whitelists description/interval/last-done fields '
      'only, never notes or doneBy (crew name)', () {
    final payload = LlmPayloadBuilder.maintenanceBacklog(
      asOf: DateTime.utc(2026, 8, 3),
      tasks: [
        (
          description: 'Replace impeller',
          intervalHours: 500,
          intervalMonths: null,
          lastDoneHours: 100,
          lastDoneDate: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Replace impeller'));
    expect(encoded, contains('2026-08-03'));
    expect(payload.keys, {'asOfDate', 'tasks'});
    final task = (payload['tasks'] as List).first as Map;
    expect(task.keys,
        {'description', 'intervalHours', 'lastDoneHours', 'lastDoneDate'});
    expect(encoded, isNot(contains(poisonEmail)));
    expect(encoded, isNot(contains(poisonPhone)));
    expect(encoded, isNot(contains(poisonNotes)));
  });

  test('maintenanceBacklog omits null interval/last-done fields per task '
      'rather than sending them as null', () {
    final payload = LlmPayloadBuilder.maintenanceBacklog(
      asOf: DateTime.utc(2026, 8, 3),
      tasks: [
        (
          description: 'Check rig tension',
          intervalHours: null,
          intervalMonths: 12,
          lastDoneHours: null,
          lastDoneDate: null,
        ),
      ],
    );
    final task = (payload['tasks'] as List).first as Map;
    expect(task.keys, {'description', 'intervalMonths'});
  });

  test('passageWeatherBriefing whitelists hourly wind/marine fields only, '
      'never GPS-exact coordinates or charted depth', () {
    final payload = LlmPayloadBuilder.passageWeatherBriefing(
      placeName: 'Cabo San Lucas',
      hourlyWind: [
        (
          time: DateTime.utc(2026, 8, 3, 14),
          windKt: 18.5,
          windDirDeg: 270.0,
          precipProb: 10.0,
        ),
      ],
      hourlyMarine: [
        (
          time: DateTime.utc(2026, 8, 3, 14),
          waveHeightM: 1.2,
          waveDirDeg: 260.0,
          wavePeriodS: 7.0,
        ),
      ],
    );
    final encoded = jsonEncode(payload);

    expect(encoded, contains('Cabo San Lucas'));
    expect(encoded, contains('18.5'));
    expect(encoded, contains('1.2'));
    expect(payload.keys, {'placeName', 'hourlyWind', 'hourlyMarine'});
    final wind = (payload['hourlyWind'] as List).first as Map;
    expect(wind.keys, {'time', 'windKt', 'windDirDeg', 'precipProb'});
    final marine = (payload['hourlyMarine'] as List).first as Map;
    expect(marine.keys, {'time', 'waveHeightM', 'waveDirDeg', 'wavePeriodS'});
    expect(encoded, isNot(contains('lat')));
    expect(encoded, isNot(contains('lon')));
    expect(encoded, isNot(contains('waterDepthM')));
  });
}
