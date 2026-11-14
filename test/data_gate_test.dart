import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/main.dart';

class _MemoryVault implements KeyVault {
  final values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;

  @override
  Future<void> delete(String name) async => values.remove(name);

  @override
  Future<void> deleteAll() async => values.clear();
}

void main() {
  late Directory folder;
  late _MemoryVault vault;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('kibuo_gate_');
    vault = _MemoryVault();
  });
  tearDown(() => folder.deleteSync(recursive: true));

  Future<OpenResult> open() =>
      openKibuoDatabase(folder: folder, vault: vault, inBackground: false);

  Future<void> start(WidgetTester tester, Future<OpenResult> opening) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.runAsync(() => opening);
    await tester.pumpWidget(
      KibuoApp(
        opening: opening,
        eraseAndStartOver: () => eraseAndStartOver(
          folder: folder,
          vault: vault,
          inBackground: false,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('with readable data, Accueil opens', (tester) async {
    final opening = open();
    await start(tester, opening);

    expect(find.text('Aujourd’hui'), findsOneWidget);
    await tester.runAsync(
      () async => ((await opening) as Opened).database.close(),
    );
  });

  testWidgets(
    'with a lost key, the screen explains and starting over opens Accueil',
    (tester) async {
      await tester.runAsync(() async {
        await ((await open()) as Opened).database.close();
      });
      vault.values.clear();

      await start(tester, open());
      expect(
        find.text('Vos données ne peuvent pas être ouvertes'),
        findsOneWidget,
      );
      expect(find.text('Aujourd’hui'), findsNothing);

      // Files are moved and reopened for real, outside the test's fake time.
      await tester.runAsync(() async {
        await tester.tap(find.text('Repartir de zéro'));
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Aujourd’hui'), findsOneWidget);
    },
  );
}
