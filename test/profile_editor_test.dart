import 'package:energy_balance/data/models.dart';
import 'package:energy_balance/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'recalculate inserts a numeric value and save recovers after failure',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileEditor(
                initial: UserProfile.defaults(),
                submitLabel: '保存',
                onSaved: (_) async {
                  attempts++;
                  if (attempts == 1) throw StateError('test failure');
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '当前每日基础消耗'),
        '1',
      );
      await tester.ensureVisible(find.text('重新计算并填入'));
      await tester.tap(find.text('重新计算并填入'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, '当前每日基础消耗'),
      );
      expect(
        int.tryParse(field.controller!.text),
        UserProfile.defaults().suggestedBaselineKcal,
      );
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('正在保存…'), findsNothing);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
