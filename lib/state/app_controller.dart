import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/models.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final appControllerProvider = AsyncNotifierProvider<AppController, AppState>(
  AppController.new,
);

const _keepSelectedPlan = Object();

class AppState {
  const AppState({
    required this.profile,
    required this.goals,
    required this.selectedDate,
    required this.day,
    required this.meals,
    required this.exercises,
    required this.recipes,
    required this.trainingPlans,
    required this.selectedTrainingPlanId,
    required this.bodyMeasurements,
    required this.trends,
  });

  final UserProfile profile;
  final Map<DayType, DayGoal> goals;
  final DateTime selectedDate;
  final DayRecord day;
  final List<MealEntry> meals;
  final List<ExerciseEntry> exercises;
  final List<Recipe> recipes;
  final List<TrainingPlan> trainingPlans;
  final int? selectedTrainingPlanId;
  final List<BodyMeasurement> bodyMeasurements;
  final List<DailySummary> trends;

  TrainingPlan? get selectedTrainingPlan {
    for (final plan in trainingPlans) {
      if (plan.id == selectedTrainingPlanId) return plan;
    }
    return null;
  }

  Nutrition get intake =>
      meals.fold(const Nutrition(), (total, meal) => total + meal.total);

  double get exerciseKcal =>
      exercises.fold(0, (total, item) => total + item.energyKcal);

  DailySummary get summary =>
      DailySummary(record: day, intake: intake, exerciseKcal: exerciseKcal);

  AppState copyWith({
    UserProfile? profile,
    Map<DayType, DayGoal>? goals,
    DateTime? selectedDate,
    DayRecord? day,
    List<MealEntry>? meals,
    List<ExerciseEntry>? exercises,
    List<Recipe>? recipes,
    List<TrainingPlan>? trainingPlans,
    Object? selectedTrainingPlanId = _keepSelectedPlan,
    List<BodyMeasurement>? bodyMeasurements,
    List<DailySummary>? trends,
  }) => AppState(
    profile: profile ?? this.profile,
    goals: goals ?? this.goals,
    selectedDate: selectedDate ?? this.selectedDate,
    day: day ?? this.day,
    meals: meals ?? this.meals,
    exercises: exercises ?? this.exercises,
    recipes: recipes ?? this.recipes,
    trainingPlans: trainingPlans ?? this.trainingPlans,
    selectedTrainingPlanId: identical(selectedTrainingPlanId, _keepSelectedPlan)
        ? this.selectedTrainingPlanId
        : selectedTrainingPlanId as int?,
    bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
    trends: trends ?? this.trends,
  );
}

class AppController extends AsyncNotifier<AppState> {
  AppDatabase get _database => ref.read(databaseProvider);

  @override
  Future<AppState> build() async => _load(dayOnly(DateTime.now()));

  Future<AppState> _load(DateTime selectedDate) async {
    final profile = await _database.loadProfile();
    final goals = await _database.loadGoals();
    final day = await _database.ensureDay(selectedDate, profile, goals);
    final meals = await _database.loadMeals(selectedDate);
    final exercises = await _database.loadExercises(selectedDate);
    final recipes = await _database.loadRecipes();
    final trainingPlans = await _database.loadTrainingPlans();
    final bodyMeasurements = await _database.loadBodyMeasurements();
    final selectedPlan = _preferredPlan(trainingPlans);
    final trends = await _summariesForPlan(selectedPlan);
    return AppState(
      profile: profile,
      goals: goals,
      selectedDate: selectedDate,
      day: day,
      meals: meals,
      exercises: exercises,
      recipes: recipes,
      trainingPlans: trainingPlans,
      selectedTrainingPlanId: selectedPlan?.id,
      bodyMeasurements: bodyMeasurements,
      trends: trends,
    );
  }

  Future<void> reloadAll({DateTime? selectedDate}) async {
    final date =
        selectedDate ?? state.value?.selectedDate ?? dayOnly(DateTime.now());
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(date));
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.requireValue;
    final selected = dayOnly(date);
    final day = await _database.ensureDay(
      selected,
      current.profile,
      current.goals,
    );
    final meals = await _database.loadMeals(selected);
    final exercises = await _database.loadExercises(selected);
    state = AsyncData(
      current.copyWith(
        selectedDate: selected,
        day: day,
        meals: meals,
        exercises: exercises,
      ),
    );
  }

  Future<void> setDayType(DayType type) async {
    final current = state.requireValue;
    final day = DayRecord(
      date: current.selectedDate,
      type: type,
      baselineKcal: current.day.baselineKcal,
      target: current.goals[type]!.target,
    );
    await _database.saveDay(day);
    state = AsyncData(current.copyWith(day: day));
    await _refreshTrends();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _database.saveProfile(profile);
    final current = state.requireValue;
    if (!current.profile.configured && profile.configured) {
      final day = DayRecord(
        date: current.selectedDate,
        type: profile.defaultDayType,
        baselineKcal: profile.baselineKcal,
        target: current.goals[profile.defaultDayType]!.target,
      );
      await _database.saveDay(day);
      state = AsyncData(current.copyWith(profile: profile, day: day));
      await _refreshTrends();
      return;
    }
    state = AsyncData(current.copyWith(profile: profile));
  }

  Future<void> saveGoal(DayGoal goal) async {
    await _database.saveGoal(goal);
    final current = state.requireValue;
    final goals = {...current.goals, goal.type: goal};
    state = AsyncData(current.copyWith(goals: goals));
  }

  Future<void> saveRecipe(Recipe recipe) async {
    await _database.saveRecipe(recipe);
    final current = state.requireValue;
    state = AsyncData(current.copyWith(recipes: await _database.loadRecipes()));
  }

  Future<void> deleteRecipe(int id) async {
    await _database.deleteRecipe(id);
    final current = state.requireValue;
    state = AsyncData(current.copyWith(recipes: await _database.loadRecipes()));
  }

  Future<void> importRecipes(
    List<Recipe> recipes, {
    required bool overwrite,
  }) async {
    await _database.importRecipes(recipes, overwrite: overwrite);
    final current = state.requireValue;
    state = AsyncData(current.copyWith(recipes: await _database.loadRecipes()));
  }

  Future<void> saveMeal(MealEntry meal) async {
    await _database.saveMeal(meal);
    await _refreshDayEntries();
  }

  Future<void> deleteMeal(int id) async {
    await _database.deleteMeal(id);
    await _refreshDayEntries();
  }

  Future<void> saveExercise(ExerciseEntry exercise) async {
    await _database.saveExercise(exercise);
    await _refreshDayEntries();
  }

  Future<void> deleteExercise(int id) async {
    await _database.deleteExercise(id);
    await _refreshDayEntries();
  }

  Future<void> selectTrainingPlan(int id) async {
    final current = state.requireValue;
    final plan = current.trainingPlans.where((item) => item.id == id).first;
    final trends = await _summariesForPlan(plan);
    state = AsyncData(
      current.copyWith(selectedTrainingPlanId: id, trends: trends),
    );
  }

  Future<void> saveTrainingPlan(TrainingPlan plan) async {
    final id = await _database.saveTrainingPlan(plan);
    final current = state.requireValue;
    final plans = await _database.loadTrainingPlans();
    final saved = plans.where((item) => item.id == id).first;
    final trends = await _summariesForPlan(saved);
    state = AsyncData(
      current.copyWith(
        trainingPlans: plans,
        selectedTrainingPlanId: id,
        trends: trends,
      ),
    );
  }

  Future<void> deleteTrainingPlan(int id) async {
    await _database.deleteTrainingPlan(id);
    final current = state.requireValue;
    final plans = await _database.loadTrainingPlans();
    TrainingPlan? selected;
    if (current.selectedTrainingPlanId != id) {
      for (final plan in plans) {
        if (plan.id == current.selectedTrainingPlanId) {
          selected = plan;
          break;
        }
      }
    }
    selected ??= _preferredPlan(plans);
    final trends = await _summariesForPlan(selected);
    state = AsyncData(
      current.copyWith(
        trainingPlans: plans,
        selectedTrainingPlanId: selected?.id,
        trends: trends,
      ),
    );
  }

  Future<void> saveBodyMeasurement(BodyMeasurement measurement) async {
    final current = state.requireValue;
    for (final existing in current.bodyMeasurements) {
      if (dateKey(existing.date) == dateKey(measurement.date) &&
          existing.id != measurement.id) {
        throw StateError('该日期已有身体记录，请编辑已有记录');
      }
    }
    await _database.saveBodyMeasurement(measurement);
    state = AsyncData(
      current.copyWith(
        bodyMeasurements: await _database.loadBodyMeasurements(),
      ),
    );
  }

  Future<void> deleteBodyMeasurement(int id) async {
    await _database.deleteBodyMeasurement(id);
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        bodyMeasurements: await _database.loadBodyMeasurements(),
      ),
    );
  }

  Future<void> _refreshDayEntries() async {
    final current = state.requireValue;
    final meals = await _database.loadMeals(current.selectedDate);
    final exercises = await _database.loadExercises(current.selectedDate);
    state = AsyncData(current.copyWith(meals: meals, exercises: exercises));
    await _refreshTrends();
  }

  Future<void> _refreshTrends() async {
    final trends = await _summariesForPlan(
      state.requireValue.selectedTrainingPlan,
    );
    state = AsyncData(state.requireValue.copyWith(trends: trends));
  }

  TrainingPlan? _preferredPlan(List<TrainingPlan> plans) {
    final today = dayOnly(DateTime.now());
    for (final plan in plans) {
      if (plan.includes(today)) return plan;
    }
    return plans.isEmpty ? null : plans.first;
  }

  Future<List<DailySummary>> _summariesForPlan(TrainingPlan? plan) async {
    if (plan == null) return const [];
    final today = dayOnly(DateTime.now());
    final start = dayOnly(plan.startDate);
    var end = plan.endDate == null ? today : dayOnly(plan.endDate!);
    if (end.isAfter(today)) end = today;
    if (end.isBefore(start)) return const [];
    return _database.summaries(start, end);
  }
}
