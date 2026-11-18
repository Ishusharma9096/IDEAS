import 'package:flutter_test/flutter_test.dart';
import 'package:goabusconnect/main.dart';

void main() {
  testWidgets('GoaBusConnect app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const GoaBusConnectApp());

    expect(find.text('GoaBusConnect'), findsOneWidget);
  });
}
