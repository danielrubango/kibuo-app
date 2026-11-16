import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kibuo/data/pin_store.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/pin_pad.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Before an important action, once its confirmation sheet said yes: the
/// code or the fingerprint, when « Code pour les actions importantes » is on
/// (PRODUCT). True when the action may go on.
Future<bool> confirmWithCode(BuildContext context, String reason) async {
  final lock = KibuoLock.maybeControllerOf(context);
  if (lock == null || !lock.protectsActions) return true;
  final ok = await showKibuoSheet<bool>(
    context,
    title: AppLocalizations.of(context).protectTitle,
    builder: (_) => _ProtectSheet(lock: lock, reason: reason),
  );
  return ok ?? false;
}

/// Canvas ProtectionCodeB: the reason, the boxes, « Utiliser l'empreinte »
/// and the lock's own keypad, with its waits after wrong codes.
class _ProtectSheet extends StatefulWidget {
  const _ProtectSheet({required this.lock, required this.reason});

  final LockController lock;
  final String reason;

  @override
  State<_ProtectSheet> createState() => _ProtectSheetState();
}

class _ProtectSheetState extends State<_ProtectSheet> {
  String _entry = '';
  int _seed = DateTime.now().microsecondsSinceEpoch;
  int? _failures;
  DateTime? _lockedUntil;
  Timer? _tick;
  bool _checking = false;

  LockController get _lock => widget.lock;

  @override
  void initState() {
    super.initState();
    _refreshLockout();
    // Fingerprint first, when it is on; the code stays right there.
    if (_lock.fingerprintOn) {
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
    if (until == null) return;
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

  Future<void> _useFingerprint() async {
    final ok = await _lock.biometrics.authenticate(widget.reason);
    if (ok && mounted) Navigator.of(context).pop(true);
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
        Navigator.of(context).pop(true);
        return;
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
    final until = _lockedUntil;
    final waiting = until != null;
    final (line, color) = waiting
        ? (
            l.lockRetryIn(formatWait(until.difference(DateTime.now()))),
            KibuoColors.warningInk,
          )
        : _failures != null
        ? (l.lockWrong(_failures!), KibuoColors.danger)
        : (widget.reason, KibuoColors.inkSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(line, style: KibuoType.help.copyWith(color: color)),
        const SizedBox(height: 16),
        Center(
          child: PinBoxes(
            count: _lock.pinLength,
            filled: _entry.length,
            greyed: waiting,
          ),
        ),
        const SizedBox(height: 8),
        if (_lock.fingerprintOn)
          Center(
            child: TextButton(
              onPressed: _useFingerprint,
              child: Text(l.lockUseFingerprint),
            ),
          ),
        const SizedBox(height: 8),
        PinKeypad(
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
      ],
    );
  }
}
