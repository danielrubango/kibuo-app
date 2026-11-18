import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  testWidgets('a group: 14 between groups, 8 under the title, centred', (
    tester,
  ) async {
    Widget card(String key) => SizedBox(
      key: Key(key),
      height: 64,
      child: const ColoredBox(color: Colors.white),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        home: Scaffold(
          body: ListView(
            children: [
              card('a'),
              const SizedBox(height: GroupTitle.before),
              GroupTitle(title: 'Hier', folded: false, onTap: () {}),
              card('b'),
            ],
          ),
        ),
      ),
    );
    final text = tester.getRect(find.text('Hier'));
    final zone = tester.getRect(find.byType(InkWell));
    final above = tester.getRect(find.byKey(const Key('a')));
    final below = tester.getRect(find.byKey(const Key('b')));
    expect(text.top - above.bottom, GroupTitle.gap);
    expect(below.top - text.bottom, 8);
    expect(text.top - zone.top, zone.bottom - text.bottom);
    expect(zone.top, above.bottom + GroupTitle.before);
    expect(zone.bottom, below.top);
  });
}
