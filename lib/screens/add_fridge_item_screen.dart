import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/fridge_item_service.dart';
import '../services/fridge_service.dart';
import '../models/fridge_model.dart';
import '../utils/constants.dart';

class AddFridgeItemScreen extends StatefulWidget {
  final String fridgeId;

  const AddFridgeItemScreen({super.key, required this.fridgeId});

  @override
  State<AddFridgeItemScreen> createState() => _AddFridgeItemScreenState();
}

class _AddFridgeItemScreenState extends State<AddFridgeItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = 'Vegetables';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  DateTime _reminderDate = DateTime.now().add(const Duration(days: 6));
  File? _imageFile;
  bool _isLoading = false;
  String _selectedCompartment = 'chiller'; // Default to chiller
  FridgeModel? _fridge;

  final FridgeItemService _fridgeItemService = FridgeItemService();
  final FridgeService _fridgeService = FridgeService();
  final ImagePicker _imagePicker = ImagePicker();

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
    _loadFridgeInfo();
  }

  Future<void> _loadFridgeInfo() async {
    try {
      final fridge = await _fridgeService.getFridge(widget.fridgeId).first;
      setState(() {
        _fridge = fridge;
        // Set default compartment based on fridge type
        if (fridge?.type == 'freezer') {
          _selectedCompartment = 'freezer';
        } else if (fridge?.type == 'chiller') {
          _selectedCompartment = 'chiller';
        }
        // For 'both' type, keep default as 'chiller'
      });
    } catch (e) {
      // Handle error silently or show a message
      print('Error loading fridge info: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
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
        // Set reminder date to 1 day before expiry by default
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

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _fridgeItemService.addFridgeItem(
        fridgeId: widget.fridgeId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        imageFile: _imageFile,
        expiryDate: _expiryDate,
        reminderDate: _reminderDate,
        compartment: _selectedCompartment,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Item name
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

              // Category dropdown
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
                    child: Text(category),
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

              // Compartment selection (only show if fridge type is "both")
              if (_fridge?.type == 'both') ...[
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

              // Expiry date
              InkWell(
                onTap: _selectExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('MMM d, yyyy').format(_expiryDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Reminder date
              InkWell(
                onTap: _selectReminderDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Reminder Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notifications),
                  ),
                  child: Text(DateFormat('MMM d, yyyy').format(_reminderDate)),
                ),
              ),
              const SizedBox(height: 24),

              // Add button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
