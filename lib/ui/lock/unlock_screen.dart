import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kibuo/data/pin_store.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/lock/forgot_sheet.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/pin_pad.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// Asks for the code. Used to open Kibuo, and to confirm the current code
/// before changing or removing it ([confirmOnly]).
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.controller,
    required this.onUnlocked,
    this.confirmOnly = false,
  });

  final LockController controller;
  final VoidCallback onUnlocked;
  final bool confirmOnly;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  String _entry = '';
  int _seed = DateTime.now().microsecondsSinceEpoch;
  int? _failures;
  DateTime? _lockedUntil;
  Timer? _tick;
  bool _checking = false;

  LockController get _lock => widget.controller;

  @override
  void initState() {
    super.initState();
    _refreshLockout();
    // Fingerprint first, when it is on; the code stays one tap away.
    if (!widget.confirmOnly && _lock.fingerprintOn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useFingerprint());
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refreshLockout() async {
    final until = await _lock.pins.lockedUntil();
    if (!mounted) return;
    setState(() => _lockedUntil = until);
    _tick?.cancel();
    if (until != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!DateTime.now().isBefore(until)) {
          _tick?.cancel();
          setState(() => _lockedUntil = null);
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _useFingerprint() async {
    final ok = await _lock.biometrics.authenticate(
      AppLocalizations.of(context).fingerprintReason,
    );
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _digit(String d) async {
    if (_checking || _lockedUntil != null) return;
    final entry = _entry + d;
    if (entry.length < _lock.pinLength) {
      setState(() => _entry = entry);
      return;
    }
    setState(() {
      _entry = entry;
      _checking = true;
    });
    final result = await _lock.pins.check(entry);
    if (!mounted) return;
    switch (result) {
      case PinAccepted():
        widget.onUnlocked();
      case PinRejected(:final failures):
        setState(() {
          _failures = failures;
          _entry = '';
          _seed++;
        });
      case PinLockedOut():
        setState(() {
          _entry = '';
          _seed++;
        });
        await _refreshLockout();
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final until = _lockedUntil;
    final waiting = until != null;
    final (title, sub, subColor) = waiting
        ? (
            l.lockTooMany,
            l.lockRetryIn(formatWait(until.difference(DateTime.now()))),
            KibuoColors.warningInk,
          )
        : _failures != null
        ? (
            widget.confirmOnly ? l.lockCurrentTitle : l.lockEnterTitle,
            l.lockWrong(_failures!),
            KibuoColors.danger,
          )
        : (
            widget.confirmOnly ? l.lockCurrentTitle : l.lockEnterTitle,
            '',
            KibuoColors.inkSecondary,
          );

    return PopScope(
      canPop: widget.confirmOnly,
      child: PinLayout(
        appBar: widget.confirmOnly ? AppBar() : null,
        top: Column(
          children: [
            if (!widget.confirmOnly) ...[
              const SizedBox(height: 40),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: KibuoColors.ink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const CustomPaint(painter: KibuoMarkPainter()),
              ),
              const SizedBox(height: 12),
            ],
            Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: Text(
                sub,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: subColor),
              ),
            ),
            const SizedBox(height: 12),
            PinBoxes(
              count: _lock.pinLength,
              filled: _entry.length,
              greyed: waiting,
            ),
            const SizedBox(height: 8),
            if (_lock.fingerprintOn)
              TextButton(
                onPressed: _useFingerprint,
                child: Text(l.lockUseFingerprint),
              ),
            if (!widget.confirmOnly)
              TextButton(
                onPressed: () => showForgotSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: KibuoColors.inkSecondary,
                ),
                child: Text(l.lockForgot),
              ),
          ],
        ),
        keypad: PinKeypad(
          shuffle: _lock.settings.shuffle,
          layoutSeed: _seed,
          enabled: !waiting && !_checking,
          onDigit: _digit,
          onDelete: () => setState(
            () => _entry = _entry.isEmpty
                ? ''
                : _entry.substring(0, _entry.length - 1),
          ),
        ),
      ),
    );
  }
}
