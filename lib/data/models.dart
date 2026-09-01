import 'dart:math' as math;

enum Sex { male, female }

enum DayType { cardio, strength, rest }

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

class Recipe {
  const Recipe({
    this.id,
    required this.name,
    required this.servingLabel,
    required this.nutrition,
  });

  final int? id;
  final String name;
  final String servingLabel;
  final Nutrition nutrition;

  Recipe copyWith({int? id}) => Recipe(
    id: id ?? this.id,
    name: name,
    servingLabel: servingLabel,
    nutrition: nutrition,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'servingLabel': servingLabel,
    ...nutrition.toJson(),
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] as String).trim(),
    servingLabel: (json['servingLabel'] as String).trim(),
    nutrition: Nutrition.fromJson(json),
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
    required this.createdAt,
  });

  final int? id;
  final DateTime date;
  final int? recipeId;
  final String recipeName;
  final String servingLabel;
  final double servings;
  final Nutrition perServing;
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
