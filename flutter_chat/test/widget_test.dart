import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FrappeChatApp());
    await tester.pumpAndSettle();

    expect(find.text('Frappe Chat'), findsOneWidget);
  });
}
