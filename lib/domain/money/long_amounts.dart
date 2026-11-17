/// How long amounts are written (PRODUCT: Montants longs).
enum LongAmounts {
  /// Shortened only where the whole amount does not fit (the default).
  auto,

  /// Shortened from 10 000.
  always,

  /// Always whole, smaller when it must.
  never,
}
