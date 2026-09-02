import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_database.dart';
import 'models.dart';

class TransferService {
  TransferService(this.database);

  final AppDatabase database;

  Future<void> exportBackup() async {
    final data = await database.exportAll();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'CalorieRecord_备份_$stamp.json';
    final payload = const JsonEncoder.withIndent('  ').convert(data);
    if (Platform.isWindows || Platform.isLinux) {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出 CalorieRecord 完整备份',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (outputPath == null) return;
      await File(outputPath).writeAsString(payload, flush: true);
      return;
    }
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(payload, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        subject: '能量收支数据备份',
        text: '能量收支 App 完整数据备份',
        files: [XFile(file.path, mimeType: 'application/json')],
      ),
    );
  }

  Future<Map<String, dynamic>?> pickJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return null;
    final picked = result.files.single;
    final bytes =
        picked.bytes ??
        (picked.path == null ? null : await File(picked.path!).readAsBytes());
    if (bytes == null) throw const FormatException('无法读取所选文件');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 顶层必须是对象');
    }
    return decoded;
  }

  Future<List<Recipe>?> pickRecipeFile() async {
    final data = await pickJson();
    if (data == null) return null;
    if ((data['schemaVersion'] != 1 &&
            data['schemaVersion'] != 2 &&
            data['schemaVersion'] != 3 &&
            data['schemaVersion'] != 4) ||
        data['recipes'] is! List) {
      throw const FormatException('菜谱文件版本或结构不正确');
    }
    final recipes = <Recipe>[];
    for (final raw in data['recipes'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('菜谱条目必须是对象');
      }
      final recipe = Recipe.fromJson(raw);
      if (recipe.name.isEmpty || recipe.servingLabel.isEmpty) {
        throw const FormatException('菜谱名称和每份说明不能为空');
      }
      final n = recipe.nutrition;
      if ([
        n.energyKcal,
        n.carbsG,
        n.proteinG,
        n.fatG,
      ].any((value) => !value.isFinite || value < 0)) {
        throw FormatException('“${recipe.name}”包含无效或负数营养值');
      }
      recipes.add(
        Recipe(
          name: recipe.name,
          servingLabel: recipe.servingLabel,
          nutrition: recipe.nutrition,
          imageBytes: recipe.imageBytes,
          imageMimeType: recipe.imageMimeType,
        ),
      );
    }
    return recipes;
  }
}
