/// How far an account may go below zero (GLOSSARY: Découvert): not at all,
/// down to [limit] (in the account's minor unit), or without limit when
/// [limit] is null or 0 (PRODUCT).
class Overdraft {
  const Overdraft({required this.allowed, this.limit});

  static const none = Overdraft(allowed: false);

  final bool allowed;

  /// Kept even while [allowed] is off, so turning it back on restores it.
  final int? limit;

  bool get unlimited => allowed && (limit == null || limit == 0);

  /// The lowest balance allowed, or null when there is none.
  int? get floor => !allowed ? 0 : (unlimited ? null : -limit!);

  /// Whether the account may end at [balance].
  bool allows(int balance) => floor == null || balance >= floor!;

  /// What may still leave an account holding [balance], or null when
  /// anything may.
  int? available(int balance) => floor == null ? null : balance - floor!;
}
