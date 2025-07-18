import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/fridge_service.dart';
import '../../services/fridge_item_service.dart';
import '../../models/fridge_model.dart';
import '../../models/fridge_item_model.dart';
import '../fridge/fridge_item_tile.dart';
import '../../screens/fridge_detail_screen.dart';
import 'package:async/async.dart';

class ExpiryTrackerList extends StatelessWidget {
  const ExpiryTrackerList({super.key});

  @override
  Widget build(BuildContext context) {
    final fridgeService = FridgeService();
    final fridgeItemService = FridgeItemService();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox();
    }

    return StreamBuilder<List<FridgeModel>>(
      stream: fridgeService.getFridges(),
      builder: (context, fridgeSnapshot) {
        if (fridgeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final fridges = fridgeSnapshot.data ?? [];
        if (fridges.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No fridge data',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }
        // Merge all almost_expiry and expired items from all fridges
        return StreamBuilder<List<List<FridgeItemModel>>>(
          stream: StreamZip([
            ...fridges.map(
              (fridge) => fridgeItemService.getItemsByStatus(
                fridge.id,
                'almost_expiry',
              ),
            ),
            ...fridges.map(
              (fridge) =>
                  fridgeItemService.getItemsByStatus(fridge.id, 'expired'),
            ),
          ]),
          builder: (context, itemSnapshot) {
            if (itemSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allItems = itemSnapshot.data?.expand((x) => x).toList() ?? [];
            // Group items by status
            final almostExpiryItems = allItems
                .where((item) => item.status == 'almost_expiry')
                .toList();
            final expiredItems = allItems
                .where((item) => item.status == 'expired')
                .toList();
            if (almostExpiryItems.isEmpty && expiredItems.isEmpty) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No almost expired or expired items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }
            Widget buildSection(
              String title,
              List<FridgeItemModel> items,
              Color color,
              IconData icon,
            ) {
              if (items.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final fridge = fridges.firstWhere(
                        (f) => f.id == item.fridgeId,
                        orElse: () => FridgeModel(
                          id: '',
                          name: '',
                          type: '',
                          ownerId: '',
                          contributors: [],
                          createdAt: DateTime.now(),
                        ),
                      );
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FridgeItemTile(
                          item: item,
                          fridgeOwnerId: fridge.ownerId,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FridgeDetailScreen(
                                  fridge: fridge,
                                  initialFilter: item.status,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Expiry Tracker List',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                buildSection(
                  'Expired',
                  expiredItems,
                  Colors.red,
                  Icons.warning_amber_rounded,
                ),
                if (expiredItems.isNotEmpty && almostExpiryItems.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(thickness: 1.2, height: 24),
                  ),
                buildSection(
                  'Almost Expiry',
                  almostExpiryItems,
                  Colors.orange,
                  Icons.access_time_rounded,
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}
