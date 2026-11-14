import 'package:flutter/material.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/pin_pad.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// Creates (or changes) the code: 4 to 6 digits then « Valider », typed
/// again to confirm, then the fingerprint is offered when the phone has one.
/// Pops with true once the code is saved.
class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key, required this.controller});

  final LockController controller;

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _entry = '';
  String? _first;
  bool _mismatch = false;
  int _seed = DateTime.now().microsecondsSinceEpoch;

  bool get _confirming => _first != null;

  Future<void> _digit(String d) async {
    final first = _first;
    final entry = _entry + d;
    if (first != null && entry.length == first.length) {
      if (entry == first) {
        await widget.controller.setPin(entry);
        if (!mounted) return;
        await _done();
      } else {
        setState(() {
          _first = null;
          _entry = '';
          _mismatch = true;
          _seed++;
        });
      }
      return;
    }
    if (entry.length > 6) return;
    setState(() {
      _entry = entry;
      _mismatch = false;
    });
  }

  void _validate() {
    if (!isValidPin(_entry)) return;
    setState(() {
      _first = _entry;
      _entry = '';
      _seed++;
    });
  }

  Future<void> _done() async {
    final lock = widget.controller;
    if (lock.biometricsAvailable && !lock.settings.fingerprint) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FingerprintOfferScreen(controller: lock),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final first = _first;
    return PinLayout(
      appBar: AppBar(title: Text(l.lockCreateTitle)),
      top: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            _confirming ? l.lockConfirm : l.lockChoose,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Text(
              _mismatch
                  ? l.lockMismatch
                  : _confirming
                  ? l.lockConfirmHint
                  : l.lockChooseHint,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: _mismatch
                    ? KibuoColors.danger
                    : KibuoColors.inkSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          PinBoxes(
            count: first?.length ?? 6,
            firm: first?.length ?? 4,
            filled: _entry.length,
          ),
        ],
      ),
      keypad: PinKeypad(
        shuffle: widget.controller.settings.shuffle,
        layoutSeed: _seed,
        onDigit: _digit,
        onDelete: () => setState(
          () => _entry = _entry.isEmpty
              ? ''
              : _entry.substring(0, _entry.length - 1),
        ),
      ),
      button: _confirming
          ? null
          : FilledButton(
              onPressed: isValidPin(_entry) ? _validate : null,
              child: Text(l.lockValidate),
            ),
    );
  }
}

/// Offered right after the code is created.
class FingerprintOfferScreen extends StatelessWidget {
  const FingerprintOfferScreen({super.key, required this.controller});

  final LockController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: KibuoColors.accentTintStrong,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 36,
                  color: KibuoColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.fingerprintOfferTitle,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l.fingerprintOfferBody,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = await controller.biometrics.authenticate(
                      l.fingerprintReason,
                    );
                    if (ok) {
                      await controller.updateSettings(
                        controller.settings.copyWith(fingerprint: true),
                      );
                    }
                    if (ok && context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(l.fingerprintEnable),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: KibuoColors.inkSecondary,
                ),
                child: Text(l.later),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
