import 'package:flutter/material.dart';
import '../../models/fridge_item_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FridgeItemTile extends StatelessWidget {
  final FridgeItemModel item;
  final String? fridgeOwnerId;
  final VoidCallback? onTap;
  final Function(FridgeItemModel, String)? onStatusChange;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const FridgeItemTile({
    super.key,
    required this.item,
    this.fridgeOwnerId,
    this.onTap,
    this.onStatusChange,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    String creatorLabel = '';
    if (fridgeOwnerId != null && item.createdBy == fridgeOwnerId) {
      creatorLabel = 'Owner';
    } else if (item.createdBy == currentUserId) {
      creatorLabel = 'Me';
    } else if (item.createdBy.isEmpty) {
      creatorLabel = '';
    } else {
      // Here you can determine ownerId by business logic, temporarily use Shared
      creatorLabel = 'Shared';
    }

    // Debug: Check if onEdit callback is provided
    if (onEdit != null) {
      print('FridgeItemTile: onEdit callback provided for item: ${item.name}');
    } else {
      print(
        'FridgeItemTile: onEdit callback NOT provided for item: ${item.name}',
      );
    }

    // Calculate days until expiry
    final now = DateTime.now();
    final difference = item.expiryDate.difference(now).inDays;

    // Determine color based on status and expiry date
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (item.status) {
      case 'fresh':
        statusColor = Colors.green;
        statusText = 'Fresh';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'almost_expiry':
        statusColor = Colors.orange;
        statusText = 'Almost Expired';
        statusIcon = Icons.warning_amber_outlined;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusText = 'Expired';
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.green;
        statusText = 'Fresh';
        statusIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Item image or placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl.isEmpty
                    ? const Icon(Icons.fastfood, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (creatorLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Created by: $creatorLabel',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Compartment indicator (only show if compartment is set)
                        if (item.compartment.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCompartmentColor(
                                item.compartment,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getCompartmentColor(
                                  item.compartment,
                                ).withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              _getCompartmentIcon(item.compartment),
                              size: 14,
                              color: _getCompartmentColor(item.compartment),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${DateFormat('yyyy-MM-dd HH:mm').format(item.expiryDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: difference < 0 ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              if (onStatusChange != null || onDelete != null || onEdit != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    print(
                      'PopupMenu selected: $value for item: ${item.name}, current status: ${item.status}',
                    );
                    print(
                      'onStatusChange callback is null? ' +
                          (onStatusChange == null).toString(),
                    );
                    if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    } else if (value == 'used' && onStatusChange != null) {
                      print('onStatusChange called with used');
                      onStatusChange!(item, value);
                    } else if (value == 'clear' && onStatusChange != null) {
                      print('onStatusChange called with clear');
                      onStatusChange!(item, value);
                    } else if (value == 'expired' && onStatusChange != null) {
                      print('onStatusChange called with expired');
                      onStatusChange!(item, value);
                    } else if (value == 'edit' && onEdit != null) {
                      print('Edit option selected for item: ' + item.name);
                      onEdit!();
                    } else {
                      print(
                        'No action taken for value: $value, onStatusChange is null: ' +
                            (onStatusChange == null).toString(),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onStatusChange != null && item.status != 'used') ...[
                      if (item.status == 'expired')
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Mark as Clear'),
                            ],
                          ),
                        ),
                      if (item.status == 'fresh' ||
                          item.status == 'almost_expiry')
                        PopupMenuItem(
                          value: 'used',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Mark as Used'),
                            ],
                          ),
                        ),
                    ],
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompartmentColor(String compartment) {
    switch (compartment.toLowerCase()) {
      case 'freezer':
        return Colors.blue;
      case 'chiller':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCompartmentIcon(String compartment) {
    switch (compartment.toLowerCase()) {
      case 'freezer':
        return Icons.ac_unit;
      case 'chiller':
        return Icons.kitchen;
      default:
        return Icons.kitchen;
    }
  }
}
