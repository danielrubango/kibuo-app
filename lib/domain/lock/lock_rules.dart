/// The rules of the app lock (docs/PRODUCT.md › Verrouillage).
library;

/// How long the user must wait after [failures] wrong codes in a row.
/// Nothing is ever erased: the wait only grows, up to an hour.
Duration waitAfter(int failures) => switch (failures) {
  < 5 => Duration.zero,
  5 => const Duration(seconds: 30),
  6 => const Duration(minutes: 1),
  7 => const Duration(minutes: 5),
  8 => const Duration(minutes: 15),
  9 => const Duration(minutes: 30),
  _ => const Duration(hours: 1),
};

/// How long Kibuo may stay in the background before asking for the code.
enum AutoLockDelay {
  immediately(Duration.zero),
  thirtySeconds(Duration(seconds: 30)),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5)),
  fifteenMinutes(Duration(minutes: 15));

  const AutoLockDelay(this.duration);

  final Duration duration;

  static const standard = oneMinute;
}

/// Whether coming back at [now], after leaving at [left], needs the code.
/// A clock that went backwards locks, rather than trusting it.
bool shouldLockOnReturn({
  required DateTime left,
  required DateTime now,
  required AutoLockDelay delay,
}) {
  if (now.isBefore(left)) return true;
  if (delay == AutoLockDelay.immediately) return true;
  return now.difference(left) >= delay.duration;
}

final _pin = RegExp(r'^\d{4,6}$');

/// A code has 4 to 6 digits.
bool isValidPin(String pin) => _pin.hasMatch(pin);
