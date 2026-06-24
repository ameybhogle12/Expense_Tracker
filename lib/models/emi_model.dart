import 'package:hive/hive.dart';

part 'emi_model.g.dart';

@HiveType(typeId: 5)
class EmiModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String itemName;

  @HiveField(2)
  double totalAmount;

  @HiveField(3)
  double monthlyInstallment;

  @HiveField(4)
  int totalMonths;

  @HiveField(5)
  int monthsPaid;

  @HiveField(6)
  int paymentDay;

  @HiveField(7)
  DateTime? lastProcessed;

  @HiveField(8)
  String paymentMethod;

  EmiModel({
    required this.id,
    required this.itemName,
    required this.totalAmount,
    required this.monthlyInstallment,
    required this.totalMonths,
    required this.monthsPaid,
    required this.paymentDay,
    this.lastProcessed,
    required this.paymentMethod,
  });
}
