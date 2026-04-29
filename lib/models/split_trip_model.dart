import 'package:hive/hive.dart';

part 'split_trip_model.g.dart';

@HiveType(typeId: 6)
class SplitTripModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> members;

  @HiveField(3)
  final DateTime createdAt;

  SplitTripModel({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });
}
