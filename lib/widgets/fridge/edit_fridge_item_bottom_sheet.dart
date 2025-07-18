import 'package:flutter/material.dart';
import '../../models/fridge_item_model.dart';
import '../../models/fridge_model.dart';
import '../../services/fridge_item_service.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import 'dart:io';

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
  File? _imageFile;
  final bool _removeImage = false;
  bool _isInitialized = false;

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

  // Default shelf life config
  static const Map<String, Map<String, int>> defaultExpiryDays = {
    'chiller': {
      'Vegetables': 7,
      'Fruits': 7,
      'Dairy Products': 10,
      'Meat & Poultry': 3,
      'Bakery & Grains': 5,
      'Drinks & Beverages': 14,
      'Condiments & Sauces': 30,
      'Frozen Food': 2,
      'Other': 7,
    },
    'freezer': {
      'Vegetables': 60,
      'Fruits': 60,
      'Dairy Products': 30,
      'Meat & Poultry': 90,
      'Bakery & Grains': 30,
      'Drinks & Beverages': 60,
      'Condiments & Sauces': 90,
      'Frozen Food': 180,
      'Other': 60,
    },
  };

  void _updateExpiryByCategoryCompartment() {
    final days = defaultExpiryDays[_selectedCompartment]?[_selectedCategory];
    if (days != null) {
      setState(() {
        _expiryDate = DateTime.now().add(Duration(days: days));
        _reminderDate = _expiryDate.subtract(const Duration(days: 1));
      });
    }
  }

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
    // Initialize image
    _imageFile = null;
    // Mark as initialized to preserve original dates
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiryDate),
      );
      if (pickedTime != null) {
        setState(() {
          _expiryDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Update reminder date to 1 day before expiry, keeping the same time
          _reminderDate = DateTime(
            _expiryDate.year,
            _expiryDate.month,
            _expiryDate.day - 1,
            _expiryDate.hour,
            _expiryDate.minute,
          );
        });
      }
    }
  }

  Future<void> _selectReminderDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now(),
      lastDate: _expiryDate,
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate),
      );
      if (pickedTime != null) {
        setState(() {
          _reminderDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _fridgeItemService.updateFridgeItem(
      itemId: widget.item.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      expiryDate: _expiryDate,
      reminderDate: _reminderDate,
      compartment: _selectedCompartment,
      newImageFile: _imageFile,
      removeImage:
          _removeImage, // New parameter, indicates whether to remove image
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
                          // Image selection area
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : (widget.item.imageUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                widget.item.imageUrl,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : DecorationImage(
                                              image: AssetImage(
                                                'assets/no_image.jpg',
                                              ),
                                              fit: BoxFit.cover,
                                            )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                              if (value != null && _isInitialized) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                                _updateExpiryByCategoryCompartment();
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
                                if (value != null && _isInitialized) {
                                  setState(() {
                                    _selectedCompartment = value;
                                  });
                                  _updateExpiryByCategoryCompartment();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          InkWell(
                            onTap: _selectExpiryDateTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat(
                                  'MMM d, yyyy HH:mm',
                                ).format(_expiryDate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectReminderDateTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Reminder Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.notifications),
                              ),
                              child: Text(
                                DateFormat(
                                  'MMM d, yyyy HH:mm',
                                ).format(_reminderDate),
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
