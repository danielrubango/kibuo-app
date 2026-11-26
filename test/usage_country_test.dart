import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/ui/device_country.dart';

/// The statistics carry the region chosen in the phone's settings, never the
/// country of its network or SIM, which would be a location (Google Play's
/// Data safety, decided by the owner on 26 November 2026).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the statistics take the settings region, not the network', () async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('kibuo/device'),
      (call) async => call.method == 'country' ? 'CD' : null,
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('kibuo/device'),
        null,
      ),
    );
    binding.platformDispatcher.localeTestValue = const Locale('fr', 'BE');
    addTearDown(binding.platformDispatcher.clearLocaleTestValue);

    // The currency suggestion still follows the network.
    expect(await deviceCountry(), 'CD');
    expect(usageCountry(), 'BE');
  });
}
