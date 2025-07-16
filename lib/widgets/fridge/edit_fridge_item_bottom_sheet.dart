import 'package:flutter/material.dart';
import '../../models/fridge_item_model.dart';
import '../../models/fridge_model.dart';
import '../../services/fridge_item_service.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _removeImage = false;
  bool _ignoreExpiry = false;

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
    _ignoreExpiry = widget.item.ignoreExpiry;
    _updateExpiryByCategoryCompartment(); // Also call once at init
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

  Future<void> _pickImage({required ImageSource source}) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
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
      expiryDate: _expiryDate,
      reminderDate: _reminderDate,
      compartment: _selectedCompartment,
      newImageFile: _imageFile,
      removeImage:
          _removeImage, // New parameter, indicates whether to remove image
      ignoreExpiry: _ignoreExpiry,
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
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.photo_library,
                                          ),
                                          title: const Text(
                                            'Choose from Gallery',
                                          ),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await _pickImage(
                                              source: ImageSource.gallery,
                                            );
                                            setState(() {
                                              _removeImage = false;
                                            });
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt),
                                          title: const Text('Take a Photo'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await _pickImage(
                                              source: ImageSource.camera,
                                            );
                                            setState(() {
                                              _removeImage = false;
                                            });
                                          },
                                        ),
                                        if (_imageFile != null ||
                                            widget.item.imageUrl.isNotEmpty)
                                          ListTile(
                                            leading: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            title: const Text(
                                              'Remove Photo',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              setState(() {
                                                _imageFile = null;
                                                _removeImage = true;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                                      : (widget.item.imageUrl.isNotEmpty &&
                                                !_removeImage
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  widget.item.imageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                ),
                                child:
                                    (_imageFile == null &&
                                        (widget.item.imageUrl.isEmpty ||
                                            _removeImage))
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.camera_alt,
                                            size: 36,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
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
                              if (value != null) {
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
                                if (value != null) {
                                  setState(() {
                                    _selectedCompartment = value;
                                  });
                                  _updateExpiryByCategoryCompartment();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Checkbox(
                                value: _ignoreExpiry,
                                onChanged: (val) {
                                  setState(() {
                                    _ignoreExpiry = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Ignore expiry & reminder for this item',
                              ),
                            ],
                          ),
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
