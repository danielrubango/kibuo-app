import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/categories/category_form_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// What the screens show of an operation: its names, ready to read.
class OperationLabels {
  const OperationLabels({
    required this.category,
    required this.categoryPath,
    required this.account,
    required this.accountCurrency,
  });

  final CategoryInfo? category;

  /// « Taxi », or « Transport › Taxi » for a subcategory.
  final String categoryPath;
  final String account;
  final String accountCurrency;

  static Future<OperationLabels> of(
    BuildContext context,
    EntryData data,
    TransactionInfo t,
  ) async {
    final l = AppLocalizations.of(context);
    final category = await data.categories.category(t.categoryId);
    final parent = category?.parentId == null
        ? null
        : await data.categories.category(category!.parentId!);
    final accounts = [
      ...await data.accounts.accounts(),
      ...await data.accounts.accounts(archived: true),
    ];
    final account = accounts.where((a) => a.id == t.accountId).firstOrNull;
    final name = category == null ? '' : categoryName(l, category);
    return OperationLabels(
      category: category,
      categoryPath: parent == null
          ? name
          : '${categoryName(l, parent)} › $name',
      account: account?.name ?? '',
      accountCurrency: account?.currency ?? t.total.total.currency,
    );
  }
}

/// « −5,11 $ » or « +49,50 $ »: what the operation did to its account.
String signedTotal(BuildContext context, TransactionInfo t) {
  final lang = Localizations.localeOf(context).languageCode;
  final total = t.total.total;
  final text = formatMoney(
    Money(total.minor.abs(), total.currency),
    currencyOf(total.currency),
    lang,
  );
  return t.kind == EntryKind.expense ? '−$text' : '+$text';
}

/// « Aujourd'hui, 15:45 », « Hier, 08:15 », « Mardi 10 novembre, 08:15 ».
String operationWhen(BuildContext context, DateTime date, DateTime now) {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = DateFormat.Hm(lang).format(local);
  final String dayText;
  if (day == today) {
    dayText = l.entryToday;
  } else if (day == today.subtract(const Duration(days: 1))) {
    dayText = l.entryYesterday;
  } else {
    final t = DateFormat.MMMMEEEEd(lang).format(local);
    dayText = t[0].toUpperCase() + t.substring(1);
  }
  return '$dayText, $time';
}

/// Opens the entry; once saved, the « Dépense enregistrée » sheet offers
/// « Annuler et modifier » (the same operation, to edit) or another entry
/// of the same kind (canvas ApresFeuilleB). [onSaved] runs after each save.
Future<void> runEntry(
  BuildContext context,
  EntryData data, {
  required EntryKind kind,
  TransactionInfo? initial,
  bool editing = false,
  VoidCallback? onSaved,
}) async {
  var nextKind = kind;
  var nextInitial = initial;
  var nextEditing = editing;
  // What an operation needs comes first: an account, a category.
  final accountId = await _needed(context, data, kind);
  if (accountId == null) return;
  while (true) {
    if (!context.mounted) return;
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EntryScreen(
          data: data,
          kind: nextKind,
          initial: nextInitial,
          editing: nextEditing,
          accountId: accountId.isEmpty ? null : accountId,
        ),
      ),
    );
    if (id == null || !context.mounted) return;
    onSaved?.call();
    if (nextEditing && editing) return;
    final saved = await data.transactions.get(id);
    if (saved == null || !context.mounted) return;
    final labels = await OperationLabels.of(context, data, saved);
    if (!context.mounted) return;
    final action = await showSavedSheet(context, saved, labels);
    switch (action) {
      case SavedAction.edit:
        nextKind = saved.kind;
        nextInitial = saved;
        nextEditing = true;
      case SavedAction.another:
        nextKind = saved.kind;
        nextInitial = null;
        nextEditing = false;
      case null:
        return;
    }
  }
}

/// When an account, or a category of [kind], is missing, a sheet says why
/// and offers to create it first (canvas VideB). Returns null if the user
/// puts it off, the new account's id if one was created, else an empty
/// string.
Future<String?> _needed(
  BuildContext context,
  EntryData data,
  EntryKind kind,
) async {
  final l = AppLocalizations.of(context);
  final expense = kind == EntryKind.expense;
  var accountId = '';
  if ((await data.accounts.accounts()).isEmpty) {
    if (!context.mounted) return null;
    final go = await _firstSheet(
      context,
      icon: KibuoIcons.wallet,
      title: l.entryFirstAccountTitle,
      text: expense ? l.entryFirstAccountExpense : l.entryFirstAccountIncome,
      action: l.entryFirstAccountAction,
    );
    if (!go || !context.mounted) return null;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          accounts: data.accounts,
          currencies: data.currencies,
        ),
      ),
    );
    if (!(created ?? false)) return null;
    accountId = (await data.accounts.accounts()).last.id;
  }
  final categoryKind = expense ? CategoryKind.out : CategoryKind.into;
  if ((await data.categories.categories(categoryKind)).isEmpty) {
    if (!context.mounted) return null;
    final go = await _firstSheet(
      context,
      icon: KibuoIcons.tag,
      title: l.entryFirstCategoryTitle,
      text: expense ? l.entryFirstCategoryExpense : l.entryFirstCategoryIncome,
      action: l.entryFirstCategoryAction,
    );
    if (!go || !context.mounted) return null;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CategoryFormScreen(categories: data.categories, kind: categoryKind),
      ),
    );
    if (!(created ?? false)) return null;
  }
  return accountId;
}

/// « D'abord, un compte »: an icon, why it is needed, then the action and
/// « Plus tard ». Returns true for the action.
Future<bool> _firstSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String text,
  required String action,
}) async {
  final l = AppLocalizations.of(context);
  final go = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: KibuoColors.accentTint,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
              ),
              child: Icon(icon, size: 34, color: KibuoColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KibuoType.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: KibuoType.help.copyWith(fontSize: 14, height: 20 / 14),
          ),
          const SizedBox(height: 16),
          KibuoButton(
            label: action,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          KibuoButton(
            label: l.entryLater,
            kind: ButtonKind.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
  return go ?? false;
}

enum SavedAction { edit, another }

/// « Dépense enregistrée »: what was saved, then « Annuler et modifier »
/// and « Nouvelle dépense ». It closes by itself after a few seconds,
/// unless its content is touched.
Future<SavedAction?> showSavedSheet(
  BuildContext context,
  TransactionInfo saved,
  OperationLabels labels,
) {
  return showModalBottomSheet<SavedAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _SavedSheet(saved: saved, labels: labels),
  );
}

class _SavedSheet extends StatefulWidget {
  const _SavedSheet({required this.saved, required this.labels});

  final TransactionInfo saved;
  final OperationLabels labels;

  @override
  State<_SavedSheet> createState() => _SavedSheetState();
}

class _SavedSheetState extends State<_SavedSheet>
    with SingleTickerProviderStateMixin {
  static const _stay = Duration(seconds: 6);
  late final _clock = AnimationController(vsync: this, duration: _stay)
    ..forward().whenCompleteOrCancel(() {
      if (mounted && !_held) Navigator.of(context).maybePop();
    });
  bool _held = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _hold() {
    if (_held) return;
    setState(() => _held = true);
    _clock.stop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final t = widget.saved;
    final expense = t.kind == EntryKind.expense;
    final details = <(String, String, bool)>[
      if (t.rate != null) ...[
        (
          expense ? l.entryPaid : l.entryReceived,
          formatMoney(t.paid, currencyOf(t.paid.currency), lang),
          false,
        ),
        (
          l.entryRateFrozen(currencyOf(t.rate!.base).symbol),
          formatRate(t.rate!, lang).split(' = ').last,
          true,
        ),
      ],
      if (t.total.fees.minor > 0)
        (
          l.entryFees,
          '${expense ? '+' : '−'} '
              '${formatMoney(t.total.fees, currencyOf(t.total.fees.currency), lang)}',
          false,
        ),
    ];
    return Listener(
      onPointerDown: (_) => _hold(),
      child: Padding(
        padding: sheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: KibuoColors.mint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(KibuoIcons.check, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense ? l.entrySavedExpense : l.entrySavedIncome,
                        style: KibuoType.itemName,
                      ),
                      Text(
                        '${widget.labels.categoryPath.split(' › ').last} · '
                        '${widget.labels.account} · '
                        '${operationWhen(context, t.date, DateTime.now())}',
                        style: KibuoType.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(signedTotal(context, t), style: KibuoType.cardTitle),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: KibuoColors.surface,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                ),
                child: Column(
                  children: [
                    for (final (label, value, locked) in details)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(label, style: KibuoType.body)),
                            if (locked)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  KibuoIcons.lockSimple,
                                  size: 14,
                                  color: KibuoColors.inkSecondary,
                                ),
                              ),
                            Text(
                              value,
                              style: KibuoType.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontVariations: const [
                                  FontVariation.weight(600),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: KibuoButton(
                    label: l.entryUndoEdit,
                    kind: ButtonKind.secondary,
                    onPressed: () =>
                        Navigator.of(context).pop(SavedAction.edit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KibuoButton(
                    label: expense ? l.entryNewExpense : l.entryNewIncome,
                    kind: ButtonKind.secondary,
                    onPressed: () =>
                        Navigator.of(context).pop(SavedAction.another),
                  ).withMint(),
                ),
              ],
            ),
            if (!_held) ...[
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _clock,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1 - _clock.value,
                    minHeight: 4,
                    color: KibuoColors.mint,
                    backgroundColor: KibuoColors.track,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(l.entryClosesSoon, style: KibuoType.caption),
            ],
          ],
        ),
      ),
    );
  }
}

extension on KibuoButton {
  /// The sheet's second button is mint, but only 48 high, beside a white
  /// one of the same height.
  Widget withMint() => Material(
    color: KibuoColors.mint,
    borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: KibuoTheme.heightSecondary,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: KibuoType.buttonSmall,
          ),
        ),
      ),
    ),
  );
}
