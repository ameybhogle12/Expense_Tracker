import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String note;

  @HiveField(5)
  String paymentMethod;

  @HiveField(6)
  final bool isIncome;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    required this.paymentMethod,
    this.isIncome = false,
  });
}
