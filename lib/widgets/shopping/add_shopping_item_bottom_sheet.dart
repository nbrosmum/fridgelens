import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'dart:io';
import '../common/image_picker_widget.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class AddShoppingItemBottomSheet extends StatefulWidget {
  final Function(
    String name,
    int quantity,
    String category, {
    File? imageFile,
    bool isFridge,
  })
  onAdd;
  final String? initialName;
  final int? initialQuantity;
  final String? initialCategory;
  final String? initialImageUrl;
  final bool isEditing;
  final bool? initialIsFridge;

  const AddShoppingItemBottomSheet({
    super.key,
    required this.onAdd,
    this.initialName,
    this.initialQuantity,
    this.initialCategory,
    this.initialImageUrl,
    this.isEditing = false,
    this.initialIsFridge,
  });

  @override
  State<AddShoppingItemBottomSheet> createState() =>
      _AddShoppingItemBottomSheetState();
}

class _AddShoppingItemBottomSheetState
    extends State<AddShoppingItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String _selectedCategory = 'Other';
  File? _imageFile;
  bool _isLoading = false;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isFridge = false;

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
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _quantityController = TextEditingController(
      text: (widget.initialQuantity ?? 1).toString(),
    );
    _selectedCategory = widget.initialCategory ?? 'Other';
    // Set _isFridge to true if editing and the item is a fridge item
    if (widget.isEditing && widget.initialIsFridge != null) {
      _isFridge = widget.initialIsFridge!;
    } else {
      _isFridge = false;
    }
  }

  Future<void> _loadModel(BuildContext context) async {
    if (_interpreter != null && _labels.isNotEmpty) return;
    _interpreter = await Interpreter.fromAsset(
      'assets/model/model_unquant.tflite',
    );
    final labelsTxt = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/model/labels.txt');
    _labels = labelsTxt.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  Future<String?> _runInference(BuildContext context, File imageFile) async {
    await _loadModel(context);
    final bytes = await imageFile.readAsBytes();
    img.Image? oriImage = img.decodeImage(bytes);
    if (oriImage == null) return null;
    img.Image resized = img.copyResize(oriImage, width: 224, height: 224);
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
      return null;
    }
    return _labels[maxIdx];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isEditing
                          ? 'Edit Shopping Item'
                          : 'Add Shopping Item',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Image picker and display
                if (widget.isEditing) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        image: (_imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : (widget.initialImageUrl != null &&
                                      widget.initialImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.initialImageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: AssetImage('assets/no_image.jpg'),
                                      fit: BoxFit.cover,
                                    ))),
                      ),
                    ),
                  ),
                ] else ...[
                  ImagePickerWidget(
                    initialImage: _imageFile,
                    onImagePicked: (file) {
                      setState(() {
                        _imageFile = file;
                      });
                    },
                    addLabel: 'Add Image',
                  ),
                  const SizedBox(height: 8),
                  // Smart insert button
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Smart Insert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final picked = await showModalBottomSheet<XFile?>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () async {
                                    final image = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 70,
                                    );
                                    Navigator.pop(context, image);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take a Photo'),
                                  onTap: () async {
                                    final photo = await ImagePicker().pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 70,
                                    );
                                    Navigator.pop(context, photo);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                        if (picked == null) return;
                        final file = File(picked.path);
                        final detected = await _runInference(context, file);
                        if (detected != null) {
                          // Clean label: remove leading numbers and spaces (e.g., '0 fruits' -> 'fruits')
                          final cleanedLabel = detected.replaceFirst(
                            RegExp(r'^\d+\s*'),
                            '',
                          );
                          // Try to match cleaned label to a category (case-insensitive)
                          String? matchedCategory = _categories.firstWhere(
                            (cat) =>
                                cat.toLowerCase() == cleanedLabel.toLowerCase(),
                            orElse: () => _selectedCategory,
                          );
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Detected Item'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Detected item: $cleanedLabel'),
                                  Text('Category: $matchedCategory'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            setState(() {
                              _nameController.text = cleanedLabel;
                              _selectedCategory = matchedCategory;
                              _imageFile = file;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Detected: $cleanedLabel'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unclassified item. Please insert manually.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
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
                              prefixIcon: Icon(Icons.shopping_bag_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter item name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return 'Please enter valid quantity';
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
                              prefixIcon: Icon(Icons.category_outlined),
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
                          const SizedBox(height: 24),
                          // Move isFridge checkbox here, below category
                          Row(
                            children: [
                              Checkbox(
                                value: _isFridge,
                                onChanged: (val) {
                                  setState(() {
                                    _isFridge = val ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text(
                                'Fridge Item',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
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
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    widget.onAdd(
                                      _nameController.text.trim(),
                                      int.parse(_quantityController.text),
                                      _selectedCategory,
                                      imageFile: _imageFile,
                                      isFridge: _isFridge,
                                    );
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(widget.isEditing ? 'Save' : 'Add'),
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
