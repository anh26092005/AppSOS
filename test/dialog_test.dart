import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appsos/widgets/sos_alert_dialog.dart';

void main() {
  group('🧪 Kiểm tra Dialog Cảnh Báo SOS', () {
    testWidgets('✅ Hiển thị dialog đúng tiêu đề và nội dung', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SOSAlertDialog(
                        title: 'Cảnh Báo SOS',
                        body: 'Có trường hợp khẩn cấp',
                        data: {'caseId': '123'},
                        caseId: '123',
                        onAccept: () {},
                      ),
                    );
                  },
                  child: const Text('Hiện Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Bấm nút để hiện dialog
      await tester.tap(find.text('Hiện Dialog'));
      await tester.pumpAndSettle();

      // Kiểm tra nội dung
      expect(find.text('Cảnh Báo SOS'), findsOneWidget);
      expect(find.text('Có trường hợp khẩn cấp'), findsOneWidget);
      expect(find.text('Chấp nhận'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
    });

    testWidgets('✅ Gọi callback khi bấm Chấp Nhận', (
      WidgetTester tester,
    ) async {
      bool daChapNhan = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SOSAlertDialog(
                        title: 'Test',
                        body: 'Test',
                        data: {'caseId': '123'},
                        caseId: '123',
                        onAccept: () {
                          daChapNhan = true;
                        },
                      ),
                    );
                  },
                  child: const Text('Hiện'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Hiện'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chấp nhận'));
      await tester.pumpAndSettle();

      expect(daChapNhan, true);
    });
  });
}
