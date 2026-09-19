import 'package:file_picker/file_picker.dart';

import 'app_database.dart';

class StorageService {
  const StorageService(this.database);

  final AppDatabase database;

  Future<String?> pickDirectory() => FilePicker.platform.getDirectoryPath(
    dialogTitle: '选择 CalorieRecord 数据存储目录',
    lockParentWindow: true,
  );

  Future<void> moveTo(String directoryPath) =>
      database.moveStorageDirectory(directoryPath);
}
