import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/app/app.dart';
import 'package:app_hoc_tieng_anh/features/challenge/presentation/pages/daily_challenge_page.dart';

void main() {
  testWidgets('App launches with learning path as initial route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Mục tiêu hôm nay'), findsOneWidget);
    expect(find.text('CHẶNG 1'), findsOneWidget);
  });

  testWidgets('Daily challenge checks answers and reports the final score', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DailyChallengePage()));

    final answers = ['rộng lượng', 'mượn', 'cải thiện', 'đông đúc', 'đến nơi'];
    for (var index = 0; index < answers.length; index++) {
      await tester.ensureVisible(find.text(answers[index]));
      await tester.pumpAndSettle();
      await tester.tap(find.text(answers[index]));
      await tester.ensureVisible(find.text('Kiểm tra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiểm tra'));
      await tester.pump();

      expect(find.textContaining('Chính xác!'), findsOneWidget);
      final nextLabel = index == answers.length - 1
          ? 'Xem kết quả'
          : 'Câu tiếp theo';
      await tester.ensureVisible(find.text(nextLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(nextLabel));
      await tester.pump();
    }

    expect(find.text('5/5 câu đúng'), findsOneWidget);
    expect(find.text('Hoàn thành thử thách!'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(find.text('1/5'), findsOneWidget);
  });
}
