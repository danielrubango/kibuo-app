import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/main.dart';

void main() {
  testWidgets('the app starts and shows its name', (tester) async {
    await tester.pumpWidget(const KibuoApp());

    expect(find.text('Kibuo'), findsOneWidget);
  });
}
