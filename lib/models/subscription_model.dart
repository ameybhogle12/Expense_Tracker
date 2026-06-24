import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 2)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  String paymentMethod;

  @HiveField(4)
  String note;

  @HiveField(5)
  int paymentDay;

  @HiveField(6)
  DateTime? lastProcessed;

  @HiveField(7, defaultValue: 0)
  int paymentHour;

  @HiveField(8, defaultValue: 0)
  int paymentMinute;

  SubscriptionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.note,
    required this.paymentDay,
    this.lastProcessed,
    this.paymentHour = 0,
    this.paymentMinute = 0,
  });
}
