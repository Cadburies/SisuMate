/// #16: whitelist-only payload builders for anything sent to an LLM
/// provider (#203's `LlmClientService`). Every LLM-powered feature must
/// build its request through one of these, never by passing a whole domain
/// object/`toJson()` straight into a prompt — that way a new field added to
/// a model later can't silently start leaving the device.
///
/// Applies even though there's no server-side proxy anymore (BYOK, #203):
/// the destination is a third-party provider the app has no contract with
/// beyond what the user configured, so the discipline matters just as much.
class LlmPayloadBuilder {
  const LlmPayloadBuilder._();

  /// Task/checklist-item titles only — never descriptions, notes, or photos.
  static Map<String, dynamic> taskTitles(Iterable<String> titles) =>
      {'tasks': titles.toList()};

  /// Bar/pantry ingredient names only — never quantities, prices, purchase
  /// history, or photos.
  static Map<String, dynamic> ingredientNames(Iterable<String> names) =>
      {'ingredients': names.toList()};

  /// Minimal weather snippet — never a full forecast payload or position.
  static Map<String, dynamic> weatherSnippet({
    String? summary,
    double? windSpeedKt,
    String? windDirection,
  }) =>
      {
        'summary': ?summary,
        'windSpeedKt': ?windSpeedKt,
        'windDirection': ?windDirection,
      };

  /// Maintenance alert explainer (#18): description + interval only — never
  /// `notes` (free text may contain PII) or `doneBy` (a crew member's name).
  static Map<String, dynamic> maintenanceAlert({
    required String description,
    int? intervalHours,
    int? intervalMonths,
  }) =>
      {
        'description': description,
        'intervalHours': ?intervalHours,
        'intervalMonths': ?intervalMonths,
      };

  /// Travel-safety briefing (#224): destination country + crew nationalities
  /// only. Never a passport number, DOB, photo, or any other passport
  /// field — nationality is all a visa/entry-safety lookup needs, and this
  /// is a hard privacy line, not a scope-convenience one.
  static Map<String, dynamic> travelSafetyQuery({
    required String destinationCountry,
    required Iterable<String> nationalities,
  }) =>
      {
        'destinationCountry': destinationCountry,
        'nationalities': nationalities.toList(),
      };

  /// Warranty/manual coverage check (#222): breakage description + a
  /// user-pasted excerpt of their own manual/warranty terms/wiring diagram
  /// labels. Unlike the other builders above, [manualExcerpt] is not a
  /// domain-object field being whitelisted out of a larger record — there is
  /// no `Document` text-extraction pipeline (#222's scope note), so the only
  /// thing this builder ever sees is exactly what the user typed/pasted into
  /// the dialog for this one query. It is capped for token-budget reasons
  /// (BYOK — the user pays per token), not as a privacy filter.
  static Map<String, dynamic> warrantyQuery({
    required String breakageDescription,
    required String manualExcerpt,
  }) =>
      {
        'breakageDescription': breakageDescription,
        'manualExcerpt': manualExcerpt.length > 4000
            ? manualExcerpt.substring(0, 4000)
            : manualExcerpt,
      };

  /// Safety equipment compliance check (#226): item description + a
  /// user-pasted excerpt of a flare/life-raft/EPIRB/fire-extinguisher
  /// service manual or certification card. Same shape/reasoning as
  /// [warrantyQuery] above — no `Document` OCR/text-extraction pipeline, so
  /// the only content sent is exactly what the user typed/pasted into the
  /// dialog for this one query. Capped for token-budget reasons (BYOK), not
  /// as a privacy filter.
  static Map<String, dynamic> safetyComplianceQuery({
    required String itemDescription,
    required String excerptText,
  }) =>
      {
        'itemDescription': itemDescription,
        'excerptText': excerptText.length > 4000
            ? excerptText.substring(0, 4000)
            : excerptText,
      };

  /// Insurance claim likelihood check (#227): incident description + a
  /// user-pasted excerpt of the relevant policy clause (coverage,
  /// exclusions, deductible terms). Same shape/reasoning as [warrantyQuery]
  /// above — no `Document` OCR/text-extraction pipeline, so the only
  /// content sent is exactly what the user typed/pasted into the dialog for
  /// this one query. Capped for token-budget reasons (BYOK), not as a
  /// privacy filter.
  static Map<String, dynamic> insuranceClaimQuery({
    required String incidentDescription,
    required String policyExcerpt,
  }) =>
      {
        'incidentDescription': incidentDescription,
        'policyExcerpt': policyExcerpt.length > 4000
            ? policyExcerpt.substring(0, 4000)
            : policyExcerpt,
      };

  /// Freeform Captain's Log entry parsing (#220): **intentionally not
  /// whitelist-filtered** like every other builder in this file — the
  /// user's own freeform typed/dictated text *is* the payload; there is no
  /// larger domain object to filter fields out of, so there is nothing to
  /// whitelist against. This is a deliberate exception to the class-level
  /// discipline documented above, not an oversight.
  ///
  /// Boundary this exception does NOT extend past: never forward this raw
  /// text into any *other* LLM feature's payload (e.g. #218's cross-history
  /// pattern detection) without the user separately opting in for that
  /// specific feature — freeform log prose can carry crew names, exact
  /// plans, or health notes the user typed for this one entry, not for a
  /// different downstream AI call to reason over.
  static Map<String, dynamic> parseLogEntryText(String freeform) => {
        'freeformText': freeform,
      };

  /// Cross-history pattern detection (#218): free-text notes + dates only
  /// from Captain's Log and maintenance notes — never crew names
  /// (`watchCrew`/`crewOnBoard`/`doneBy`), exact position
  /// (`positionLat`/`positionLng`), or photos. [source] is a caller-chosen
  /// tag (e.g. `'log'` / `'maintenance'`) so the model can reason about
  /// patterns that span both streams without losing where each note came
  /// from. Records (not `CaptainLogEntry`/`MaintenanceTask`) as the shape
  /// keeps this builder structurally incapable of leaking a field added to
  /// either model later.
  static Map<String, dynamic> historySnippets({
    required Iterable<({DateTime date, String source, String text})> entries,
  }) =>
      {
        'entries': entries
            .map((e) => {
                  'date': e.date.toIso8601String().split('T').first,
                  'source': e.source,
                  'text': e.text,
                })
            .toList(),
      };

  /// Location-aware part sourcing (#217): the part/task description plus a
  /// **coarse** location string (city/region, e.g. from a reverse-geocode
  /// call already truncated to a short place label) — never exact GPS
  /// coordinates. [coarseLocation] is nullable because a user may decline
  /// location permission and skip location entirely; the LLM still gets a
  /// useful (if less targeted) answer from the part description alone.
  static Map<String, dynamic> partSourcingQuery({
    required String partDescription,
    String? coarseLocation,
  }) =>
      {
        'partDescription': partDescription,
        'coarseLocation': ?coarseLocation,
      };

  /// Risk-prioritized maintenance triage (#216): the whole outstanding
  /// backlog's description + interval/last-done fields only — never `notes`
  /// (free text may contain PII) or `doneBy` (a crew member's name), same
  /// exclusions as [maintenanceAlert] above. [asOf] is today's date so the
  /// model reasons about "overdue by how much" against a fixed reference
  /// point rather than its own guess at the current date. Records (not
  /// `MaintenanceTask` itself) as the parameter shape keeps this builder
  /// structurally incapable of leaking a field added to that model later.
  static Map<String, dynamic> maintenanceBacklog({
    required DateTime asOf,
    required Iterable<
            ({
              String description,
              int? intervalHours,
              int? intervalMonths,
              int? lastDoneHours,
              DateTime? lastDoneDate,
            })>
        tasks,
  }) =>
      {
        'asOfDate': asOf.toIso8601String().split('T').first,
        'tasks': tasks
            .map((t) => {
                  'description': t.description,
                  'intervalHours': ?t.intervalHours,
                  'intervalMonths': ?t.intervalMonths,
                  'lastDoneHours': ?t.lastDoneHours,
                  'lastDoneDate':
                      ?t.lastDoneDate?.toIso8601String().split('T').first,
                })
            .toList(),
      };

  /// Passage weather safety briefing (#219): the already-fetched hourly wind
  /// + marine wave forecast window, whitelisted field-by-field rather than
  /// forwarding `WeatherBundle`/`HourlyWeather`/`HourlyMarine` — same
  /// discipline as every other builder here, even though weather data
  /// carries no privacy risk on its own. Never GPS-exact coordinates or
  /// charted depth; [placeName] is the only location context sent. Records
  /// (not the model classes) as the parameter shape keeps this builder
  /// structurally incapable of leaking a field added to those classes later
  /// without a matching change here. Capped to 24h — a caller passing more
  /// than that is a bug, not something to silently truncate further.
  /// #230: [hourlyWind]'s `confidence` field is #229's ensemble-derived
  /// high/medium/low agreement label — null whenever ensemble data isn't
  /// available (offline, cache miss, or the fetch never ran), which the
  /// caller must pass explicitly since Dart records have no optional
  /// fields. A null/absent confidence must never block or alter anything
  /// else about the briefing — it's an additive signal, not a requirement.
  static Map<String, dynamic> passageWeatherBriefing({
    String? placeName,
    required Iterable<
            ({
              DateTime time,
              double? windKt,
              double? windDirDeg,
              double? precipProb,
              String? confidence,
            })>
        hourlyWind,
    required Iterable<
            ({DateTime time, double? waveHeightM, double? waveDirDeg, double? wavePeriodS})>
        hourlyMarine,
  }) =>
      {
        'placeName': ?placeName,
        'hourlyWind': hourlyWind
            .map((h) => {
                  'time': h.time.toIso8601String(),
                  'windKt': ?h.windKt,
                  'windDirDeg': ?h.windDirDeg,
                  'precipProb': ?h.precipProb,
                  'confidence': ?h.confidence,
                })
            .toList(),
        'hourlyMarine': hourlyMarine
            .map((m) => {
                  'time': m.time.toIso8601String(),
                  'waveHeightM': ?m.waveHeightM,
                  'waveDirDeg': ?m.waveDirDeg,
                  'wavePeriodS': ?m.wavePeriodS,
                })
            .toList(),
      };
}
