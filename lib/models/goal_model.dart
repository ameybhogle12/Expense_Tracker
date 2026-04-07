import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 4)
class GoalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  double savedAmount;

  @HiveField(4)
  final DateTime? deadline;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final int iconCodePoint;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.colorValue,
    required this.iconCodePoint,
  });
}
