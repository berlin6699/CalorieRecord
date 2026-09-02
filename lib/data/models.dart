import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

enum Sex { male, female }

enum DayType { cardio, strength, rest }

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label => switch (this) {
    MealType.breakfast => '早餐',
    MealType.lunch => '午餐',
    MealType.dinner => '晚餐',
    MealType.snack => '加餐/其他',
  };
}

enum TrainingPlanType { cutting, maintaining, bulking, custom }

extension TrainingPlanTypeX on TrainingPlanType {
  String get label => switch (this) {
    TrainingPlanType.cutting => '减脂期',
    TrainingPlanType.maintaining => '维持期',
    TrainingPlanType.bulking => '增肌期',
    TrainingPlanType.custom => '自定义',
  };
}

extension DayTypeX on DayType {
  String get label => switch (this) {
    DayType.cardio => '有氧日',
    DayType.strength => '无氧日',
    DayType.rest => '休息日',
  };

  String get shortLabel => switch (this) {
    DayType.cardio => '有氧',
    DayType.strength => '无氧',
    DayType.rest => '休息',
  };
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

double calculateBmr({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final adjustment = sex == Sex.male ? 5 : -161;
  return 10 * weightKg + 6.25 * heightCm - 5 * age + adjustment;
}

int calculateSedentaryTdee({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) =>
    (calculateBmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age) *
            1.2)
        .round();

class Nutrition {
  const Nutrition({
    this.energyKcal = 0,
    this.carbsG = 0,
    this.proteinG = 0,
    this.fatG = 0,
  });

  final double energyKcal;
  final double carbsG;
  final double proteinG;
  final double fatG;

  Nutrition operator +(Nutrition other) => Nutrition(
    energyKcal: energyKcal + other.energyKcal,
    carbsG: carbsG + other.carbsG,
    proteinG: proteinG + other.proteinG,
    fatG: fatG + other.fatG,
  );

  Nutrition operator *(double factor) => Nutrition(
    energyKcal: energyKcal * factor,
    carbsG: carbsG * factor,
    proteinG: proteinG * factor,
    fatG: fatG * factor,
  );

  Map<String, dynamic> toJson() => {
    'energyKcal': energyKcal,
    'carbsG': carbsG,
    'proteinG': proteinG,
    'fatG': fatG,
  };

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
    energyKcal: _number(json['energyKcal']),
    carbsG: _number(json['carbsG']),
    proteinG: _number(json['proteinG']),
    fatG: _number(json['fatG']),
  );
}

class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.suggestedBaselineKcal,
    required this.baselineKcal,
    required this.defaultDayType,
    this.configured = false,
  });

  factory UserProfile.defaults() {
    const sex = Sex.male;
    const age = 25;
    const height = 175.0;
    const weight = 70.0;
    final tdee = calculateSedentaryTdee(
      sex: sex,
      weightKg: weight,
      heightCm: height,
      age: age,
    );
    return UserProfile(
      sex: sex,
      age: age,
      heightCm: height,
      weightKg: weight,
      suggestedBaselineKcal: tdee,
      baselineKcal: tdee,
      defaultDayType: DayType.strength,
    );
  }

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final int suggestedBaselineKcal;
  final int baselineKcal;
  final DayType defaultDayType;
  final bool configured;

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    int? suggestedBaselineKcal,
    int? baselineKcal,
    DayType? defaultDayType,
    bool? configured,
  }) => UserProfile(
    sex: sex ?? this.sex,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    suggestedBaselineKcal: suggestedBaselineKcal ?? this.suggestedBaselineKcal,
    baselineKcal: baselineKcal ?? this.baselineKcal,
    defaultDayType: defaultDayType ?? this.defaultDayType,
    configured: configured ?? this.configured,
  );

  Map<String, dynamic> toJson() => {
    'sex': sex.name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'suggestedBaselineKcal': suggestedBaselineKcal,
    'baselineKcal': baselineKcal,
    'defaultDayType': defaultDayType.name,
    'configured': configured,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    sex: Sex.values.byName(json['sex'] as String),
    age: (json['age'] as num).toInt(),
    heightCm: _number(json['heightCm']),
    weightKg: _number(json['weightKg']),
    suggestedBaselineKcal: (json['suggestedBaselineKcal'] as num).toInt(),
    baselineKcal: (json['baselineKcal'] as num).toInt(),
    defaultDayType: DayType.values.byName(json['defaultDayType'] as String),
    configured: json['configured'] == true || json['configured'] == 1,
  );
}

class DayGoal {
  const DayGoal({required this.type, required this.target});

  final DayType type;
  final Nutrition target;

  Map<String, dynamic> toJson() => {'type': type.name, ...target.toJson()};

  factory DayGoal.fromJson(Map<String, dynamic> json) => DayGoal(
    type: DayType.values.byName(json['type'] as String),
    target: Nutrition.fromJson(json),
  );
}

Map<DayType, DayGoal> defaultGoals() => {
  DayType.cardio: const DayGoal(
    type: DayType.cardio,
    target: Nutrition(energyKcal: 2200, carbsG: 280, proteinG: 140, fatG: 58),
  ),
  DayType.strength: const DayGoal(
    type: DayType.strength,
    target: Nutrition(energyKcal: 2400, carbsG: 300, proteinG: 160, fatG: 62),
  ),
  DayType.rest: const DayGoal(
    type: DayType.rest,
    target: Nutrition(energyKcal: 2000, carbsG: 210, proteinG: 150, fatG: 62),
  ),
};

class DayRecord {
  const DayRecord({
    required this.date,
    required this.type,
    required this.baselineKcal,
    required this.target,
  });

  final DateTime date;
  final DayType type;
  final int baselineKcal;
  final Nutrition target;

  Map<String, dynamic> toJson() => {
    'date': dateKey(date),
    'type': type.name,
    'baselineKcal': baselineKcal,
    ...target.toJson(),
  };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
    date: DateTime.parse(json['date'] as String),
    type: DayType.values.byName(json['type'] as String),
    baselineKcal: (json['baselineKcal'] as num).toInt(),
    target: Nutrition.fromJson(json),
  );
}

class RecipeCategory {
  const RecipeCategory({this.id, required this.name, required this.createdAt});

  final int? id;
  final String name;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecipeCategory.fromJson(Map<String, dynamic> json) => RecipeCategory(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] as String).trim(),
    createdAt: json['createdAt'] is String
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );
}

class Recipe {
  const Recipe({
    this.id,
    required this.name,
    required this.servingLabel,
    required this.nutrition,
    this.categoryId,
    this.categoryName,
    this.imageBytes,
    this.imageMimeType,
  });

  final int? id;
  final String name;
  final String servingLabel;
  final Nutrition nutrition;
  final int? categoryId;
  final String? categoryName;
  final Uint8List? imageBytes;
  final String? imageMimeType;

  Recipe copyWith({int? id}) => Recipe(
    id: id ?? this.id,
    name: name,
    servingLabel: servingLabel,
    nutrition: nutrition,
    categoryId: categoryId,
    categoryName: categoryName,
    imageBytes: imageBytes,
    imageMimeType: imageMimeType,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'servingLabel': servingLabel,
    ...nutrition.toJson(),
    if (categoryId != null) 'categoryId': categoryId,
    if (categoryName != null) 'categoryName': categoryName,
    if (imageBytes != null) 'imageBase64': base64Encode(imageBytes!),
    if (imageMimeType != null) 'imageMimeType': imageMimeType,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] as String).trim(),
    servingLabel: (json['servingLabel'] as String).trim(),
    nutrition: Nutrition.fromJson(json),
    categoryId: (json['categoryId'] as num?)?.toInt(),
    categoryName: json['categoryName'] as String?,
    imageBytes: json['imageBase64'] is String
        ? base64Decode(json['imageBase64'] as String)
        : null,
    imageMimeType: json['imageMimeType'] as String?,
  );
}

class MealEntry {
  const MealEntry({
    this.id,
    required this.date,
    required this.recipeId,
    required this.recipeName,
    required this.servingLabel,
    required this.servings,
    required this.perServing,
    required this.mealType,
    required this.createdAt,
  });

  final int? id;
  final DateTime date;
  final int? recipeId;
  final String recipeName;
  final String servingLabel;
  final double servings;
  final Nutrition perServing;
  final MealType mealType;
  final DateTime createdAt;

  Nutrition get total => perServing * servings;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'date': dateKey(date),
    'recipeId': recipeId,
    'recipeName': recipeName,
    'servingLabel': servingLabel,
    'servings': servings,
    ...perServing.toJson(),
    'mealType': mealType.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
    id: (json['id'] as num?)?.toInt(),
    date: DateTime.parse(json['date'] as String),
    recipeId: (json['recipeId'] as num?)?.toInt(),
    recipeName: json['recipeName'] as String,
    servingLabel: json['servingLabel'] as String,
    servings: _number(json['servings']),
    perServing: Nutrition.fromJson(json),
    mealType: MealType.values.firstWhere(
      (value) => value.name == json['mealType'],
      orElse: () => MealType.snack,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class ExerciseEntry {
  const ExerciseEntry({
    this.id,
    required this.date,
    required this.name,
    required this.energyKcal,
    required this.createdAt,
  });

  final int? id;
  final DateTime date;
  final String name;
  final double energyKcal;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'date': dateKey(date),
    'name': name,
    'energyKcal': energyKcal,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
    id: (json['id'] as num?)?.toInt(),
    date: DateTime.parse(json['date'] as String),
    name: json['name'] as String,
    energyKcal: _number(json['energyKcal']),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class TrainingPlan {
  const TrainingPlan({
    this.id,
    required this.name,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final TrainingPlanType type;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  bool includes(DateTime date) {
    final day = dayOnly(date);
    return !day.isBefore(dayOnly(startDate)) &&
        (endDate == null || !day.isAfter(dayOnly(endDate!)));
  }

  int get plannedDays => math.max(
    0,
    (endDate == null ? dayOnly(DateTime.now()) : dayOnly(endDate!))
            .difference(dayOnly(startDate))
            .inDays +
        1,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type.name,
    'startDate': dateKey(startDate),
    if (endDate != null) 'endDate': dateKey(endDate!),
    'createdAt': createdAt.toIso8601String(),
  };

  factory TrainingPlan.fromJson(Map<String, dynamic> json) => TrainingPlan(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] as String).trim(),
    type: TrainingPlanType.values.byName(json['type'] as String),
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] == null
        ? null
        : DateTime.parse(json['endDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class BodyMeasurement {
  const BodyMeasurement({
    this.id,
    required this.date,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.bodyFatPercent,
    required this.visceralFatLevel,
    required this.subcutaneousFatPercent,
    required this.musclePercent,
    required this.boneMassKg,
    required this.waterPercent,
    required this.proteinPercent,
    required this.bmrKcal,
    required this.createdAt,
  });

  final int? id;
  final DateTime date;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final double bodyFatPercent;
  final double visceralFatLevel;
  final double subcutaneousFatPercent;
  final double musclePercent;
  final double boneMassKg;
  final double waterPercent;
  final double proteinPercent;
  final double bmrKcal;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'date': dateKey(date),
    'heightCm': heightCm,
    'weightKg': weightKg,
    'bmi': bmi,
    'bodyFatPercent': bodyFatPercent,
    'visceralFatLevel': visceralFatLevel,
    'subcutaneousFatPercent': subcutaneousFatPercent,
    'musclePercent': musclePercent,
    'boneMassKg': boneMassKg,
    'waterPercent': waterPercent,
    'proteinPercent': proteinPercent,
    'bmrKcal': bmrKcal,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: (json['id'] as num?)?.toInt(),
        date: DateTime.parse(json['date'] as String),
        heightCm: _number(json['heightCm']),
        weightKg: _number(json['weightKg']),
        bmi: _number(json['bmi']),
        bodyFatPercent: _number(json['bodyFatPercent']),
        visceralFatLevel: _number(json['visceralFatLevel']),
        subcutaneousFatPercent: _number(json['subcutaneousFatPercent']),
        musclePercent: _number(json['musclePercent']),
        boneMassKg: _number(json['boneMassKg']),
        waterPercent: _number(json['waterPercent']),
        proteinPercent: _number(json['proteinPercent']),
        bmrKcal: _number(json['bmrKcal']),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class DailySummary {
  const DailySummary({
    required this.record,
    required this.intake,
    required this.exerciseKcal,
  });

  final DayRecord record;
  final Nutrition intake;
  final double exerciseKcal;

  double get netEnergy =>
      intake.energyKcal - record.baselineKcal - exerciseKcal;

  double ratio(double actual, double target) =>
      target <= 0 ? 0 : math.max(0, actual / target);
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}
