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
  static Map<String, dynamic> passageWeatherBriefing({
    String? placeName,
    required Iterable<
            ({DateTime time, double? windKt, double? windDirDeg, double? precipProb})>
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
