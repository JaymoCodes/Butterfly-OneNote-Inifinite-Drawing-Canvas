import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'api/full_screen.dart';

Future<void> setup() async {
  setupFullScreen();
  await setupLicenses();
}

Future<void> setupLicenses() async {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Comfortaa'],
        await rootBundle.loadString('fonts/Comfortaa-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks(
        ['Roboto'], await rootBundle.loadString('fonts/Roboto-LICENSE.txt'));
  });
}
