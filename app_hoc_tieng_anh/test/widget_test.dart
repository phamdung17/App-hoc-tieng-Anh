import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_hoc_tieng_anh/app/app.dart';

void main() {
  testWidgets('LingoUpApp smoke test - verifies initialization without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LingoUpApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(LingoUpApp), findsOneWidget);
  });
}
