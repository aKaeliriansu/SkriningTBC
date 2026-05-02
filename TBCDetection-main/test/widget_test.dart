import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App shows TBC Screening and informasi content', (WidgetTester tester) async {
    await tester.pumpWidget(const TbDetectionApp());
    await tester.pumpAndSettle();

    expect(find.text('TBC Screening'), findsOneWidget);
    expect(find.textContaining('Informasi'), findsWidgets);
    expect(find.textContaining('Informasi Tuberkulosis'), findsOneWidget);
  });
}
