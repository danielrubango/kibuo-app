import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/segmented_tabs.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/recurrences/repeat_screen.dart';
import 'package:kibuo/ui/recurrences/rhythm_text.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/attachment_viewer.dart';
import 'package:kibuo/ui/transactions/attachments_card.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';
import 'package:uuid/uuid.dart';

/// The repositories an entry needs.
class EntryData {
  const EntryData({
    required this.accounts,
    required this.categories,
    required this.currencies,
    required this.transactions,
    required this.attachments,
    this.picker = const DeviceAttachmentPicker(),
    this.opener = const DeviceAttachmentOpener(),
    this.recurrences,
    this.reminders,
  });

  final AccountRepository accounts;
  final CategoryRepository categories;
  final CurrencyRepository currencies;
  final TransactionRepository transactions;
  final AttachmentRepository attachments;
  final AttachmentPicker picker;
  final AttachmentOpener opener;

  /// Where « Répéter » keeps its recurrences; without it, no « Répéter ».
  final RecurringRepository? recurrences;

  /// The reminders' settings: a recurrence's own « Rappel ».
  final ReminderStore? reminders;
}

/// What the entry pops when it planned instead of saving (PRODUCT): not
/// an operation's id.
String plannedResult(String ruleId) => 'planned:$ruleId';

/// Opens [item] in the viewer.
Future<void> viewAttachment(
  BuildContext context,
  EntryData data,
  AttachmentInfo item,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => AttachmentViewer(
      item: item,
      read: data.attachments.read,
      opener: data.opener,
    ),
  ),
);

/// « Nouvelle dépense » / « Nouveau revenu » (canvas: ParcoursUSD to
/// RevenuDecompte): the amount and the currency paid, the account, the
/// category, the date, the fees and a note. With [editing], « Modifier la
/// dépense »; with [initial] only, a copy to save as new. Pops the saved
/// operation's id.
class EntryScreen extends StatefulWidget {
  const EntryScreen({
    super.key,
    required this.data,
    required this.kind,
    this.initial,
    this.editing = false,
    this.now,
    this.accountId,
    this.rule,
    this.ruleOnly = false,
  });

  /// The account to start on (the one just created).
  final String? accountId;

  final EntryData data;
  final EntryKind kind;
  final TransactionInfo? initial;
  final bool editing;
  final DateTime Function()? now;

  /// Only a recurrence (« Nouvelle récurrence » from Récurrences, or its
  /// « Modifier » with [rule]): « Date » becomes « Première fois », and
  /// saving keeps the recurrence alone.
  final bool ruleOnly;
  final RecurringInfo? rule;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late EntryKind _kind = widget.initial?.kind ?? widget.kind;
  List<AccountInfo> _accounts = const [];
  List<CustomAccountType> _types = const [];
  List<CategoryInfo> _categories = const [];
  AccountInfo? _account;
  CurrencyInfo? _accountCurrency;
  CurrencyInfo? _paidCurrency;
  CategoryInfo? _category;

  // A transfer's receiving account (none chosen at first: PRODUCT).
  AccountInfo? _to;
  CurrencyInfo? _toCurrency;
  ExchangeRate? _today;
  String _typed = '';
  String _fees = '';
  bool _rateTyped = false;
  String _rateText = '';
  late DateTime _date;
  RepeatChoice? _repeat;
  final _note = TextEditingController();
  bool _keypad = true;
  final _amountKey = GlobalKey();
  bool _open = false;

  // Attachments: added under a draft id until « Enregistrer » (PRODUCT);
  // those of an edited operation are taken away only then too.
  final _draft = 'draft-${const Uuid().v7()}';
  List<AttachmentInfo> _attachments = const [];
  final _drafts = <String>{};
  final _leaving = <String>{};
  final _chosen = <String>{};
  String? _attachError;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _date = widget.editing && initial != null ? initial.date.toLocal() : _now();
    final rule = widget.rule;
    if (rule != null) {
      final s = rule.schedule;
      final next = rule.upcoming(_now(), count: 1);
      _date = next.isEmpty ? s.start : next.first;
      _repeat = RepeatChoice(
        unit: s.unit,
        start: _date,
        every: s.every,
        weekdays: s.weekdays,
        end: s.count != null
            ? RepeatEnd.count
            : s.until != null
            ? RepeatEnd.date
            : RepeatEnd.never,
        count: s.count ?? 6,
        until: s.until,
        asDraft: rule.asDraft ?? false,
      );
    }
    _note.text = initial?.note ?? '';
    _keypad = initial == null;
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = widget.data;
    final accounts = await data.accounts.accounts();
    final types = await data.accounts.types();
    final initial = widget.initial;
    final account =
        accounts
            .where((a) => a.id == (initial?.accountId ?? widget.accountId))
            .firstOrNull ??
        (accounts.isEmpty ? null : accounts.first);
    final categories = await data.categories.categories(_kind.category);
    CategoryInfo? category;
    if (initial != null) {
      for (final c in categories) {
        if (c.id == initial.categoryId) category = c;
        for (final s in c.subs) {
          if (s.id == initial.categoryId) category = s;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _types = types;
      _categories = categories;
      _category = category;
    });
    await _loadAttachments();
    await _setAccount(account, paid: initial?.paid.currency);
    final to = accounts.where((a) => a.id == initial?.toAccountId).firstOrNull;
    if (to != null) await _setTo(to);
    if (initial != null && mounted) {
      final paid = await data.currencies.currency(initial.paid.currency);
      setState(() {
        _typed = typedFrom(initial.paid, paid);
        _fees = initial.total.fees.minor == 0
            ? ''
            : typedFrom(initial.total.fees, _accountCurrency!);
        _rateTyped = initial.rateTyped;
        _rateText = initial.rateTyped
            ? initial.rate!.value.toString().replaceAll('.', ',')
            : '';
      });
    }
  }

  Future<void> _loadAttachments() async {
    final repo = widget.data.attachments;
    final initial = widget.initial;
    final own = widget.editing && initial != null
        ? await repo.list(initial.id)
        : <AttachmentInfo>[];
    final drafts = await repo.list(_draft);
    if (!mounted) return;
    setState(() {
      _attachments = [
        for (final a in own)
          if (!_leaving.contains(a.id)) a,
        ...drafts,
      ];
    });
  }

  Future<void> _addAttachment() async {
    final l = AppLocalizations.of(context);
    final source = await pickAttachmentSource(context);
    if (source == null) return;
    final picked = await widget.data.picker.pick(source);
    if (picked == null || !mounted) return;
    if (picked.bytes.length > AttachmentRepository.maxBytes) {
      setState(() => _attachError = l.attachTooBig);
      return;
    }
    final photos = _attachments
        .where((a) => a.kind == AttachmentKind.photo)
        .length;
    final id = await widget.data.attachments.add(
      transactionId: _draft,
      bytes: picked.bytes,
      name: picked.name ?? l.attachPhotoName(photos + 1),
      kind: picked.kind,
    );
    _drafts.add(id);
    setState(() => _attachError = null);
    await _loadAttachments();
  }

  Future<void> _removeChosen() async {
    for (final id in _chosen) {
      if (_drafts.remove(id)) {
        await widget.data.attachments.remove(id);
      } else {
        _leaving.add(id);
      }
    }
    _chosen.clear();
    await _loadAttachments();
  }

  Future<void> _setAccount(AccountInfo? account, {String? paid}) async {
    if (account == null) return;
    final currencies = widget.data.currencies;
    final accountCurrency = await currencies.currency(account.currency);
    final paidCurrency = await currencies.currency(paid ?? account.currency);
    if (!mounted) return;
    setState(() {
      _account = account;
      _accountCurrency = accountCurrency;
      _paidCurrency = paidCurrency;
      _fees = '';
    });
    await _loadToday();
  }

  Future<void> _setTo(AccountInfo to) async {
    final currency = await widget.data.currencies.currency(to.currency);
    if (!mounted) return;
    setState(() {
      _to = to;
      _toCurrency = currency;
      _rateTyped = false;
      _rateText = '';
    });
    await _loadToday();
  }

  bool get _transfer => _kind == EntryKind.transfer;

  /// The currency the amount is converted into or from: the one paid for an
  /// expense or income, the receiving account's for a transfer.
  CurrencyInfo? get _otherCurrency => _transfer ? _toCurrency : _paidCurrency;

  Future<void> _loadToday() async {
    final account = _accountCurrency;
    final paid = _otherCurrency;
    if (account == null || paid == null || account.code == paid.code) {
      setState(() => _today = null);
      return;
    }
    final (base, quote) = rateDirection(main: account, other: paid);
    // A saved operation keeps the rate it was converted at (« Une conversion
    // passée ne change jamais »), as long as its two currencies are the same.
    final saved = widget.initial?.rate;
    if (widget.editing &&
        saved != null &&
        {saved.base, saved.quote}.containsAll({account.code, paid.code})) {
      setState(() => _today = saved.toward(base, quote));
      return;
    }
    final info = await widget.data.currencies.latestRate(
      account.code,
      paid.code,
    );
    if (mounted) {
      setState(() {
        _today = info?.rate.toward(base, quote);
        if (_today == null) _rateTyped = true;
      });
    }
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  bool get _converts =>
      _otherCurrency != null &&
      _accountCurrency != null &&
      _otherCurrency!.code != _accountCurrency!.code;

  (String, String) get _direction =>
      rateDirection(main: _accountCurrency!, other: _otherCurrency!);

  ExchangeRate? get _rate {
    if (!_converts) return null;
    if (!_rateTyped) return _today;
    final value = RateValue.tryParse(_rateText);
    if (value == null) return null;
    final (base, quote) = _direction;
    return ExchangeRate(base: base, quote: quote, value: value);
  }

  Money? get _paid {
    final c = _paidCurrency;
    if (c == null) return null;
    return typedMoney(_typed, c);
  }

  int get _feesMinor =>
      _fees.isEmpty ? 0 : typedMoney(_fees, _accountCurrency!).minor;

  TransferTotal? get _transferTotal {
    final sent = _paid;
    final to = _toCurrency;
    if (!_transfer || sent == null || to == null) return null;
    if (_converts && _rate == null) return null;
    return transferTotal(sent: sent, to: to, rate: _rate, fees: _feesMinor);
  }

  EntryTotal? get _total {
    final paid = _paid;
    final account = _accountCurrency;
    if (_transfer || paid == null || account == null) return null;
    if (_converts && _rate == null) return null;
    return entryTotal(
      kind: _kind,
      paid: paid,
      account: account,
      rate: _rate,
      fees: _fees.isEmpty ? 0 : typedMoney(_fees, account).minor,
    );
  }

  /// When the change would take an account below its floor (PRODUCT:
  /// Découvert), what to say.
  OverdraftRefusal? get _refusal {
    // Planned: the floor is checked on the day itself (PRODUCT).
    if (_later) return null;
    final account = _account;
    final paid = _paid;
    if (account == null || paid == null || paid.minor == 0) return null;
    final Map<String, int> after;
    if (_transfer) {
      final moved = _transferTotal;
      after = {
        account.id: -(paid.minor + _feesMinor),
        if (moved != null && _to != null) _to!.id: moved.arrived.minor,
      };
    } else {
      final total = _total;
      if (total == null) return null;
      after = {account.id: total.balanceChange};
    }
    // A draft counted nothing yet: there is nothing to undo.
    final initial = widget.editing && widget.initial?.counts == true
        ? widget.initial
        : null;
    return checkOverdraft(
      accounts: _accounts,
      after: after,
      date: _date.toUtc(),
      before: initial == null ? const {} : effectsOf(initial),
      beforeDate: initial?.date,
    );
  }

  /// « Autoriser » opens the account's form, then the entry carries on.
  Future<void> _authorize(AccountInfo account) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          accounts: widget.data.accounts,
          currencies: widget.data.currencies,
          account: account,
          categories: widget.data.categories,
          transactions: widget.data.transactions,
        ),
      ),
    );
    final accounts = await widget.data.accounts.accounts();
    if (!mounted) return;
    AccountInfo? fresh(AccountInfo? a) =>
        a == null ? null : accounts.where((x) => x.id == a.id).firstOrNull;
    setState(() {
      _accounts = accounts;
      _account = fresh(_account) ?? _account;
      _to = fresh(_to);
    });
  }

  bool get _canSave =>
      (widget.ruleOnly ? _repeat != null : _refusal == null) &&
      (_paid?.minor ?? 0) > 0 &&
      _account != null &&
      (_transfer
          ? _to != null && _transferTotal != null
          : _category != null && _total != null);

  String _money(Money m) => formatMoney(
    m,
    m.currency == _accountCurrency?.code
        ? _accountCurrency!
        : m.currency == _otherCurrency?.code
        ? _otherCurrency!
        : currencyOf(m.currency),
    _lang,
  );

  Future<void> _switchKind(EntryKind kind) async {
    if (kind == _kind) return;
    if (kind == EntryKind.transfer) {
      // Two accounts first (PRODUCT), then back to this entry.
      if (!await transferAccountsReady(context, widget.data)) return;
      final accounts = await widget.data.accounts.accounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _kind = kind;
        _category = null;
        _rateTyped = false;
        _rateText = '';
      });
      // Sent in the sending account's currency.
      await _setAccount(_account ?? accounts.first);
      return;
    }
    final categories = await widget.data.categories.categories(kind.category);
    if (!mounted) return;
    setState(() {
      _kind = kind;
      _categories = categories;
      _category = null;
      _to = null;
      _toCurrency = null;
    });
    await _loadToday();
  }

  Future<void> _chooseAccount() async {
    final picked = await pickAccount(
      context,
      accounts: _accounts,
      current: _account?.id,
    );
    if (picked == null) return;
    // The two accounts of a transfer differ.
    if (picked.id == _to?.id) {
      setState(() {
        _to = null;
        _toCurrency = null;
      });
    }
    await _setAccount(picked);
  }

  Future<void> _chooseTo() async {
    final l = AppLocalizations.of(context);
    final picked = await pickAccount(
      context,
      accounts: [
        for (final a in _accounts)
          if (a.id != _account?.id) a,
      ],
      current: _to?.id,
      question: l.transferToQuestion,
    );
    if (picked != null) await _setTo(picked);
  }

  Future<void> _choosePaidCurrency() async {
    final account = _account;
    final accountCurrency = _accountCurrency;
    if (account == null || accountCurrency == null) return;
    final mine = await widget.data.currencies.currencyCodes();
    if (!mounted) return;
    final code = await pickPaidCurrency(
      context,
      income: _kind == EntryKind.income,
      accountName: account.name,
      account: accountCurrency,
      others: [
        for (final c in mine)
          if (c != accountCurrency.code) c,
      ],
      current: _paidCurrency?.code ?? accountCurrency.code,
    );
    if (code == null || code == _paidCurrency?.code) return;
    final paid = await widget.data.currencies.currency(code);
    setState(() {
      _paidCurrency = paid;
      _typed = '';
      _rateTyped = false;
      _rateText = '';
    });
    await _loadToday();
  }

  Future<void> _chooseCategory() async {
    final picked = await pickCategory(
      context,
      categories: _categories,
      current: _category?.id,
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _chooseRate() async {
    final l = AppLocalizations.of(context);
    final paid = _paid;
    if (paid == null) return;
    final (base, quote) = _direction;
    final choice = await pickEntryRate(
      context,
      income: _kind == EntryKind.income,
      paidLabel: _transfer ? l.transferSent : null,
      paid: _money(paid),
      base: base,
      quote: quote,
      today: _today,
      current: RateChoice(typed: _rateTyped, value: _rateText),
    );
    if (choice != null) {
      setState(() {
        _rateTyped = choice.typed;
        _rateText = choice.value ?? '';
      });
    }
  }

  Future<void> _chooseFees() async {
    final account = _accountCurrency;
    if (account == null) return;
    final fees = await pickFees(context, account: account, current: _fees);
    if (fees != null) setState(() => _fees = fees == '0' ? '' : fees);
  }

  /// A new operation may be dated later: it is then planned, a
  /// recurrence of a single time (PRODUCT: À reprendre).
  bool get _canPlan =>
      !widget.ruleOnly && !widget.editing && widget.data.recurrences != null;

  /// Dated after today: planned, not saved as an operation.
  bool get _later {
    if (!_canPlan) return false;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(
      _date.year,
      _date.month,
      _date.day,
    ).isBefore(today.add(const Duration(days: 1)));
  }

  Future<void> _chooseDate() async {
    final now = _now();
    final day = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.ruleOnly
          ? DateTime(now.year, now.month, now.day)
          : DateTime(2000),
      // A recurrence may start later, and a new operation be planned.
      lastDate: widget.ruleOnly || _canPlan ? DateTime(now.year + 5) : now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    var picked = DateTime(
      day.year,
      day.month,
      day.day,
      time?.hour ?? _date.hour,
      time?.minute ?? _date.minute,
    );
    // A saved operation never moves into the future.
    if (!widget.ruleOnly && !_canPlan && picked.isAfter(now)) picked = now;
    setState(() {
      _date = picked;
      _repeat = _repeat?.copyWith(start: picked);
    });
  }

  /// « Répéter » (canvas RepeterA): opens « Nouvelle récurrence ».
  Future<void> _chooseRepeat() async {
    final l = AppLocalizations.of(context);
    final paid = _paid;
    final account = _account;
    final answer = await Navigator.of(context).push<RepeatAnswer>(
      MaterialPageRoute(
        builder: (_) => RepeatScreen(
          start: _date,
          initial: _repeat,
          facts: [
            if (paid != null && paid.minor > 0) (l.entryAmount, _money(paid)),
            if (account != null) (l.entryAccount, account.name),
            if (_transfer && _to != null)
              (l.transferTo, _to!.name)
            else if (_category != null)
              (l.entryCategory, categoryName(l, _category!)),
          ],
        ),
      ),
    );
    if (answer != null && mounted) setState(() => _repeat = answer.choice);
  }

  /// Keeps « Répéter »'s recurrence: from this entry ([firstMade]), or on
  /// its own.
  Future<String> _saveRule({String? firstMade}) async {
    final repo = widget.data.recurrences!;
    final r = _repeat!;
    final s = r.schedule;
    final args = (
      kind: _kind,
      accountId: _account!.id,
      toAccountId: _transfer ? _to?.id : null,
      categoryId: _transfer ? null : _category?.id,
      amount: _paid!,
      fees: _feesMinor,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    final rule = widget.rule;
    if (rule != null) {
      await repo.update(
        rule.id,
        kind: args.kind,
        accountId: args.accountId,
        toAccountId: args.toAccountId,
        categoryId: args.categoryId,
        amount: args.amount,
        fees: args.fees,
        note: args.note,
        unit: s.unit,
        every: s.every,
        weekdays: s.weekdays,
        start: _date,
        endCount: s.count,
        endDate: s.until,
        asDraft: r.asDraft ? true : null,
      );
      return rule.id;
    }
    return repo.create(
      kind: args.kind,
      accountId: args.accountId,
      toAccountId: args.toAccountId,
      categoryId: args.categoryId,
      amount: args.amount,
      fees: args.fees,
      note: args.note,
      unit: s.unit,
      every: s.every,
      weekdays: s.weekdays,
      start: _date,
      endCount: s.count,
      endDate: s.until,
      asDraft: r.asDraft ? true : null,
      firstMade: firstMade,
    );
  }

  Future<void> _save() async {
    if (widget.ruleOnly) {
      final id = await _saveRule();
      // A first time today or before is made at once.
      await widget.data.recurrences!.catchUp(_now());
      if (mounted) Navigator.of(context).pop(id);
      return;
    }
    if (_later) return _plan();
    final paid = _paid!;
    final repo = widget.data.transactions;
    final fees = _feesMinor;
    final initial = widget.initial;
    final String id;
    if (_transfer && widget.editing && initial != null) {
      id = initial.id;
      await repo.updateTransfer(
        id,
        fromId: _account!.id,
        toId: _to!.id,
        sent: paid,
        rate: _rate,
        rateTyped: _rateTyped,
        fees: fees,
        date: _date,
        note: _note.text,
      );
    } else if (_transfer) {
      id = await repo.createTransfer(
        fromId: _account!.id,
        toId: _to!.id,
        sent: paid,
        rate: _rate,
        rateTyped: _rateTyped,
        fees: fees,
        date: _date,
        note: _note.text,
      );
    } else if (widget.editing && initial != null) {
      id = initial.id;
      await repo.update(
        id,
        kind: _kind,
        accountId: _account!.id,
        categoryId: _category!.id,
        paid: paid,
        rate: _rate,
        rateTyped: _rateTyped,
        fees: fees,
        date: _date,
        note: _note.text,
      );
    } else {
      id = await repo.create(
        kind: _kind,
        accountId: _account!.id,
        categoryId: _category!.id,
        paid: paid,
        rate: _rate,
        rateTyped: _rateTyped,
        fees: fees,
        date: _date,
        note: _note.text,
      );
    }
    // « Répéter »: this operation is the recurrence's first time.
    if (_repeat != null && !widget.editing) await _saveRule(firstMade: id);
    // A draft's entry: saving validates it too (PRODUCT).
    if (widget.editing && initial != null && !initial.counts) {
      await repo.validate(id);
    }
    await _finish(id);
  }

  /// Dated later: a recurrence (one time, or as « Répéter » says), shown
  /// « Prévu » until its day, when it arrives like any recurrence.
  Future<void> _plan() async {
    final l = AppLocalizations.of(context);
    final String rule;
    if (_repeat != null) {
      rule = await _saveRule();
    } else {
      rule = await widget.data.recurrences!.create(
        kind: _kind,
        accountId: _account!.id,
        toAccountId: _transfer ? _to?.id : null,
        categoryId: _transfer ? null : _category?.id,
        amount: _paid!,
        fees: _feesMinor,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        unit: RepeatUnit.day,
        start: _date,
        endCount: 1,
      );
    }
    if (!mounted) return;
    showKibuoToast(
      context,
      l.entryPlannedToast(DateFormat.MMMMd(_lang).format(_date)),
    );
    Navigator.of(context).pop(plannedResult(rule));
  }

  /// Gives the attachments to the saved operation [id], then closes.
  Future<void> _finish(String id) async {
    final attachments = widget.data.attachments;
    final drafts = (await attachments.list(_draft)).map((a) => a.id).toList();
    await attachments.attach(drafts, id);
    for (final leaving in _leaving) {
      await attachments.remove(leaving);
    }
    if (mounted) Navigator.of(context).pop(id);
  }

  String _dateText(AppLocalizations l) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(_date.year, _date.month, _date.day);
    if (day == today) return l.entryToday;
    if (day == today.subtract(const Duration(days: 1))) {
      return l.entryYesterday;
    }
    final text = DateFormat.MMMMEEEEd(_lang).format(_date);
    return text[0].toUpperCase() + text.substring(1);
  }

  /// The transfer's details (canvas TransfertDecompte): sent, rate and what
  /// arrives when the currencies differ, then the fees.
  List<(String, String, String?, VoidCallback?)> _transferLines(
    AppLocalizations l,
    TransferTotal? moved,
  ) => [
    if (_converts && _paid != null) ...[
      (l.transferSent, _money(_paid!), null, null),
      (
        l.entryRateFor(currencyOf(_direction.$1).symbol),
        _rate == null
            ? l.entryChoose
            : formatRate(_rate!, _lang).split(' = ').last,
        _rateTyped ? l.entryRateTypedTag : l.entryRateTodayTag,
        _chooseRate,
      ),
      if (moved != null)
        (l.transferArrives(_to?.name ?? ''), _money(moved.arrived), null, null),
    ],
    (
      l.entryFees,
      moved == null || moved.fees.minor == 0
          ? l.entryNone
          : '+ ${_money(moved.fees)}',
      null,
      _chooseFees,
    ),
  ];

  /// De, Vers, Date and Frais (canvas TransfertMeme): no category.
  List<Widget> _transferFields(AppLocalizations l, AccountInfo? account) {
    final labels = AccountTypeLabels(l, _types);
    final moved = _transferTotal;
    return [
      EntryField(
        icon: account == null ? KibuoIcons.wallet : labels.icon(account.type),
        label: l.transferFrom,
        value: account?.name,
        placeholder: l.entryChoose,
        trailing: account?.currency,
        onTap: _chooseAccount,
      ),
      EntryField(
        icon: _to == null ? KibuoIcons.wallet : labels.icon(_to!.type),
        label: l.transferTo,
        value: _to?.name,
        placeholder: l.entryChoose,
        trailing: _to?.currency,
        onTap: _chooseTo,
      ),
      EntryField(
        icon: KibuoIcons.calendarBlank,
        label: l.entryDate,
        value: _dateText(l),
        trailing: DateFormat.Hm(_lang).format(_date),
        onTap: _chooseDate,
      ),
      EntryField(
        icon: KibuoIcons.receipt,
        label: l.entryFees,
        value: moved == null || moved.fees.minor == 0
            ? null
            : _money(moved.fees),
        placeholder: l.entryNone,
        onTap: _chooseFees,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final expense = _kind == EntryKind.expense;
    final title = widget.ruleOnly
        ? (widget.rule == null ? l.recurrenceNew : l.recurrenceEdit)
        : switch ((_kind, widget.editing)) {
            (EntryKind.expense, false) => l.entryNewExpense,
            (EntryKind.expense, true) => l.entryEditExpense,
            (EntryKind.income, false) => l.entryNewIncome,
            (EntryKind.income, true) => l.entryEditIncome,
            (EntryKind.transfer, false) => l.entryNewTransfer,
            (EntryKind.transfer, true) => l.entryEditTransfer,
          };
    final repeatField = widget.data.recurrences == null || widget.editing
        ? null
        : EntryField(
            icon: KibuoIcons.repeat,
            label: l.repeatTitle,
            value: _repeat == null
                ? null
                : rhythmText(l, _lang, _repeat!.schedule),
            valueColor: KibuoColors.accent,
            placeholder: l.repeatNever,
            onTap: _chooseRepeat,
          );
    final account = _account;
    final total = _total;
    final moved = _transferTotal;
    final categoryText = _category == null
        ? null
        : _category!.parentId == null
        ? categoryName(l, _category!)
        : '${categoryName(l, _categories.firstWhere((c) => c.id == _category!.parentId))} › '
              '${categoryName(l, _category!)}';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(title: title, cancel: l.cancel),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  SegmentedTabs(
                    items: [
                      (EntryKind.expense, l.entryExpense),
                      (EntryKind.income, l.entryIncome),
                      (EntryKind.transfer, l.entryTransfer),
                    ],
                    value: _kind,
                    onPick: _switchKind,
                  ),
                  const SizedBox(height: 12),
                  _AmountCard(
                    key: _amountKey,
                    kind: _kind,
                    value: shownTyped(context, _typed),
                    unit: _paidCurrency?.symbol ?? '',
                    focused: _keypad,
                    onTap: () {
                      // The phone's keyboard gives way to Kibuo's.
                      FocusScope.of(context).unfocus();
                      setState(() => _keypad = true);
                      revealAboveKeypad(_amountKey);
                    },
                    // A transfer is sent in its account's currency.
                    onUnitTap: _transfer ? null : _choosePaidCurrency,
                    footLabel: _transfer
                        ? l.transferTakenFrom(account?.name ?? '')
                        : expense
                        ? l.entryTakenFrom
                        : l.entryAddedTo,
                    // What leaves the account is known before « Vers ».
                    footValue: _transfer
                        ? (_paid == null
                              ? ''
                              : _money(
                                  Money(
                                    _paid!.minor + _feesMinor,
                                    _paid!.currency,
                                  ),
                                ))
                        : total == null
                        ? ''
                        : _money(total.total),
                    open: _open,
                    onToggle: () => setState(() => _open = !_open),
                    lines: _transfer
                        ? _transferLines(l, moved)
                        : [
                            if (_converts && _paid != null) ...[
                              (
                                expense ? l.entryPaid : l.entryReceived,
                                _money(_paid!),
                                null,
                                null,
                              ),
                              (
                                l.entryRateFor(
                                  currencyOf(_direction.$1).symbol,
                                ),
                                _rate == null
                                    ? l.entryChoose
                                    : formatRate(
                                        _rate!,
                                        _lang,
                                      ).split(' = ').last,
                                _rateTyped
                                    ? l.entryRateTypedTag
                                    : l.entryRateTodayTag,
                                _chooseRate,
                              ),
                              if (total != null)
                                (
                                  l.entrySo,
                                  _money(total.converted),
                                  null,
                                  null,
                                ),
                            ],
                            (
                              l.entryFees,
                              total == null || total.fees.minor == 0
                                  ? l.entryNone
                                  : '${expense ? '+' : '−'} ${_money(total.fees)}',
                              null,
                              _chooseFees,
                            ),
                          ],
                  ),
                  if (_refusal case final refusal?) ...[
                    const SizedBox(height: 8),
                    RefusalLine(
                      text: refusal.account.id == account?.id
                          ? l.overdraftAvailable(
                              _money(refusal.available),
                              refusal.account.name,
                            )
                          : l.overdraftWouldGo(
                              refusal.account.name,
                              _money(refusal.after),
                            ),
                      action: l.overdraftAuthorize,
                      onAction: () => _authorize(refusal.account),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _FieldsCard(
                    children: _transfer
                        ? [..._transferFields(l, account), ?repeatField]
                        : [
                            EntryField(
                              icon: account == null
                                  ? KibuoIcons.wallet
                                  : AccountTypeLabels(
                                      l,
                                      _types,
                                    ).icon(account.type),
                              label: l.entryAccount,
                              value: account?.name,
                              placeholder: l.entryChoose,
                              trailing: account?.currency,
                              onTap: _chooseAccount,
                            ),
                            EntryField(
                              leading: _category == null
                                  ? null
                                  : CategoryTile(
                                      category: _category!,
                                      size: 32,
                                    ),
                              icon: KibuoIcons.tag,
                              label: l.entryCategory,
                              value: categoryText,
                              placeholder: l.entryChoose,
                              onTap: _chooseCategory,
                            ),
                            EntryField(
                              icon: KibuoIcons.calendarBlank,
                              label: widget.ruleOnly
                                  ? l.repeatFirst
                                  : l.entryDate,
                              value: _dateText(l),
                              trailing: DateFormat.Hm(_lang).format(_date),
                              onTap: _chooseDate,
                            ),
                            EntryField(
                              icon: KibuoIcons.receipt,
                              label: l.entryFees,
                              value: total == null || total.fees.minor == 0
                                  ? null
                                  : _money(total.fees),
                              placeholder: l.entryNone,
                              onTap: _chooseFees,
                            ),
                            ?repeatField,
                          ],
                  ),
                  // A planned operation has no attachment until its day.
                  if (!_later) const SizedBox(height: 12),
                  if (!_later)
                    AttachmentsCard(
                      items: _attachments,
                      preview: widget.data.attachments.read,
                      selected: _chosen,
                      onToggle: (id) => setState(
                        () => _chosen.contains(id)
                            ? _chosen.remove(id)
                            : _chosen.add(id),
                      ),
                      onAdd: _addAttachment,
                      onOpen: (a) => viewAttachment(context, widget.data, a),
                      error: _attachError,
                    ),
                  const SizedBox(height: 12),
                  _NoteCard(
                    label: l.entryNote,
                    hint: l.entryNoteHint,
                    controller: _note,
                    onFocus: () => setState(() => _keypad = false),
                  ),
                ],
              ),
            ),
            if (_chosen.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: AttachmentSelectionBar(
                  count: _chosen.length,
                  onClear: () => setState(_chosen.clear),
                  onRemove: _removeChosen,
                  onView: () => viewAttachment(
                    context,
                    widget.data,
                    _attachments.firstWhere((a) => a.id == _chosen.single),
                  ),
                ),
              )
            else if (_keypad)
              KeypadPanel(
                keypad: KibuoKeypad(
                  onKey: (k) => setState(() {
                    final c = _paidCurrency;
                    if (c == null) return;
                    _typed = typeKey(
                      _typed,
                      k,
                      decimals: c.usesDecimals ? c.digits : 0,
                    );
                  }),
                  onDelete: () => setState(() {
                    if (_typed.isNotEmpty) {
                      _typed = _typed.substring(0, _typed.length - 1);
                    }
                  }),
                  allowDecimal: _paidCurrency?.usesDecimals ?? true,
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
                  label: widget.editing || widget.rule != null
                      ? l.entrySaveChanges
                      : l.entrySave,
                  onPressed: _canSave ? _save : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on EntryKind {
  CategoryKind get category =>
      this == EntryKind.expense ? CategoryKind.out : CategoryKind.into;
}

/// The big amount, tinted by its meaning, and what it does to the account;
/// touching that line unrolls the details (paid, rate, converted, fees).
class _AmountCard extends StatelessWidget {
  const _AmountCard({
    super.key,
    required this.kind,
    required this.value,
    required this.unit,
    required this.focused,
    required this.onTap,
    required this.onUnitTap,
    required this.footLabel,
    required this.footValue,
    required this.open,
    required this.onToggle,
    required this.lines,
  });

  final EntryKind kind;
  final String value;
  final String unit;
  final bool focused;
  final VoidCallback onTap;

  /// None when the currency can't change (a transfer).
  final VoidCallback? onUnitTap;
  final String footLabel;
  final String footValue;
  final bool open;
  final VoidCallback onToggle;

  /// Label, value, tag, and what touching the line does.
  final List<(String, String, String?, VoidCallback?)> lines;

  @override
  Widget build(BuildContext context) {
    // Peach for an expense, mint for an income, blue for a transfer, which
    // neither earns nor spends (canvas TransfertMeme).
    final (:tint, :edge, :ink) = kindColors(kind);
    final sign = switch (kind) {
      EntryKind.expense => '−',
      EntryKind.income => '+',
      EntryKind.transfer => '',
    };
    return Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        border: Border.all(color: edge, width: 1.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$sign${value.isEmpty ? '0' : value}',
                              style: KibuoType.bigAmount.copyWith(
                                color: value.isEmpty
                                    ? KibuoColors.inkMuted
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        if (focused) const BlinkingCaret(height: 30),
                      ],
                    ),
                  ),
                  CurrencyPill(
                    text: unit,
                    onTap: onUnitTap,
                    background: edge,
                    foreground: ink,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: edge, indent: 14, endIndent: 14),
          if (open)
            for (final (label, text, tag, onLine) in lines)
              _Line(label: label, value: text, tag: tag, onTap: onLine),
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      footLabel,
                      style: KibuoType.body.copyWith(
                        fontWeight: open ? FontWeight.w700 : null,
                        fontVariations: open
                            ? const [FontVariation.weight(700)]
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    footValue,
                    style: KibuoType.buttonSmall.copyWith(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    open ? KibuoIcons.caretUp : KibuoIcons.caretDown,
                    size: 14,
                    color: ink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.tag, this.onTap});

  final String label;
  final String value;
  final String? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: KibuoType.body)),
            if (tag != null) ...[
              Text(
                tag!,
                style: KibuoType.caption.copyWith(
                  color: KibuoColors.accent,
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation.weight(600)],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              value,
              style: KibuoType.body.copyWith(
                fontWeight: FontWeight.w600,
                fontVariations: const [FontVariation.weight(600)],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(KibuoIcons.caretRight, size: 14),
            ] else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 56,
                endIndent: 14,
                color: KibuoColors.background,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// A field of an operation (DIRECTION): an icon tile, the label in small
/// above the value, the extra information on the right.
class EntryField extends StatelessWidget {
  const EntryField({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.placeholder,
    this.trailing,
    this.leading,
    this.onTap,
    this.valueColor,
  });

  final IconData icon;
  final Widget? leading;

  /// The value's colour once set (« Répéter » in green).
  final Color? valueColor;
  final String label;
  final String? value;
  final String? placeholder;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: KibuoColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: KibuoColors.inkSecondary),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: KibuoType.caption),
                  Text(
                    value ?? placeholder ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.rowLabel.copyWith(
                      fontWeight: value == null ? null : FontWeight.w600,
                      fontVariations: value == null
                          ? null
                          : const [FontVariation.weight(600)],
                      color: value == null ? KibuoColors.inkMuted : valueColor,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: KibuoType.caption.copyWith(fontSize: 13)),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  KibuoIcons.caretRight,
                  size: 16,
                  color: KibuoColors.inkMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onFocus,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                KibuoIcons.list,
                size: 14,
                color: KibuoColors.inkSecondary,
              ),
              const SizedBox(width: 8),
              Text(label, style: KibuoType.caption),
            ],
          ),
          // Focus, not only a tap: Kibuo's keypad closes whatever way the
          // note takes the focus.
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (on) {
              if (on) onFocus();
            },
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              style: KibuoType.body.copyWith(fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: KibuoType.body.copyWith(
                  fontSize: 15,
                  color: KibuoColors.inkMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
