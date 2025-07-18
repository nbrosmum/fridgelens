import 'package:flutter/material.dart';
import '../../models/shopping_item_model.dart';
import '../../utils/constants.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final Function(bool?) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool?) onToggleIsFridge;
  final VoidCallback? onInsertToFridge;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleIsFridge,
    this.onInsertToFridge,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: item.isCompleted
                ? Colors.grey.withAlpha(77) // 0.3 * 255 ≈ 77
                : Colors.transparent,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: item.isCompleted,
                onChanged: onToggle,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(item.imageUrl, fit: BoxFit.contain)
                            : Image.asset(
                                'assets/no_image.jpg',
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'assets/no_image.jpg',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                        )
                      : Image.asset(
                          'assets/no_image.jpg',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ],
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'Qty:  ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (item.isFridge) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.kitchen, size: 16, color: Colors.blueAccent),
                    ],
                  ],
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              } else if (value == 'insert_to_fridge' &&
                  onInsertToFridge != null) {
                onInsertToFridge!();
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ];
              if (item.isCompleted &&
                  item.isFridge &&
                  onInsertToFridge != null) {
                items.insert(
                  0,
                  PopupMenuItem(
                    value: 'insert_to_fridge',
                    child: Row(
                      children: const [
                        Icon(Icons.move_to_inbox, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Insert to Fridge'),
                      ],
                    ),
                  ),
                );
              }
              return items;
            },
          ),
        ),
      ),
    );
  }
}
