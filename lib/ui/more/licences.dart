import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The fonts and icons bundled with kibuo, whose licences ask to be shown:
/// they join the packages' licences in À propos › Licences.
const bundledLicences = {
  'Inter': 'assets/fonts/OFL-Inter.txt',
  'Plus Jakarta Sans': 'assets/fonts/OFL-PlusJakartaSans.txt',
  'Space Grotesk': 'assets/fonts/OFL-SpaceGrotesk.txt',
  'Phosphor Icons': 'assets/icons/LICENSE-Phosphor.txt',
};

/// Adds [bundledLicences] to Flutter's licence list, once at start.
void registerBundledLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in bundledLicences.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    }
  });
}
