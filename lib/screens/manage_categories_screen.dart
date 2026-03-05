import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../widgets/category_tile.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  // ── Controllers reused across dialogs ─────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  // ── Add dialog ─────────────────────────────────────────────────────────────
  void _showAddDialog() {
    _nameCtrl.clear();
    _limitCtrl.clear();
    _openCategoryDialog(
      title: 'Add Category',
      confirmLabel: 'Add',
      onConfirm: () async {
        if (!_formKey.currentState!.validate()) return;
        await CategoryService.addCategory(
          name: _nameCtrl.text.trim(),
          spendingLimit: int.parse(_limitCtrl.text.trim()),
        );
        if (mounted) Navigator.pop(context);
      },
    );
  }

  // ── Edit dialog ────────────────────────────────────────────────────────────
  void _showEditDialog(CategoryModel category) {
    _nameCtrl.text = category.name;
    _limitCtrl.text = category.spendingLimit.toString();
    _openCategoryDialog(
      title: 'Edit Category',
      confirmLabel: 'Save',
      onConfirm: () async {
        if (!_formKey.currentState!.validate()) return;
        await CategoryService.updateCategory(
          category,
          name: _nameCtrl.text.trim(),
          spendingLimit: int.parse(_limitCtrl.text.trim()),
        );
        if (mounted) Navigator.pop(context);
      },
    );
  }

  // ── Shared dialog builder ──────────────────────────────────────────────────
  void _openCategoryDialog({
    required String title,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Category name field ──────────────────────────────────────
              _StyledField(
                controller: _nameCtrl,
                label: 'Category Name',
                hint: 'e.g. Gym, Petrol…',
                icon: Icons.label_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  // Duplicate check (case-insensitive)
                  final existing = CategoryService.getCategoryNames()
                      .map((n) => n.toLowerCase())
                      .toList();
                  if (title == 'Add Category' &&
                      existing.contains(v.trim().toLowerCase())) {
                    return 'Category already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // ── Spending limit field ─────────────────────────────────────
              _StyledField(
                controller: _limitCtrl,
                label: 'Monthly Spending Limit (₹)',
                hint: 'e.g. 1000',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a limit';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Category?',
          style: TextStyle(color: Colors.white),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Deleting '),
              TextSpan(
                text: '"${category.name}"',
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text:
                    ' will not delete existing transactions but they will no '
                    'longer be matched to this category. This action cannot be undone.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await CategoryService.deleteCategory(category);
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        title: const Text(
          'Manage Categories',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        // ── Summary chip in actions ──────────────────────────────────────
        actions: [
          ValueListenableBuilder(
            valueListenable: CategoryService.getBox().listenable(),
            builder: (_, Box<CategoryModel> box, __) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text(
                    '${box.length} categories',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: Colors.blueAccent.withOpacity(0.25),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),

      body: ValueListenableBuilder(
        valueListenable: CategoryService.getBox().listenable(),
        builder: (context, Box<CategoryModel> box, _) {
          final categories = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'No categories yet.\nTap + to add your first one!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header info banner ───────────────────────────────────────
              _InfoBanner(totalBudget: _totalBudget(categories)),
              const SizedBox(height: 4),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return CategoryTile(
                      category: cat,
                      onEdit: () => _showEditDialog(cat),
                      onDelete: () => _confirmDelete(cat),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _totalBudget(List<CategoryModel> cats) =>
      cats.fold(0, (sum, c) => sum + c.spendingLimit);
}

// ── Info banner at top of list ─────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final int totalBudget;
  const _InfoBanner({required this.totalBudget});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B263B), Color(0xFF162032)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet,
                color: Colors.blueAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Monthly Budget',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '₹$totalBudget',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable styled text field ─────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF0A192F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
