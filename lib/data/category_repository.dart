import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/categories/default_categories.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

export 'package:kibuo/domain/categories/default_categories.dart';

/// A category as the screens show it, with its subcategories.
class CategoryInfo {
  const CategoryInfo({
    required this.id,
    required this.kind,
    required this.icon,
    required this.removed,
    this.parentId,
    this.key,
    this.name,
    this.subs = const [],
  });

  final String id;
  final CategoryKind kind;
  final String? parentId;

  /// A provided category's key; its name comes from the app's language
  /// while [name] is null.
  final String? key;
  final String? name;
  final String icon;
  final bool removed;
  final List<CategoryInfo> subs;
}

/// The user's categories, provided ones included. Every write carries the
/// sync metadata of ADR 0003.
class CategoryRepository {
  CategoryRepository(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  static const _seeded = 'categories_seeded';
  static const _adjustSeeded = 'categories_adjust_seeded';

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  static String _cleanName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError.value(name, 'name', 'is empty');
    return clean;
  }

  /// Adds the provided categories once. Their ids are fixed (« default-
  /// food »), so two phones that start apart do not end up with two « Repas »
  /// once synced.
  Future<void> _ensureProvided() async {
    final flag = await (_db.select(
      _db.preferences,
    )..where((p) => p.name.equals(_seeded))).getSingleOrNull();
    if (flag != null) return;
    await _db.transaction(() async {
      Future<void> add(
        CategoryKind kind,
        DefaultCategory c,
        int position,
        String? parent,
      ) async {
        await _db
            .into(_db.categories)
            .insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: 'default-${c.key}',
                version: await _nextVersion(),
                deviceId: _db.deviceId,
                kind: kind.stored,
                parentId: Value(parent),
                key: Value(c.key),
                icon: c.icon,
                position: position,
              ),
            );
        for (final (i, sub) in c.subs.indexed) {
          await add(kind, sub, i + 1, 'default-${c.key}');
        }
      }

      for (final (i, c) in defaultExpenses.indexed) {
        await add(CategoryKind.out, c, i + 1, null);
      }
      for (final (i, c) in defaultIncome.indexed) {
        await add(CategoryKind.into, c, i + 1, null);
      }
      await _db
          .into(_db.preferences)
          .insert(
            PreferencesCompanion.insert(
              id: const Uuid().v7(),
              version: await _nextVersion(),
              deviceId: _db.deviceId,
              name: _seeded,
              value: 'true',
            ),
          );
    });
  }

  /// « Régularisation » came after the first categories: added once, at the
  /// end of each list, for new and older data alike.
  Future<void> _ensureAdjustments() async {
    final flag = await (_db.select(
      _db.preferences,
    )..where((p) => p.name.equals(_adjustSeeded))).getSingleOrNull();
    if (flag != null) return;
    await _db.transaction(() async {
      for (final (kind, c) in [
        (CategoryKind.out, adjustmentExpense),
        (CategoryKind.into, adjustmentIncome),
      ]) {
        final last = _db.categories.position.max();
        final position =
            await (_db.selectOnly(_db.categories)
                  ..addColumns([last])
                  ..where(
                    _db.categories.kind.equals(kind.stored) &
                        _db.categories.parentId.isNull(),
                  ))
                .map((r) => r.read(last))
                .getSingle() ??
            0;
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: adjustmentCategoryId(kind),
                version: await _nextVersion(),
                deviceId: _db.deviceId,
                kind: kind.stored,
                key: Value(c.key),
                icon: c.icon,
                position: position + 1,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await _db
          .into(_db.preferences)
          .insert(
            PreferencesCompanion.insert(
              id: const Uuid().v7(),
              version: await _nextVersion(),
              deviceId: _db.deviceId,
              name: _adjustSeeded,
              value: 'true',
            ),
          );
    });
  }

  /// The categories of [kind] still offered, in order, each with its own
  /// subcategories still offered.
  Future<List<CategoryInfo>> categories(CategoryKind kind) async {
    await _ensureProvided();
    await _ensureAdjustments();
    final rows =
        await (_db.select(_db.categories)
              ..where(
                (c) =>
                    c.deleted.not() &
                    c.removed.not() &
                    c.kind.equals(kind.stored),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.position)]))
            .get();
    final top = rows.where((r) => r.parentId == null);
    return [
      for (final r in top)
        _info(r, [
          for (final s in rows)
            if (s.parentId == r.id) _info(s),
        ]),
    ];
  }

  /// One category, removed or not (old operations keep showing it).
  Future<CategoryInfo?> category(String id) async {
    await _ensureProvided();
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _info(row);
  }

  static CategoryInfo _info(
    CategoryRow r, [
    List<CategoryInfo> subs = const [],
  ]) => CategoryInfo(
    id: r.id,
    kind: CategoryKind.fromStored(r.kind),
    parentId: r.parentId,
    key: r.key,
    name: r.name,
    icon: r.icon,
    removed: r.removed,
    subs: subs,
  );

  /// Adds a category, last of its siblings; under [parentId] for a
  /// subcategory. Returns its id.
  Future<String> create({
    required CategoryKind kind,
    required String name,
    required String icon,
    String? parentId,
  }) async {
    final clean = _cleanName(name);
    await _ensureProvided();
    await _ensureAdjustments();
    final last = _db.categories.position.max();
    final query = _db.selectOnly(_db.categories)
      ..addColumns([last])
      ..where(
        (parentId == null
                ? _db.categories.parentId.isNull()
                : _db.categories.parentId.equals(parentId)) &
            _db.categories.kind.equals(kind.stored),
      );
    final position = await query.map((r) => r.read(last)).getSingle() ?? 0;
    final id = const Uuid().v7();
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            kind: kind.stored,
            parentId: Value(parentId),
            name: Value(clean),
            icon: icon,
            position: position + 1,
          ),
        );
    return id;
  }

  /// Renames [id] (a null [name] keeps the current one, so a provided
  /// category keeps following the app's language) and sets its icon.
  Future<void> update(String id, {String? name, required String icon}) =>
      _write(
        _db.categories.id.equals(id),
        CategoriesCompanion(
          name: name == null ? const Value.absent() : Value(_cleanName(name)),
          icon: Value(icon),
        ),
      );

  /// Takes the category, and its subcategories, out of the choices. Their
  /// operations keep them.
  Future<void> remove(String id) => _write(
    _db.categories.id.equals(id) | _db.categories.parentId.equals(id),
    const CategoriesCompanion(removed: Value(true)),
  );

  Future<void> _write(
    Expression<bool> which,
    CategoriesCompanion changes,
  ) async {
    await (_db.update(_db.categories)..where((_) => which)).write(
      changes.copyWith(
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }
}
