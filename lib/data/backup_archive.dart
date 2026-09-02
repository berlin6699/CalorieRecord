import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const backupManifestName = 'backup.json';
const backupReadmeName = 'README.txt';

class BackupArchiveCodec {
  const BackupArchiveCodec._();

  static Uint8List encode(Map<String, dynamic> source) {
    final data = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    final archive = Archive();
    final recipes = data['recipes'];
    var imageCount = 0;

    if (recipes is List) {
      for (var index = 0; index < recipes.length; index++) {
        final raw = recipes[index];
        if (raw is! Map<String, dynamic>) continue;
        final encodedImage = raw.remove('imageBase64');
        if (encodedImage is! String || encodedImage.isEmpty) continue;

        Uint8List imageBytes;
        try {
          imageBytes = base64Decode(encodedImage);
        } on FormatException {
          throw FormatException('菜谱“${raw['name'] ?? index + 1}”的图片数据无效');
        }

        final extension = _imageExtension(raw['imageMimeType'] as String?);
        final id = raw['id'] ?? index + 1;
        final name = _safeFileName('${raw['name'] ?? 'recipe'}');
        final imagePath = 'images/recipes/${id}_$name.$extension';
        raw['imageFile'] = imagePath;
        archive.add(ArchiveFile.bytes(imagePath, imageBytes));
        imageCount++;
      }
    }

    data['backupContainerVersion'] = 1;
    data['imageStorage'] = 'files';
    data['imageCount'] = imageCount;
    final manifest = const JsonEncoder.withIndent('  ').convert(data);
    archive.add(ArchiveFile.string(backupManifestName, manifest));
    archive.add(
      ArchiveFile.string(
        backupReadmeName,
        'CalorieRecord 完整备份\r\n'
        '\r\n'
        'backup.json：个人资料、目标、历史记录、菜谱、分类、训练计划和身体数据。\r\n'
        'images/recipes/：菜谱原始文件。\r\n'
        '\r\n'
        '请保留整个 ZIP 文件，并通过 CalorieRecord 的“从备份恢复”功能导入。\r\n'
        '不要只移动或修改 ZIP 内的单个文件。\r\n',
      ),
    );

    return ZipEncoder().encodeBytes(archive);
  }

  static Map<String, dynamic> decode(List<int> bytes) {
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (_) {
      throw const FormatException('无法打开备份压缩包，文件可能已损坏');
    }

    final manifestFile = archive.find(backupManifestName);
    if (manifestFile == null || !manifestFile.isFile) {
      throw const FormatException('备份压缩包缺少 backup.json');
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(manifestFile.content));
    } catch (_) {
      throw const FormatException('备份压缩包内的 backup.json 无效');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('backup.json 顶层必须是对象');
    }

    final recipes = decoded['recipes'];
    if (recipes is List) {
      for (var index = 0; index < recipes.length; index++) {
        final raw = recipes[index];
        if (raw is! Map<String, dynamic>) continue;
        final imagePath = raw['imageFile'];
        if (imagePath == null) continue;
        if (imagePath is! String || !_isSafeImagePath(imagePath)) {
          throw FormatException('第 ${index + 1} 个菜谱的图片路径无效');
        }
        final imageFile = archive.find(imagePath);
        if (imageFile == null || !imageFile.isFile) {
          throw FormatException('备份压缩包缺少图片：$imagePath');
        }
        raw['imageBase64'] = base64Encode(imageFile.content);
      }
    }

    return decoded;
  }

  static String _safeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .trim();
    return sanitized.isEmpty ? 'recipe' : sanitized;
  }

  static bool _isSafeImagePath(String value) {
    return value.startsWith('images/recipes/') &&
        !value.contains('..') &&
        !value.contains('\\') &&
        value.length > 'images/recipes/'.length;
  }

  static String _imageExtension(String? mimeType) {
    return switch (mimeType?.toLowerCase()) {
      'image/jpeg' || 'image/jpg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/bmp' => 'bmp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'bin',
    };
  }
}
