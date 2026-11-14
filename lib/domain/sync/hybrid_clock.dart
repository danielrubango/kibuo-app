/// Gives every change a version that only ever increases on this device,
/// even if the phone's clock is moved back (ADR 0003, ADR 0010).
///
/// A version packs the time in milliseconds with a 16-bit counter for
/// changes made within the same millisecond, so versions sort by time and
/// later sync can compare them across devices.
final class HybridClock {
  HybridClock({required this._last, int Function()? now})
    : _now = now ?? _wallClock;

  int _last;
  final int Function() _now;

  static const _counterBits = 16;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  /// The next version: the current time, or one more than the last version
  /// when the clock has not moved forward.
  int next() {
    final fromWall = _now() << _counterBits;
    _last = fromWall > _last ? fromWall : _last + 1;
    return _last;
  }

  /// When [version] was made, to the millisecond.
  static DateTime timeOf(int version) =>
      DateTime.fromMillisecondsSinceEpoch(version >> _counterBits, isUtc: true);
}
