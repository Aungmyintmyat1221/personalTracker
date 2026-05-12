import 'package:hive/hive.dart';
part 'routineModel.g.dart';

@HiveType(typeId: 1)
class RoutineModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int hour;

  @HiveField(3)
  final int minute;

  @HiveField(4)
  bool isDoneToday;

  @HiveField(5)
  int streak;

  @HiveField(6)
  DateTime? lastCompletedDate;

  @HiveField(7)
  int priority; // 1 low, 2 medium, 3 high

  @HiveField(8)
  String scheduleType; // everyday / workday / holiday

  RoutineModel({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.isDoneToday = false,
    this.streak = 0,
    this.lastCompletedDate,
    this.priority = 2,
    this.scheduleType = 'everyday',
  });
}
