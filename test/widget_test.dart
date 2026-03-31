import 'package:flutter_test/flutter_test.dart';

import 'package:trilink_mobile/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('LOG IN'), findsOneWidget);
  });
}
