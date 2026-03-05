import 'package:hive/hive.dart';
import '../models/category_model.dart';

class CategoryService {
  static const String _boxName = 'categories';

  // ── Default categories seeded on first launch ──────────────────────────────
  static const List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Food',          'limit': 1000},
    {'name': 'Travel',        'limit': 1500},
    {'name': 'Entertainment', 'limit': 400},
    {'name': 'Subscription',  'limit': 750},
    {'name': 'Movies',        'limit': 500},
    {'name': 'Shopping',      'limit': 1000},
    {'name': 'Laundry',       'limit': 500},
    {'name': 'Self-Care',     'limit': 500},
    {'name': 'Miscellaneous', 'limit': 300},
  ];

  // ── Open the Hive box ──────────────────────────────────────────────────────
  static Future<Box<CategoryModel>> openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<CategoryModel>(_boxName);
    }
    return await Hive.openBox<CategoryModel>(_boxName);
  }

  // ── Seed defaults only on first launch ────────────────────────────────────
  static Future<void> seedDefaultsIfEmpty() async {
    final box = await openBox();
    if (box.isEmpty) {
      for (final cat in _defaultCategories) {
        final model = CategoryModel(
          id: DateTime.now().microsecondsSinceEpoch.toString() +
              cat['name'].toString(),
          name: cat['name'] as String,
          spendingLimit: cat['limit'] as int,
        );
        await box.put(model.id, model);
      }
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Returns all categories sorted by name.
  static List<CategoryModel> getAll() {
    final box = Hive.box<CategoryModel>(_boxName);
    final list = box.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Returns the live Hive box for ValueListenableBuilder.
  static Box<CategoryModel> getBox() => Hive.box<CategoryModel>(_boxName);

  /// Add a brand-new category.
  static Future<void> addCategory({
    required String name,
    required int spendingLimit,
  }) async {
    final box = Hive.box<CategoryModel>(_boxName);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final model = CategoryModel(id: id, name: name, spendingLimit: spendingLimit);
    await box.put(id, model);
  }

  /// Update an existing category's name and/or limit.
  static Future<void> updateCategory(
    CategoryModel category, {
    required String name,
    required int spendingLimit,
  }) async {
    category.name = name;
    category.spendingLimit = spendingLimit;
    await category.save();
  }

  /// Delete a category by its Hive key (== id).
  static Future<void> deleteCategory(CategoryModel category) async {
    await category.delete();
  }

  /// Returns the "Miscellaneous" category, creating it if missing.
  static CategoryModel getOrCreateMiscellaneous() {
    final box = Hive.box<CategoryModel>(_boxName);
    final existing = box.values.firstWhere(
      (c) => c.name.toLowerCase() == 'miscellaneous',
      orElse: () {
        final model = CategoryModel(
          id: 'miscellaneous_default',
          name: 'Miscellaneous',
          spendingLimit: 300,
        );
        box.put(model.id, model);
        return model;
      },
    );
    return existing;
  }

  /// Builds a Map<String, int> of {name → limit} for backward-compat use.
  static Map<String, int> getCategoryLimitsMap() {
    final box = Hive.box<CategoryModel>(_boxName);
    return {for (final c in box.values) c.name: c.spendingLimit};
  }

  /// Returns just category names as a list.
  static List<String> getCategoryNames() {
    return getAll().map((c) => c.name).toList();
  }
}
