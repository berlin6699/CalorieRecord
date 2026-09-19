import 'package:energy_balance/core/chart_dates.dart';
import 'package:energy_balance/data/app_database.dart';
import 'package:energy_balance/data/models.dart';
import 'package:energy_balance/state/app_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    database = await AppDatabase.openInMemory();
    await database.saveProfile(
      UserProfile.defaults().copyWith(configured: true),
    );
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    await container.read(appControllerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await (await database.database).close();
  });

  test('browsing empty dates does not create deficits; indulgence remains balanced', () async {
    final controller = container.read(appControllerProvider.notifier);
    final date = DateTime(2026, 1, 5);
    await controller.selectDate(date);
    expect(await database.summaries(date, date), isEmpty);
    await controller.setDayType(DayType.indulgence);
    expect((await database.summaries(date, date)).single.netEnergy, 0);
    await controller.setDayType(DayType.rest);
    expect(await database.summaries(date, date), isEmpty);
    await controller.saveMeal(
      MealEntry(
        date: date,
        recipeId: null,
        recipeName: '测试餐食',
        servingLabel: '一份',
        servings: 1,
        perServing: const Nutrition(energyKcal: 600),
        mealType: MealType.lunch,
        createdAt: date,
      ),
    );
    expect(
      (await database.summaries(date, date)).single.intake.energyKcal,
      600,
    );
    await controller.setDayType(DayType.indulgence);
    expect((await database.summaries(date, date)).single.netEnergy, 0);
    expect((await database.loadMeals(date)).length, 1);
    await controller.setDayType(DayType.rest);
    expect(
      (await database.summaries(date, date)).single.intake.energyKcal,
      600,
    );
  });

  test('last target change updates today even when viewing history, never yesterday', () async {
    final controller = container.read(appControllerProvider.notifier);
    final today = dayOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    await controller.selectDate(yesterday);
    final original = (await database.getDay(yesterday))!;
    final type = (await database.getDay(today))!.type;
    await controller.saveGoal(
      DayGoal(type: type, target: const Nutrition(carbsG: 180)),
    );
    await controller.saveGoal(
      DayGoal(type: type, target: const Nutrition(carbsG: 210)),
    );
    expect((await database.getDay(today))!.target.carbsG, 210);
    expect(
      (await database.getDay(yesterday))!.target.carbsG,
      original.target.carbsG,
    );
    expect(
      container.read(appControllerProvider).requireValue.day.target.carbsG,
      original.target.carbsG,
    );
    await controller.selectDate(today);
    expect(
      container.read(appControllerProvider).requireValue.day.target.carbsG,
      210,
    );
  });

  test(
    'chart spacing represents elapsed calendar days rather than record count',
    () {
      expect(chartDayOffset(DateTime(2026, 9, 6), DateTime(2026, 9, 1)), 5);
      expect(chartDateAt(DateTime(2026, 8, 30), 4), DateTime(2026, 9, 3));
    },
  );
}
