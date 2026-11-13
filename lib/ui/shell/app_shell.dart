import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/screens/placeholders.dart';
import 'package:kibuo/ui/shell/add_choice.dart';
import 'package:kibuo/ui/shell/add_sheet.dart';
import 'package:kibuo/ui/shell/plus_fan.dart';
import 'package:kibuo/ui/shell/tab_icons.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

enum _Tab { home, operations, overview, more }

/// The four tabs, the floating bottom bar and the + button.
///
/// Tap + for the « Ajouter » sheet; hold it for the fan, slide to a choice
/// and lift the finger. Back from another tab returns to Accueil.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Tab _tab = _Tab.home;
  bool _fanOpen = false;
  AddChoice? _hovered;
  final _plusKey = GlobalKey();

  Offset get _plusCenter {
    final box = _plusKey.currentContext!.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == _Tab.home && !_fanOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_fanOpen) {
            _closeFan();
          } else {
            _tab = _Tab.home;
          }
        });
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    TabPlaceholder(
                      key: const ValueKey('screen-home'),
                      title: AppLocalizations.of(context).homeTitle,
                      icon: PlaceholderIcons.home,
                      message: AppLocalizations.of(context).homePlaceholder,
                    ),
                    TabPlaceholder(
                      key: const ValueKey('screen-operations'),
                      title: AppLocalizations.of(context).tabOperations,
                      icon: PlaceholderIcons.operations,
                      message: AppLocalizations.of(context)
                          .operationsPlaceholder,
                    ),
                    TabPlaceholder(
                      key: const ValueKey('screen-overview'),
                      title: AppLocalizations.of(context).tabOverview,
                      icon: PlaceholderIcons.overview,
                      message: AppLocalizations.of(context).overviewPlaceholder,
                    ),
                    TabPlaceholder(
                      key: const ValueKey('screen-more'),
                      title: AppLocalizations.of(context).tabMore,
                      icon: PlaceholderIcons.more,
                      message: AppLocalizations.of(context).morePlaceholder,
                    ),
                  ],
                ),
              ),
            ),
            const _BottomFade(),
            _BottomBar(
              current: _tab,
              plusKey: _plusKey,
              onTab: (tab) => setState(() => _tab = tab),
              onPlusTap: _openSheet,
              onPlusHoldStart: _openFan,
              onPlusHoldMove: _hover,
              onPlusHoldEnd: _release,
            ),
            if (_fanOpen)
              Positioned.fill(
                child: PlusFan(
                  plusCenter: _plusCenter,
                  hovered: _hovered,
                  onPick: _pickFromFan,
                  onClose: () => setState(_closeFan),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet() async {
    final choice = await showAddSheet(context);
    if (choice != null && mounted) await _openEntry(choice);
  }

  void _openFan() {
    HapticFeedback.mediumImpact();
    setState(() {
      _fanOpen = true;
      _hovered = null;
    });
  }

  void _closeFan() {
    _fanOpen = false;
    _hovered = null;
  }

  void _hover(Offset finger) {
    final width = MediaQuery.sizeOf(context).width;
    final under = PlusFan.choiceAt(finger, _plusCenter, width);
    if (under == _hovered) return;
    if (under != null) HapticFeedback.selectionClick();
    setState(() => _hovered = under);
  }

  /// Lifting on a choice opens it; lifting elsewhere leaves the fan open so
  /// the user can tap.
  void _release(Offset finger) {
    final width = MediaQuery.sizeOf(context).width;
    final under = PlusFan.choiceAt(finger, _plusCenter, width);
    if (under != null) {
      _pickFromFan(under);
    } else {
      setState(() => _hovered = null);
    }
  }

  void _pickFromFan(AddChoice choice) {
    setState(_closeFan);
    _openEntry(choice);
  }

  Future<void> _openEntry(AddChoice choice) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryPlaceholder(choice: choice),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Fades the content out just above the bar, so white cards never touch it.
class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 132 + bottom,
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.62],
              colors: [Color(0x00EEF1F7), KibuoColors.background],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.current,
    required this.plusKey,
    required this.onTab,
    required this.onPlusTap,
    required this.onPlusHoldStart,
    required this.onPlusHoldMove,
    required this.onPlusHoldEnd,
  });

  final _Tab current;
  final GlobalKey plusKey;
  final ValueChanged<_Tab> onTab;
  final VoidCallback onPlusTap;
  final VoidCallback onPlusHoldStart;
  final ValueChanged<Offset> onPlusHoldMove;
  final ValueChanged<Offset> onPlusHoldEnd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget tab(_Tab t, String label, TabGlyph glyph) => Expanded(
      child: _TabButton(
        label: label,
        glyph: glyph,
        selected: current == t,
        onTap: () => onTab(t),
      ),
    );

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12 + bottom,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KibuoColors.track),
          boxShadow: [
            BoxShadow(
              color: KibuoColors.ink.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            tab(_Tab.home, AppLocalizations.of(context).tabHome, TabGlyph.home),
            tab(
              _Tab.operations,
              AppLocalizations.of(context).tabOperations,
              TabGlyph.operations,
            ),
            Expanded(
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxHeight: 140,
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: _PlusButton(
                    key: plusKey,
                    onTap: onPlusTap,
                    onHoldStart: onPlusHoldStart,
                    onHoldMove: onPlusHoldMove,
                    onHoldEnd: onPlusHoldEnd,
                  ),
                ),
              ),
            ),
            tab(
              _Tab.overview,
              AppLocalizations.of(context).tabOverview,
              TabGlyph.overview,
            ),
            tab(_Tab.more, AppLocalizations.of(context).tabMore, TabGlyph.more),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final TabGlyph glyph;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? KibuoColors.accent : KibuoColors.inkSecondary;
    // No ripple: the drawn icon is the feedback.
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KibuoTabIcon(glyph: glyph, active: selected),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The + button. A tap presses it in, it bounces back, then the sheet opens.
class _PlusButton extends StatefulWidget {
  const _PlusButton({
    super.key,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldMove,
    required this.onHoldEnd,
  });

  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final ValueChanged<Offset> onHoldMove;
  final ValueChanged<Offset> onHoldEnd;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _tap() {
    if (!MediaQuery.disableAnimationsOf(context)) _press.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).plusButton,
      hint: AppLocalizations.of(context).plusButtonHint,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _tap,
        onLongPressStart: (_) => widget.onHoldStart(),
        onLongPressMoveUpdate: (d) => widget.onHoldMove(d.globalPosition),
        onLongPressEnd: (d) => widget.onHoldEnd(d.globalPosition),
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            // The button presses in, then bounces back.
            final t = Curves.easeOut.transform(_press.value);
            final scale = switch (t) {
              < .3 => lerpDouble(1, .86, t / .3)!,
              < .65 => lerpDouble(.86, 1.08, (t - .3) / .35)!,
              _ => lerpDouble(1.08, 1, (t - .65) / .35)!,
            };
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: KibuoColors.mint,
              borderRadius: BorderRadius.circular(20),
              // The ring of page colour that makes the button stand out.
              boxShadow: const [
                BoxShadow(color: KibuoColors.background, spreadRadius: 5),
              ],
            ),
            child: const Icon(
              KibuoIcons.plusBold,
              size: 28,
              color: KibuoColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
