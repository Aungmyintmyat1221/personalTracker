import 'package:hive/hive.dart';

part 'routineModel.g.dart';

@HiveType(typeId: 1)
class RoutineModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime time;

  @HiveField(2)
  int reminderMinutesBefore; // e.g. 15 = notify 15 min before

  RoutineModel({
    required this.title,
    required this.time,
    this.reminderMinutesBefore = 10,
  });
}
