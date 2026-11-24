import 'package:drift/drift.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/database.dart';
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
  }) async {
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
          ),
        );
  }

  /// Every project, running first, with what is set aside.
  Future<List<ProjectInfo>> projects() async {
    final rows = await (_db.select(
      _db.projects,
    )..where((p) => p.deleted.not())).get();
    final saved = await _saved();
    final names = {
      for (final a in await _db.select(_db.accounts).get()) a.id: a.name,
    };
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
