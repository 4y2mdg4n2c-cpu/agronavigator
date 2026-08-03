import 'package:agronavigator_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the app home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Агронавигатор'), findsOneWidget);
    expect(find.text('Выберите режим работы: '), findsOneWidget);
  });
}
