import 'dart:async';

import 'package:flutter/material.dart';

/// One line of text that, when cut, slides slowly to its end and comes
/// back (owner, 23 November): a pause, the slide at reading speed, a pause
/// at the end, a fade back to the start, a longer pause, again. A line
/// that fits, or a phone asking for fewer animations, stays still, cut
/// by « … ».
class ScrollingLine extends StatefulWidget {
  const ScrollingLine(this.text, {super.key, required this.style, this.runs});

  final String text;
  final TextStyle style;

  /// How many times it slides before staying at its start; none, always.
  final int? runs;

  /// Points per second: a quiet reading pace.
  static const speed = 30.0;
  static const startPause = Duration(milliseconds: 1500);
  static const endPause = Duration(milliseconds: 1500);
  static const againPause = Duration(seconds: 3);
  static const fade = Duration(milliseconds: 250);

  @override
  State<ScrollingLine> createState() => _ScrollingLineState();
}

class _ScrollingLineState extends State<ScrollingLine> {
  final _scroll = ScrollController();
  Timer? _timer;
  bool _visible = true;
  bool _running = false;
  int _done = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    _running = true;
    _wait(ScrollingLine.startPause, _slide);
  }

  void _wait(Duration d, VoidCallback then) {
    _timer?.cancel();
    _timer = Timer(d, () {
      if (mounted) then();
    });
  }

  Future<void> _slide() async {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    await _scroll.animateTo(
      end,
      duration: Duration(
        milliseconds: (end / ScrollingLine.speed * 1000).round(),
      ),
      curve: Curves.linear,
    );
    if (!mounted) return;
    _wait(ScrollingLine.endPause, _back);
  }

  void _back() {
    setState(() => _visible = false);
    _wait(ScrollingLine.fade, () {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      setState(() => _visible = true);
      _done++;
      final runs = widget.runs;
      if (runs != null && _done >= runs) return;
      _wait(ScrollingLine.againPause, _slide);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Measured as it is drawn: the page's text style under this one.
      final style = DefaultTextStyle.of(context).style.merge(widget.style);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final fits = painter.width <= box.maxWidth;
      final still = MediaQuery.disableAnimationsOf(context);
      if (fits || still) {
        return Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
      return AnimatedOpacity(
        duration: ScrollingLine.fade,
        opacity: _visible ? 1 : 0,
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Text(widget.text, style: widget.style, maxLines: 1),
        ),
      );
    },
  );
}
