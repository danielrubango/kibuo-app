import 'package:flutter/material.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « 20:00 »: a time of day in minutes after midnight.
String timeOfDayText(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

/// Plus › « Rappels et alertes » (canvas Rappels): for now, « Noter mes
/// opérations » and its time. Android's leave is asked at the first switch
/// turned on, never at start (PRODUCT: Rappels).
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({
    super.key,
    required this.store,
    required this.notifier,
    required this.onChanged,
  });

  final ReminderStore store;
  final Notifier notifier;

  /// The reminders are scheduled again.
  final Future<void> Function() onChanged;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  bool? _on;
  int _minute = ReminderStore.defaultEntryMinute;
  bool _dueOn = false;
  int _dueDays = ReminderStore.defaultDueDays;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from Android's settings: the leave may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final on = await widget.store.entryOn();
    final minute = await widget.store.entryMinute();
    final allowed = await widget.notifier.allowed();
    final dueOn = await widget.store.dueOn();
    final dueDays = await widget.store.dueDays();
    if (!mounted) return;
    setState(() {
      _on = on && allowed;
      _minute = minute;
      // On by default, but only once Android allows it.
      _dueOn = dueOn && allowed;
      _dueDays = dueDays;
      _blocked = _blocked && !allowed;
    });
  }

  Future<void> _switch(bool on) async {
    if (on && !await widget.notifier.allowed()) {
      final yes = await widget.notifier.ask();
      if (!yes) {
        if (mounted) setState(() => _blocked = true);
        return;
      }
    }
    await widget.store.setEntryOn(on);
    if (mounted) {
      setState(() {
        _on = on;
        _blocked = false;
      });
    }
    await widget.onChanged();
  }

  Future<void> _switchDue(bool on) async {
    if (on && !await widget.notifier.allowed()) {
      final yes = await widget.notifier.ask();
      if (!yes) {
        if (mounted) setState(() => _blocked = true);
        return;
      }
    }
    await widget.store.setDueOn(on);
    if (mounted) {
      setState(() {
        _dueOn = on;
        _blocked = false;
      });
    }
    await widget.onChanged();
  }

  Future<void> _pickDelay() async {
    final l = AppLocalizations.of(context);
    final picked = await showKibuoSheet<int>(
      context,
      title: l.remindersDelay,
      builder: (context) => SettingsCard(
        children: [
          for (final days in ReminderStore.dueChoices)
            CheckChoice(
              label: l.daysBefore(days),
              help: '',
              on: days == _dueDays,
              onTap: () => Navigator.of(context).pop(days),
            ),
        ],
      ),
    );
    if (picked == null || picked == _dueDays) return;
    await widget.store.setDueDays(picked);
    if (mounted) setState(() => _dueDays = picked);
    await widget.onChanged();
  }

  Future<void> _pickTime() async {
    final l = AppLocalizations.of(context);
    final picked = await showKibuoSheet<int>(
      context,
      title: l.remindersTimeTitle,
      builder: (context) => _TimePicker(minute: _minute),
    );
    if (picked == null || picked == _minute) return;
    await widget.store.setEntryMinute(picked);
    if (mounted) setState(() => _minute = picked);
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = _on;
    return Scaffold(
      appBar: AppBar(title: Text(l.remindersTitle)),
      body: on == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                const SizedBox(height: GroupTitle.before),
                GroupTitle(title: l.remindersEntryGroup),
                SettingsCard(
                  children: [
                    SettingsSwitch(
                      label: l.remindersEntry,
                      help: _blocked
                          ? l.remindersBlocked
                          : on
                          ? l.remindersEntryHelp(timeOfDayText(_minute))
                          : l.remindersEntryOffHelp,
                      value: on,
                      onChanged: _switch,
                    ),
                    if (on)
                      SettingsRow(
                        label: l.remindersTime,
                        value: timeOfDayText(_minute),
                        onTap: _pickTime,
                      ),
                  ],
                ),
                const SizedBox(height: GroupTitle.before),
                GroupTitle(title: l.remindersDueGroup),
                SettingsCard(
                  children: [
                    SettingsSwitch(
                      label: l.remindersDue,
                      help: _dueOn
                          ? l.remindersDueHelp(_dueDays)
                          : l.remindersDueOffHelp,
                      value: _dueOn,
                      onChanged: _switchDue,
                    ),
                    if (_dueOn)
                      SettingsRow(
                        label: l.remindersDelay,
                        value: l.daysBefore(_dueDays),
                        onTap: _pickDelay,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                HelpText(l.remindersRuleNote),
                if (_blocked) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextAction(
                      label: l.remindersOpenSettings,
                      onPressed: widget.notifier.openSettings,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// A wheel of times, every quarter of an hour, then « Enregistrer ».
class _TimePicker extends StatefulWidget {
  const _TimePicker({required this.minute});

  final int minute;

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  static const _row = 44.0;
  static const _step = 15;
  late int _index = widget.minute ~/ _step;
  late final _wheel = FixedExtentScrollController(initialItem: _index);

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 5 * _row,
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                top: 2 * _row,
                height: _row,
                child: Container(
                  decoration: BoxDecoration(
                    color: KibuoColors.background,
                    borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _wheel,
                itemExtent: _row,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _index = i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24 * 60 ~/ _step,
                  builder: (context, i) => Center(
                    child: Text(
                      timeOfDayText(i * _step),
                      style: i == _index
                          ? KibuoType.body.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontVariations: const [FontVariation.weight(700)],
                            )
                          : KibuoType.body.copyWith(
                              fontSize: 17,
                              color: KibuoColors.inkSecondary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KibuoButton(
          label: l.remindersTimeSave,
          onPressed: () => Navigator.of(context).pop(_index * _step),
        ),
      ],
    );
  }
}
