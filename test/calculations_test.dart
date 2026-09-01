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
        createdAt: DateTime(2026, 9, 1, 12),
      );
      expect(meal.total.energyKcal, 600);
      expect(meal.total.proteinG, 40);
    });
  });

  test('date keys ignore the time component', () {
    expect(dateKey(DateTime(2026, 9, 1, 23, 59)), '2026-09-01');
  });
}
