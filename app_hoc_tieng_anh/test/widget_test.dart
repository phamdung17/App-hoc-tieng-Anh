import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/app/app.dart';

void main() {
  testWidgets('Login screen is the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Lưu trọn hành trình học'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}
