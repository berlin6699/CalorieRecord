import 'dart:io';
import 'dart:ui' as ui;

import 'package:energy_balance/core/app_theme.dart';
import 'package:energy_balance/data/models.dart';
import 'package:energy_balance/screens/app_shell.dart';
import 'package:energy_balance/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// This fixture is isolated from the user's database and exports.
AppState _fixture() {
  final today = dayOnly(DateTime.now());
  final goals = defaultGoals();
  final recipes = [
    Recipe(
      id: 1,
      name: '虾仁滑蛋饭',
      servingLabel: '一份',
      categoryId: 1,
      categoryName: '学校食堂',
      nutrition: const Nutrition(
        energyKcal: 580,
        carbsG: 75,
        proteinG: 32,
        fatG: 17,
      ),
    ),
    Recipe(
      id: 2,
      name: '鸡肉套餐 · 加一份蔬菜的长名称测试',
      servingLabel: '一份',
      categoryId: 2,
      categoryName: '外出用餐',
      nutrition: const Nutrition(
        energyKcal: 620,
        carbsG: 66,
        proteinG: 38,
        fatG: 19,
      ),
    ),
    Recipe(
      id: 3,
      name: '牛奶与鸡蛋',
      servingLabel: '一份',
      categoryId: 1,
      categoryName: '学校食堂',
      nutrition: const Nutrition(
        energyKcal: 280,
        carbsG: 16,
        proteinG: 22,
        fatG: 14,
      ),
    ),
  ];
  return AppState(
    profile: UserProfile.defaults().copyWith(
      configured: true,
      baselineKcal: 1700,
    ),
    goals: goals,
    selectedDate: today,
    day: DayRecord(
      date: today,
      type: DayType.strength,
      baselineKcal: 1700,
      target: goals[DayType.strength]!.target,
    ),
    meals: [
      for (var i = 0; i < 3; i++)
        MealEntry(
          id: i + 1,
          date: today,
          recipeId: recipes[i].id,
          recipeName: recipes[i].name,
          servingLabel: '一份',
          servings: 1,
          perServing: recipes[i].nutrition,
          mealType: MealType.values[i],
          createdAt: today,
        ),
    ],
    exercises: [
      ExerciseEntry(
        id: 1,
        date: today,
        name: '力量训练',
        energyKcal: 300,
        createdAt: today,
      ),
    ],
    recipes: recipes,
    recipeCategories: [
      RecipeCategory(id: 1, name: '学校食堂', createdAt: today),
      RecipeCategory(id: 2, name: '外出用餐', createdAt: today),
    ],
    trainingPlans: [
      TrainingPlan(
        id: 1,
        name: '秋季减脂计划',
        type: TrainingPlanType.cutting,
        startDate: today.subtract(const Duration(days: 15)),
        endDate: today.add(const Duration(days: 45)),
        createdAt: today,
      ),
    ],
    selectedTrainingPlanId: 1,
    bodyMeasurements: [
      for (var i = 0; i < 4; i++)
        BodyMeasurement(
          id: i + 1,
          date: today.subtract(Duration(days: i * 4)),
          heightCm: 175,
          weightKg: 70 + i * .4,
          bmi: 22.9,
          bodyFatPercent: 18.6 + i * .3,
          visceralFatLevel: 5,
          subcutaneousFatPercent: 15,
          musclePercent: 75,
          boneMassKg: 3,
          waterPercent: 58,
          proteinPercent: 18,
          bmrKcal: 1700,
          createdAt: today,
        ),
    ],
    trends: [
      for (var i = 0; i < 10; i++)
        DailySummary(
          record: DayRecord(
            date: today.subtract(Duration(days: 9 - i)),
            type: i == 5 ? DayType.indulgence : DayType.strength,
            baselineKcal: 1700,
            target: goals[DayType.strength]!.target,
          ),
          intake: Nutrition(
            energyKcal: 1800 + (i % 3) * 120,
            carbsG: 220 + i * 5,
            proteinG: 130 + i * 3,
            fatG: 55,
          ),
          exerciseKcal: 400,
        ),
    ],
  );
}

class _PreviewController extends AppController {
  @override
  Future<AppState> build() async => _fixture();

  @override
  Future<void> selectDate(DateTime date) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        selectedDate: dayOnly(date),
        day: DayRecord(
          date: date,
          type: current.day.type,
          baselineKcal: current.day.baselineKcal,
          target: current.day.target,
        ),
      ),
    );
  }

  @override
  Future<void> setDayType(DayType type) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        day: DayRecord(
          date: current.selectedDate,
          type: type,
          baselineKcal: current.day.baselineKcal,
          target: current.goals[type]!.target,
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    final font = File(
      Platform.environment['CALORIE_UI_FONT'] ?? r'C:\Windows\Fonts\msyh.ttc',
    );
    if (await font.exists()) {
      final loader = FontLoader('Microsoft YaHei');
      loader.addFont(
        font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
    }
    final icons = File(
      r'D:\toolchains\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    );
    if (await icons.exists()) {
      final loader = FontLoader('MaterialIcons');
      loader.addFont(
        icons.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
    }
  });

  for (final viewport in [
    ('mobile', const Size(390, 844), TargetPlatform.android, 1.0),
    ('small_mobile', const Size(320, 740), TargetPlatform.android, 1.15),
    ('desktop', const Size(1320, 900), TargetPlatform.windows, 1.0),
    ('compact_desktop', const Size(1040, 760), TargetPlatform.windows, 1.0),
  ]) {
    testWidgets(
      '${viewport.$1}: navigation, daily context, sheets and all page layouts',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        final theme = buildTheme();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appControllerProvider.overrideWith(_PreviewController.new),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('zh', 'CN'),
              supportedLocales: const [Locale('zh', 'CN')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: theme.copyWith(
                platform: viewport.$3,
                textTheme: theme.textTheme.apply(fontFamily: 'Microsoft YaHei'),
                appBarTheme: theme.appBarTheme.copyWith(
                  titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                    fontFamily: 'Microsoft YaHei',
                  ),
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(viewport.$4)),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
              home: const AppShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, boundary, '${viewport.$1}_today');
        final mobile = viewport.$3 == TargetPlatform.android;
        for (final page
            in mobile
                ? ['菜谱', '计划', '身体', '设置']
                : ['我的菜谱', '训练计划', '身体数据', '个人与设置']) {
          await tester.tap(find.text(page).last);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${viewport.$1}: $page',
          );
          await _capture(
            tester,
            boundary,
            '${viewport.$1}_${['菜谱', '我的菜谱'].contains(page)
                ? 'recipes'
                : ['计划', '训练计划'].contains(page)
                ? 'trends'
                : ['身体', '身体数据'].contains(page)
                ? 'body'
                : 'settings'}',
          );
        }
        await tester.tap(find.text(mobile ? '今日' : '今日概览').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('前一天'));
        await tester.pumpAndSettle();
        expect(find.text('每日记录'), findsOneWidget);
        expect(find.text('当日净能量'), findsOneWidget);
        await tester.tap(find.text('回到今天'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('今天'));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, boundary, '${viewport.$1}_date_picker');
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('放纵'));
        await tester.pumpAndSettle();
        expect(find.text('今天，给自己放个假'), findsOneWidget);
        expect(find.text('记录餐食'), findsNothing);
        await _capture(tester, boundary, '${viewport.$1}_indulgence');
        await tester.tap(find.text('无氧'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('记录餐食'));
        await tester.tap(find.text('记录餐食'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, boundary, '${viewport.$1}_meal_editor');
        await tester.tap(find.text('搜索或按分类选择'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.widgetWithText(TextField, '搜索菜谱'), '虾仁');
        await tester.pumpAndSettle();
        expect(find.text('虾仁滑蛋饭').hitTestable(), findsOneWidget);
        await _capture(tester, boundary, '${viewport.$1}_recipe_picker');
        await tester.tap(find.text('虾仁滑蛋饭').hitTestable());
        await tester.pumpAndSettle();
        await tester.tap(find.text('临时餐食'));
        await tester.pumpAndSettle();
        if (mobile) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(find.text('添加到当天')).bottom,
            lessThanOrEqualTo(viewport.$2.height - 280),
          );
          await _capture(tester, boundary, '${viewport.$1}_keyboard');
        }
      },
    );
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CALORIE_UI_CAPTURE'] != '1') return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = await Directory('build/ui-review').create(recursive: true);
    await File('${dir.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
}
