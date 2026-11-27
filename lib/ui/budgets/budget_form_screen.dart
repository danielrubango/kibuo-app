import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';

/// « Nouveau budget » and « Modifier le budget » (canvas BudgetNouveau):
/// the amount per month with the average under it, the category and the
/// period, the note that nothing carries over, then the button at the
/// bottom. Pops true when something changed.
class BudgetFormScreen extends StatefulWidget {
  const BudgetFormScreen({
    super.key,
    required this.loader,
    required this.book,
    this.line,
  });

  final BudgetLoader loader;

  /// The period shown on Budgets: its categories and budgets.
  final BudgetBook book;

  /// The budget to change; none for a new one.
  final BudgetLine? line;

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  late CategoryInfo? _category = widget.line?.category;
  late String _typed = widget.line == null
      ? ''
      : typedFrom(widget.line!.status.amount, widget.book.main);
  late bool _keypad = widget.line == null;
  Money? _average;
  final _amountKey = GlobalKey();
  final _categoryKey = GlobalKey();

  /// Saving touched with something missing: it shows in red.
  bool _tried = false;

  bool get _editing => widget.line != null;
  CurrencyInfo get _main => widget.book.main;
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    if (_category != null) _loadAverage(_category!);
  }

  Future<void> _loadAverage(CategoryInfo c) async {
    final average = await widget.loader.average(c);
    if (mounted && _category?.id == c.id) setState(() => _average = average);
  }

  Money get _amount {
    final typed = _typed.isEmpty ? '0' : _typed.replaceAll(',', '.');
    return Money.fromMajor(typed.endsWith('.') ? '${typed}0' : typed, _main);
  }

  /// The amount the keypad opened on, shown selected: the first key
  /// replaces it (PRODUCT, 27 November 2026).
  late bool _selected = _keypad && _typed.isNotEmpty;

  void _key(String k) => setState(() {
    _typed = typeKey(
      _selected ? '' : _typed,
      k,
      decimals: _main.usesDecimals ? _main.digits : 0,
    );
    _selected = false;
  });

  void _delete() => setState(() {
    _selected = false;
    if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
  });

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context);
    final picked = await pickCategory(
      context,
      categories: widget.book.categories,
      current: _category?.id,
      withSubs: false,
      unavailable: {for (final b in widget.book.budgets) b.categoryId},
      unavailableNote: l.budgetAlready,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _category = picked;
      _average = null;
    });
    await _loadAverage(picked);
  }

  Future<void> _save() async {
    final repo = widget.loader.budgets;
    final month = monthKey(periodOf(DateTime.now()).month);
    final line = widget.line;
    if (line == null) {
      await repo.create(
        categoryId: _category!.id,
        amount: _amount,
        fromMonth: month,
      );
    } else if (_amount != line.status.amount) {
      await repo.setAmount(line.budget.id, _amount, fromMonth: month);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final line = widget.line!;
    final name = categoryName(l, line.category);
    final sure = await confirmRemoval(
      context,
      title: l.budgetDeleteTitle(name),
      summary: RemovalSummary(
        leading: CategoryTile(category: line.category, size: 36),
        title: name,
        trailing: formatMoney(line.status.amount, _main, _lang),
      ),
      text: l.budgetDeleteText,
      action: l.budgetDeleteConfirm,
    );
    if (!sure || !mounted) return;
    if (!await confirmWithCode(context, l.protectDeleteBudget(name))) return;
    await widget.loader.budgets.delete(line.budget.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  /// « du 1er au 30 », or « du 25 oct. au 24 nov. ».
  String _periodText(AppLocalizations l) {
    final p = periodOf(DateTime.now());
    if (p.first.month == p.last.month) {
      final first = _lang == 'fr' && p.first.day == 1
          ? '1er'
          : '${p.first.day}';
      return l.budgetsDays(first, '${p.last.day}');
    }
    return l.listPeriod(
      DateFormat.MMMd(_lang).format(p.first),
      DateFormat.MMMd(_lang).format(p.last),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final category = _category;
    final average = _average;
    final ready = category != null && _amount.minor > 0;
    // Something typed or chosen: the button says what is missing
    // (DIRECTION, 25 November 2026).
    final touched = _typed.isNotEmpty || category != null || _editing;
    void trySave() {
      if (ready) {
        _save();
        return;
      }
      setState(() => _tried = true);
      showMissing(_amount.minor <= 0 ? _amountKey : _categoryKey);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(
              title: _editing ? l.budgetEdit : l.budgetNew,
              cancel: l.cancel,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ValueField(
                    key: _amountKey,
                    label: l.budgetAmount,
                    value: shownTyped(context, _typed),
                    unit: _main.symbol,
                    focused: _keypad,
                    selected: _keypad && _selected,
                    missing: _tried && _amount.minor <= 0,
                    onTap: () {
                      // Touched again while typing: kept, the keys follow
                      // on.
                      if (_keypad) {
                        setState(() => _selected = false);
                        return;
                      }
                      setState(() {
                        _keypad = true;
                        _selected = _typed.isNotEmpty;
                      });
                      revealAboveKeypad(_amountKey);
                    },
                  ),
                  if (average != null && category != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            KibuoIcons.chartBar,
                            size: 16,
                            color: KibuoColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l.budgetAverage(
                                formatMoney(average, _main, _lang),
                                categoryName(l, category),
                              ),
                              style: KibuoType.help.copyWith(
                                color: KibuoColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SettingsCard(
                    children: [
                      MissingUnderline(
                        key: _categoryKey,
                        missing: _tried && category == null,
                        child: _PickRow(
                          icon: category == null
                              ? KibuoIcons.tag
                              : categoryIcon(category),
                          label: l.budgetCategory,
                          value: category == null
                              ? l.budgetChoose
                              : categoryName(l, category),
                          onTap: _editing ? null : _pickCategory,
                        ),
                      ),
                      _PickRow(
                        icon: KibuoIcons.calendarBlank,
                        label: l.budgetPeriod,
                        value: l.budgetEveryMonth,
                        detail: _periodText(l),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HelpText(l.budgetNoCarry),
                  if (_editing) ...[
                    const SizedBox(height: 24),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          label: l.budgetDelete,
                          danger: true,
                          onTap: _remove,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_keypad)
              KeypadPanel(
                keypad: KibuoKeypad(
                  onKey: _key,
                  onDelete: _delete,
                  allowDecimal: _main.usesDecimals,
                  decimalSeparator: NumberFormat.decimalPattern(_lang)
                      .symbols
                      .DECIMAL_SEP,
                ),
                done: l.keypadDone,
                onDone: () => setState(() => _keypad = false),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: KibuoButton(
                  label: _editing ? l.budgetSave : l.budgetCreate,
                  onPressed: touched ? trySave : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A row of the form's card: its icon in a grey tile, a small label over
/// the value, an optional detail, and › when it can be touched.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                tint: KibuoColors.background,
                ink: KibuoColors.inkSecondary,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: KibuoType.caption),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: KibuoType.rowLabel.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                  ],
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: 8),
                Text(detail!, style: KibuoType.caption.copyWith(fontSize: 13)),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  KibuoIcons.caretRight,
                  size: 16,
                  color: KibuoColors.lineStrong,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
