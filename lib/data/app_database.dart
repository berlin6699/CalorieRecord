import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), 'energy_balance.db');
    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
    );
    await _seed();
    return _database!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goals (
        type TEXT PRIMARY KEY,
        energy REAL NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE day_records (
        date TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        baseline INTEGER NOT NULL,
        target_energy REAL NOT NULL,
        target_carbs REAL NOT NULL,
        target_protein REAL NOT NULL,
        target_fat REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE,
        serving_label TEXT NOT NULL,
        energy REAL NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        recipe_id INTEGER,
        recipe_name TEXT NOT NULL,
        serving_label TEXT NOT NULL,
        servings REAL NOT NULL,
        energy REAL NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_meals_date ON meals(date)');
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        energy REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_exercises_date ON exercises(date)');
  }

  Future<void> _seed() async {
    final db = _database!;
    final profileRows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['profile'],
      limit: 1,
    );
    if (profileRows.isEmpty) {
      await saveProfile(UserProfile.defaults());
    }
    for (final goal in defaultGoals().values) {
      await db.insert(
        'goals',
        _goalRow(goal),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<UserProfile> loadProfile() async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['profile'],
      limit: 1,
    );
    if (rows.isEmpty) return UserProfile.defaults();
    return UserProfile.fromJson(
      jsonDecode(rows.first['value'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await database;
    await db.insert('settings', {
      'key': 'profile',
      'value': jsonEncode(profile.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<DayType, DayGoal>> loadGoals() async {
    final db = await database;
    final rows = await db.query('goals');
    return {
      for (final row in rows)
        DayType.values.byName(row['type'] as String): DayGoal(
          type: DayType.values.byName(row['type'] as String),
          target: Nutrition(
            energyKcal: (row['energy'] as num).toDouble(),
            carbsG: (row['carbs'] as num).toDouble(),
            proteinG: (row['protein'] as num).toDouble(),
            fatG: (row['fat'] as num).toDouble(),
          ),
        ),
    };
  }

  Future<void> saveGoal(DayGoal goal) async {
    final db = await database;
    await db.insert(
      'goals',
      _goalRow(goal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object> _goalRow(DayGoal goal) => {
    'type': goal.type.name,
    'energy': goal.target.energyKcal,
    'carbs': goal.target.carbsG,
    'protein': goal.target.proteinG,
    'fat': goal.target.fatG,
  };

  Future<DayRecord> ensureDay(
    DateTime date,
    UserProfile profile,
    Map<DayType, DayGoal> goals,
  ) async {
    final existing = await getDay(date);
    if (existing != null) return existing;
    final type = profile.defaultDayType;
    final record = DayRecord(
      date: dayOnly(date),
      type: type,
      baselineKcal: profile.baselineKcal,
      target: goals[type]!.target,
    );
    await saveDay(record);
    return record;
  }

  Future<DayRecord?> getDay(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'day_records',
      where: 'date = ?',
      whereArgs: [dateKey(date)],
      limit: 1,
    );
    return rows.isEmpty ? null : _dayFromRow(rows.first);
  }

  Future<void> saveDay(DayRecord record) async {
    final db = await database;
    await db.insert(
      'day_records',
      _dayRow(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object> _dayRow(DayRecord record) => {
    'date': dateKey(record.date),
    'type': record.type.name,
    'baseline': record.baselineKcal,
    'target_energy': record.target.energyKcal,
    'target_carbs': record.target.carbsG,
    'target_protein': record.target.proteinG,
    'target_fat': record.target.fatG,
  };

  DayRecord _dayFromRow(Map<String, Object?> row) => DayRecord(
    date: DateTime.parse(row['date'] as String),
    type: DayType.values.byName(row['type'] as String),
    baselineKcal: (row['baseline'] as num).toInt(),
    target: Nutrition(
      energyKcal: (row['target_energy'] as num).toDouble(),
      carbsG: (row['target_carbs'] as num).toDouble(),
      proteinG: (row['target_protein'] as num).toDouble(),
      fatG: (row['target_fat'] as num).toDouble(),
    ),
  );

  Future<List<Recipe>> loadRecipes() async {
    final db = await database;
    final rows = await db.query('recipes', orderBy: 'name COLLATE NOCASE');
    return rows.map(_recipeFromRow).toList();
  }

  Future<int> saveRecipe(Recipe recipe) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final row = <String, Object?>{
      'name': recipe.name.trim(),
      'serving_label': recipe.servingLabel.trim(),
      'energy': recipe.nutrition.energyKcal,
      'carbs': recipe.nutrition.carbsG,
      'protein': recipe.nutrition.proteinG,
      'fat': recipe.nutrition.fatG,
      'updated_at': now,
    };
    if (recipe.id == null) {
      row['created_at'] = now;
      return db.insert('recipes', row);
    }
    await db.update('recipes', row, where: 'id = ?', whereArgs: [recipe.id]);
    return recipe.id!;
  }

  Future<void> deleteRecipe(int id) async {
    final db = await database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Recipe _recipeFromRow(Map<String, Object?> row) => Recipe(
    id: (row['id'] as num).toInt(),
    name: row['name'] as String,
    servingLabel: row['serving_label'] as String,
    nutrition: Nutrition(
      energyKcal: (row['energy'] as num).toDouble(),
      carbsG: (row['carbs'] as num).toDouble(),
      proteinG: (row['protein'] as num).toDouble(),
      fatG: (row['fat'] as num).toDouble(),
    ),
  );

  Future<List<MealEntry>> loadMeals(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'meals',
      where: 'date = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'created_at DESC',
    );
    return rows.map(_mealFromRow).toList();
  }

  Future<int> saveMeal(MealEntry meal) async {
    final db = await database;
    final row = _mealRow(meal)..remove('id');
    if (meal.id == null) return db.insert('meals', row);
    await db.update('meals', row, where: 'id = ?', whereArgs: [meal.id]);
    return meal.id!;
  }

  Future<void> deleteMeal(int id) async {
    final db = await database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _mealRow(MealEntry meal) => {
    'id': meal.id,
    'date': dateKey(meal.date),
    'recipe_id': meal.recipeId,
    'recipe_name': meal.recipeName,
    'serving_label': meal.servingLabel,
    'servings': meal.servings,
    'energy': meal.perServing.energyKcal,
    'carbs': meal.perServing.carbsG,
    'protein': meal.perServing.proteinG,
    'fat': meal.perServing.fatG,
    'created_at': meal.createdAt.toIso8601String(),
  };

  MealEntry _mealFromRow(Map<String, Object?> row) => MealEntry(
    id: (row['id'] as num).toInt(),
    date: DateTime.parse(row['date'] as String),
    recipeId: (row['recipe_id'] as num?)?.toInt(),
    recipeName: row['recipe_name'] as String,
    servingLabel: row['serving_label'] as String,
    servings: (row['servings'] as num).toDouble(),
    perServing: Nutrition(
      energyKcal: (row['energy'] as num).toDouble(),
      carbsG: (row['carbs'] as num).toDouble(),
      proteinG: (row['protein'] as num).toDouble(),
      fatG: (row['fat'] as num).toDouble(),
    ),
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  Future<List<ExerciseEntry>> loadExercises(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'exercises',
      where: 'date = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'created_at DESC',
    );
    return rows.map(_exerciseFromRow).toList();
  }

  Future<int> saveExercise(ExerciseEntry exercise) async {
    final db = await database;
    final row = _exerciseRow(exercise)..remove('id');
    if (exercise.id == null) return db.insert('exercises', row);
    await db.update(
      'exercises',
      row,
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
    return exercise.id!;
  }

  Future<void> deleteExercise(int id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _exerciseRow(ExerciseEntry exercise) => {
    'id': exercise.id,
    'date': dateKey(exercise.date),
    'name': exercise.name,
    'energy': exercise.energyKcal,
    'created_at': exercise.createdAt.toIso8601String(),
  };

  ExerciseEntry _exerciseFromRow(Map<String, Object?> row) => ExerciseEntry(
    id: (row['id'] as num).toInt(),
    date: DateTime.parse(row['date'] as String),
    name: row['name'] as String,
    energyKcal: (row['energy'] as num).toDouble(),
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  Future<List<DailySummary>> summaries(DateTime from, DateTime to) async {
    final db = await database;
    final dayRows = await db.query(
      'day_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [dateKey(from), dateKey(to)],
      orderBy: 'date',
    );
    final mealRows = await db.rawQuery(
      '''
      SELECT date,
        COALESCE(SUM(energy * servings), 0) energy,
        COALESCE(SUM(carbs * servings), 0) carbs,
        COALESCE(SUM(protein * servings), 0) protein,
        COALESCE(SUM(fat * servings), 0) fat
      FROM meals WHERE date >= ? AND date <= ? GROUP BY date
    ''',
      [dateKey(from), dateKey(to)],
    );
    final exerciseRows = await db.rawQuery(
      '''
      SELECT date, COALESCE(SUM(energy), 0) energy
      FROM exercises WHERE date >= ? AND date <= ? GROUP BY date
    ''',
      [dateKey(from), dateKey(to)],
    );
    final mealsByDate = {
      for (final row in mealRows) row['date'] as String: row,
    };
    final exerciseByDate = {
      for (final row in exerciseRows) row['date'] as String: row,
    };
    return dayRows.map((row) {
      final key = row['date'] as String;
      final meal = mealsByDate[key];
      final exercise = exerciseByDate[key];
      return DailySummary(
        record: _dayFromRow(row),
        intake: Nutrition(
          energyKcal: (meal?['energy'] as num?)?.toDouble() ?? 0,
          carbsG: (meal?['carbs'] as num?)?.toDouble() ?? 0,
          proteinG: (meal?['protein'] as num?)?.toDouble() ?? 0,
          fatG: (meal?['fat'] as num?)?.toDouble() ?? 0,
        ),
        exerciseKcal: (exercise?['energy'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    final profile = await loadProfile();
    final goals = await loadGoals();
    final dayRows = await db.query('day_records', orderBy: 'date');
    final recipes = await loadRecipes();
    final mealRows = await db.query('meals', orderBy: 'date, created_at');
    final exerciseRows = await db.query(
      'exercises',
      orderBy: 'date, created_at',
    );
    return {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'goals': goals.values.map((item) => item.toJson()).toList(),
      'days': dayRows.map(_dayFromRow).map((item) => item.toJson()).toList(),
      'recipes': recipes.map((item) => item.toJson()).toList(),
      'meals': mealRows.map(_mealFromRow).map((item) => item.toJson()).toList(),
      'exercises': exerciseRows
          .map(_exerciseFromRow)
          .map((item) => item.toJson())
          .toList(),
    };
  }

  Future<void> restoreAll(Map<String, dynamic> data) async {
    _validateBackup(data);
    final profile = UserProfile.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
    final goals = (data['goals'] as List)
        .map((item) => DayGoal.fromJson(item as Map<String, dynamic>))
        .toList();
    final days = (data['days'] as List)
        .map((item) => DayRecord.fromJson(item as Map<String, dynamic>))
        .toList();
    final recipes = (data['recipes'] as List)
        .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
        .toList();
    final meals = (data['meals'] as List)
        .map((item) => MealEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    final exercises = (data['exercises'] as List)
        .map((item) => ExerciseEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'meals',
        'exercises',
        'day_records',
        'recipes',
        'goals',
      ]) {
        await txn.delete(table);
      }
      await txn.insert('settings', {
        'key': 'profile',
        'value': jsonEncode(profile.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final goal in goals) {
        await txn.insert('goals', _goalRow(goal));
      }
      for (final day in days) {
        await txn.insert('day_records', _dayRow(day));
      }
      for (final recipe in recipes) {
        final row = <String, Object?>{
          ..._recipeBackupRow(recipe),
          'id': recipe.id,
        };
        await txn.insert('recipes', row);
      }
      for (final meal in meals) {
        await txn.insert('meals', _mealRow(meal));
      }
      for (final exercise in exercises) {
        await txn.insert('exercises', _exerciseRow(exercise));
      }
    });
  }

  Map<String, Object?> _recipeBackupRow(Recipe recipe) {
    final stamp = DateTime.now().toIso8601String();
    return {
      'name': recipe.name,
      'serving_label': recipe.servingLabel,
      'energy': recipe.nutrition.energyKcal,
      'carbs': recipe.nutrition.carbsG,
      'protein': recipe.nutrition.proteinG,
      'fat': recipe.nutrition.fatG,
      'created_at': stamp,
      'updated_at': stamp,
    };
  }

  Future<(int imported, int skipped)> importRecipes(
    List<Recipe> recipes, {
    required bool overwrite,
  }) async {
    final db = await database;
    var imported = 0;
    var skipped = 0;
    await db.transaction((txn) async {
      for (final recipe in recipes) {
        final existing = await txn.query(
          'recipes',
          columns: ['id'],
          where: 'name = ? COLLATE NOCASE',
          whereArgs: [recipe.name],
          limit: 1,
        );
        if (existing.isNotEmpty && !overwrite) {
          skipped++;
          continue;
        }
        final row = _recipeBackupRow(recipe);
        if (existing.isNotEmpty) {
          await txn.update(
            'recipes',
            row..remove('created_at'),
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          await txn.insert('recipes', row);
        }
        imported++;
      }
    });
    return (imported, skipped);
  }

  void _validateBackup(Map<String, dynamic> data) {
    if (data['schemaVersion'] != 1) {
      throw const FormatException('不支持的备份版本');
    }
    for (final key in [
      'profile',
      'goals',
      'days',
      'recipes',
      'meals',
      'exercises',
    ]) {
      if (!data.containsKey(key)) throw FormatException('备份缺少字段：$key');
    }
  }
}
