import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

/// The « Accueil » tab (canvas Aujourdhui, Total_sansprojet): today's date,
/// what is available, and the month so far. Debts, « À traiter » and
/// « À venir » join it with their modules (PRODUCT).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.data,
    this.refresh,
    this.onOpenAccounts,
    this.onOpenMonth,
  });

  final EntryData data;

  /// Bumped by the shell when something may have changed.
  final Listenable? refresh;

  /// Touching the available amount.
  final VoidCallback? onOpenAccounts;

  /// Touching the month: the list, until the overview exists.
  final VoidCallback? onOpenMonth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CurrencyInfo? _main;
  AccountTotal? _available;
  FlowTotals? _month;

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (old.refresh != widget.refresh) {
      old.refresh?.removeListener(_load);
      widget.refresh?.addListener(_load);
    }
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final data = widget.data;
    final accounts = await data.accounts.accounts();
    final ops = await data.transactions.all();
    final mainCode = await data.currencies.primaryCurrency() ?? 'USD';
    final main = await data.currencies.currency(mainCode);
    final now = DateTime.now();
    final month = [
      for (final t in ops)
        if (_sameMonth(t, now)) t,
    ];
    final rates = <String, ExchangeRate>{};
    final codes = {
      for (final a in accounts) a.balance.currency,
      for (final t in month) ...[
        if (flowOf(t).incoming case final m?) m.currency,
        if (flowOf(t).outgoing case final m?) m.currency,
      ],
    }..remove(mainCode);
    for (final code in codes) {
      final rate = await data.currencies.latestRate(mainCode, code);
      if (rate != null) rates[code] = rate.rate;
    }
    if (!mounted) return;
    setState(() {
      _main = main;
      _available = totalIn(main, [
        for (final a in accounts) a.balance,
      ], (code) => rates[code]);
      _month = flowTotals(main, month.map(flowOf), (code) => rates[code]);
    });
  }

  static bool _sameMonth(TransactionInfo t, DateTime now) {
    final d = t.date.toLocal();
    return d.year == now.year && d.month == now.month;
  }

  Future<void> _openCurrencies() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CurrenciesScreen(repository: widget.data.currencies),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final available = _available;
    final month = _month;
    final main = _main;
    return ListView(
      // Room for the floating bar and its fade.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        TabHeader(
          title: TabHeader.text(l.homeTitle),
          subtitle: _capitalized(DateFormat.MMMMEEEEd(lang).format(now)),
        ),
        if (available != null && month != null && main != null) ...[
          const SizedBox(height: 16),
          _AvailableCard(
            long: isLong(available.amount),
            amount: (short) => (short ? formatShort : formatMoney)(
              available.amount,
              main,
              lang,
            ),
            onTap: widget.onOpenAccounts,
          ),
          if (available.withoutRate.isNotEmpty) ...[
            const SizedBox(height: 8),
            HelpText(l.accountsNoRateNote(available.withoutRate.join(', '))),
            Align(
              alignment: Alignment.centerLeft,
              child: TextAction(
                label: l.accountsAddRate,
                onPressed: _openCurrencies,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _MonthCard(
            name: _capitalized(DateFormat.MMMM(lang).format(now)),
            totals: month,
            today: now,
            money: (m, short) =>
                (short ? formatShort : formatMoney)(m, main, lang),
            signed: (m, short) => short
                ? '${m.minor > 0 ? '+' : ''}'
                      '${formatShort(m, main, lang, symbol: false)}'
                : formatSigned(m, main, lang),
            onTap: widget.onOpenMonth,
          ),
        ],
      ],
    );
  }

  static String _capitalized(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// « Disponible », the amount, « à dépenser librement »: mint, 22 round,
/// opening Comptes.
class _AvailableCard extends StatelessWidget {
  const _AvailableCard({required this.amount, required this.long, this.onTap});

  /// Whole or short.
  final String Function(bool short) amount;
  final bool long;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      hint: l.homeOpenAccounts,
      child: Material(
        color: KibuoColors.mint,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.homeAvailable,
                        style: KibuoType.help.copyWith(
                          fontWeight: FontWeight.w500,
                          fontVariations: const [FontVariation.weight(500)],
                          color: KibuoColors.accentDeep,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FitAmount(
                        long: long,
                        style: KibuoType.bigAmount.copyWith(height: 42 / 34),
                        span: (short) => TextSpan(text: amount(short)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.homeAvailableHelp,
                        style: KibuoType.caption.copyWith(
                          color: KibuoColors.accentDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  KibuoIcons.caretRight,
                  size: 20,
                  color: KibuoColors.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Novembre · ce mois-ci », what is left, the bar with today on it, and
/// « 49 % dépensés · −588,00 sur +1 200,00 ».
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.name,
    required this.totals,
    required this.today,
    required this.money,
    required this.signed,
    this.onTap,
  });

  final String name;
  final FlowTotals totals;
  final DateTime today;
  final String Function(Money, bool short) money;
  final String Function(Money, bool short) signed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final rest = totals.rest;
    final pre = totals.approximate ? '≈ ' : '';
    // As in the list (PRODUCT): the bar is always there; full and in alert
    // with exits and no entry.
    final share = totals.spentPercent;
    final outOnly = share == null && totals.exits.minor > 0;
    final level = share ?? (outOnly ? 101 : 0);
    final (barColor, shareColor) = level <= 80
        ? (KibuoColors.inkMuted, KibuoColors.ink)
        : level <= 100
        ? (KibuoColors.warning, KibuoColors.warningInk)
        : (KibuoColors.debtInk, KibuoColors.debtInk);
    final bold = TextStyle(
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
      color: shareColor,
    );
    final exits = Money(-totals.exits.minor, totals.exits.currency);
    String restText(bool short) =>
        rest.minor > 0 ? '+${money(rest, short)}' : money(rest, short);
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    const Icon(
                      KibuoIcons.calendarBlank,
                      size: 16,
                      color: KibuoColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: name,
                          children: [
                            TextSpan(
                              text: ' · ${l.homeThisMonth}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontVariations: [FontVariation.weight(500)],
                                color: KibuoColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                        style: KibuoType.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    const Icon(
                      KibuoIcons.caretRight,
                      size: 18,
                      color: KibuoColors.inkMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              FitAmount(
                long: isLong(rest),
                span: (short) => TextSpan(
                  text: '$pre${restText(short)}',
                  style: KibuoType.tabTitle.copyWith(
                    height: 1.2,
                    color: rest.minor < 0 ? KibuoColors.debtInk : null,
                  ),
                  children: [
                    TextSpan(
                      text: ' ${l.homeLeft}',
                      style: KibuoType.help.copyWith(
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation.weight(500)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _MonthBar(
                spent: (level / 100).clamp(0, 1).toDouble(),
                color: barColor,
                today: monthElapsed(today),
                todayLabel: DateFormat.MMMd(lang).format(today),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: outOnly ? l.listNoEntries : null),
                        if (!outOnly) ..._percent(l.listSpent(level), bold),
                      ],
                    ),
                    maxLines: 1,
                    style: KibuoType.caption,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FitAmount(
                      long: isLong(exits) || isLong(totals.entries),
                      alignment: Alignment.centerRight,
                      style: KibuoType.caption,
                      span: (short) => _outOfIn(
                        l,
                        '$pre${signed(exits, short)}',
                        '$pre${signed(totals.entries, short)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// « 49 % » in bold, then « dépensés ».
  static List<InlineSpan> _percent(String text, TextStyle bold) {
    final cut = text.indexOf('%');
    if (cut < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, cut + 1), style: bold),
      TextSpan(text: text.substring(cut + 1)),
    ];
  }

  /// « −588,00 » in the debt colour, « sur », « +1 200,00 » in green.
  static TextSpan _outOfIn(AppLocalizations l, String out, String income) {
    const outMark = '\u0000';
    const inMark = '\u0001';
    final pattern = l.homeOutOfIn(outMark, inMark);
    final spans = <InlineSpan>[];
    var rest = pattern;
    while (rest.isNotEmpty) {
      final i = rest.indexOf(RegExp('[$outMark$inMark]'));
      if (i < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (i > 0) spans.add(TextSpan(text: rest.substring(0, i)));
      final isOut = rest[i] == outMark;
      final text = isOut ? out : income;
      final zero = !text.contains(RegExp('[+−]'));
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation.weight(700)],
            color: zero
                ? KibuoColors.inkMuted
                : isOut
                ? KibuoColors.debtInk
                : KibuoColors.accent,
          ),
        ),
      );
      rest = rest.substring(i + 1);
    }
    return TextSpan(children: spans);
  }
}

/// The bar: spent share on a track, and today as a mark with its date above.
class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.spent,
    required this.color,
    required this.today,
    required this.todayLabel,
  });

  final double spent;
  final Color color;
  final double today;
  final String todayLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: LayoutBuilder(
        builder: (context, box) {
          final x = box.maxWidth * today;
          final style = KibuoType.caption.copyWith(
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation.weight(600)],
          );
          final width = (TextPainter(
            text: TextSpan(text: todayLabel, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout()).width;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: spent,
                    minHeight: 10,
                    color: color,
                    backgroundColor: KibuoColors.track,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Positioned(
                left: x - 1,
                top: 14,
                child: Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: KibuoColors.ink,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Centred on the mark, kept inside the card.
              Positioned(
                top: 0,
                left: (x - width / 2).clamp(0, box.maxWidth - width).toDouble(),
                child: Text(todayLabel, maxLines: 1, style: style),
              ),
            ],
          );
        },
      ),
    );
  }
}
