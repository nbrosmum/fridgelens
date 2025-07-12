import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import '../models/fridge_item_model.dart';
import '../utils/cloudinary_config.dart';
import 'fridge_service.dart';

class FridgeItemService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Initialize Cloudinary with credentials from config
  final cloudinary = CloudinaryPublic(
    CloudinaryConfig.cloudName,
    CloudinaryConfig.uploadPreset,
    cache: false,
  );
  final FridgeService _fridgeService = FridgeService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add a new item to a fridge
  Future<Map<String, dynamic>> addFridgeItem({
    required String fridgeId,
    required String name,
    required String category,
    required File? imageFile,
    required DateTime expiryDate,
    DateTime? reminderDate,
    String status = 'fresh',
    String compartment = 'chiller',
  }) async {
    try {
      // Check if user has access to the fridge
      final hasAccess = await _fridgeService.hasAccessToFridge(fridgeId);
      if (!hasAccess) {
        return {
          'success': false,
          'message': 'You do not have access to this fridge',
        };
      }

      // Upload image if provided
      String imageUrl = '';
      String publicId = '';
      if (imageFile != null) {
        try {
          // Create a folder path for organization
          final folderPath = 'fridge_items/$fridgeId';

          // Upload to Cloudinary
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              imageFile.path,
              folder: folderPath,
              resourceType: CloudinaryResourceType.Image,
            ),
          );

          // Get the secure URL and public ID
          imageUrl = response.secureUrl;
          publicId = response.publicId;
        } catch (e) {
          print('Error uploading image to Cloudinary: $e');
        }
      }

      // Set reminder date (default to 1 day before expiry if not provided)
      final actualReminderDate =
          reminderDate ?? expiryDate.subtract(const Duration(days: 1));

      // Add the item to Firestore
      final docRef = await _firestore.collection('fridge_items').add({
        'fridgeId': fridgeId,
        'name': name,
        'category': category,
        'imageUrl': imageUrl,
        'publicId': publicId,
        'expiryDate': expiryDate,
        'reminderDate': actualReminderDate,
        'status': status,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'compartment': compartment,
      });

      return {
        'success': true,
        'message': 'Item added to fridge successfully',
        'itemId': docRef.id,
      };
    } catch (e) {
      print('Error adding fridge item: $e');
      return {'success': false, 'message': 'Failed to add item to fridge: $e'};
    }
  }

  // Update an existing fridge item
  Future<Map<String, dynamic>> updateFridgeItem({
    required String itemId,
    String? name,
    String? category,
    File? newImageFile,
    DateTime? reminderDate,
    String? status,
    String? compartment,
  }) async {
    try {
      // Get the item first to check access
      final itemDoc = await _firestore
          .collection('fridge_items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) {
        return {'success': false, 'message': 'Item not found'};
      }

      final itemData = itemDoc.data() as Map<String, dynamic>;
      final String fridgeId = itemData['fridgeId'];

      // Check if user has access to the fridge
      final hasAccess = await _fridgeService.hasAccessToFridge(fridgeId);
      if (!hasAccess) {
        return {
          'success': false,
          'message': 'You do not have access to modify this item',
        };
      }

      // Upload new image if provided
      String? imageUrl;
      if (newImageFile != null) {
        try {
          // Create a folder path for organization
          final folderPath = 'fridge_items/$fridgeId';

          // Upload to Cloudinary
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              newImageFile.path,
              folder: folderPath,
              resourceType: CloudinaryResourceType.Image,
            ),
          );

          // Get the secure URL
          imageUrl = response.secureUrl;
        } catch (e) {
          print('Error uploading image to Cloudinary: $e');
        }
      }

      // Update the item
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (category != null) updateData['category'] = category;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (reminderDate != null) updateData['reminderDate'] = reminderDate;
      if (status != null) updateData['status'] = status;
      if (compartment != null) updateData['compartment'] = compartment;

      await _firestore
          .collection('fridge_items')
          .doc(itemId)
          .update(updateData);

      return {'success': true, 'message': 'Item updated successfully'};
    } catch (e) {
      print('Error updating fridge item: $e');
      return {'success': false, 'message': 'Failed to update item: $e'};
    }
  }

  // Delete a fridge item
  Future<Map<String, dynamic>> deleteFridgeItem(String itemId) async {
    try {
      // Get the item first to check access
      final itemDoc = await _firestore
          .collection('fridge_items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) {
        return {'success': false, 'message': 'Item not found'};
      }

      final itemData = itemDoc.data() as Map<String, dynamic>;
      final String fridgeId = itemData['fridgeId'];

      // Check if user has access to the fridge
      final hasAccess = await _fridgeService.hasAccessToFridge(fridgeId);
      if (!hasAccess) {
        return {
          'success': false,
          'message': 'You do not have access to delete this item',
        };
      }

      // Delete the item
      await _firestore.collection('fridge_items').doc(itemId).delete();

      return {'success': true, 'message': 'Item deleted successfully'};
    } catch (e) {
      print('Error deleting fridge item: $e');
      return {'success': false, 'message': 'Failed to delete item: $e'};
    }
  }

  // Get all items in a fridge
  Stream<List<FridgeItemModel>> getFridgeItems(String fridgeId) {
    return _firestore
        .collection('fridge_items')
        .where('fridgeId', isEqualTo: fridgeId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FridgeItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get a specific fridge item
  Stream<FridgeItemModel?> getFridgeItem(String itemId) {
    return _firestore.collection('fridge_items').doc(itemId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return null;
      }
      return FridgeItemModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Update item status
  Future<Map<String, dynamic>> updateItemStatus({
    required String itemId,
    required String status,
  }) async {
    return updateFridgeItem(itemId: itemId, status: status);
  }

  // Get items by status
  Stream<List<FridgeItemModel>> getItemsByStatus(
    String fridgeId,
    String status,
  ) {
    return _firestore
        .collection('fridge_items')
        .where('fridgeId', isEqualTo: fridgeId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FridgeItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get expiring items (items that will expire within the next 3 days)
  Stream<List<FridgeItemModel>> getExpiringItems(String fridgeId) {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    return _firestore
        .collection('fridge_items')
        .where('fridgeId', isEqualTo: fridgeId)
        .where('expiryDate', isGreaterThanOrEqualTo: now)
        .where('expiryDate', isLessThanOrEqualTo: threeDaysLater)
        .where('status', isEqualTo: 'fresh')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FridgeItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
