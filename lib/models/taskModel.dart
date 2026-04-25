import 'package:hive/hive.dart';

part 'taskModel.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  /// 🔥 NEW FIELD (must use new index)
  @HiveField(2)
  String priority; // "low", "medium", "high"

  TaskModel({
    required this.title,
    this.isDone = false,
    this.priority = "medium", // ✅ default value (important)
  });
}
