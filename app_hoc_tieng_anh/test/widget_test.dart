import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/app/app.dart';

void main() {
  testWidgets('App launches with learning path as initial route', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Mục tiêu hôm nay'), findsOneWidget);
    expect(find.text('CHẶNG 1'), findsOneWidget);
  });
}
