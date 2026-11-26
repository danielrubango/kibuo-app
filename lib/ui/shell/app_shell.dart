import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/hint_store.dart';
import 'package:kibuo/data/long_amounts_store.dart';
import 'package:kibuo/data/month_start_store.dart';
import 'package:kibuo/data/overview_store.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/search_history.dart';
import 'package:kibuo/data/todo_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/accounts_screen.dart';
import 'package:kibuo/ui/backup/auto_backup.dart';
import 'package:kibuo/ui/backup/auto_backup_task.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/backup/backup_screen.dart';
import 'package:kibuo/ui/backup/restore_sheet.dart';
import 'package:kibuo/ui/budgets/budget_alerts.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budgets_screen.dart';
import 'package:kibuo/ui/categories/categories_screen.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/kit/choice_sheet.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/more/about_screen.dart';
import 'package:kibuo/ui/more/plus_page.dart';
import 'package:kibuo/ui/more/plus_summary.dart';
import 'package:kibuo/ui/obligations/debts_screen.dart';
import 'package:kibuo/ui/obligations/new_debt_screen.dart';
import 'package:kibuo/ui/overview/overview_screen.dart';
import 'package:kibuo/ui/projects/new_project_screen.dart';
import 'package:kibuo/ui/projects/project_money.dart';
import 'package:kibuo/ui/projects/project_screen.dart';
import 'package:kibuo/ui/projects/projects_screen.dart';
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/reminders/reminder_planner.dart';
import 'package:kibuo/ui/screens/placeholders.dart';
import 'package:kibuo/ui/settings/settings_screen.dart';
import 'package:kibuo/ui/shell/add_choice.dart';
import 'package:kibuo/ui/shell/add_sheet.dart';
import 'package:kibuo/ui/shell/plus_fan.dart';
import 'package:kibuo/ui/shell/tab_icons.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';
import 'package:kibuo/ui/transactions/redo.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';
import 'package:kibuo/ui/usage/usage_sheet.dart';
import 'package:path_provider/path_provider.dart';

enum _Tab { home, operations, overview, more }

/// The four tabs, the floating bottom bar and the + button.
///
/// Tap + for the « Ajouter » sheet; hold it for the fan, slide to a choice
/// and lift the finger. Back from another tab returns to Accueil.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.notifier});

  /// The phone's notifications; none in most tests.
  final Notifier? notifier;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  _Tab _tab = _Tab.home;
  bool _fanOpen = false;
  bool _tip = false;
  AddChoice? _hovered;
  final _plusKey = GlobalKey();

  /// Tells the Opérations tab to reload after a save.
  final _saved = ValueNotifier<int>(0);

  /// Tells Accueil to reload when it comes back into view.
  final _homeShown = ValueNotifier<int>(0);

  /// Tells Plus to read its figures again when it comes into view.
  final _plusShown = ValueNotifier<int>(0);
  late final _plusRefresh = Listenable.merge([_saved, _plusShown]);

  /// Tells Opérations to show this month (from Accueil's month).
  final _thisMonth = ValueNotifier<int>(0);

  /// Tells the Aperçu to show the current period (from Accueil's month).
  final _overviewNow = ValueNotifier<int>(0);

  late final _homeRefresh = Listenable.merge([
    _saved,
    _homeShown,
    monthStartChoice,
  ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    OperationsScreen.show.addListener(_showOperations);
  }

  void _showOperations() {
    if (OperationsScreen.show.value != null) _show(_Tab.operations);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OperationsScreen.show.removeListener(_showOperations);
    _saved.removeListener(_reschedule);

    _saved.dispose();
    _homeShown.dispose();
    _plusShown.dispose();
    _thisMonth.dispose();
    _overviewNow.dispose();
    DeviceBackupFiles.instance.opened.removeListener(_openedFile);
    _waitingLock?.removeListener(_whenUnlocked);
    _backupLock?.removeListener(_backupWhenUnlocked);
    _usageLock?.removeListener(_usageWhenUnlocked);
    usage.removeListener(_usageLoaded);
    super.dispose();
  }

  bool _choiceRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // « Montants longs », once at start.
    final db = KibuoData.maybeOf(context);
    if (_choiceRead || db == null) return;
    _choiceRead = true;
    LongAmountsStore(db).read().then((c) => longAmountsChoice.value = c);
    MonthStartStore(db).read().then((d) => monthStartChoice.value = d);
    _open();
    _autoBackup();
    _describeUsage(db);
    _askUsage();
    _saved.addListener(_reschedule);

    widget.notifier
        ?.start(_onNotice)
        .then((payload) => payload == null ? null : _onNotice(payload));
    // A .kibuo file kibuo was opened with, now or later (PRODUCT).
    DeviceBackupFiles.instance.opened.addListener(_openedFile);
    _openedFile();
  }

  /// The lock a file waits behind; let go once unlocked or gone.
  LockController? _waitingLock;

  void _whenUnlocked() {
    final lock = _waitingLock;
    if (lock == null || !lock.ready || lock.locked) return;
    lock.removeListener(_whenUnlocked);
    _waitingLock = null;
    if (mounted) _openedFile();
  }

  /// What a restore needs, from this screen that sees the data.
  RestoreTools? _restoreTools() {
    final data = _entryData(context);
    final replace = KibuoRestore.maybeOf(context)?.replace;
    final backups = data?.backups;
    if (data == null || replace == null || backups == null) return null;
    return RestoreTools(
      service: backups,
      transactions: data.transactions,
      replace: replace,
    );
  }

  Future<void> _openedFile() async {
    // Never over the lock: the file waits until kibuo is unlocked.
    final lock = KibuoLock.maybeControllerOf(context);
    if (lock != null && (!lock.ready || lock.locked)) {
      _waitingLock?.removeListener(_whenUnlocked);
      _waitingLock = lock..addListener(_whenUnlocked);
      return;
    }
    final picked = await DeviceBackupFiles.instance.takeOpened();
    final tools = picked == null || !mounted ? null : _restoreTools();
    if (picked == null || tools == null || !mounted) return;
    await runRestore(context, picked, tools);
  }

  /// The lock the automatic backup waits behind, to say a failure.
  LockController? _backupLock;
  bool _backingUp = false;

  void _backupWhenUnlocked() {
    final lock = _backupLock;
    if (lock == null || !lock.ready || lock.locked) return;
    lock.removeListener(_backupWhenUnlocked);
    _backupLock = null;
    if (mounted) _autoBackup();
  }

  /// At every opening and return (PRODUCT: Sauvegardes automatiques): the
  /// weekly backup if due, once kibuo is unlocked; a failure said at the
  /// bottom with « Voir », once a week at most.
  Future<void> _autoBackup() async {
    final backups = _entryData(context)?.backups;
    if (backups == null || _backingUp) return;
    final lock = KibuoLock.maybeControllerOf(context);
    if (lock != null && (!lock.ready || lock.locked)) {
      _backupLock?.removeListener(_backupWhenUnlocked);
      _backupLock = lock..addListener(_backupWhenUnlocked);
      return;
    }
    _backingUp = true;
    final language = Localizations.localeOf(context).languageCode;
    try {
      // For the backups made kibuo closed.
      await backups.rememberLanguage(language);
      final state = await backups.state();
      await scheduleAutoBackup(on: state.auto);
      final outcome = await AutoBackup(
        service: backups,
        folders: const DeviceBackupFolders(),
      ).run(now: DateTime.now(), language: language);
      if (outcome
          case AutoBackupOutcome.done ||
              AutoBackupOutcome.failed ||
              AutoBackupOutcome.folderMissing) {
        usage.track(
          UsageEvent.backup(
            automatic: true,
            done: outcome == AutoBackupOutcome.done,
          ),
        );
      }
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final text = switch (outcome) {
        AutoBackupOutcome.folderMissing => l.autoBackupFolderToast,
        AutoBackupOutcome.failed => l.autoBackupFailed,
        _ => null,
      };
      if (text != null) {
        showKibuoToast(
          context,
          text,
          action: l.budgetAlertSee,
          onAction: _openBackup,
        );
      }
    } on Object {
      // No vault or channel (tests): nothing to back up.
    } finally {
      _backingUp = false;
    }
  }

  /// What every message says of the phone (ADR 0013); nothing leaves
  /// before a yes.
  Future<void> _describeUsage(KibuoDatabase db) async {
    final language = Localizations.localeOf(context).languageCode;
    String? currency;
    try {
      currency = await CurrencyRepository(db).primaryCurrency();
    } on Object {
      currency = null;
    }
    await usage.describe(
      language: language,
      country: usageCountry(),
      currency: currency,
    );
  }

  /// The lock the question of « Aider à améliorer kibuo » waits behind.
  LockController? _usageLock;
  bool _asking = false;

  void _usageWhenUnlocked() {
    final lock = _usageLock;
    if (lock == null || !lock.ready || lock.locked) return;
    lock.removeListener(_usageWhenUnlocked);
    _usageLock = null;
    if (mounted) _askUsage();
  }

  /// Asked once (ADR 0013): after the first launch, or at the next opening
  /// for who already had kibuo; never over the lock or another sheet.
  Future<void> _askUsage() async {
    if (_asking) return;
    if (!usage.toAsk) {
      if (usage.consent == null) usage.addListener(_usageLoaded);
      return;
    }
    final lock = KibuoLock.maybeControllerOf(context);
    if (lock != null && (!lock.ready || lock.locked)) {
      _usageLock?.removeListener(_usageWhenUnlocked);
      _usageLock = lock..addListener(_usageWhenUnlocked);
      return;
    }
    _asking = true;
    try {
      // Once the home has shown.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || !usage.toAsk) return;
      // Another sheet or screen on top: next time.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      await askUsageConsent(context, usage);
    } finally {
      _asking = false;
    }
  }

  /// The answer read from the vault, after the shell first showed.
  void _usageLoaded() {
    if (!usage.toAsk && usage.consent == null) return;
    usage.removeListener(_usageLoaded);
    if (mounted && usage.toAsk) _askUsage();
  }

  Future<void> _openBackup() async {
    final backups = _entryData(context)?.backups;
    if (backups == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BackupScreen(service: backups, restore: _restoreTools()),
      ),
    );
  }

  /// At opening: thresholds already crossed are said in silence, then the
  /// recurrences arrive (and may cross one, said).
  Future<void> _open() async {
    await _budgetAlerts()?.settle(DateTime.now());
    await _catchUp();
  }

  BudgetAlerts? _budgetAlerts() {
    final db = KibuoData.maybeOf(context);
    final data = _entryData(context);
    if (db == null || data == null) return null;
    return BudgetAlerts(
      loader: BudgetLoader(data, BudgetRepository(db)),
      store: ReminderStore(db),
    );
  }

  /// After a save or a recurrence's arrival (PRODUCT: Alertes de budget).
  Future<void> _checkBudgets() async {
    if (!mounted) return;
    await _budgetAlerts()?.check(context, DateTime.now());
  }

  /// A notification touched (PRODUCT: Rappels).
  void _onNotice(String payload) {
    if (!mounted) return;
    if (payload == autoBackupPayload) {
      _openBackup();
    } else if (payload == ReminderPlanner.entryPayload) {
      _openEntry(AddChoice.expense);
    } else if (payload == ReminderPlanner.homePayload) {
      _show(_Tab.home);
    } else if (payload.startsWith('project:')) {
      final data = _entryData(context);
      if (data?.projects == null) return;
      Navigator.of(context)
          .push<void>(
            MaterialPageRoute(
              builder: (_) => ProjectScreen(
                data: data!,
                projects: data.projects!,
                id: payload.substring(8),
                onChanged: () => _saved.value++,
              ),
            ),
          )
          .then((_) => _saved.value++);
    } else if (payload.startsWith('rule:')) {
      final data = _entryData(context);
      if (data == null) return;
      openRuleCard(
        context,
        data,
        payload.substring(5),
      ).then((_) => _saved.value++);
    }
  }

  /// The next 30 days' reminders, again.
  Future<void> _reschedule() async {
    final notifier = widget.notifier;
    final db = KibuoData.maybeOf(context);
    if (notifier == null || db == null || !mounted) return;
    final l = AppLocalizations.of(context);
    await ReminderPlanner(
      store: ReminderStore(db),
      notifier: notifier,
      transactions: TransactionRepository(db),
      data: _entryData(context),
    ).refresh(l, DateTime.now());
  }

  /// Recurrences' missed dates (PRODUCT): at every opening and return.
  Future<void> _catchUp() async {
    final db = KibuoData.maybeOf(context);
    if (db == null) return;
    final made = await RecurringRepository(db).catchUp(DateTime.now());
    if (made > 0 && mounted) {
      _saved.value++;
      await _checkBudgets();
    } else {
      await _reschedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      usage.track(UsageEvent.opened);
      _catchUp();
      _autoBackup();
      _askUsage();
    }
    if (state == AppLifecycleState.paused) usage.flush();
  }

  void _show(_Tab tab) {
    if (tab != _tab) {
      usage.track(UsageEvent.tab(UsageTab.values.byName(tab.name)));
    }
    if (tab == _Tab.home && _tab != _Tab.home) _homeShown.value++;
    if (tab == _Tab.more && _tab != _Tab.more) _plusShown.value++;
    setState(() => _tab = tab);
  }

  Future<void> _openAccounts(KibuoDatabase db) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => AccountsScreen(
            accounts: AccountRepository(db),
            currencies: CurrencyRepository(db),
            categories: CategoryRepository(db),
            transactions: TransactionRepository(db),
            data: _entryData(context),
          ),
        ),
      )
      // A corrected balance adds an operation: the list follows.
      .then((_) => _saved.value++);

  EntryData? _entryData(BuildContext context) {
    final db = KibuoData.maybeOf(context);
    if (db == null) return null;
    return EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.lazy(
        db,
        getApplicationSupportDirectory,
      ),
      recurrences: RecurringRepository(db),
      reminders: ReminderStore(db),
      debts: DebtRepository(db),
      projects: ProjectRepository(db),
      backups: BackupService(db: db, appFolder: getApplicationSupportDirectory),
    );
  }

  Offset get _plusCenter {
    final box = _plusKey.currentContext!.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == _Tab.home && !_fanOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_fanOpen) return setState(_closeFan);
        _show(_Tab.home);
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    if (_entryData(context) case final data?)
                      HomeScreen(
                        key: const ValueKey('screen-home'),
                        data: data,
                        refresh: _homeRefresh,
                        onChanged: () => _saved.value++,
                        budgets: switch (KibuoData.maybeOf(context)) {
                          final db? => BudgetLoader(data, BudgetRepository(db)),
                          null => null,
                        },
                        todos: switch (KibuoData.maybeOf(context)) {
                          final db? => TodoStore(db),
                          null => null,
                        },
                        onOpenAccounts: () =>
                            _openAccounts(KibuoData.maybeOf(context)!),
                        onOpenDebts: (tab) =>
                            _openDebts(KibuoData.maybeOf(context)!, tab),
                        onOpenProjects: _openProjects,
                        onNewProject: _newProject,
                        // The month's figures open the overview (PRODUCT).
                        onOpenMonth: () {
                          _overviewNow.value++;
                          _show(_Tab.overview);
                        },
                      )
                    else
                      // Without data (some tests): the title alone.
                      ListView(
                        key: const ValueKey('screen-home'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          TabHeader(
                            title: TabHeader.text(
                              AppLocalizations.of(context).homeTitle,
                            ),
                          ),
                        ],
                      ),
                    if (_entryData(context) case final data?)
                      // A hidden tab keeps its place but not its animations.
                      TickerMode(
                        key: const ValueKey('screen-operations'),
                        enabled: _tab == _Tab.operations,
                        child: OperationsScreen(
                          data: data,
                          refresh: _saved,
                          thisMonth: _thisMonth,
                          onAdd: () => _openEntry(AddChoice.expense),
                          hints: KibuoData.maybeOf(context) == null
                              ? null
                              : HintStore(KibuoData.maybeOf(context)!),
                          history: KibuoData.maybeOf(context) == null
                              ? null
                              : SearchHistory(KibuoData.maybeOf(context)!),
                        ),
                      )
                    else
                      TabPlaceholder(
                        key: const ValueKey('screen-operations'),
                        title: AppLocalizations.of(context).tabOperations,
                        icon: PlaceholderIcons.operations,
                        message: AppLocalizations.of(context)
                            .operationsPlaceholder,
                      ),
                    if (_entryData(context) case final data?)
                      TickerMode(
                        key: const ValueKey('screen-overview'),
                        enabled: _tab == _Tab.overview,
                        child: OverviewScreen(
                          data: data,
                          refresh: _saved,
                          now: _overviewNow,
                          store: OverviewStore(KibuoData.maybeOf(context)!),
                        ),
                      )
                    else
                      ListView(
                        key: const ValueKey('screen-overview'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          TabHeader(
                            title: TabHeader.text(
                              AppLocalizations.of(context).tabOverview,
                            ),
                          ),
                        ],
                      ),
                    if (_entryData(context) case final data?)
                      PlusPage(
                        key: const ValueKey('screen-more'),
                        load: () =>
                            loadPlusSummary(KibuoData.maybeOf(context)!, data),
                        onOpen: _openPlus,
                        backups: data.backups,
                        refresh: _plusRefresh,
                      )
                    else
                      TabPlaceholder(
                        key: const ValueKey('screen-more'),
                        title: AppLocalizations.of(context).tabMore,
                        icon: PlaceholderIcons.more,
                        message: AppLocalizations.of(context).morePlaceholder,
                      ),
                  ],
                ),
              ),
            ),
            const _BottomFade(),
            _BottomBar(
              current: _tab,
              plusKey: _plusKey,
              onTab: _show,
              onPlusTap: _openSheet,
              onPlusHoldStart: _openFan,
              onPlusHoldMove: _hover,
              onPlusHoldEnd: _release,
            ),
            // The hold tip, once, after a few taps (canvas PlusBtnC2).
            if (_tip && !_fanOpen)
              Positioned(
                left: 24,
                right: 24,
                bottom: MediaQuery.paddingOf(context).bottom + 96,
                child: _HoldTip(onDone: _tipDone),
              ),
            if (_fanOpen)
              Positioned.fill(
                child: PlusFan(
                  plusCenter: _plusCenter,
                  hovered: _hovered,
                  onPick: _pickFromFan,
                  onClose: () => setState(_closeFan),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A line of Plus touched (canvas Plus).
  Future<void> _openPlus(PlusEntry entry) async {
    usage.track(UsageEvent.place(UsagePlace.values.byName(entry.name)));
    final db = KibuoData.maybeOf(context);
    final data = _entryData(context);
    if (db == null || data == null) return;
    Future<void> push(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));
    switch (entry) {
      case PlusEntry.accounts:
        await _openAccounts(db);
      case PlusEntry.budgets:
        await push(
          BudgetsScreen(
            loader: BudgetLoader(data, BudgetRepository(db)),
            prefs: PreferenceStore(db),
          ),
        );
      case PlusEntry.projects:
        await _openProjects();
      case PlusEntry.debts:
        await _openDebts(db, DebtDirection.owe);
      case PlusEntry.recurrences:
        // What it made may have reached the list.
        await push(RecurrencesScreen(data: data));
        _saved.value++;
      case PlusEntry.categories:
        await push(CategoriesScreen(categories: CategoryRepository(db)));
      case PlusEntry.settings:
        await push(
          SettingsScreen(
            db: db,
            lock: KibuoLock.maybeControllerOf(context),
            notifier: widget.notifier,
            onRemindersChanged: _reschedule,
            backups: data.backups,
            restore: _restoreTools(),
          ),
        );
      case PlusEntry.backup:
        await _openBackup();
      case PlusEntry.about:
        await push(const AboutScreen());
    }
  }

  Future<void> _openSheet() async {
    final db = KibuoData.maybeOf(context);
    final tip = db != null && await HintStore(db).sheetOpened();
    if (!mounted) return;
    final picked = await showAddSheet(context, redo: _redoCards());
    if (tip && mounted) setState(() => _tip = true);
    if (!mounted) return;
    switch (picked) {
      case AddChoice():
        await _openEntry(picked);
      // « Refaire »: the same operation, ready to save again today.
      case TransactionInfo():
        final data = _entryData(context);
        if (data == null) return;
        await runEntry(
          context,
          data,
          kind: picked.kind,
          initial: picked,
          onSaved: _afterSave,
        );
    }
  }

  /// The « Refaire » cards (PRODUCT): the latest operations, once each.
  Future<List<RedoCard<Object>>> _redoCards() async {
    final data = _entryData(context);
    if (data == null) return const [];
    final candidates = redoCandidates(await data.transactions.all());
    final cards = <RedoCard<Object>>[];
    for (final t in candidates) {
      if (!mounted) return const [];
      final labels = await OperationLabels.of(context, data, t);
      if (!mounted) return const [];
      final path = labels.categoryPath.split(' › ');
      cards.add(
        RedoCard(
          title: path.last,
          amount: signedTotal(context, t),
          color: kindColors(t.kind).ink,
          subtitle: [
            labels.account,
            if (path.length > 1) path.first,
          ].join(' · '),
          value: t,
        ),
      );
    }
    return cards;
  }

  void _afterSave() {
    // The list opens on the new operation (PRODUCT).
    setState(() => _tab = _Tab.operations);
    _saved.value++;
  }

  void _tipDone() {
    setState(() => _tip = false);
    final db = KibuoData.maybeOf(context);
    if (db != null) HintStore(db).tipDone();
  }

  void _openFan() {
    // Found the hold alone: the tip never comes.
    _tipDone();
    HapticFeedback.mediumImpact();
    setState(() {
      _fanOpen = true;
      _hovered = null;
    });
  }

  void _closeFan() {
    _fanOpen = false;
    _hovered = null;
  }

  void _hover(Offset finger) {
    final width = MediaQuery.sizeOf(context).width;
    final under = PlusFan.choiceAt(finger, _plusCenter, width);
    if (under == _hovered) return;
    if (under != null) HapticFeedback.selectionClick();
    setState(() => _hovered = under);
  }

  /// Lifting on a choice opens it; lifting elsewhere leaves the fan open so
  /// the user can tap.
  void _release(Offset finger) {
    final width = MediaQuery.sizeOf(context).width;
    final under = PlusFan.choiceAt(finger, _plusCenter, width);
    if (under != null) {
      _pickFromFan(under);
    } else {
      setState(() => _hovered = null);
    }
  }

  void _pickFromFan(AddChoice choice) {
    setState(_closeFan);
    _openEntry(choice);
  }

  Future<void> _openEntry(AddChoice choice) {
    final data = _entryData(context);
    final kind = switch (choice) {
      AddChoice.expense => EntryKind.expense,
      AddChoice.income => EntryKind.income,
      AddChoice.transfer => EntryKind.transfer,
      _ => null,
    };
    final db = KibuoData.maybeOf(context);
    if (choice == AddChoice.debt && data != null && db != null) {
      return _newDebt(data, db);
    }
    if (choice == AddChoice.project && data != null) return _putAside(data);
    if (data != null && kind != null) {
      // The alert once the saved sheet is gone (PRODUCT: Alertes).
      return runEntry(
        context,
        data,
        kind: kind,
        onSaved: _afterSave,
      ).then((_) => _checkBudgets());
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryPlaceholder(choice: choice),
        fullscreenDialog: true,
      ),
    );
  }

  /// Plus › Projets.
  Future<void> _openProjects() async {
    final data = _entryData(context);
    if (data?.projects == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectsScreen(
          data: data!,
          projects: data.projects!,
          onChanged: () => _saved.value++,
        ),
      ),
    );
    _saved.value++;
  }

  /// « Projet (mettre de côté) » from the + (PRODUCT): straight to the
  /// sheet with one running project, a choice with several, « Nouveau
  /// projet » with none.
  Future<void> _putAside(EntryData data) async {
    final projects = data.projects;
    if (projects == null) return;
    final open = [
      for (final p in await projects.projects())
        if (p.running && !p.reached) p,
    ];
    if (!mounted) return;
    if (open.isEmpty) return _newProject();
    final l = AppLocalizations.of(context);
    final picked = open.length == 1
        ? open.single
        : await showChoiceSheet<ProjectInfo>(
            context,
            title: l.projectPutAside,
            options: [for (final p in open) (p, p.name)],
          );
    if (picked == null || !mounted) return;
    if (await putAsideFlow(
      context,
      data: data,
      projects: projects,
      project: picked,
    )) {
      _saved.value++;
    }
  }

  /// « Nouveau projet », from the + or the home.
  Future<void> _newProject() async {
    final data = _entryData(context);
    if (data?.projects == null) return;
    final made = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewProjectScreen(data: data!, projects: data.projects!),
      ),
    );
    if (made == true) _saved.value++;
  }

  /// Dettes et créances, on [tab].
  Future<void> _openDebts(KibuoDatabase db, DebtDirection tab) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DebtsScreen(
            data: _entryData(context)!,
            debts: DebtRepository(db),
            prefs: PreferenceStore(db),
            hints: HintStore(db),
            tab: tab,
            onChanged: () => _saved.value++,
          ),
        ),
      );

  /// « Nouvelle dette ou créance » from the +, then « Dette enregistrée ».
  Future<void> _newDebt(EntryData data, KibuoDatabase db) => runNewDebt(
    context,
    data: data,
    debts: DebtRepository(db),
    onSaved: () => _saved.value++,
  );
}

/// Fades the content out just above the bar, so white cards never touch it.
class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 132 + bottom,
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.62],
              colors: [Color(0x00EEF1F7), KibuoColors.background],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.current,
    required this.plusKey,
    required this.onTab,
    required this.onPlusTap,
    required this.onPlusHoldStart,
    required this.onPlusHoldMove,
    required this.onPlusHoldEnd,
  });

  final _Tab current;
  final GlobalKey plusKey;
  final ValueChanged<_Tab> onTab;
  final VoidCallback onPlusTap;
  final VoidCallback onPlusHoldStart;
  final ValueChanged<Offset> onPlusHoldMove;
  final ValueChanged<Offset> onPlusHoldEnd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget tab(_Tab t, String label, TabGlyph glyph) => Expanded(
      child: _TabButton(
        label: label,
        glyph: glyph,
        selected: current == t,
        onTap: () => onTab(t),
      ),
    );

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12 + bottom,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KibuoColors.track),
          boxShadow: [
            BoxShadow(
              color: KibuoColors.ink.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            tab(_Tab.home, AppLocalizations.of(context).tabHome, TabGlyph.home),
            tab(
              _Tab.operations,
              AppLocalizations.of(context).tabOperations,
              TabGlyph.operations,
            ),
            Expanded(
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxHeight: 140,
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: _PlusButton(
                    key: plusKey,
                    onTap: onPlusTap,
                    onHoldStart: onPlusHoldStart,
                    onHoldMove: onPlusHoldMove,
                    onHoldEnd: onPlusHoldEnd,
                  ),
                ),
              ),
            ),
            tab(
              _Tab.overview,
              AppLocalizations.of(context).tabOverview,
              TabGlyph.overview,
            ),
            tab(_Tab.more, AppLocalizations.of(context).tabMore, TabGlyph.more),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final TabGlyph glyph;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? KibuoColors.accent : KibuoColors.inkSecondary;
    // No ripple: the drawn icon is the feedback.
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KibuoTabIcon(glyph: glyph, active: selected),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The + button. A tap presses it in, it bounces back, then the sheet opens.
class _PlusButton extends StatefulWidget {
  const _PlusButton({
    super.key,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldMove,
    required this.onHoldEnd,
  });

  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final ValueChanged<Offset> onHoldMove;
  final ValueChanged<Offset> onHoldEnd;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _tap() {
    if (!MediaQuery.disableAnimationsOf(context)) _press.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).plusButton,
      hint: AppLocalizations.of(context).plusButtonHint,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _tap,
        onLongPressStart: (_) => widget.onHoldStart(),
        onLongPressMoveUpdate: (d) => widget.onHoldMove(d.globalPosition),
        onLongPressEnd: (d) => widget.onHoldEnd(d.globalPosition),
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            // The button presses in, then bounces back.
            final t = Curves.easeOut.transform(_press.value);
            final scale = switch (t) {
              < .3 => lerpDouble(1, .86, t / .3)!,
              < .65 => lerpDouble(.86, 1.08, (t - .3) / .35)!,
              _ => lerpDouble(1.08, 1, (t - .65) / .35)!,
            };
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: KibuoColors.mint,
              borderRadius: BorderRadius.circular(20),
              // The ring of page colour that makes the button stand out.
              boxShadow: const [
                BoxShadow(color: KibuoColors.background, spreadRadius: 5),
              ],
            ),
            child: const Icon(
              KibuoIcons.plusBold,
              size: 28,
              color: KibuoColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// « Astuce : maintenez + puis glissez vers un choix, sans lever le
/// doigt. » with « Compris », pointing at the + (canvas PlusBtnC2).
class _HoldTip extends StatelessWidget {
  const _HoldTip({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          decoration: BoxDecoration(
            color: KibuoColors.ink,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l.plusHoldTip,
                style: KibuoType.body.copyWith(
                  color: KibuoColors.surface,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: onDone,
                style: TextButton.styleFrom(foregroundColor: KibuoColors.mint),
                child: Text(l.plusHoldTipDone),
              ),
            ],
          ),
        ),
        // The point, towards the +.
        Transform.translate(
          offset: const Offset(0, -6),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 12, height: 12, color: KibuoColors.ink),
          ),
        ),
      ],
    );
  }
}
