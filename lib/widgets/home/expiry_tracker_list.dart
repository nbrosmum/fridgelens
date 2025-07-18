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
        // 合并所有fridge的almost_expiry和expired item
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
            // 只显示当前用户有权限的item
            final filteredItems = allItems
                .where((item) => item.createdBy == userId)
                .toList();
            if (filteredItems.isEmpty) {
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Expiry Tracker List',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
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
                    return FridgeItemTile(
                      item: item,
                      fridgeOwnerId: fridge.ownerId,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FridgeDetailScreen(
                              fridge: fridge,
                              initialFilter:
                                  item.status, // 传递almost_expiry或expired
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
