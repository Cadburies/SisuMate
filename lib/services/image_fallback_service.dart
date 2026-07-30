/// Service for determining appropriate fallback images based on item type and category
class ImageFallbackService {
  /// Gets the appropriate fallback asset for a checklist item
  static String getFallbackAsset(String? itemName, String? groupName) {
    if (itemName == null || groupName == null) {
      return 'NoPicture.jpg';
    }

    // Try to find category-specific fallback
    final categoryFallback = _getCategoryFallback(groupName);
    if (categoryFallback != null) {
      return categoryFallback;
    }

    // Return general fallback
    return 'NoPicture.jpg';
  }

  /// Gets category-specific fallback image
  static String? _getCategoryFallback(String groupName) {
    final lowerGroupName = groupName.toLowerCase();

    // Engine maintenance categories
    if (lowerGroupName.contains('engine') || lowerGroupName.contains('hour')) {
      return 'lists/50HourEngineService/NoPicture.jpg';
    }

    // Safety briefings
    if (lowerGroupName.contains('safety') || lowerGroupName.contains('briefing')) {
      return 'lists/DayTripSafetyBriefing/NoPicture.jpg';
    }

    // Documents
    if (lowerGroupName.contains('document')) {
      return 'lists/DocumentsChecks/NoPicture.jpg';
    }

    // Annual checks
    if (lowerGroupName.contains('annual') || lowerGroupName.contains('year')) {
      return 'lists/AnualChecks/NoPicture.jpg';
    }

    // Daily checks
    if (lowerGroupName.contains('daily')) {
      return 'lists/DailyEngineChecks/NoPicture.jpg';
    }

    // Watch checks
    if (lowerGroupName.contains('watch')) {
      return 'lists/WatchChecks/NoPicture.jpg';
    }

    // Weekly checks
    if (lowerGroupName.contains('week')) {
      return 'lists/OneWeek/NoPicture.jpg';
    }

    return null; // No specific fallback found
  }

  /// Gets a list of all available fallback images
  static List<String> getAllFallbackImages() {
    return [
      'NoPicture.jpg',
      'lists/50HourEngineService/NoPicture.jpg',
      'lists/250HourEngineService/NoPicture.jpg',
      'lists/500HourEngineService/NoPicture.jpg',
      'lists/1000HourEngineService/NoPicture.jpg',
      'lists/DailyEngineChecks/NoPicture.jpg',
      'lists/DocumentsChecks/NoPicture.jpg',
      'lists/AnualChecks/NoPicture.jpg',
      'lists/OneWeek/NoPicture.jpg',
      'lists/OneDay/NoPicture.jpg',
      'lists/LastMinute/NoPicture.jpg',
      'lists/WatchChecks/NoPicture.jpg',
      'lists/DayTripSafetyBriefing/NoPicture.jpg',
      'lists/LongTripSafetyBriefing/NoPicture.jpg',
      'lists/WelcomeOnBoard/NoPicture.jpg',
    ];
  }

  /// Validates if an asset name exists in the fallback list
  static bool isValidFallback(String assetName) {
    return getAllFallbackImages().contains(assetName);
  }
}
