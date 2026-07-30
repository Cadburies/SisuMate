/// Static Northern-Hemisphere season-to-ingredient map.
/// Returns ingredients that are typically in season for the current month.
class SeasonalService {
  // month (1–12) → ingredient names in season (Northern Hemisphere)
  static const _nhSeasons = <int, List<String>>{
    1:  ['leeks', 'parsnips', 'kale', 'celeriac', 'blood oranges', 'clementines', 'mussels', 'oysters'],
    2:  ['leeks', 'purple sprouting broccoli', 'forced rhubarb', 'blood oranges', 'mussels', 'oysters'],
    3:  ['purple sprouting broccoli', 'spring greens', 'forced rhubarb', 'watercress', 'sea trout'],
    4:  ['asparagus', 'spring onions', 'watercress', 'wild garlic', 'Jersey Royal potatoes', 'sea trout', 'lamb'],
    5:  ['asparagus', 'broad beans', 'Jersey Royal potatoes', 'spinach', 'strawberries', 'sea bass', 'lamb'],
    6:  ['asparagus', 'broad beans', 'strawberries', 'gooseberries', 'courgettes', 'peas', 'sea bass', 'mackerel'],
    7:  ['courgettes', 'tomatoes', 'sweetcorn', 'blueberries', 'raspberries', 'runner beans', 'mackerel', 'crab'],
    8:  ['tomatoes', 'sweetcorn', 'aubergine', 'peppers', 'plums', 'peaches', 'runner beans', 'mackerel', 'crab'],
    9:  ['tomatoes', 'butternut squash', 'apples', 'pears', 'blackberries', 'mushrooms', 'oysters'],
    10: ['butternut squash', 'pumpkin', 'parsnips', 'apples', 'pears', 'quince', 'mushrooms', 'mussels', 'oysters'],
    11: ['parsnips', 'celeriac', 'kale', 'quince', 'clementines', 'chestnuts', 'mussels', 'oysters', 'venison'],
    12: ['parsnips', 'celeriac', 'leeks', 'blood oranges', 'clementines', 'chestnuts', 'mussels', 'oysters', 'venison'],
  };

  // Southern-Hemisphere: offset by 6 months — built once at class load time
  static final _shSeasons = <int, List<String>>{
    for (int m = 1; m <= 12; m++)
      m: _nhSeasons[((m + 5) % 12) + 1]!,
  };

  /// Returns ingredients currently in season.
  /// [southernHemisphere] flips the calendar by 6 months.
  static List<String> getInSeasonNow({bool southernHemisphere = false}) {
    final month = DateTime.now().month;
    final map = southernHemisphere ? _shSeasons : _nhSeasons;
    return map[month] ?? [];
  }

  /// Full month name for display.
  static String get currentMonthName {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[DateTime.now().month];
  }
}
