import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/seasonal_service.dart';

void main() {
  group('SeasonalService', () {
    test('currentMonthName matches the real current month', () {
      const names = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      expect(SeasonalService.currentMonthName, names[DateTime.now().month]);
    });

    test('getInSeasonNow returns a non-empty list for the current month', () {
      expect(SeasonalService.getInSeasonNow(), isNotEmpty);
    });

    test('southern hemisphere list differs from the northern one', () {
      final nh = SeasonalService.getInSeasonNow();
      final sh = SeasonalService.getInSeasonNow(southernHemisphere: true);
      expect(sh, isNot(equals(nh)));
    });

    test('both hemisphere lists resolve for the current month regardless of when the suite runs', () {
      expect(SeasonalService.getInSeasonNow(southernHemisphere: false), isNotEmpty);
      expect(SeasonalService.getInSeasonNow(southernHemisphere: true), isNotEmpty);
    });
  });
}
