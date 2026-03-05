import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int spendingLimit;

  CategoryModel({
    required this.id,
    required this.name,
    required this.spendingLimit,
  });

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, limit: $spendingLimit)';
}
