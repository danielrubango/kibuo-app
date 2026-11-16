import 'package:flutter/material.dart';

/// A row that scrolls sideways when it is too long, its edges fading over
/// 32 where more is hidden (canvas ListeOperations, the filter chips).
class FadingRow extends StatefulWidget {
  const FadingRow({super.key, required this.children, this.spacing = 8});

  final List<Widget> children;
  final double spacing;

  @override
  State<FadingRow> createState() => _FadingRowState();
}

class _FadingRowState extends State<FadingRow> {
  static const _fade = 32.0;
  final _scroll = ScrollController();
  double _left = 0;
  double _right = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_measure);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final left = p.pixels.clamp(0.0, _fade);
    final right = (p.maxScrollExtent - p.pixels).clamp(0.0, _fade);
    if (left != _left || right != _right) {
      setState(() {
        _left = left;
        _right = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        return false;
      },
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final w = rect.width <= 0 ? 1.0 : rect.width;
          return LinearGradient(
            colors: const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            stops: [0, _left / w, 1 - _right / w, 1],
          ).createShader(rect);
        },
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, child) in widget.children.indexed) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
