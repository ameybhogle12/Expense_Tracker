import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final int iconCodePoint;

  @HiveField(4)
  final bool isCustom;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    this.isCustom = true,
  });
}
