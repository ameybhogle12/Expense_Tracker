import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 8)
class WalletModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  WalletModel({
    required this.id,
    required this.name,
  });
}
