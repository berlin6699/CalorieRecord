import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:energy_balance/data/backup_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupArchiveCodec', () {
    test(
      'stores recipe images as files and restores them into backup data',
      () {
        final image = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3, 4]);
        final source = <String, dynamic>{
          'schemaVersion': 5,
          'exportedAt': '2026-09-02T20:00:00.000',
          'profile': <String, dynamic>{'age': 22},
          'recipes': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 7,
              'name': '虾仁滑蛋饭',
              'servingLabel': '一份',
              'imageBase64': base64Encode(image),
              'imageMimeType': 'image/png',
            },
          ],
          'meals': <dynamic>[],
        };

        final zipBytes = BackupArchiveCodec.encode(source);
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final manifest = jsonDecode(
          utf8.decode(archive.find(backupManifestName)!.content),
        ) as Map<String, dynamic>;
        final archivedRecipe =
            (manifest['recipes'] as List).single as Map<String, dynamic>;
        final imagePath = archivedRecipe['imageFile'] as String;

        expect(archivedRecipe, isNot(contains('imageBase64')));
        expect(imagePath, 'images/recipes/7_虾仁滑蛋饭.png');
        expect(archive.find(imagePath)!.content, image);
        expect(archive.find(backupReadmeName), isNotNull);
        expect(manifest['imageCount'], 1);

        final restored = BackupArchiveCodec.decode(zipBytes);
        final restoredRecipe =
            (restored['recipes'] as List).single as Map<String, dynamic>;
        expect(base64Decode(restoredRecipe['imageBase64'] as String), image);
        expect(restoredRecipe['imageMimeType'], 'image/png');
        expect(restored['profile'], source['profile']);
      },
    );

    test('rejects an archive whose declared image is missing', () {
      final archive = Archive()
        ..add(
          ArchiveFile.string(
            backupManifestName,
            jsonEncode(<String, dynamic>{
              'schemaVersion': 5,
              'recipes': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': '测试菜谱',
                  'imageFile': 'images/recipes/1_missing.jpg',
                },
              ],
            }),
          ),
        );
      final bytes = ZipEncoder().encodeBytes(archive);

      expect(
        () => BackupArchiveCodec.decode(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('缺少图片'),
          ),
        ),
      );
    });

    test('rejects unsafe image paths without extracting files', () {
      final archive = Archive()
        ..add(
          ArchiveFile.string(
            backupManifestName,
            jsonEncode(<String, dynamic>{
              'schemaVersion': 5,
              'recipes': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': '测试菜谱',
                  'imageFile': 'images/recipes/../../outside.jpg',
                },
              ],
            }),
          ),
        );
      final bytes = ZipEncoder().encodeBytes(archive);

      expect(
        () => BackupArchiveCodec.decode(bytes),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
