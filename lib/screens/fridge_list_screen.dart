import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fridge_service.dart';
import '../models/fridge_model.dart';
import '../utils/constants.dart';
import '../widgets/fridge/fridge_tile.dart';
import 'add_fridge_screen.dart';
import 'fridge_detail_screen.dart';

class FridgeListScreen extends StatefulWidget {
  const FridgeListScreen({super.key});

  @override
  State<FridgeListScreen> createState() => _FridgeListScreenState();
}

class _FridgeListScreenState extends State<FridgeListScreen> {
  final FridgeService _fridgeService = FridgeService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fridge List'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFridgeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view your fridges'))
          : StreamBuilder<List<FridgeModel>>(
              stream: _fridgeService.getFridges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading fridges: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final fridges = snapshot.data ?? [];

                if (fridges.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.kitchen_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Fridges Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Add your first fridge to start tracking items',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddFridgeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Fridge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group fridges: owned fridges first, then shared fridges
                final ownedFridges = fridges
                    .where((fridge) => fridge.ownerId == userId)
                    .toList();
                final sharedFridges = fridges
                    .where((fridge) => fridge.ownerId != userId)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (ownedFridges.isNotEmpty) ...[
                      const Text(
                        'My Fridges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ownedFridges.map(
                        (fridge) => FridgeTile(
                          fridge: fridge,
                          isOwner: true,
                          onTap: () => _navigateToFridgeDetail(fridge),
                          onEdit: () => _showEditFridgeDialog(fridge),
                          onDelete: () => _showDeleteFridgeDialog(fridge),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (sharedFridges.isNotEmpty) ...[
                      const Text(
                        'Shared With Me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sharedFridges.map(
                        (fridge) => FridgeTile(
                          fridge: fridge,
                          isOwner: false,
                          onTap: () => _navigateToFridgeDetail(fridge),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFridgeScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _navigateToFridgeDetail(FridgeModel fridge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FridgeDetailScreen(fridge: fridge),
      ),
    );
  }

  void _showEditFridgeDialog(FridgeModel fridge) {
    final nameController = TextEditingController(text: fridge.name);
    final formKey = GlobalKey<FormState>();
    String selectedType = fridge.type;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fridge'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Fridge Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Fridge Type'),
                items: const [
                  DropdownMenuItem(value: 'chiller', child: Text('Chiller')),
                  DropdownMenuItem(value: 'freezer', child: Text('Freezer')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                // Update the fridge
                final result = await _fridgeService.updateFridge(
                  fridgeId: fridge.id,
                  name: nameController.text.trim(),
                  type: selectedType,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success']
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFridgeDialog(FridgeModel fridge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fridge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${fridge.name}"?'),
            const SizedBox(height: 16),
            const Text(
              'This will permanently delete the fridge and all items in it.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              // Delete the fridge
              final result = await _fridgeService.deleteFridge(fridge.id);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: result['success']
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
