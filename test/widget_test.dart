import 'package:flutter_test/flutter_test.dart';

import 'package:uniflow/main.dart';

void main() {
  testWidgets('UniFlow app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const UniFlowApp());

    expect(find.text('UniFlow'), findsOneWidget);
    expect(find.text('Good morning, Aamir 👋'), findsOneWidget);
    expect(find.text('Current GPA'), findsOneWidget);
    expect(find.text('3.53'), findsOneWidget);
  });
}