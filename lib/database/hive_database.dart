import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/work_entry.dart';

class HiveDatabase {
  static late Box<WorkEntry> _workEntryBox;

  static Box<WorkEntry> get workEntryBox => _workEntryBox;

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    _workEntryBox =
        await Hive.openBox<WorkEntry>(AppConstants.hiveWorkEntryBox);
  }

  static Future<void> close() async {
    await _workEntryBox.close();
  }
}
