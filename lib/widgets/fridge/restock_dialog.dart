import 'package:flutter/material.dart';
import '../../models/fridge_item_model.dart';
import '../../utils/constants.dart';

class RestockDialog extends StatefulWidget {
  final FridgeItemModel item;
  final String action; // 'used' or 'clear'

  const RestockDialog({super.key, required this.item, required this.action});

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  int quantity = 1;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.action == 'used' ? Icons.check_circle : Icons.clear,
            color: widget.action == 'used' ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            widget.action == 'used' ? 'Item Used' : 'Item Cleared',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            if (widget.item.imageUrl.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Item details
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Category: ${widget.item.category}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Question
            const Text(
              'Do you want to add this item to shopping list for restock?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Quantity input
            Row(
              children: [
                const Text('Quantity: ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        quantity = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'addToShoppingList': false, 'quantity': quantity});
          },
          child: const Text('No', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'addToShoppingList': true, 'quantity': quantity});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Yes, Add to Shopping List'),
        ),
      ],
    );
  }
}
