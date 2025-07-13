import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../models/fridge_item_model.dart';
import '../utils/imagekit_config.dart';
import 'fridge_service.dart';

class FridgeItemService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FridgeService _fridgeService = FridgeService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Upload image to ImageKit
  Future<Map<String, dynamic>> _uploadImageToImageKit(
    File imageFile,
    String folderPath,
  ) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ImageKitConfig.authenticationEndpoint),
      );

      // Add authorization header
      request.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode(ImageKitConfig.privateKey + ':'))}';

      // Add fields
      request.fields['fileName'] =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      request.fields['folder'] = folderPath;

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': jsonResponse['url'],
          'fileId': jsonResponse['fileId'],
        };
      } else {
        return {
          'success': false,
          'error': jsonResponse['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Upload error: $e'};
    }
  }

  // Delete image from ImageKit.io
  Future<bool> _deleteImageFromImageKit(String fileId) async {
    try {
      final url = Uri.parse('https://api.imagekit.io/v1/files/$fileId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode(ImageKitConfig.privateKey + ':'))}',
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting image from ImageKit: $e');
      return false;
    }
  }

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
      String fileId = '';
      if (imageFile != null) {
        try {
          // Create a folder path for organization
          final folderPath = '${ImageKitConfig.uploadFolder}/$fridgeId';

          // Upload to ImageKit
          final uploadResult = await _uploadImageToImageKit(
            imageFile,
            folderPath,
          );

          if (uploadResult['success']) {
            imageUrl = uploadResult['url'];
            fileId = uploadResult['fileId'];
          } else {
            print(
              'Error uploading image to ImageKit: ${uploadResult['error']}',
            );
          }
        } catch (e) {
          print('Error uploading image to ImageKit: $e');
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
        'fileId': fileId,
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
          final folderPath = '${ImageKitConfig.uploadFolder}/$fridgeId';

          // Upload to ImageKit
          final uploadResult = await _uploadImageToImageKit(
            newImageFile,
            folderPath,
          );

          if (uploadResult['success']) {
            imageUrl = uploadResult['url'];
          } else {
            print(
              'Error uploading image to ImageKit: ${uploadResult['error']}',
            );
          }
        } catch (e) {
          print('Error uploading image to ImageKit: $e');
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

      // Delete image from ImageKit if fileId exists
      if (itemData['fileId'] != null &&
          itemData['fileId'].toString().isNotEmpty) {
        await _deleteImageFromImageKit(itemData['fileId']);
      }

      // Delete the item from Firestore
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
