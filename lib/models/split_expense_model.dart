import 'package:hive/hive.dart';

part 'split_expense_model.g.dart';

@HiveType(typeId: 7)
class SplitExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String paidBy;

  @HiveField(5)
  final List<String> splitAmong;

  @HiveField(6)
  final DateTime date;

  SplitExpenseModel({
    required this.id,
    required this.tripId,
    required this.amount,
    required this.description,
    required this.paidBy,
    required this.splitAmong,
    required this.date,
  });
}
