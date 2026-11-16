import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/domain/lock/recovery_code.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Shows a new [code], then asks to retype one group drawn at random.
/// True once the user has proved they wrote it down.
Future<bool> handOverRecoveryCode(BuildContext context, String code) async {
  final proved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => RecoveryShowScreen(code: code)),
  );
  return proved ?? false;
}

/// « Notez votre code de récupération ».
class RecoveryShowScreen extends StatelessWidget {
  const RecoveryShowScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.recoveryTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.recoveryShowTitle, style: text.headlineSmall),
              const SizedBox(height: 12),
              Text(l.recoveryShowBody, style: text.bodyLarge),
              const SizedBox(height: 24),
              _CodeCard(code: code),
              const SizedBox(height: 12),
              Text(
                l.recoveryShowWarning,
                style: text.bodyMedium?.copyWith(color: KibuoColors.warningInk),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  final proved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => RecoveryProofScreen(
                        code: code,
                        group: Random.secure().nextInt(4) + 1,
                      ),
                    ),
                  );
                  if ((proved ?? false) && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: Text(l.recoveryNoted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = recoveryGroups(code);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        children: [
          Semantics(
            label: formatRecoveryCode(code),
            excludeSemantics: true,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [for (final g in groups) _Group(text: g)],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: formatRecoveryCode(code)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.recoveryCopied)));
              }
            },
            icon: const Icon(KibuoIcons.copy, size: 18),
            label: Text(l.recoveryCopy),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KibuoColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: KibuoTheme.displayFont,
          fontVariations: [FontVariation.weight(600)],
          fontSize: 24,
          letterSpacing: 3,
          color: KibuoColors.ink,
        ),
      ),
    );
  }
}

/// « Retapez le groupe 3 ».
class RecoveryProofScreen extends StatefulWidget {
  const RecoveryProofScreen({
    super.key,
    required this.code,
    required this.group,
  });

  final String code;

  /// 1 to 4.
  final int group;

  @override
  State<RecoveryProofScreen> createState() => _RecoveryProofScreenState();
}

class _RecoveryProofScreenState extends State<RecoveryProofScreen> {
  final _field = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _check() {
    final expected = recoveryGroups(widget.code)[widget.group - 1];
    if (normalizeRecoveryCode(_field.text) == expected) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.recoveryTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Text(
                l.recoveryProofTitle(widget.group),
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _wrong ? l.recoveryProofWrong : l.recoveryProofBody,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: _wrong ? KibuoColors.danger : KibuoColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var g = 1; g <= 4; g++) ...[
                    if (g > 1) const SizedBox(width: 8),
                    if (g == widget.group)
                      _GroupField(
                        controller: _field,
                        autofocus: true,
                        error: _wrong,
                        onChanged: (_) => setState(() => _wrong = false),
                        onSubmitted: (_) => _check(),
                      )
                    else
                      const _GroupPlaceholder(),
                  ],
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ListenableBuilder(
                  listenable: _field,
                  builder: (context, _) => FilledButton(
                    onPressed: normalizeRecoveryCode(_field.text).length == 4
                        ? _check
                        : null,
                    child: Text(l.lockValidate),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: KibuoColors.inkSecondary,
                ),
                child: Text(l.recoverySeeAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupPlaceholder extends StatelessWidget {
  const _GroupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KibuoColors.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '····',
        style: TextStyle(color: KibuoColors.lineStrong),
      ),
    );
  }
}

/// One box of 4 characters, uppercase, without dashes.
class _GroupField extends StatelessWidget {
  const _GroupField({
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    this.error = false,
    this.onChanged,
    this.onSubmitted,
    this.maxLength = 4,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );
    return SizedBox(
      width: 72,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.visiblePassword,
        inputFormatters: [
          _Upper(),
          FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
          LengthLimitingTextInputFormatter(maxLength),
        ],
        style: const TextStyle(
          fontFamily: KibuoTheme.displayFont,
          fontVariations: [FontVariation.weight(600)],
          fontSize: 18,
          letterSpacing: 1.5,
          color: KibuoColors.ink,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: KibuoColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          counterText: '',
          enabledBorder: border(
            error ? KibuoColors.danger : KibuoColors.lineStrong,
          ),
          focusedBorder: border(
            error ? KibuoColors.danger : KibuoColors.accent,
          ),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _Upper extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// « Saisissez votre code de récupération »: 4 boxes; a pasted code fills
/// them all. [onCode] says whether the code was right.
class RecoveryEntryScreen extends StatefulWidget {
  const RecoveryEntryScreen({super.key, required this.onCode});

  final Future<bool> Function(String code) onCode;

  @override
  State<RecoveryEntryScreen> createState() => _RecoveryEntryScreenState();
}

class _RecoveryEntryScreenState extends State<RecoveryEntryScreen> {
  final _fields = List.generate(4, (_) => TextEditingController());
  final _focus = List.generate(4, (_) => FocusNode());
  bool _wrong = false;
  bool _checking = false;

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _fields.map((f) => f.text).join();

  void _changed(int i, String value) {
    setState(() => _wrong = false);
    if (value.length == 4 && i < 3) _focus[i + 1].requestFocus();
  }

  Future<void> _open() async {
    setState(() => _checking = true);
    final ok = await widget.onCode(_code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _checking = false;
        _wrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final complete = isRecoveryCode(normalizeRecoveryCode(_code));
    return Scaffold(
      appBar: AppBar(title: Text(l.recoveryTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: KibuoColors.accentTintStrong,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(KibuoIcons.key, color: KibuoColors.accent),
              ),
              const SizedBox(height: 12),
              Text(
                l.recoveryEnterTitle,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _wrong ? l.recoveryWrong : l.recoveryEnterBody,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: _wrong ? KibuoColors.danger : KibuoColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _GroupField(
                      controller: _fields[i],
                      focusNode: _focus[i],
                      autofocus: i == 0,
                      error: _wrong,
                      // The first box takes a whole pasted code.
                      maxLength: i == 0 ? 19 : 4,
                      onChanged: (v) {
                        if (i == 0 && v.length > 4) {
                          final groups = recoveryGroups(
                            normalizeRecoveryCode(v),
                          );
                          for (var g = 0; g < 4; g++) {
                            _fields[g].text = g < groups.length
                                ? groups[g]
                                : '';
                          }
                          setState(() => _wrong = false);
                          return;
                        }
                        _changed(i, v);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(l.recoveryEnterHint, style: text.bodySmall),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: complete && !_checking ? _open : null,
                  child: _checking
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.recoveryOpen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sécurité › Code de récupération.
class RecoverySettingsScreen extends StatelessWidget {
  const RecoverySettingsScreen({super.key, required this.lock});

  final LockController lock;

  Future<void> _newCode(BuildContext context) async {
    if (lock.hasPin) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (routeContext) => UnlockScreen(
            controller: lock,
            confirmOnly: true,
            onUnlocked: () => Navigator.of(routeContext).pop(true),
          ),
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    final code = await lock.newRecoveryCode();
    if (context.mounted) await handOverRecoveryCode(context, code);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: lock,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final text = Theme.of(context).textTheme;
      final created = lock.recoveryCreatedAt;
      final s = lock.settings;
      return Scaffold(
        appBar: AppBar(title: Text(l.recoveryTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (created == null) ...[
              HelpText(l.recoveryCreateHelp),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _newCode(context),
                child: Text(l.recoveryCreate),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KibuoColors.surface,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: KibuoColors.accentTintStrong,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        KibuoIcons.key,
                        color: KibuoColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.recoveryNotedOn(
                              formatRecoveryDate(context, created),
                            ),
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(l.recoveryNotKept, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SettingsCard(
                children: [
                  SettingsRow(
                    label: l.recoveryNew,
                    onTap: () => _newCode(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HelpText(l.recoveryNewHelp),
              const SizedBox(height: 24),
              SettingsCard(
                children: [
                  SettingsSwitch(
                    label: l.recoveryAndroidCopy,
                    value: s.androidCopy,
                    onChanged: (on) =>
                        lock.updateSettings(s.copyWith(androidCopy: on)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HelpText(l.recoveryAndroidCopyHelp),
            ],
          ],
        ),
      );
    },
  );
}

/// « 15 nov. 2026 » in the app's language.
String formatRecoveryDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(date.toLocal());
