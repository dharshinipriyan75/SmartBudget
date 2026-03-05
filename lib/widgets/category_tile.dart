import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMisc =
        category.name.toLowerCase() == 'miscellaneous';

    return Card(
      color: const Color(0xFF1E2A38),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isMisc
              ? Colors.blueAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Icon bubble ────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForCategory(category.name),
                color: Colors.blueAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // ── Name + limit ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isMisc) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'default',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monthly limit: ₹${category.spendingLimit}',
                    style: const TextStyle(
                      color: Color(0xFF9FB3C8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Action buttons ─────────────────────────────────────────────
            _ActionBtn(
              icon: Icons.edit_outlined,
              color: Colors.blueAccent,
              tooltip: 'Edit',
              onTap: onEdit,
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              icon: Icons.delete_outline,
              color: isMisc ? Colors.white24 : Colors.redAccent,
              tooltip: isMisc ? 'Cannot delete default' : 'Delete',
              onTap: isMisc ? null : onDelete,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'travel':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.sports_esports;
      case 'subscription':
        return Icons.subscriptions;
      case 'movies':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'self-care':
        return Icons.spa;
      case 'miscellaneous':
        return Icons.category;
      default:
        return Icons.label_outline;
    }
  }
}

// ── Small circular icon button ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(onTap == null ? 0.05 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
