import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:energy_balance/data/app_database.dart';
import 'package:energy_balance/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'moves the complete database and remembers the selected directory',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'calorie_storage_test_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final originalDir = Directory(p.join(root.path, 'original'));
      final targetDir = Directory(p.join(root.path, 'selected'));
      final config = File(p.join(root.path, 'config', 'storage.json'));
      final originalPath = p.join(
        originalDir.path,
        AppDatabase.databaseFileName,
      );
      final database = await AppDatabase.openAtForTesting(
        databasePath: originalPath,
        configPath: config.path,
      );
      await database.saveProfile(
        UserProfile.defaults().copyWith(configured: true),
      );
      await database.saveRecipe(
        Recipe(
          name: '带图片的菜谱',
          servingLabel: '一份',
          nutrition: Nutrition(energyKcal: 520, proteinG: 35),
          imageBytes: Uint8List.fromList([1, 2, 3, 4]),
          imageMimeType: 'image/png',
        ),
      );

      await database.moveStorageDirectory(targetDir.path);

      expect(await database.storageDirectory, p.normalize(targetDir.path));
      expect(await File(originalPath).exists(), isFalse);
      expect(
        await File(p.join(targetDir.path, AppDatabase.databaseFileName))
            .exists(),
        isTrue,
      );
      final configJson =
          jsonDecode(await config.readAsString()) as Map<String, dynamic>;
      expect(configJson['directory'], p.normalize(targetDir.path));
      final recipes = await database.loadRecipes();
      expect(recipes.single.name, '带图片的菜谱');
      expect(recipes.single.imageBytes, [1, 2, 3, 4]);
      await (await database.database).close();

      final reopened = await AppDatabase.openConfiguredForTesting(
        defaultDirectory: originalDir.path,
        configPath: config.path,
      );
      expect(await reopened.storageDirectory, p.normalize(targetDir.path));
      final reopenedRecipes = await reopened.loadRecipes();
      expect(reopenedRecipes.single.name, '带图片的菜谱');
      expect(reopenedRecipes.single.imageBytes, [1, 2, 3, 4]);
      await (await reopened.database).close();
    },
  );

  test(
    'refuses to overwrite an existing database in the target directory',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'calorie_storage_guard_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final database = await AppDatabase.openAtForTesting(
        databasePath: p.join(root.path, 'source', AppDatabase.databaseFileName),
        configPath: p.join(root.path, 'config.json'),
      );
      final target = Directory(p.join(root.path, 'occupied'));
      await target.create(recursive: true);
      await File(p.join(target.path, AppDatabase.databaseFileName))
          .writeAsString('existing');

      await expectLater(
        database.moveStorageDirectory(target.path),
        throwsA(isA<StateError>()),
      );
      expect(await database.storageDirectory, p.join(root.path, 'source'));
      await (await database.database).close();
    },
  );
}
