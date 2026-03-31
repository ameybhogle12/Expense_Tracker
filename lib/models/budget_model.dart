import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String category;

  @HiveField(1)
  double monthlyLimit;

  BudgetModel({
    required this.category,
    required this.monthlyLimit,
  });
}
