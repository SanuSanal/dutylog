import 'package:flutter_test/flutter_test.dart';

import 'package:anjus_duties/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
