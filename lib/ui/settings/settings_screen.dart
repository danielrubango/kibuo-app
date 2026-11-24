import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/first_launch_store.dart';
import 'package:kibuo/data/long_amounts_store.dart';
import 'package:kibuo/data/month_start_store.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/domain/money/long_amounts.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_types_screen.dart';
import 'package:kibuo/ui/backup/backup_screen.dart';
import 'package:kibuo/ui/backup/restore_sheet.dart';
import 'package:kibuo/ui/categories/categories_screen.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/design_system_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/recovery_screens.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/recurrences/list_display.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/reminders/reminders_screen.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/settings/language_sheet.dart';
import 'package:kibuo/ui/settings/long_amounts_sheet.dart';
import 'package:kibuo/ui/settings/month_start_sheet.dart';
import 'package:kibuo/ui/settings/security_screens.dart';

/// Plus › Réglages (canvas Reglages, PRODUCT 25 November 2026): Général,
/// Notifications, Sécurité, Données, one white card each.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.db,
    required this.openAccounts,
    this.notifier,
    this.onRemindersChanged,
    this.backups,
    this.restore,
  });

  final KibuoDatabase db;

  /// Comptes, as the rest of the app opens it.
  final Future<void> Function() openAccounts;

  /// « Rappels et alertes »; no line without it.
  final Notifier? notifier;
  final Future<void> Function()? onRemindersChanged;

  /// « Sauvegarde et restauration »; no section without it.
  final BackupService? backups;
  final RestoreTools? restore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _accounts;
  int? _types;
  String? _currency;

  late final _accountsRepo = AccountRepository(widget.db);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await _accountsRepo.accounts();
    final types = await _accountsRepo.types();
    final currency = await CurrencyRepository(widget.db).primaryCurrency();
    if (!mounted) return;
    setState(() {
      _accounts = accounts.length;
      _types = AccountType.provided.length + types.length;
      _currency = currency;
    });
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final db = widget.db;
    final lock = KibuoLock.maybeControllerOf(context);
    final language = switch (Localizations.localeOf(context).languageCode) {
      'en' => 'English',
      _ => 'Français',
    };
    final sections = <(String, List<Widget>)>[
      (
        l.settingsGeneral,
        [
          SettingsRow(
            label: l.settingsLanguage,
            value: language,
            onTap: () => showLanguageSheet(context, FirstLaunchStore(db)),
          ),
          SettingsRow(
            label: l.accountsTitle,
            value: _accounts == null ? null : '$_accounts',
            onTap: () async {
              await widget.openAccounts();
              await _load();
            },
          ),
          SettingsRow(
            label: l.typesTitle,
            value: _types == null ? null : '$_types',
            onTap: () => _push(AccountTypesScreen(accounts: _accountsRepo)),
          ),
          SettingsRow(
            label: l.currenciesTitle,
            value: _currency,
            onTap: () =>
                _push(CurrenciesScreen(repository: CurrencyRepository(db))),
          ),
          SettingsRow(
            label: l.categoriesTitle,
            onTap: () =>
                _push(CategoriesScreen(categories: CategoryRepository(db))),
          ),
          ValueListenableBuilder<int>(
            valueListenable: monthStartChoice,
            builder: (context, day, _) => SettingsRow(
              label: l.monthStart,
              value: l.monthStartValue(day),
              onTap: () => showMonthStartSheet(context, MonthStartStore(db)),
            ),
          ),
          // After « Début du mois » (PRODUCT, 25 November 2026).
          ValueListenableBuilder<LongAmounts>(
            valueListenable: longAmountsChoice,
            builder: (context, choice, _) => SettingsRow(
              label: l.longAmounts,
              value: longAmountsName(l, choice),
              onTap: () => showLongAmountsSheet(context, LongAmountsStore(db)),
            ),
          ),
          RecurrencesSettingsRow(recurrences: RecurringRepository(db)),
        ],
      ),
      if (widget.notifier case final notifier?)
        (
          l.settingsNotifications,
          [
            SettingsRow(
              label: l.remindersTitle,
              onTap: () => _push(
                RemindersScreen(
                  store: ReminderStore(db),
                  notifier: notifier,
                  onChanged: widget.onRemindersChanged ?? () async {},
                ),
              ),
            ),
          ],
        ),
      if (lock != null)
        (
          l.settingsSecurity,
          [
            SettingsRow(
              label: l.securityLock,
              value: lock.hasPin ? l.settingsLockOn : l.settingsLockOff,
              onTap: () => _push(LockSettingsScreen(lock: lock)),
            ),
            SettingsRow(
              label: l.securityPrivacy,
              value: privacySummary(l, lock),
              onTap: () => _push(PrivacyScreen(lock: lock)),
            ),
            if (lock.recovery != null)
              SettingsRow(
                label: l.recoveryTitle,
                value: recoverySummary(context, lock),
                onTap: () => _push(RecoverySettingsScreen(lock: lock)),
              ),
          ],
        ),
      if (widget.backups case final backups?)
        (
          l.settingsData,
          [
            SettingsRow(
              label: l.settingsBackup,
              onTap: () => _push(
                BackupScreen(service: backups, restore: widget.restore),
              ),
            ),
          ],
        ),
    ];
    final screen = Scaffold(
      appBar: AppBar(title: Text(l.plusSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final (title, rows) in sections) ...[
            SectionTitle(title),
            SettingsCard(children: rows),
            const SizedBox(height: 14),
          ],
          // Debug builds only: the design system, to review on a phone.
          if (kDebugMode)
            SettingsCard(
              children: [
                SettingsRow(
                  label: 'Système de design',
                  onTap: () => _push(const DesignSystemScreen()),
                ),
              ],
            ),
        ],
      ),
    );
    // The security values follow the lock as it changes.
    return lock == null
        ? screen
        : ListenableBuilder(listenable: lock, builder: (_, _) => screen);
  }
}
