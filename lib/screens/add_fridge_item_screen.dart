import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/fridge_item_service.dart';
import '../services/fridge_service.dart';
import '../models/fridge_model.dart';
import '../utils/constants.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _ignoreExpiry = false;

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
      _updateExpiryByCategoryCompartment();
    } catch (e) {
      // Handle error silently or show a message
      print('Error loading fridge info: $e');
    }
  }

  // Load TFLite model and labels
  Future<void> _loadModel() async {
    if (_interpreter != null && _labels.isNotEmpty) return;
    _interpreter = await Interpreter.fromAsset(
      'assets/model/model_unquant.tflite',
    );
    final labelsTxt = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/model/labels.txt');
    _labels = labelsTxt.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  // Run inference on an image file
  Future<String?> _runInference(File imageFile) async {
    await _loadModel();
    // Read image from file
    final bytes = await imageFile.readAsBytes();
    img.Image? oriImage = img.decodeImage(bytes);
    if (oriImage == null) return null;
    // Resize to 224x224 (Teachable Machine default)
    img.Image resized = img.copyResize(oriImage, width: 224, height: 224);
    // Normalize to [0,1] and convert to float32
    var input = List.generate(
      1,
      (b) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) => List.generate(3, (c) {
            final pixel = resized.getPixel(x, y);
            return c == 0
                ? pixel.r
                : c == 1
                ? pixel.g
                : pixel.b;
          }, growable: false),
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    );
    // Convert to float32 and normalize
    var inputAsFloat = List.generate(
      1,
      (b) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) => List.generate(
            3,
            (c) => (input[b][y][x][c] / 255.0).toDouble(),
            growable: false,
          ),
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    );
    var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter!.run(inputAsFloat, output);
    final scores = output[0] as List<double>;
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIdx = scores.indexOf(maxScore);
    if (maxScore < 0.75) {
      return null; // Less than 75% confidence, treat as unclassified
    }
    return _labels[maxIdx];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
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
        final DateTime combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _expiryDate = combined;
          // Set reminder date为过期前一天同一时间
          _reminderDate = combined.subtract(const Duration(days: 1));
        });
      }
    }
  }

  Future<void> _selectReminderDate() async {
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
        final DateTime combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _reminderDate = combined;
        });
      }
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
        ignoreExpiry: _ignoreExpiry,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 800),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.pop(context);
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

  // Smart Insert button handler
  Future<void> _onSmartInsertPressed() async {
    _showImageSourceOptions(smartInsert: true);
  }

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
              const SizedBox(height: 16),
              // Smart Insert Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Smart Insert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _onSmartInsertPressed,
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
                    _updateExpiryByCategoryCompartment();
                    // Auto-switch compartment if needed
                    if (_fridge?.type == 'both' &&
                        (value == 'Meat & Poultry' || value == 'Frozen Food')) {
                      _selectedCompartment = 'freezer';
                    }
                    // User can still manually change compartment
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
                      _updateExpiryByCategoryCompartment();
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
                  child: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(_expiryDate),
                  ),
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
                  child: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(_reminderDate),
                  ),
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
              const SizedBox(height: 16),
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
                  const Text('Ignore expiry & reminder for this item'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions({bool smartInsert = false}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    _imageFile = File(image.path);
                  });
                  if (smartInsert) {
                    await _handleSmartInsertWithImage(_imageFile!);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (photo != null) {
                  setState(() {
                    _imageFile = File(photo.path);
                  });
                  if (smartInsert) {
                    await _handleSmartInsertWithImage(_imageFile!);
                  }
                }
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

  // New helper for smart insert with any image
  Future<void> _handleSmartInsertWithImage(File imageFile) async {
    final detectedCategory = await _runInference(imageFile);
    if (detectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unclassified item. Please insert manually.'),
        ),
      );
      setState(() {
        _imageFile = null;
      });
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Detected Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Detected category: $detectedCategory'),
            TextFormField(
              initialValue: detectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (val) => _selectedCategory = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final cleanedCategory = detectedCategory.replaceFirst(
        RegExp(r'^\d+\s*'),
        '',
      );
      _nameController.text = cleanedCategory;
      if (_categories.contains(cleanedCategory)) {
        setState(() {
          _selectedCategory = cleanedCategory;
          if (_fridge?.type == 'both' &&
              (cleanedCategory == 'Meat & Poultry' ||
                  cleanedCategory == 'Frozen Food')) {
            _selectedCompartment = 'freezer';
          }
        });
        _updateExpiryByCategoryCompartment();
      }
    } else {
      setState(() {
        _imageFile = null;
      });
    }
  }
}
