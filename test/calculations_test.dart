import 'dart:typed_data';

import 'package:energy_balance/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mifflin-St Jeor calculations', () {
    test('calculates male BMR and sedentary TDEE', () {
      final bmr = calculateBmr(
        sex: Sex.male,
        weightKg: 70,
        heightCm: 175,
        age: 25,
      );
      expect(bmr, 1673.75);
      expect(
        calculateSedentaryTdee(
          sex: Sex.male,
          weightKg: 70,
          heightCm: 175,
          age: 25,
        ),
        2009,
      );
    });

    test('calculates female adjustment', () {
      final male = calculateBmr(
        sex: Sex.male,
        weightKg: 60,
        heightCm: 165,
        age: 30,
      );
      final female = calculateBmr(
        sex: Sex.female,
        weightKg: 60,
        heightCm: 165,
        age: 30,
      );
      expect(male - female, 166);
    });
  });

  group('nutrition and daily balance', () {
    test('scales recipe nutrition by decimal servings', () {
      const perServing = Nutrition(
        energyKcal: 500,
        carbsG: 60,
        proteinG: 35,
        fatG: 15,
      );
      final total = perServing * 1.5;
      expect(total.energyKcal, 750);
      expect(total.carbsG, 90);
      expect(total.proteinG, 52.5);
      expect(total.fatG, 22.5);
    });

    test('net energy subtracts baseline and exercise', () {
      final summary = DailySummary(
        record: DayRecord(
          date: DateTime(2026, 9, 1),
          type: DayType.cardio,
          baselineKcal: 2000,
          target: const Nutrition(energyKcal: 2200),
        ),
        intake: const Nutrition(energyKcal: 2300),
        exerciseKcal: 500,
      );
      expect(summary.netEnergy, -200);
    });

    test('meal keeps its own nutrition snapshot', () {
      final meal = MealEntry(
        date: DateTime(2026, 9, 1),
        recipeId: 1,
        recipeName: '测试餐',
        servingLabel: '一份',
        servings: 2,
        perServing: const Nutrition(energyKcal: 300, proteinG: 20),
        mealType: MealType.lunch,
        createdAt: DateTime(2026, 9, 1, 12),
      );
      expect(meal.total.energyKcal, 600);
      expect(meal.total.proteinG, 40);
      expect(meal.mealType, MealType.lunch);
    });

    test('legacy meal backups default to snack/other', () {
      final restored = MealEntry.fromJson({
        'date': '2026-09-01',
        'recipeId': 1,
        'recipeName': '旧餐食',
        'servingLabel': '一份',
        'servings': 1,
        'energyKcal': 300,
        'carbsG': 20,
        'proteinG': 10,
        'fatG': 8,
        'createdAt': '2026-09-01T12:00:00.000',
      });
      expect(restored.mealType, MealType.snack);
    });

    test('temporary meal round-trips without a recipe id', () {
      final original = MealEntry(
        date: DateTime(2026, 9, 3),
        recipeId: null,
        recipeName: '外出聚餐',
        servingLabel: '一餐',
        servings: 1,
        perServing: const Nutrition(
          energyKcal: 850,
          carbsG: 90,
          proteinG: 40,
          fatG: 32,
        ),
        mealType: MealType.dinner,
        createdAt: DateTime(2026, 9, 3, 19),
      );

      final restored = MealEntry.fromJson(original.toJson());
      expect(restored.recipeId, isNull);
      expect(restored.recipeName, '外出聚餐');
      expect(restored.perServing.energyKcal, 850);
      expect(restored.mealType, MealType.dinner);
    });

    test('recipe image round-trips through backup JSON', () {
      final original = Recipe(
        name: '带图菜谱',
        servingLabel: '一份',
        nutrition: const Nutrition(energyKcal: 320),
        categoryId: 9,
        categoryName: '学校食堂',
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        imageMimeType: 'image/png',
      );
      final restored = Recipe.fromJson(original.toJson());
      expect(restored.imageBytes, [1, 2, 3, 4]);
      expect(restored.imageMimeType, 'image/png');
      expect(restored.categoryId, 9);
      expect(restored.categoryName, '学校食堂');
    });

    test('recipe category round-trips through backup JSON', () {
      final original = RecipeCategory(
        id: 4,
        name: '临时外食',
        createdAt: DateTime(2026, 9, 2, 15, 30),
      );
      final restored = RecipeCategory.fromJson(original.toJson());
      expect(restored.id, 4);
      expect(restored.name, '临时外食');
      expect(restored.createdAt, DateTime(2026, 9, 2, 15, 30));
    });
  });

  test('date keys ignore the time component', () {
    expect(dateKey(DateTime(2026, 9, 1, 23, 59)), '2026-09-01');
  });

  group('training plans', () {
    test('includes both boundaries of a fixed plan', () {
      final plan = TrainingPlan(
        name: '秋季减脂',
        type: TrainingPlanType.cutting,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 31),
        createdAt: DateTime(2026, 9, 1),
      );

      expect(plan.includes(DateTime(2026, 8, 31)), isFalse);
      expect(plan.includes(DateTime(2026, 9, 1, 23, 59)), isTrue);
      expect(plan.includes(DateTime(2026, 10, 31, 23, 59)), isTrue);
      expect(plan.includes(DateTime(2026, 11, 1)), isFalse);
      expect(plan.plannedDays, 61);
    });

    test('an ongoing plan has no upper date boundary', () {
      final plan = TrainingPlan(
        name: '增肌期',
        type: TrainingPlanType.bulking,
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(plan.includes(DateTime(2099, 1, 1)), isTrue);
    });

    test('round-trips through backup JSON', () {
      final original = TrainingPlan(
        id: 7,
        name: '维持阶段',
        type: TrainingPlanType.maintaining,
        startDate: DateTime(2026, 9, 2),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 9, 2, 8, 30),
      );

      final restored = TrainingPlan.fromJson(original.toJson());
      expect(restored.id, 7);
      expect(restored.name, '维持阶段');
      expect(restored.type, TrainingPlanType.maintaining);
      expect(dateKey(restored.startDate), '2026-09-02');
      expect(dateKey(restored.endDate!), '2026-09-30');
    });
  });

  group('body measurements', () {
    test('round-trips every measured field through backup JSON', () {
      final original = BodyMeasurement(
        id: 3,
        date: DateTime(2026, 9, 2),
        heightCm: 178,
        weightKg: 73.6,
        bmi: 23.2,
        bodyFatPercent: 21,
        visceralFatLevel: 6,
        subcutaneousFatPercent: 18.8,
        musclePercent: 44.8,
        boneMassKg: 3.9,
        waterPercent: 58,
        proteinPercent: 15.6,
        bmrKcal: 1623.3,
        createdAt: DateTime(2026, 9, 2, 13),
      );

      final restored = BodyMeasurement.fromJson(original.toJson());
      expect(restored.id, 3);
      expect(dateKey(restored.date), '2026-09-02');
      expect(restored.heightCm, 178);
      expect(restored.weightKg, 73.6);
      expect(restored.bmi, 23.2);
      expect(restored.bodyFatPercent, 21);
      expect(restored.visceralFatLevel, 6);
      expect(restored.subcutaneousFatPercent, 18.8);
      expect(restored.musclePercent, 44.8);
      expect(restored.boneMassKg, 3.9);
      expect(restored.waterPercent, 58);
      expect(restored.proteinPercent, 15.6);
      expect(restored.bmrKcal, 1623.3);
    });
  });
}
