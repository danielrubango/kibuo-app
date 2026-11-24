import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/operation_card.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/recurrences/rhythm_text.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';

/// A draft paid in another currency than its account's, still without a
/// rate: it can't count until one is given (PRODUCT).
bool waitsForRate(TransactionInfo t, OperationLabels labels) =>
    t.kind != EntryKind.transfer &&
    t.rate == null &&
    t.paid.currency != labels.accountCurrency;

/// What a toast names: the note, or the category.
String draftName(TransactionInfo t, OperationLabels labels) {
  final note = t.note?.trim() ?? '';
  return note.isNotEmpty ? note : labels.categoryPath.split(' › ').last;
}

/// « Valider » on a draft in a list: at once, with a toast, unless a rate
/// is missing or the account would go below its floor; then the draft's
/// card opens and says so (PRODUCT).
Future<void> validateFromList(
  BuildContext context,
  EntryData data,
  TransactionInfo t,
  OperationLabels labels,
) async {
  final l = AppLocalizations.of(context);
  final blocked =
      waitsForRate(t, labels) ||
      checkOverdraft(
            accounts: await data.accounts.accounts(),
            after: effectsOf(t),
            date: t.date,
          ) !=
          null;
  if (!context.mounted) return;
  if (blocked) return openDraft(context, data, t);
  await data.transactions.validate(t.id);
  if (context.mounted) {
    showKibuoToast(context, l.draftValidated(draftName(t, labels)));
  }
}

/// « Ignorer » on a draft in a list, with a toast.
Future<void> ignoreFromList(
  BuildContext context,
  EntryData data,
  TransactionInfo t,
  OperationLabels labels,
) async {
  final l = AppLocalizations.of(context);
  await data.transactions.ignore(t.id);
  if (context.mounted) {
    showKibuoToast(context, l.draftIgnoredToast(draftName(t, labels)));
  }
}

Future<void> openDraft(
  BuildContext context,
  EntryData data,
  TransactionInfo t,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => DraftScreen(data: data, id: t.id),
  ),
);

/// A draft's card, or an ignored one's (canvas OperationCarteBrouillon,
/// OperationCarteIgnoree): what it is, when it was due, its account,
/// category and recurrence, then « Valider l'opération », « Changer le
/// montant » and, for a draft, « Ignorer cette fois ». A missing rate or a
/// floor in the way shows the usual red line instead of validating.
class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key, required this.data, required this.id});

  final EntryData data;
  final String id;

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  TransactionInfo? _t;
  OperationLabels? _labels;
  RecurringInfo? _rule;
  OverdraftRefusal? _refusal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = widget.data;
    final t = await data.transactions.get(widget.id);
    if (!mounted) return;
    // Gone, or validated from elsewhere: back to the list.
    if (t == null || t.counts) {
      Navigator.of(context).pop();
      return;
    }
    final labels = await OperationLabels.of(context, data, t);
    final rules = await data.recurrences?.rules() ?? const <RecurringInfo>[];
    final refusal = checkOverdraft(
      accounts: await data.accounts.accounts(),
      after: effectsOf(t),
      date: t.date,
    );
    if (!mounted) return;
    setState(() {
      _t = t;
      _labels = labels;
      _rule = rules.where((r) => r.id == t.recurringId).firstOrNull;
      _refusal = refusal;
    });
  }

  Future<void> _validate() async {
    final l = AppLocalizations.of(context);
    await widget.data.transactions.validate(_t!.id);
    if (!mounted) return;
    showKibuoToast(context, l.draftValidated(draftName(_t!, _labels!)));
    Navigator.of(context).pop();
  }

  Future<void> _ignore() async {
    final l = AppLocalizations.of(context);
    await widget.data.transactions.ignore(_t!.id);
    if (!mounted) return;
    showKibuoToast(context, l.draftIgnoredToast(draftName(_t!, _labels!)));
    Navigator.of(context).pop();
  }

  /// The draft's entry; « Enregistrer » saves and validates it (PRODUCT).
  Future<void> _change() async {
    final l = AppLocalizations.of(context);
    final before = _t!;
    final labels = _labels!;
    await runEntry(
      context,
      widget.data,
      kind: before.kind,
      initial: before,
      editing: true,
    );
    final after = await widget.data.transactions.get(before.id);
    if (!mounted) return;
    if (after != null && after.counts) {
      showKibuoToast(context, l.draftValidated(draftName(after, labels)));
      Navigator.of(context).pop();
      return;
    }
    await _load();
  }

  /// « Autoriser » opens the account's form, then the card checks again.
  Future<void> _authorize(AccountInfo account) async {
    final data = widget.data;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          accounts: data.accounts,
          currencies: data.currencies,
          account: account,
          categories: data.categories,
          transactions: data.transactions,
        ),
      ),
    );
    await _load();
  }

  String _due(AppLocalizations l, String lang, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final text = DateFormat.MMMMEEEEd(lang).format(local);
    if (day == today) return l.draftDueToday(text);
    if (day == today.subtract(const Duration(days: 1))) {
      return l.draftDueYesterday(text);
    }
    return l.draftDueOn(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final t = _t;
    final labels = _labels;
    if (t == null || labels == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final ignored = t.isIgnored;
    final (:card, :dash) = draftColors(t.kind);
    final ink = kindColors(t.kind).ink;
    final rule = _rule;
    String money(Money m) => context.money(m);
    final noRate = waitsForRate(t, labels);
    final refusal = _refusal;
    final blocked = noRate || refusal != null;
    final unit = rule?.schedule.unit.name ?? 'month';
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
        children: [
          OperationHero(
            tile: OperationTile(
              kind: t.kind,
              labels: labels,
              size: 44,
              muted: ignored,
            ),
            title: draftName(t, labels),
            status: l.draftStatus(t.status, unit),
            statusColor: ignored ? KibuoColors.inkSecondary : ink,
            amount: signedTotal(context, t),
            amountColor: ignored ? KibuoColors.inkMuted : KibuoColors.ink,
            struck: ignored,
            chip: _due(l, lang, t.date),
            background: ignored ? KibuoColors.surface : card,
            dash: ignored ? KibuoColors.line : dash,
          ),
          const SizedBox(height: 14),
          NoticeCard(
            icon: KibuoIcons.repeat,
            text: ignored ? l.ignoredNotice : l.draftNotice,
            background: ignored ? KibuoColors.surface : KibuoColors.warningSoft,
            ink: ignored
                ? KibuoColors.inkSecondary
                : KibuoColors.warningSoftInk,
          ),
          const SizedBox(height: 14),
          Material(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                EntryField(
                  icon: KibuoIcons.wallet,
                  label: l.entryAccount,
                  value: t.kind == EntryKind.transfer
                      ? '${labels.account} → ${labels.toAccount ?? ''}'
                      : labels.account,
                  trailing: labels.accountCurrency,
                ),
                if (t.kind != EntryKind.transfer)
                  EntryField(
                    icon: KibuoIcons.tag,
                    label: l.entryCategory,
                    value: labels.categoryPath,
                  ),
                if (rule != null)
                  EntryField(
                    icon: KibuoIcons.repeat,
                    label: l.recurrenceTitle,
                    value: rhythmOnly(l, lang, rule.schedule),
                    trailing: endText(l, lang, rule.schedule),
                  ),
              ],
            ),
          ),
          if (blocked) ...[
            const SizedBox(height: 8),
            if (noRate)
              RefusalLine(text: l.draftNoRate(t.paid.currency))
            else
              RefusalLine(
                text: l.overdraftAvailable(
                  money(refusal!.available),
                  refusal.account.name,
                ),
                action: l.overdraftAuthorize,
                onAction: () => _authorize(refusal.account),
              ),
          ],
          const SizedBox(height: 18),
          KibuoButton(
            label: l.draftValidateAction,
            onPressed: blocked ? null : _validate,
          ),
          const SizedBox(height: 8),
          KibuoButton(
            label: l.draftChangeAmount,
            kind: ButtonKind.secondary,
            icon: KibuoIcons.pencilSimple,
            onPressed: _change,
          ),
          if (!ignored) ...[
            const SizedBox(height: 8),
            Center(
              child: TextAction(
                label: l.draftIgnoreOnce,
                color: KibuoColors.inkSecondary,
                onPressed: _ignore,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
