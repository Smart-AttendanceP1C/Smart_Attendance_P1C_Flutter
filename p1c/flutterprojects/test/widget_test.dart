import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Sign in screen is shown first', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAttendanceApp());

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('YOUR NAME'), findsOneWidget);
  });
}