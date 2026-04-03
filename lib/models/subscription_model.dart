import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 2)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String paymentMethod; 

  @HiveField(4)
  final String note;

  @HiveField(5)
  final int paymentDay; 

  @HiveField(6)
  DateTime? lastProcessed; 

  @HiveField(7, defaultValue: 0)
  final int paymentHour;

  @HiveField(8, defaultValue: 0)
  final int paymentMinute;

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
