import 'package:flutter/material.dart';
import '../../models/fridge_item_model.dart';
import '../../models/fridge_model.dart';
import '../../services/fridge_item_service.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class EditFridgeItemBottomSheet extends StatefulWidget {
  final FridgeItemModel item;
  final FridgeModel fridge;
  const EditFridgeItemBottomSheet({
    super.key,
    required this.item,
    required this.fridge,
  });

  @override
  State<EditFridgeItemBottomSheet> createState() =>
      _EditFridgeItemBottomSheetState();
}

class _EditFridgeItemBottomSheetState extends State<EditFridgeItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedCategory;
  late DateTime _expiryDate;
  late DateTime _reminderDate;
  late String _selectedCompartment;
  bool _isLoading = false;
  final FridgeItemService _fridgeItemService = FridgeItemService();

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Dairy Products',
    'Meat & Poultry',
    'Bakery & Grains',
    'Drinks & Beverages',
    'Condiments & Sauces',
    'Frozen Food',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _selectedCategory = widget.item.category;
    _expiryDate = widget.item.expiryDate;
    _reminderDate = widget.item.reminderDate;
    _selectedCompartment = widget.item.compartment;
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
        _reminderDate = picked.subtract(const Duration(days: 1));
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now(),
      lastDate: _expiryDate,
    );
    if (picked != null && picked != _reminderDate) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _fridgeItemService.updateFridgeItem(
      itemId: widget.item.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      reminderDate: _reminderDate,
      compartment: _selectedCompartment,
    );
    setState(() => _isLoading = false);
    if (mounted && result['success']) {
      Navigator.of(context).pop({'updated': true});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Update failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Text(
                  'Edit Fridge Item',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.fastfood),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an item name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 220,
                                  ),
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          if (widget.fridge.type == 'both') ...[
                            DropdownButtonFormField<String>(
                              value: _selectedCompartment,
                              decoration: const InputDecoration(
                                labelText: 'Compartment',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.kitchen),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'chiller',
                                  child: Row(
                                    children: [
                                      Icon(Icons.kitchen, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Chiller'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'freezer',
                                  child: Row(
                                    children: [
                                      Icon(Icons.ac_unit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Freezer'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCompartment = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          InkWell(
                            onTap: _selectExpiryDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_expiryDate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectReminderDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Reminder Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.notifications),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_reminderDate),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _save,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
