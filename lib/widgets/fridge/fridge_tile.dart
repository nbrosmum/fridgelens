import 'package:flutter/material.dart';
import '../../models/fridge_model.dart';
import '../../utils/constants.dart';

class FridgeTile extends StatelessWidget {
  final FridgeModel fridge;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOwner;

  const FridgeTile({
    super.key,
    required this.fridge,
    this.onTap,
    this.onEdit,
    this.onDelete,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    IconData fridgeIcon;
    Color fridgeColor;
    Widget iconWidget;

    // Set icon and color based on fridge type
    switch (fridge.type) {
      case 'freezer':
        fridgeIcon = Icons.ac_unit;
        fridgeColor = Colors.blue;
        iconWidget = Icon(fridgeIcon, color: fridgeColor, size: 28);
        break;
      case 'chiller':
        fridgeIcon = Icons.kitchen;
        fridgeColor = Colors.green;
        iconWidget = Icon(fridgeIcon, color: fridgeColor, size: 28);
        break;
      case 'both':
      default:
        fridgeColor = AppColors.primary;
        iconWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen, color: Colors.green, size: 24),
            const SizedBox(width: 4),
            Icon(Icons.ac_unit, color: Colors.blue, size: 24),
          ],
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fridgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: iconWidget,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fridge.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: fridgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getFridgeTypeDisplayName(fridge.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: fridgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isOwner ? Icons.person : Icons.group,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOwner ? 'Owner' : 'Contributor',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOwner && (onEdit != null || onDelete != null))
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              if (fridge.contributors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${fridge.contributors.length} contributor${fridge.contributors.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFridgeTypeDisplayName(String type) {
    switch (type) {
      case 'freezer':
        return 'FREEZER';
      case 'chiller':
        return 'CHILLER';
      case 'both':
        return 'BOTH';
      default:
        return type.toUpperCase();
    }
  }
}
