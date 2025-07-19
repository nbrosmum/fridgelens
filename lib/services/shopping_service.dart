import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_item_model.dart';
import 'dart:io';
import '../utils/imagekit_helper.dart';

class ShoppingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Get shopping list collection reference
  CollectionReference get _shoppingCollection =>
      _firestore.collection('shopping_lists');

  // Get current user's shopping list
  Stream<List<ShoppingItem>> getShoppingItems() {
    if (_userId == null) {
      return Stream.value([]);
    }

    // Modified query to avoid requiring composite index
    // Only filter by userId, then sort the results in memory
    return _shoppingCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList();

          // Sort in memory instead of in the query
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return items;
        });
  }

  // Add shopping item
  Future<void> addShoppingItem({
    required String name,
    required int quantity,
    required String category,
    File? imageFile,
    bool isFridge = false,
  }) async {
    try {
      print(
        'Adding shopping item: $name, quantity: $quantity, category: $category',
      );
      print('Current user ID:  [38;5;2m [1m [4m$_userId [0m');

      if (_userId == null) {
        print('Error: User not logged in');
        throw Exception('User not logged in');
      }

      // Upload image to /shopping/userID
      String imageUrl = '';
      String fileId = '';
      if (imageFile != null) {
        final folderPath = '/shopping/$_userId';
        final uploadResult = await ImageKitHelper.uploadImageToImageKit(
          imageFile,
          folderPath,
        );
        if (uploadResult['success']) {
          imageUrl = uploadResult['url'];
          fileId = uploadResult['fileId'] ?? '';
        } else {
          print('Image upload failed:  [31m${uploadResult['error']} [0m');
        }
      }

      // Create the item data
      final itemData = {
        'name': name,
        'quantity': quantity,
        'isCompleted': false,
        'category': category,
        'userId': _userId,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'fileId': fileId,
        'isFridge': isFridge,
      };

      print('Item data to add: $itemData');

      // Add the document to Firestore
      final docRef = await _shoppingCollection.add(itemData);
      print('Item added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding shopping item: $e');
      rethrow; // Re-throw the exception for the caller to handle
    }
  }

  // Update shopping item
  Future<void> updateShoppingItem(ShoppingItem item) async {
    await _shoppingCollection.doc(item.id).update(item.toFirestore());
  }

  // Toggle shopping item completion status
  Future<void> toggleItemCompletion(ShoppingItem item) async {
    await _shoppingCollection.doc(item.id).update({
      'isCompleted': !item.isCompleted,
    });
  }

  // Delete shopping item
  Future<void> deleteShoppingItem(String itemId) async {
    final doc = await _shoppingCollection.doc(itemId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final fileId = data['fileId'] ?? '';
      if (fileId.isNotEmpty) {
        await ImageKitHelper.deleteImageFromImageKit(fileId);
      }
    }
    await _shoppingCollection.doc(itemId).delete();
  }

  // Clear all completed items
  Future<void> clearCompletedItems() async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }

    // Get all completed items
    QuerySnapshot completedItems = await _shoppingCollection
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: true)
        .get();

    // Delete images from ImageKit for each completed item
    for (var doc in completedItems.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fileId = data['fileId'] ?? '';
      if (fileId.isNotEmpty) {
        await ImageKitHelper.deleteImageFromImageKit(fileId);
      }
    }

    // Batch delete
    WriteBatch batch = _firestore.batch();
    for (var doc in completedItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Get shopping list by category
  Stream<Map<String, List<ShoppingItem>>> getShoppingItemsByCategory() {
    if (_userId == null) {
      return Stream.value({});
    }

    // Modified query to avoid requiring composite index
    return _shoppingCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList();

          // Sort in memory
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Group by category
          final Map<String, List<ShoppingItem>> categorizedItems = {};
          for (var item in items) {
            if (!categorizedItems.containsKey(item.category)) {
              categorizedItems[item.category] = [];
            }
            categorizedItems[item.category]!.add(item);
          }
          return categorizedItems;
        });
  }
}
