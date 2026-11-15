import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _channel = MethodChannel('kibuo/device');

/// The phone's country (ISO 3166, « CD »), to suggest its currency: from the
/// SIM or network, else the phone's settings; null when unknown.
Future<String?> deviceCountry() async {
  try {
    final country = await _channel.invokeMethod<String>('country');
    if (country != null && country.isNotEmpty) return country;
  } on MissingPluginException {
    // Widget tests: no Android side.
  } on PlatformException {
    // Fall back to the app's locale below.
  }
  return WidgetsBinding.instance.platformDispatcher.locale.countryCode;
}
