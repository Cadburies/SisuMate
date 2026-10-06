import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// #416: non-pub content bundled in the app, added to Flutter's licence page
/// (`showLicensePage`) next to the pub packages. Mirrors the repo `NOTICE`;
/// CC BY / CC BY-SA require the credit to be visible to app users.
class BundledLicenses {
  BundledLicenses._();

  static const fontAsset = 'assets/games/fonts/OFL.txt';

  static const cocktailPhotoCredits =
      'Cocktail photos from Wikimedia Commons, resized to 720x480.\n\n'
      'Espresso Martini: "Espresso Martini 01" by Arnaud 25, CC BY-SA 4.0 '
      '(https://creativecommons.org/licenses/by-sa/4.0/). The resized image '
      'remains under CC BY-SA 4.0.\n\n'
      'Bloody Mary: "Bloody Mary Coctail with celery stalk" by Evan Swigart '
      'from Chicago, USA, CC BY 2.0 (https://creativecommons.org/licenses/by/2.0/).\n\n'
      'Navy Grog: "Royal Navy Grog issue" by Robert Sargent Austin RA. Public domain.\n\n'
      'Paper Plane: "Dieter Michael Krone Paper Plane" by RegiegeigeR. Public domain.\n\n'
      'Paloma: "TequilaPaloma" by Antonio Cavallo. Public domain.';

  static bool _registered = false;

  static void register() {
    if (_registered) return;
    _registered = true;
    LicenseRegistry.addLicense(entries);
  }

  static Stream<LicenseEntry> entries() async* {
    yield const LicenseEntryWithLineBreaks(
        ['Sisu Mate cocktail photos'], cocktailPhotoCredits);
    yield LicenseEntryWithLineBreaks(
        ['Noto Sans Runic'], await rootBundle.loadString(fontAsset));
  }
}
