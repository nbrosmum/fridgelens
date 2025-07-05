import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/shopping_service.dart';
import '../utils/constants.dart';
import '../utils/category_icons.dart';
import '../widgets/home/app_header.dart';
import '../widgets/shopping/shopping_item_tile.dart';
import '../widgets/shopping/add_shopping_item_dialog.dart';
import '../widgets/shopping/empty_shopping_list.dart';
import '../models/shopping_item_model.dart';
import 'change_password_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const FridgeTab(),
    const ShoppingListTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const AppHeader(
        title: AppStrings.appName,
        actions: [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.notifications_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome, ${user?.displayName ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'This is the home page of FridgeLens',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FridgeTab extends StatelessWidget {
  const FridgeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Fridge',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
            color: AppColors.primary,
          ),
        ],
      ),
      body: const Center(
        child: Text('Fridge Contents', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        heroTag: 'fridgeAddBtn',
        child: const Icon(Icons.add),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shopping List',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
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
    showDialog(
      context: context,
      builder: (context) => AddShoppingItemDialog(
        onAdd: (name, quantity, category) async {
          try {
            print('Dialog: Adding item $name, $quantity, category: $category');
            await _shoppingService.addShoppingItem(
              name: name,
              quantity: quantity,
              category: category,
            );
            print('Dialog: Item added successfully');

            // Show success message with green background
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
            print('Dialog: Error adding item: $e');

            // Show error message with red background
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
    showDialog(
      context: context,
      builder: (context) => AddShoppingItemDialog(
        isEditing: true,
        initialName: item.name,
        initialQuantity: item.quantity,
        initialCategory: item.category,
        onAdd: (name, quantity, category) async {
          try {
            final updatedItem = item.copyWith(
              name: name,
              quantity: quantity,
              category: category,
            );
            await _shoppingService.updateShoppingItem(updatedItem);

            // Show success message with green background
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
            // Show error message with red background
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
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
            icon: const Icon(Icons.logout),
            color: AppColors.primary,
          ),
        ],
      ),
      body: Center(
        child: Column(
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

            // 显示个人资料更新提醒
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
            _buildProfileOption(
              context,
              Icons.settings_outlined,
              'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
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
