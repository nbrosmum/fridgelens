import 'package:flutter/material.dart';
import '../models/fridge_model.dart';
import '../models/fridge_item_model.dart';
import '../services/fridge_service.dart';
import '../services/fridge_item_service.dart';
import '../utils/constants.dart';
import '../widgets/fridge/fridge_item_tile.dart';
import '../widgets/fridge/add_contributor_dialog.dart';
import 'add_fridge_item_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/fridge/edit_fridge_item_dialog.dart';

class FridgeDetailScreen extends StatefulWidget {
  final FridgeModel fridge;

  const FridgeDetailScreen({super.key, required this.fridge});

  @override
  State<FridgeDetailScreen> createState() => _FridgeDetailScreenState();
}

class _FridgeDetailScreenState extends State<FridgeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FridgeItemService _fridgeItemService = FridgeItemService();
  final FridgeService _fridgeService = FridgeService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'all';
  bool _freezerExpanded = true;
  bool _chillerExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isOwner => widget.fridge.ownerId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fridge.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddContributorDialog,
              tooltip: 'Add Contributors',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Items')),
              const PopupMenuItem(value: 'fresh', child: Text('Fresh Items')),
              const PopupMenuItem(
                value: 'almost_expiry',
                child: Text('Almost Expired'),
              ),
              const PopupMenuItem(value: 'expired', child: Text('Expired')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Items'),
            Tab(text: 'Contributors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildItemsTab(), _buildContributorsTab()],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddFridgeItemScreen(fridgeId: widget.fridge.id),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildItemsTab() {
    return StreamBuilder<List<FridgeItemModel>>(
      stream: _selectedFilter == 'all'
          ? _fridgeItemService.getFridgeItems(widget.fridge.id)
          : _fridgeItemService.getItemsByStatus(
              widget.fridge.id,
              _selectedFilter,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading items: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedFilter == 'all'
                      ? Icons.inventory_2_outlined
                      : Icons.filter_list,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'all'
                      ? 'No items in this fridge'
                      : 'No ${_selectedFilter.replaceAll('_', ' ')} items',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFilter == 'all'
                      ? 'Add items to keep track of your fridge contents'
                      : 'Try a different filter',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (_selectedFilter == 'all')
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddFridgeItemScreen(fridgeId: widget.fridge.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // If fridge type is "both", group by compartment first, then by category
        if (widget.fridge.type == 'both') {
          return _buildBothCompartmentsView(items);
        } else {
          // For single compartment fridges, group by category only
          return _buildSingleCompartmentView(items);
        }
      },
    );
  }

  Widget _buildBothCompartmentsView(List<FridgeItemModel> items) {
    // Separate items by compartment
    final freezerItems = items
        .where((item) => item.compartment == 'freezer')
        .toList();
    final chillerItems = items
        .where((item) => item.compartment == 'chiller')
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Freezer Section
        _buildCollapsibleCompartment(
          'Freezer',
          Icons.ac_unit,
          Colors.blue,
          freezerItems,
          _freezerExpanded,
          (value) => setState(() => _freezerExpanded = value),
        ),
        const SizedBox(height: 16),

        // Chiller Section
        _buildCollapsibleCompartment(
          'Chiller',
          Icons.kitchen,
          Colors.green,
          chillerItems,
          _chillerExpanded,
          (value) => setState(() => _chillerExpanded = value),
        ),
      ],
    );
  }

  Widget _buildSingleCompartmentView(List<FridgeItemModel> items) {
    // Group items by category
    final Map<String, List<FridgeItemModel>> categorizedItems = {};
    for (var item in items) {
      if (!categorizedItems.containsKey(item.category)) {
        categorizedItems[item.category] = [];
      }
      categorizedItems[item.category]!.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: categorizedItems.length,
      itemBuilder: (context, index) {
        final category = categorizedItems.keys.elementAt(index);
        final categoryItems = categorizedItems[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...categoryItems.map(
              (item) => FridgeItemTile(
                item: item,
                onTap: () => _showItemDetailsDialog(item),
                onStatusChange: _updateItemStatus,
                onDelete: () => _deleteItem(item),
                onEdit: () => _showEditFridgeItemDialog(item),
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }

  List<Widget> _buildCompartmentItems(List<FridgeItemModel> items) {
    // Group items by category within the compartment
    final Map<String, List<FridgeItemModel>> categorizedItems = {};
    for (var item in items) {
      if (!categorizedItems.containsKey(item.category)) {
        categorizedItems[item.category] = [];
      }
      categorizedItems[item.category]!.add(item);
    }

    List<Widget> widgets = [];

    categorizedItems.forEach((category, categoryItems) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      );

      widgets.addAll(
        categoryItems.map(
          (item) => FridgeItemTile(
            item: item,
            onTap: () => _showItemDetailsDialog(item),
            onStatusChange: _updateItemStatus,
            onDelete: () => _deleteItem(item),
            onEdit: () => _showEditFridgeItemDialog(item),
          ),
        ),
      );

      widgets.add(const Divider());
    });

    return widgets;
  }

  Widget _buildEmptyCompartment(String compartment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            compartment == 'freezer' ? Icons.ac_unit : Icons.kitchen,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No items in $compartment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to start tracking',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsTab() {
    return StreamBuilder<FridgeModel?>(
      stream: _fridgeService.getFridge(widget.fridge.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading contributors: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final fridge = snapshot.data;
        if (fridge == null) {
          return const Center(child: Text('Fridge not found'));
        }

        final contributors = fridge.contributors;
        final isOwner = fridge.ownerId == _currentUserId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                'Owner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOwner ? AppColors.primary : Colors.black87,
                ),
              ),
              subtitle: const Text(
                'This person has full control of this fridge',
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              trailing: isOwner
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Contributors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (isOwner && contributors.isNotEmpty)
                    TextButton.icon(
                      onPressed: _showManageContributorsDialog,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Manage'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            contributors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No contributors yet. Contributors can view and add items to this fridge.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: contributors.length,
                      itemBuilder: (context, index) {
                        final contributorId = contributors[index];
                        // In a real app, you would fetch user data by ID
                        return ListTile(
                          title: Text('Contributor $contributorId'),
                          subtitle: const Text('Can view and add items'),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.secondary,
                            ),
                          ),
                          trailing: isOwner
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _removeContributor(contributorId),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }

  void _showAddContributorDialog() {
    showDialog(
      context: context,
      builder: (context) => AddContributorDialog(fridgeId: widget.fridge.id),
    );
  }

  void _showItemDetailsDialog(FridgeItemModel item) {
    // Implement item details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl.isNotEmpty)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            const SizedBox(height: 16),
            _buildItemDetail('Category', item.category),
            _buildItemDetail('Status', item.status),
            _buildItemDetail(
              'Expiry Date',
              '${item.expiryDate.day}/${item.expiryDate.month}/${item.expiryDate.year}',
            ),
            _buildItemDetail(
              'Reminder Date',
              '${item.reminderDate.day}/${item.reminderDate.month}/${item.reminderDate.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _updateItemStatus(FridgeItemModel item, String newStatus) async {
    try {
      final result = await _fridgeItemService.updateItemStatus(
        itemId: item.id,
        status: newStatus,
      );

      if (mounted && !result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(FridgeItemModel item) async {
    try {
      final result = await _fridgeItemService.deleteFridgeItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showManageContributorsDialog() {
    // Implement manage contributors dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Contributors'),
        content: const Text('Select contributors to remove from this fridge.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeContributor(String contributorId) async {
    try {
      final result = await _fridgeService.removeContributor(
        fridgeId: widget.fridge.id,
        contributorId: contributorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing contributor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCollapsibleCompartment(
    String title,
    IconData icon,
    Color color,
    List<FridgeItemModel> items,
    bool isExpanded,
    Function(bool) onExpansionChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: color,
        collapsedIconColor: color,
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        children: items.isEmpty
            ? [_buildEmptyCompartment(title.toLowerCase())]
            : _buildCompartmentItems(items),
      ),
    );
  }

  void _showEditFridgeItemDialog(FridgeItemModel item) async {
    print('Opening edit dialog for item: ${item.name}');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          EditFridgeItemDialog(item: item, fridge: widget.fridge),
    );
    if (result != null && result['updated'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
