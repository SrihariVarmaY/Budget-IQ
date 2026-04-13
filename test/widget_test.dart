// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_budget_app/main.dart';

void main() {
  testWidgets('Budget Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BudgetIQApp());

    // Verify that the dashboard title is present.
    expect(find.text('Budget Dashboard'), findsOneWidget);

    // Verify that the Monthly Budget is displayed.
    expect(find.text('₹5,000.00'), findsOneWidget);

    // Verify that recent expenses section exists.
    expect(find.text('Recent Expenses'), findsOneWidget);
  });
}
