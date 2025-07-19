import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/shopping_service.dart';
import '../utils/constants.dart';
import '../utils/category_icons.dart';
import '../widgets/home/app_header.dart';
import '../widgets/shopping/shopping_item_tile.dart';
import '../widgets/shopping/empty_shopping_list.dart';
import '../models/shopping_item_model.dart';
import 'change_password_screen.dart';
import 'fridge_list_screen.dart';
import 'friend_list_screen.dart';
import 'notification_screen.dart';
import 'history_screen.dart';
import '../services/friend_service.dart';
import '../services/notification_service.dart';
import '../widgets/shopping/add_shopping_item_bottom_sheet.dart';
import '../widgets/home/fridge_usage_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/history_service.dart';
import '../models/history_item_model.dart';
import 'package:async/async.dart';
import '../services/fridge_service.dart';
import '../services/fridge_item_service.dart';
import '../models/fridge_model.dart';
import '../models/fridge_item_model.dart';
import '../widgets/home/expiry_tracker_list.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/imagekit_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Use GlobalKey to access HomeTabState
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  late final List<Widget> _screens = [
    HomeTab(key: _homeTabKey),
    const FridgeTab(),
    const ShoppingListTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // If Home tab is tapped, trigger refreshAll
    if (index == 0) {
      _homeTabKey.currentState?._refreshAll();
    }
    // If Fridge tab is tapped, update all fridge item status
    if (index == 1) {
      FridgeItemService().updateAllItemsStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.kitchen_outlined, size: 24),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.kitchen, size: 24),
                ),
                label: 'Fridge',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.shopping_cart_outlined, size: 24),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.shopping_cart, size: 24),
                ),
                label: 'Shopping',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _filter = 'Week'; // 'Week', 'Month', 'Year'
  bool _isRefreshing = false;

  // Refresh all components on the home page
  Future<void> _refreshAll() async {
    setState(() {
      _isRefreshing = true;
    });
    // Optionally: call backend services to sync status/data
    try {
      await Future.wait([
        // Add any service refresh methods here if needed
        // Example: await FridgeItemService().updateAllItemsStatus(),
        // Example: await NotificationService().refresh(),
        Future.delayed(
          const Duration(milliseconds: 500),
        ), // Simulate refresh delay
      ]);
    } catch (e) {
      // Handle error if needed
    }
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Auto refresh when page loads
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppHeader(
        title: AppStrings.appName,
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final hasNotifications = snapshot.hasData && snapshot.data! > 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showNotificationsScreen(context),
                  ),
                  if (hasNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: _isRefreshing
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : _refreshAll,
          ),
        ],
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fridge usage chart
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fridge Usage Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Show by:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _filter,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Week',
                                    child: Text('Week'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Month',
                                    child: Text('Month'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Year',
                                    child: Text('Year'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _filter = value);
                                  }
                                },
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<List<HistoryItemModel>>(
                        stream: HistoryService().getUserHistory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final history = snapshot.data ?? [];
                          final now = DateTime.now();
                          List<String> xLabels = [];
                          List<String> xDates = [];
                          List<FlSpot> usedSpots = [];
                          List<FlSpot> clearSpots = [];
                          String label = _filter;
                          if (_filter == 'Week') {
                            final startOfWeek = now.subtract(
                              Duration(days: now.weekday - 1),
                            );
                            xLabels = List.generate(
                              7,
                              (i) => [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ][i],
                            );
                            xDates = List.generate(7, (i) {
                              final day = startOfWeek.add(Duration(days: i));
                              return "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                            });
                            usedSpots = List.generate(7, (i) {
                              final day = startOfWeek.add(Duration(days: i));
                              final count = history
                                  .where(
                                    (h) =>
                                        h.status == 'used' &&
                                        h.usedAt.year == day.year &&
                                        h.usedAt.month == day.month &&
                                        h.usedAt.day == day.day,
                                  )
                                  .length;
                              return FlSpot(i.toDouble(), count.toDouble());
                            });
                            clearSpots = List.generate(7, (i) {
                              final day = startOfWeek.add(Duration(days: i));
                              final count = history
                                  .where(
                                    (h) =>
                                        h.status == 'clear' &&
                                        h.usedAt.year == day.year &&
                                        h.usedAt.month == day.month &&
                                        h.usedAt.day == day.day,
                                  )
                                  .length;
                              return FlSpot(i.toDouble(), count.toDouble());
                            });
                          } else if (_filter == 'Month') {
                            final daysInMonth = DateTime(
                              now.year,
                              now.month + 1,
                              0,
                            ).day;
                            xLabels = List.generate(
                              daysInMonth,
                              (i) => (i + 1).toString(),
                            );
                            xDates = List.generate(daysInMonth, (i) {
                              final day = DateTime(now.year, now.month, i + 1);
                              return "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                            });
                            usedSpots = List.generate(daysInMonth, (i) {
                              final day = DateTime(now.year, now.month, i + 1);
                              final count = history
                                  .where(
                                    (h) =>
                                        h.status == 'used' &&
                                        h.usedAt.year == day.year &&
                                        h.usedAt.month == day.month &&
                                        h.usedAt.day == day.day,
                                  )
                                  .length;
                              return FlSpot(i.toDouble(), count.toDouble());
                            });
                            clearSpots = List.generate(daysInMonth, (i) {
                              final day = DateTime(now.year, now.month, i + 1);
                              final count = history
                                  .where(
                                    (h) =>
                                        h.status == 'clear' &&
                                        h.usedAt.year == day.year &&
                                        h.usedAt.month == day.month &&
                                        h.usedAt.day == day.day,
                                  )
                                  .length;
                              return FlSpot(i.toDouble(), count.toDouble());
                            });
                          } else {
                            xLabels = List.generate(
                              12,
                              (i) => [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                              ][i],
                            );
                            xDates = List.generate(
                              12,
                              (i) =>
                                  "${now.year}-${(i + 1).toString().padLeft(2, '0')}",
                            );
                            usedSpots = List.generate(12, (i) {
                              final month = i + 1;
                              final count = history
                                  .where(
                                    (h) =>
                                        h.status == 'used' &&
                                        h.usedAt.year == now.year &&
                                        h.usedAt.month == month,
                                  )
                                  .length;
                              return FlSpot(i.toDouble(), count.toDouble());
                            });
                            clearSpots = List.generate(12, (i) {
                              final month = i + 1;
                              final count = history
                                  .where(
                                    (h) =>
                                        h.status == 'clear' &&
                                        h.usedAt.year == now.year &&
                                        h.usedAt.month == month,
                                  )
                                  .length;
                              return FlSpot(i.toDouble(), count.toDouble());
                            });
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: FridgeUsageChart(
                              usedSpots: usedSpots,
                              clearSpots: clearSpots,
                              filterLabel: label,
                              xLabels: xLabels,
                              xDates: xDates,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Add summary cards
              const SizedBox(height: 16),
              _HomeSummaryCards(),
              const SizedBox(height: 16),
              ExpiryTrackerList(),
            ],
          ),
        ),
      ),
    );
  }

  static void _showNotificationsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }
}

class FridgeTab extends StatelessWidget {
  const FridgeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the FridgeListScreen for the Fridge tab
    return const FridgeListScreen();
  }
}

class ShoppingListTab extends StatefulWidget {
  const ShoppingListTab({super.key});

  @override
  State<ShoppingListTab> createState() => _ShoppingListTabState();
}

class _ShoppingListTabState extends State<ShoppingListTab> {
  final ShoppingService _shoppingService = ShoppingService();
  bool _showCompleted = true;

  void _batchInsertToFridge(List<ShoppingItem> items) async {
    // Show fridge selection dialog
    final fridgeService = FridgeService();
    final fridges = await fridgeService.getFridges().first;
    String? selectedFridgeId;
    FridgeModel? selectedFridge;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Fridge'),
        content: SizedBox(
          width: double.maxFinite,
          child: fridges.isEmpty
              ? const Text('No fridges available.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: fridges.length,
                  itemBuilder: (context, index) {
                    final fridge = fridges[index];
                    const icon = Icons.kitchen;
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(icon, color: AppColors.primary, size: 32),
                        title: Text(
                          fridge.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        subtitle: Text(
                          'Type: ${fridge.type[0].toUpperCase()}${fridge.type.substring(1)}',
                          style: TextStyle(color: Colors.black54),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          selectedFridgeId = fridge.id;
                          selectedFridge = fridge;
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
    if (selectedFridgeId == null || selectedFridge == null) return;
    // Batch insert logic
    final fridgeItemService = FridgeItemService();
    int success = 0;
    int fail = 0;
    for (final item in items) {
      String newImageUrl = '';
      String newFileId = '';
      if (item.imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(item.imageUrl));
          if (response.statusCode == 200) {
            final tempDir = await Directory.systemTemp.createTemp(
              'fridgelens_fridgeitem',
            );
            final tempFile = File('${tempDir.path}/temp_image.jpg');
            await tempFile.writeAsBytes(response.bodyBytes);
            final folderPath = '/fridge_items/$selectedFridgeId';
            final uploadResult = await ImageKitHelper.uploadImageToImageKit(
              tempFile,
              folderPath,
            );
            await tempFile.delete();
            await tempDir.delete();
            if (uploadResult['success']) {
              newImageUrl = uploadResult['url'];
              newFileId = uploadResult['fileId'];
            }
          }
        } catch (e) {
          print('Image transfer error: $e');
        }
      }
      final logic = getExpiryAndCompartment(
        fridgeType: selectedFridge!.type,
        category: item.category,
      );
      final result = await fridgeItemService.addFridgeItem(
        fridgeId: selectedFridgeId!,
        name: item.name,
        category: item.category,
        imageFile: null,
        imageUrl: newImageUrl.isNotEmpty ? newImageUrl : null,
        fileId: newFileId.isNotEmpty ? newFileId : null,
        expiryDate: logic['expiryDate'],
        reminderDate: logic['reminderDate'],
        compartment: logic['compartment'],
      );
      if (result['success']) {
        await _shoppingService.deleteShoppingItem(item.id);
        // Delete original image from shopping folder
        if (item.fileId.isNotEmpty) {
          await ImageKitHelper.deleteImageFromImageKit(item.fileId);
        }
        success++;
      } else {
        fail++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inserted $success item(s) to fridge. Failed: $fail'),
          backgroundColor: success > 0 ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Shopping List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            icon: Icon(
              _showCompleted ? Icons.check_circle_outline : Icons.check_circle,
              color: AppColors.primary,
            ),
            tooltip: _showCompleted ? 'Hide Completed' : 'Show Completed',
          ),
          IconButton(
            icon: const Icon(Icons.move_to_inbox, color: Colors.white),
            tooltip: 'Insert All to Fridge',
            onPressed: () async {
              final allItems = await _shoppingService.getShoppingItems().first;
              final completedFridgeItems = allItems
                  .where((item) => item.isCompleted && item.isFridge)
                  .toList();
              if (completedFridgeItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No completed fridge items to insert.'),
                  ),
                );
                return;
              }
              _batchInsertToFridge(completedFridgeItems);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_completed') {
                _showClearCompletedDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Completed Items'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<List<ShoppingItem>>(
        stream: _shoppingService.getShoppingItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          // Filter out completed items if not showing completed
          final filteredItems = _showCompleted
              ? items
              : items.where((item) => !item.isCompleted).toList();

          if (filteredItems.isEmpty) {
            return EmptyShoppingList(onAddItem: _showAddItemDialog);
          }

          // Group by category
          final Map<String, List<ShoppingItem>> categorizedItems = {};
          for (var item in filteredItems) {
            if (!categorizedItems.containsKey(item.category)) {
              categorizedItems[item.category] = [];
            }
            categorizedItems[item.category]!.add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            itemCount: categorizedItems.length,
            itemBuilder: (context, index) {
              final category = categorizedItems.keys.elementAt(index);
              final categoryItems = categorizedItems[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CategoryIcons.getColorForCategory(
                        category,
                      ).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CategoryIcons.getIconForCategory(category),
                          color: CategoryIcons.getColorForCategory(category),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CategoryIcons.getColorForCategory(category),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CategoryIcons.getColorForCategory(
                              category,
                            ).withAlpha(80),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categoryItems.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CategoryIcons.getColorForCategory(
                                category,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...categoryItems.map(
                    (item) => ShoppingItemTile(
                      item: item,
                      onToggle: (value) {
                        _shoppingService.toggleItemCompletion(item);
                      },
                      onToggleIsFridge: (value) async {
                        final updatedItem = item.copyWith(
                          isFridge: value ?? false,
                        );
                        await _shoppingService.updateShoppingItem(updatedItem);
                      },
                      onDelete: () async {
                        try {
                          await _shoppingService.deleteShoppingItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('${item.name} deleted'),
                                ],
                              ),
                              backgroundColor: Colors.red[700],
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: Colors.white,
                                onPressed: () {
                                  _shoppingService.addShoppingItem(
                                    name: item.name,
                                    quantity: item.quantity,
                                    category: item.category,
                                  );
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('Failed to delete item: $e'),
                                ],
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      onEdit: () {
                        _showEditItemDialog(item);
                      },
                      onInsertToFridge: () async {
                        final fridgeService = FridgeService();
                        final fridges = await fridgeService.getFridges().first;
                        String? selectedFridgeId;
                        FridgeModel? selectedFridge;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Fridge'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: fridges.isEmpty
                                  ? const Text('No fridges available.')
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: fridges.length,
                                      itemBuilder: (context, index) {
                                        final fridge = fridges[index];
                                        // Always use kitchen icon and primary color
                                        const icon = Icons.kitchen;
                                        return Card(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: ListTile(
                                            leading: Icon(
                                              icon,
                                              color: AppColors.primary,
                                              size: 32,
                                            ),
                                            title: Text(
                                              fridge.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Type: ${fridge.type[0].toUpperCase()}${fridge.type.substring(1)}',
                                              style: TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            trailing: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 18,
                                              color: Colors.grey,
                                            ),
                                            onTap: () {
                                              selectedFridgeId = fridge.id;
                                              selectedFridge = fridge;
                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        );
                        if (selectedFridgeId != null &&
                            selectedFridge != null) {
                          // 1. Download and re-upload image to fridge folder
                          String newImageUrl = '';
                          String newFileId = '';
                          if (item.imageUrl.isNotEmpty) {
                            try {
                              final response = await http.get(
                                Uri.parse(item.imageUrl),
                              );
                              if (response.statusCode == 200) {
                                final tempDir = await Directory.systemTemp
                                    .createTemp('fridgelens_fridgeitem');
                                final tempFile = File(
                                  '${tempDir.path}/temp_image.jpg',
                                );
                                await tempFile.writeAsBytes(response.bodyBytes);
                                final folderPath =
                                    '/fridge_items/$selectedFridgeId';
                                final uploadResult =
                                    await ImageKitHelper.uploadImageToImageKit(
                                      tempFile,
                                      folderPath,
                                    );
                                await tempFile.delete();
                                await tempDir.delete();
                                if (uploadResult['success']) {
                                  newImageUrl = uploadResult['url'];
                                  newFileId = uploadResult['fileId'];
                                }
                              }
                            } catch (e) {
                              print('Image transfer error: $e');
                            }
                          }
                          // 2. Expiry/compartment logic
                          final logic = getExpiryAndCompartment(
                            fridgeType: selectedFridge!.type,
                            category: item.category,
                          );
                          // 3. Add to fridge
                          final fridgeItemService = FridgeItemService();
                          final result = await fridgeItemService.addFridgeItem(
                            fridgeId: selectedFridgeId!,
                            name: item.name,
                            category: item.category,
                            imageFile: null, // Already uploaded
                            imageUrl: newImageUrl.isNotEmpty
                                ? newImageUrl
                                : null,
                            fileId: newFileId.isNotEmpty ? newFileId : null,
                            expiryDate: logic['expiryDate'],
                            reminderDate: logic['reminderDate'],
                            compartment: logic['compartment'],
                          );
                          // 4. Delete from shopping list if success
                          if (result['success']) {
                            await _shoppingService.deleteShoppingItem(item.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Inserted to fridge!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed: ${result['message']}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppColors.primary,
        heroTag: 'shoppingAddBtn',
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  void _showAddItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddShoppingItemBottomSheet(
        onAdd: (name, quantity, category, {imageFile, isFridge = false}) async {
          try {
            await _shoppingService.addShoppingItem(
              name: name,
              quantity: quantity,
              category: category,
              imageFile: imageFile,
              isFridge: isFridge,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('$name added to shopping list'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Failed to add item: $e'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditItemDialog(ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddShoppingItemBottomSheet(
        isEditing: true,
        initialName: item.name,
        initialQuantity: item.quantity,
        initialCategory: item.category,
        initialImageUrl: item.imageUrl, // Pass the image URL here
        initialIsFridge: item.isFridge,
        onAdd: (name, quantity, category, {imageFile, isFridge = false}) async {
          try {
            final updatedItem = item.copyWith(
              name: name,
              quantity: quantity,
              category: category,
              isFridge: isFridge,
              // Image editing not supported yet
            );
            await _shoppingService.updateShoppingItem(updatedItem);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('$name updated successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Failed to update item: $e'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showClearCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Items'),
        content: const Text(
          'Are you sure you want to delete all completed items? This action cannot be undone.',
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
              try {
                await _shoppingService.clearCompletedItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.cleaning_services, color: Colors.white),
                        SizedBox(width: 8),
                        Text('All completed items cleared'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Failed to clear items: $e'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  bool _showProfileUpdateReminder = true;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    final userData = await _authService.getUserData();
    if (mounted) {
      setState(() {
        // Check if phone number or date of birth is empty
        _showProfileUpdateReminder =
            userData?.phoneNumber == null ||
            userData?.phoneNumber?.isEmpty == true ||
            userData?.dateOfBirth == null ||
            userData?.dateOfBirth?.isEmpty == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await _authService.signOut();
                print('Logout successful from ProfileTab');

                // Use Navigator to go to login screen after logout
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              } catch (e) {
                print('Error during logout: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 50,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  user?.email ?? 'No email',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Show profile update reminder
            if (_showProfileUpdateReminder)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please complete your profile information',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FriendService().getPendingFriendRequests(),
              builder: (context, snapshot) {
                final hasRequests =
                    snapshot.hasData && snapshot.data!.isNotEmpty;
                return _buildProfileOption(
                  context,
                  Icons.people_outline,
                  'Friends',
                  showBadge: hasRequests,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendListScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            _buildProfileOption(
              context,
              Icons.history,
              'History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              Icons.person_outline,
              'Edit Profile',
              showBadge: _showProfileUpdateReminder,
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/edit_profile',
                );
                if (result == true) {
                  // Check profile completion status after update
                  _checkProfileCompletion();
                }
              },
            ),
            _buildProfileOption(
              context,
              Icons.lock_outline,
              'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(icon, color: AppColors.secondary, size: 24),
                  if (showBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSummaryCards extends StatelessWidget {
  const _HomeSummaryCards();

  @override
  Widget build(BuildContext context) {
    // Get all fridge IDs
    final fridgeStream = FridgeService().getFridges();
    // Get user history stream
    final historyStream = HistoryService().getUserHistory();
    return StreamBuilder<List<FridgeModel>>(
      stream: fridgeStream,
      builder: (context, fridgeSnapshot) {
        if (fridgeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final fridges = fridgeSnapshot.data ?? [];
        if (fridges.isEmpty) {
          return Row(
            children: [
              _buildCard(
                context,
                Icons.kitchen,
                'Total in Fridge',
                '0',
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildCard(
                context,
                Icons.delete_forever,
                'Expired/Wasted',
                '0',
                Colors.red,
              ),
            ],
          );
        }
        // Merge all fridge_items streams
        final fridgeIds = fridges.map((f) => f.id).toList();
        return StreamBuilder<List<List<FridgeItemModel>>>(
          stream: StreamZip(
            fridgeIds.map((id) => FridgeItemService().getFridgeItems(id)),
          ),
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Merge all fridge_items
            final userId = FridgeItemService().currentUserId;
            final allItems = (itemsSnapshot.data ?? [])
                .expand((x) => x)
                .where((item) => item.createdBy == userId)
                .toList();
            return StreamBuilder<List<HistoryItemModel>>(
              stream: historyStream,
              builder: (context, historySnapshot) {
                final history = historySnapshot.data ?? [];
                final wastedCount = history
                    .where((h) => h.status == 'clear')
                    .length;
                return Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        context,
                        Icons.kitchen,
                        'Total in Fridge',
                        allItems.length.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCard(
                        context,
                        Icons.delete_forever,
                        'Expired/Wasted',
                        wastedCount.toString(),
                        Colors.red,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
