import 'package:flutter/material.dart';
import '../services/fridge_service.dart';
import '../utils/constants.dart';

class AddFridgeScreen extends StatefulWidget {
  const AddFridgeScreen({super.key});

  @override
  State<AddFridgeScreen> createState() => _AddFridgeScreenState();
}

class _AddFridgeScreenState extends State<AddFridgeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'both'; // Default type
  bool _isLoading = false;

  final FridgeService _fridgeService = FridgeService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createFridge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide any previous SnackBar before starting
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _fridgeService.createFridge(
        name: _nameController.text.trim(),
        type: _selectedType,
      );

      if (mounted) {
        if (result['success']) {
          // Hide any error SnackBar before showing success
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fridge created successfully'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 600),
            ),
          );
          // Wait for SnackBar to show, then pop
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) Navigator.pop(context);
        } else {
          // Show error message
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
            content: Text('Error creating fridge: $e'),
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
        title: const Text('Add New Fridge'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fridge Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Fridge Name',
                  hintText: 'Enter a name for your fridge',
                  prefixIcon: Icon(Icons.kitchen),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your fridge';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Fridge Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createFridge,
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
                      : const Text('Create Fridge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: [
        _buildTypeOption(
          'chiller',
          'Chiller',
          'For refrigerated items (2°C to 8°C)',
          Icons.kitchen,
          Colors.green,
        ),
        _buildTypeOption(
          'freezer',
          'Freezer',
          'For frozen items (below 0°C)',
          Icons.ac_unit,
          Colors.blue,
        ),
        _buildTypeOption(
          'both',
          'Both',
          'Combination of chiller and freezer sections',
          Icons.kitchen,
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedType == value ? color : Colors.grey[300]!,
            width: _selectedType == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedType == value ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == value ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedType == value ? color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedType,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedType = newValue;
                  });
                }
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
