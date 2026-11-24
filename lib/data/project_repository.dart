import 'package:drift/drift.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/projects/project_plan.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

export 'package:kibuo/domain/projects/project_plan.dart';

/// A project as the screens show it.
class ProjectInfo {
  const ProjectInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.accountId,
    required this.account,
    required this.goal,
    required this.saved,
    required this.startedOn,
    required this.period,
    required this.remind,
    this.due,
    this.ending,
    this.endedOn,
  });

  final String id;
  final String name;
  final String icon;
  final String accountId;

  /// The account's name.
  final String account;
  final Money goal;
  final Money saved;
  final DateTime startedOn;
  final DateTime? due;
  final PlanPeriod period;
  final bool remind;

  /// « spent » or « released »; null while running.
  final String? ending;
  final DateTime? endedOn;

  bool get running => ending == null;
  bool get reached => saved.minor >= goal.minor;

  /// From 0 to 1.
  double get share =>
      goal.minor <= 0 ? 1 : (saved.minor / goal.minor).clamp(0, 1).toDouble();
}

/// One line of « Versements »: set aside (positive) or taken back.
class ContributionLine {
  const ContributionLine({
    required this.id,
    required this.amount,
    required this.date,
    required this.account,
    this.from,
  });

  final String id;
  final Money amount;
  final DateTime date;

  /// The project's account.
  final String account;

  /// The account a transfer brought it from; null: the project's own.
  final String? from;
}

/// Projects and what is set aside for them (PRODUCT: Projets). Nothing
/// moves on the accounts: the money set aside is only held back.
class ProjectRepository {
  ProjectRepository(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  /// A new project on [accountId], its [goal] in the account's minor unit.
  Future<String> create({
    required String name,
    required String icon,
    required String accountId,
    required int goal,
    required DateTime startedOn,
    DateTime? due,
    PlanPeriod period = PlanPeriod.week,
    bool remind = true,
  }) async {
    final account = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();
    final id = const Uuid().v7();
    await _db
        .into(_db.projects)
        .insert(
          ProjectsCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            name: name.trim(),
            icon: icon,
            accountId: accountId,
            goal: goal,
            currency: account.currency,
            startedOn: startedOn.toUtc(),
            dueDate: Value(due?.toUtc()),
            period: Value(period.stored),
            remind: Value(remind),
          ),
        );
    return id;
  }

  /// [amount] set aside (or taken back, negative) for [projectId].
  Future<void> addContribution(
    String projectId, {
    required int amount,
    required DateTime date,
  }) => _insertContribution(projectId, amount, date, null);

  Future<void> _insertContribution(
    String projectId,
    int amount,
    DateTime date,
    String? from,
  ) async {
    await _db
        .into(_db.contributions)
        .insert(
          ContributionsCompanion.insert(
            id: const Uuid().v7(),
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            projectId: projectId,
            amount: amount,
            date: date.toUtc(),
            fromAccountId: Value(from),
          ),
        );
  }

  /// Every project, running first, with what is set aside.
  Future<List<ProjectInfo>> projects() async {
    final rows = await (_db.select(
      _db.projects,
    )..where((p) => p.deleted.not())).get();
    final saved = await _saved();
    final names = await _accountNames();
    return [
      for (final r in rows)
        ProjectInfo(
          id: r.id,
          name: r.name,
          icon: r.icon,
          accountId: r.accountId,
          account: names[r.accountId] ?? '',
          goal: Money(r.goal, r.currency),
          saved: Money(saved[r.id] ?? 0, r.currency),
          startedOn: r.startedOn.toLocal(),
          due: r.dueDate?.toLocal(),
          period: PlanPeriod.fromStored(r.period),
          remind: r.remind,
          ending: r.ending,
          endedOn: r.endedOn?.toLocal(),
        ),
    ];
  }

  /// One project; null once deleted.
  Future<ProjectInfo?> project(String id) async =>
      (await projects()).where((p) => p.id == id).firstOrNull;

  Future<Map<String, String>> _accountNames() async => {
    for (final a in await _db.select(_db.accounts).get()) a.id: a.name,
  };

  /// What was set aside and taken back, the newest first.
  Future<List<ContributionLine>> contributions(String projectId) async {
    final project = await (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(projectId))).getSingleOrNull();
    if (project == null) return const [];
    final names = await _accountNames();
    final rows =
        await (_db.select(_db.contributions)
              ..where((c) => c.projectId.equals(projectId) & c.deleted.not())
              ..orderBy([
                (c) => OrderingTerm.desc(c.date),
                (c) => OrderingTerm.desc(c.id),
              ]))
            .get();
    return [
      for (final c in rows)
        ContributionLine(
          id: c.id,
          amount: Money(c.amount, project.currency),
          date: c.date.toLocal(),
          account: names[project.accountId] ?? '',
          from: c.fromAccountId == null ? null : names[c.fromAccountId],
        ),
    ];
  }

  /// « Mettre de côté »: never more than what is free on the account it
  /// comes from. From another account, a transfer brings it to the
  /// project's account first (PRODUCT: Projets). False when refused.
  Future<bool> putAside(
    String projectId, {
    required int amount,
    required DateTime date,
    String? fromAccountId,
  }) async {
    final p = await project(projectId);
    if (p == null || amount <= 0) return false;
    final from = fromAccountId == p.accountId ? null : fromAccountId;
    if (amount > (await free(from ?? p.accountId)).minor) return false;
    await _db.transaction(() async {
      if (from != null) {
        await TransactionRepository(_db).createTransfer(
          fromId: from,
          toId: p.accountId,
          sent: Money(amount, p.goal.currency),
          fees: 0,
          date: date,
          note: p.name,
        );
      }
      await _insertContribution(projectId, amount, date, from);
    });
    return true;
  }

  /// « Reprendre de l'argent »: at most what is set aside; nothing moves.
  Future<bool> takeBack(
    String projectId, {
    required int amount,
    required DateTime date,
  }) async {
    final p = await project(projectId);
    if (p == null || amount <= 0 || amount > p.saved.minor) return false;
    await _insertContribution(projectId, -amount, date, null);
    return true;
  }

  /// The goal reached: « spent » or « released »; its reserve goes.
  Future<void> end(
    String projectId, {
    required String ending,
    required DateTime on,
  }) async {
    await (_db.update(
      _db.projects,
    )..where((p) => p.id.equals(projectId))).write(
      ProjectsCompanion(
        version: Value(await _nextVersion()),
        ending: Value(ending),
        endedOn: Value(on.toUtc()),
      ),
    );
  }

  /// « Modifier »: every field; [due] null takes the date away.
  Future<void> edit(
    String projectId, {
    required String name,
    required String icon,
    required int goal,
    required DateTime? due,
    required PlanPeriod period,
    required bool remind,
    required String accountId,
  }) async {
    await (_db.update(
      _db.projects,
    )..where((p) => p.id.equals(projectId))).write(
      ProjectsCompanion(
        version: Value(await _nextVersion()),
        name: Value(name.trim()),
        icon: Value(icon),
        goal: Value(goal),
        dueDate: Value(due?.toUtc()),
        period: Value(period.stored),
        remind: Value(remind),
        accountId: Value(accountId),
      ),
    );
  }

  /// The project and its lines go; the money is free again.
  Future<void> delete(String projectId) async {
    await _db.transaction(() async {
      final version = await _nextVersion();
      await (_db.update(
        _db.projects,
      )..where((p) => p.id.equals(projectId))).write(
        ProjectsCompanion(version: Value(version), deleted: const Value(true)),
      );
      await (_db.update(
        _db.contributions,
      )..where((c) => c.projectId.equals(projectId))).write(
        ContributionsCompanion(
          version: Value(await _nextVersion()),
          deleted: const Value(true),
        ),
      );
    });
  }

  Future<Map<String, int>> _saved() async {
    final rows = await (_db.select(
      _db.contributions,
    )..where((c) => c.deleted.not())).get();
    final out = <String, int>{};
    for (final c in rows) {
      out[c.projectId] = (out[c.projectId] ?? 0) + c.amount;
    }
    return out;
  }

  /// Per account, what its running projects hold back.
  Future<Map<String, int>> reserved() async {
    final out = <String, int>{};
    for (final p in await projects()) {
      if (!p.running || p.saved.minor <= 0) continue;
      out[p.accountId] = (out[p.accountId] ?? 0) + p.saved.minor;
    }
    return out;
  }

  /// What [accountId] has free: its balance less what is held back.
  Future<Money> free(String accountId) async {
    final account = (await AccountRepository(
      _db,
    ).accounts()).firstWhere((a) => a.id == accountId);
    final held = (await reserved())[accountId] ?? 0;
    return Money(account.balance.minor - held, account.balance.currency);
  }
}
