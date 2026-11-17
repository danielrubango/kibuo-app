import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/first_launch_store.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/transactions/search.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/choice_tile.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/create_pin_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Shows the guided first launch on a new app, then [child] (PRODUCT). Also
/// applies the language chosen in kibuo when Android does not keep it.
class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key, required this.child});

  final Widget child;

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  KibuoDatabase? _db;
  bool? _needed;
  int _step = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = KibuoData.maybeOf(context);
    if (db == null || db == _db) return;
    _db = db;
    _check(db);
  }

  Future<void> _check(KibuoDatabase db) async {
    final store = FirstLaunchStore(db);
    final language = await store.language();
    if (language != null) appLanguageChoice.value = Locale(language);
    final needed = await store.needed();
    final step = needed ? await store.step() : 1;
    if (mounted) {
      setState(() {
        _needed = needed;
        _step = step;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = _db;
    if (db == null) return widget.child;
    return switch (_needed) {
      null => const ColoredBox(color: KibuoColors.background),
      false => widget.child,
      true => FirstLaunchFlow(
        db: db,
        step: _step,
        onDone: () => setState(() => _needed = false),
      ),
    };
  }
}

/// The four steps (canvas Lancement1 to Lancement4): language, main
/// currency, first account, protection. Android's back goes one step back.
class FirstLaunchFlow extends StatefulWidget {
  const FirstLaunchFlow({
    super.key,
    required this.db,
    required this.step,
    required this.onDone,
  });

  final KibuoDatabase db;
  final int step;
  final VoidCallback onDone;

  @override
  State<FirstLaunchFlow> createState() => _FirstLaunchFlowState();
}

class _FirstLaunchFlowState extends State<FirstLaunchFlow> {
  late int _step = widget.step;
  late final _store = FirstLaunchStore(widget.db);
  late final _accounts = AccountRepository(widget.db);
  late final _currencies = CurrencyRepository(widget.db);

  Future<void> _go(int step) async {
    await _store.reached(step);
    if (mounted) setState(() => _step = step);
  }

  Future<void> _finish() async {
    await _store.finish();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back: the step before; from the first, Android closes kibuo.
      canPop: _step == 1 || _step == 4,
      onPopInvokedWithResult: (popped, _) {
        if (!popped && _step > 1) _go(_step - 1);
      },
      child: switch (_step) {
        1 => _LanguageStep(store: _store, onNext: () => _go(2)),
        2 => _CurrencyStep(currencies: _currencies, onNext: () => _go(3)),
        3 => _accountStep(context),
        _ => _ProtectionStep(onStart: _finish),
      },
    );
  }

  Widget _accountStep(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AccountFormScreen(
      accounts: _accounts,
      currencies: _currencies,
      intro: _StepIntro(
        step: 3,
        title: l.firstAccountTitle,
        text: l.firstAccountText,
      ),
      action: l.firstContinue,
      onCreated: (_) => _go(4),
    );
  }
}

/// « Étape 2 sur 4 », the title and its line (canvas Lancement2).
class _StepIntro extends StatelessWidget {
  const _StepIntro({
    required this.step,
    required this.title,
    required this.text,
  });

  final int step;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepTitle(step: l.firstStep(step, 4), title: title),
        const SizedBox(height: 8),
        Text(
          text,
          style: KibuoType.body.copyWith(
            fontSize: 15,
            height: 22 / 15,
            color: KibuoColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

/// A step's page: its content, then its button at the bottom.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.children,
    required this.action,
    required this.onAction,
    this.top = 32,
  });

  final List<Widget> children;
  final String action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KibuoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, top, 24, 16),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              // « J'ai une sauvegarde » comes under it with restoring
              // (ROADMAP, phase 6).
              child: KibuoButton(label: action, onPressed: onAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 1 (canvas Lancement1): the logo, « Bienvenue sur kibuo », and the
/// language, the phone's being chosen first. Choosing it changes kibuo's
/// language at once.
class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.store, required this.onNext});

  final FirstLaunchStore store;
  final VoidCallback onNext;

  static const _names = {'fr': 'Français', 'en': 'English'};

  Future<void> _pick(String code) async {
    appLanguageChoice.value = Locale(code);
    // Android 13+ keeps it, and kibuo then follows Android's setting.
    final android = await setAndroidAppLanguage(code);
    await store.setLanguage(android ? null : code);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = Localizations.localeOf(context).languageCode;
    return _StepPage(
      top: 64,
      action: l.firstContinue,
      onAction: onNext,
      children: [
        const Align(alignment: Alignment.centerLeft, child: _AppIcon()),
        const SizedBox(height: 32),
        Text(
          l.firstWelcome,
          style: KibuoType.highlight.copyWith(fontSize: 32, height: 38 / 32),
        ),
        const SizedBox(height: 8),
        Text(
          l.firstWelcomeText,
          style: KibuoType.body.copyWith(
            fontSize: 16,
            height: 24 / 16,
            color: KibuoColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l.firstLanguage,
          style: KibuoType.rowLabel.copyWith(
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation.weight(600)],
          ),
        ),
        const SizedBox(height: 12),
        for (final language in appLanguages) ...[
          ChoiceTile(
            label: _names[language.languageCode]!,
            chosen: language.languageCode == now,
            onTap: () => _pick(language.languageCode),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// kibuo's icon: the logo on its night square (canvas Lancement1).
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: KibuoColors.ink,
        borderRadius: BorderRadius.circular(88 * 22 / 96),
      ),
      child: const CustomPaint(painter: KibuoMarkPainter()),
    );
  }
}

/// Step 2 (canvas Lancement2): the currencies of the phone's country, the
/// search over all of them, its own currency chosen first.
class _CurrencyStep extends StatefulWidget {
  const _CurrencyStep({required this.currencies, required this.onNext});

  final CurrencyRepository currencies;
  final VoidCallback onNext;

  @override
  State<_CurrencyStep> createState() => _CurrencyStepState();
}

class _CurrencyStepState extends State<_CurrencyStep> {
  String? _country;
  String? _code;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final country = await deviceCountry();
    final code =
        await widget.currencies.primaryCurrency() ??
        defaultPrimaryCurrency(country);
    if (mounted) {
      setState(() {
        _country = country;
        _code = code;
      });
    }
  }

  Future<void> _next() async {
    final code = _code;
    if (code == null) return;
    await widget.currencies.setPrimaryCurrency(code);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lists = currenciesForChoosing(countryCode: _country);
    final q = SearchQuery.parse(_query);
    final chosen = _code == null ? null : currencyOf(_code!);
    final shown = q.isEmpty
        ? [
            ...lists.top,
            if (chosen != null && !lists.top.contains(chosen)) chosen,
          ]
        : [
            for (final c in [...lists.top, ...lists.rest])
              if (q.find(c.code) != null ||
                  q.find(c.nameFr) != null ||
                  q.find(c.nameEn) != null)
                c,
          ];
    return _StepPage(
      action: l.firstContinue,
      onAction: _code == null ? null : _next,
      children: [
        _StepIntro(
          step: 2,
          title: l.firstCurrencyTitle,
          text: l.firstCurrencyText,
        ),
        const SizedBox(height: 20),
        KibuoTextField(
          label: l.firstCurrencySearch,
          hint: l.firstCurrencySearchHint,
          textCapitalization: TextCapitalization.none,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 14),
        for (final c in shown) ...[
          ChoiceTile(
            label: currencyName(context, c),
            code: c.code,
            chosen: c.code == _code,
            onTap: () => setState(() => _code = c.code),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Step 4 (canvas Lancement4): « Verrouiller l'application », then
/// « Commencer », which creates the code first when it is on. Automatic
/// backups join it with the backups (ROADMAP, phase 6).
class _ProtectionStep extends StatefulWidget {
  const _ProtectionStep({required this.onStart});

  final Future<void> Function() onStart;

  @override
  State<_ProtectionStep> createState() => _ProtectionStepState();
}

class _ProtectionStepState extends State<_ProtectionStep> {
  bool _lock = false;
  bool _read = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Left while the code was being made: the lock is already on.
    if (_read) return;
    _read = true;
    _lock = KibuoLock.maybeControllerOf(context)?.hasPin ?? false;
  }

  Future<void> _start() async {
    final lock = KibuoLock.maybeControllerOf(context);
    if (!_lock && lock != null && lock.hasPin) await lock.removePin();
    if (!mounted) return;
    if (_lock && lock != null && !lock.hasPin) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CreatePinScreen(controller: lock)),
      );
      // Given up on the way: the choice stays to be made.
      if (!lock.hasPin) return;
    }
    await widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _StepPage(
      action: l.firstStart,
      onAction: _start,
      children: [
        _StepIntro(
          step: 4,
          title: l.firstProtectTitle,
          text: l.firstProtectText,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.firstLockTitle, style: KibuoType.itemName),
                    const SizedBox(height: 4),
                    Text(
                      l.firstLockHelp,
                      style: KibuoType.body.copyWith(
                        height: 20 / 14,
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _lock,
                onChanged: (on) => setState(() => _lock = on),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.firstLater,
            style: KibuoType.body.copyWith(
              height: 20 / 14,
              color: KibuoColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
