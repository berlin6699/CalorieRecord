import 'package:energy_balance/data/models.dart';
import 'package:energy_balance/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recipe = Recipe(
    id: 12,
    name: '测试套餐',
    servingLabel: '一份',
    nutrition: const Nutrition(
      energyKcal: 520,
      carbsG: 62,
      proteinG: 28,
      fatG: 18,
    ),
  );

  testWidgets('adds a temporary meal without creating a recipe link', (
    tester,
  ) async {
    MealEntry? result;
    await tester.pumpWidget(
      _MealEditorHarness(
        recipes: [recipe],
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('打开编辑器'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('临时餐食'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '餐食名称'), '外出聚餐');
    await tester.enterText(find.widgetWithText(TextFormField, '每份说明'), '一餐');
    await tester.enterText(find.widgetWithText(TextFormField, '能量'), '860');
    await tester.enterText(find.widgetWithText(TextFormField, '碳水'), '92');
    await tester.enterText(find.widgetWithText(TextFormField, '蛋白质'), '45');
    await tester.enterText(find.widgetWithText(TextFormField, '脂肪'), '31');
    await tester.enterText(find.widgetWithText(TextFormField, '本次份数'), '1.5');

    await tester.ensureVisible(find.text('添加到当天'));
    await tester.tap(find.text('添加到当天'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.recipeId, isNull);
    expect(result!.recipeName, '外出聚餐');
    expect(result!.servingLabel, '一餐');
    expect(result!.servings, 1.5);
    expect(result!.perServing.energyKcal, 860);
    expect(result!.perServing.carbsG, 92);
    expect(result!.perServing.proteinG, 45);
    expect(result!.perServing.fatG, 31);
  });

  testWidgets('allows temporary entry when the recipe library is empty', (
    tester,
  ) async {
    MealEntry? result;
    await tester.pumpWidget(
      _MealEditorHarness(
        recipes: const [],
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('打开编辑器'));
    await tester.pumpAndSettle();

    expect(find.text('这条记录只计入当天，不会保存到菜谱库。'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '餐食名称'), '临时盒饭');
    await tester.enterText(find.widgetWithText(TextFormField, '能量'), '600');
    await tester.ensureVisible(find.text('添加到当天'));
    await tester.tap(find.text('添加到当天'));
    await tester.pumpAndSettle();

    expect(result?.recipeId, isNull);
    expect(result?.recipeName, '临时盒饭');
    expect(result?.perServing.energyKcal, 600);
  });

  testWidgets('keeps the existing recipe workflow unchanged', (tester) async {
    MealEntry? result;
    await tester.pumpWidget(
      _MealEditorHarness(
        recipes: [recipe],
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('打开编辑器'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('添加到当天'));
    await tester.tap(find.text('添加到当天'));
    await tester.pumpAndSettle();

    expect(result?.recipeId, 12);
    expect(result?.recipeName, '测试套餐');
    expect(result?.perServing.energyKcal, 520);
  });

  testWidgets('edits the details of an existing temporary meal', (
    tester,
  ) async {
    MealEntry? result;
    final initial = MealEntry(
      id: 6,
      date: DateTime(2026, 9, 3),
      recipeId: null,
      recipeName: '外食',
      servingLabel: '一餐',
      servings: 1,
      perServing: const Nutrition(energyKcal: 700),
      mealType: MealType.dinner,
      createdAt: DateTime(2026, 9, 3, 18),
    );
    await tester.pumpWidget(
      _MealEditorHarness(
        recipes: [recipe],
        initial: initial,
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('打开编辑器'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '餐食名称'), '朋友聚餐');
    await tester.enterText(find.widgetWithText(TextFormField, '能量'), '920');
    await tester.ensureVisible(find.text('保存修改'));
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(result?.id, 6);
    expect(result?.recipeId, isNull);
    expect(result?.recipeName, '朋友聚餐');
    expect(result?.perServing.energyKcal, 920);
    expect(result?.createdAt, initial.createdAt);
  });
}

class _MealEditorHarness extends StatelessWidget {
  const _MealEditorHarness({
    required this.recipes,
    required this.onResult,
    this.initial,
  });

  final List<Recipe> recipes;
  final ValueChanged<MealEntry?> onResult;
  final MealEntry? initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<MealEntry>(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: MealEditor(
                      date: DateTime(2026, 9, 3),
                      recipes: recipes,
                      initial: initial,
                    ),
                  ),
                ),
              );
              onResult(result);
            },
            child: const Text('打开编辑器'),
          ),
        ),
      ),
    ),
  );
}
