/// What kibuo may tell about its use, with the user's consent (ADR 0013):
/// what was done, never what was written. Names and values are short codes
/// from this file; an amount, a label, a name or a note cannot be built
/// into an event, and [usageEventAllowed] refuses one that slipped in.
library;

/// The four tabs.
enum UsageTab { home, operations, overview, more }

/// The kinds of operation.
enum UsageOperation { expense, income, transfer }

/// The lines of Plus, and what they open.
enum UsagePlace {
  accounts,
  budgets,
  projects,
  debts,
  recurrences,
  categories,
  settings,
  backup,
  about,
}

/// One message: its name and its few properties.
class UsageEvent {
  const UsageEvent._(this.name, [this.properties = const {}]);

  /// A tab shown.
  factory UsageEvent.tab(UsageTab tab) =>
      UsageEvent._('tab_viewed', {'tab': tab.name});

  /// A line of Plus touched.
  factory UsageEvent.place(UsagePlace place) =>
      UsageEvent._('place_opened', {'place': place.name});

  /// An operation saved, new or changed.
  factory UsageEvent.operationSaved(
    UsageOperation kind, {
    bool edited = false,
  }) => UsageEvent._('operation_saved', {'kind': kind.name, 'edited': edited});

  /// A backup made, by hand or on its own, or failed.
  factory UsageEvent.backup({required bool automatic, required bool done}) =>
      UsageEvent._('backup_made', {
        'automatic': automatic,
        'outcome': done ? 'done' : 'failed',
      });

  /// A backup restored.
  static const restored = UsageEvent._('backup_restored');

  /// A code created to lock kibuo.
  static const lockOn = UsageEvent._('lock_turned_on');

  /// The language changed in Réglages.
  factory UsageEvent.language(String code) =>
      UsageEvent._('language_changed', {'language': code});

  final String name;
  final Map<String, Object> properties;

  /// One of each, for the tests.
  static final catalogue = [
    for (final t in UsageTab.values) UsageEvent.tab(t),
    for (final p in UsagePlace.values) UsageEvent.place(p),
    for (final k in UsageOperation.values) UsageEvent.operationSaved(k),
    UsageEvent.operationSaved(UsageOperation.expense, edited: true),
    UsageEvent.backup(automatic: true, done: true),
    UsageEvent.backup(automatic: false, done: false),
    restored,
    lockOn,
    UsageEvent.language('fr'),
    UsageEvent.language('en'),
  ];
}

/// The keys an event may carry, and the values each accepts.
final _allowed = <String, bool Function(Object)>{
  'tab': (v) => UsageTab.values.any((t) => t.name == v),
  'place': (v) => UsagePlace.values.any((p) => p.name == v),
  'kind': (v) => UsageOperation.values.any((k) => k.name == v),
  'edited': (v) => v is bool,
  'automatic': (v) => v is bool,
  'outcome': (v) => v == 'done' || v == 'failed',
  'language': (v) => v is String && RegExp(r'^[a-z]{2}$').hasMatch(v),
};

final _eventName = RegExp(r'^[a-z_]{3,32}$');

/// Whether an event may leave the phone: a known shape of name, and only
/// known keys with their known values.
bool usageEventAllowed(String name, Map<String, Object> properties) =>
    _eventName.hasMatch(name) &&
    properties.entries.every((e) => _allowed[e.key]?.call(e.value) ?? false);

/// What every message carries about the phone (ADR 0013): its language, its
/// country and the main currency, each left out when unknown or odd.
Map<String, Object> usageContext({
  required String? language,
  required String? country,
  required String? currency,
}) => {
  if (language != null && RegExp(r'^[a-z]{2}$').hasMatch(language))
    'language': language,
  if (country != null && RegExp(r'^[A-Z]{2}$').hasMatch(country))
    'country': country,
  if (currency != null && RegExp(r'^[A-Z]{3}$').hasMatch(currency))
    'currency': currency,
};

/// An error reduced to its type: its message could hold an amount or a
/// name, so it never leaves; where it happened comes from its stack.
class RedactedError implements Exception {
  const RedactedError._(this.type);

  factory RedactedError.of(Object error) =>
      RedactedError._(error.runtimeType.toString());

  final String type;

  @override
  String toString() => type;
}
