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
}
