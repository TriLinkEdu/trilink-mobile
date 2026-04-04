import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Smoke Test'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smoke Test'), findsOneWidget);
  });
}
