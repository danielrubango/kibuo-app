/// The nature of an account (GLOSSARY: Type de compte): one of the four
/// provided ones, or one the user created.
class AccountType {
  const AccountType._(this.key);

  /// A type the user created, by its id.
  const AccountType.custom(String id) : key = id;

  static const cash = AccountType._('cash');
  static const bank = AccountType._('bank');
  static const mobile = AccountType._('mobile');
  static const savings = AccountType._('savings');

  /// The four provided types, in the order they are offered.
  static const provided = [cash, bank, mobile, savings];

  /// What is stored: the provided type's name, or the custom type's id.
  final String key;

  bool get isProvided => provided.any((t) => t.key == key);

  static AccountType fromKey(String key) => provided.firstWhere(
    (t) => t.key == key,
    orElse: () => AccountType.custom(key),
  );

  @override
  bool operator ==(Object other) => other is AccountType && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'AccountType($key)';
}
