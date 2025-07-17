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
  static Future<bool> deleteImageFromImageKit(String fileId) async {
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

  // Copy image to history folder when item is moved to history
  Future<Map<String, dynamic>?> _copyImageToHistoryFolder(
    String originalFileId,
    String originalImageUrl,
  ) async {
    try {
      if (originalFileId.isEmpty || originalImageUrl.isEmpty) {
        return null;
      }

      // Download the original image
      final response = await http.get(Uri.parse(originalImageUrl));
      if (response.statusCode != 200) {
        print('Failed to download original image: ${response.statusCode}');
        return null;
      }

      // Create a temporary file
      final tempDir = await Directory.systemTemp.createTemp(
        'fridgelens_history',
      );
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Upload to history folder
      final historyFolderPath = '${ImageKitConfig.uploadFolder}/history';
      final uploadResult = await _uploadImageToImageKit(
        tempFile,
        historyFolderPath,
      );

      // Clean up temp file
      await tempFile.delete();
      await tempDir.delete();

      if (uploadResult['success']) {
        return {'url': uploadResult['url'], 'fileId': uploadResult['fileId']};
      } else {
        print(
          'Failed to upload image to history folder: ${uploadResult['error']}',
        );
        return null;
      }
    } catch (e) {
      print('Error copying image to history folder: $e');
      return null;
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
    bool ignoreExpiry = false,
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
        'ignoreExpiry': ignoreExpiry,
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
    DateTime? expiryDate,
    DateTime? reminderDate,
    String? status,
    String? compartment,
    bool removeImage = false, // New parameter
    bool? ignoreExpiry,
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
      // Remove image logic
      if (removeImage) {
        imageUrl = '';
      }
      // Calculate new status if expiry date is being updated
      String? newStatus = status;
      if (expiryDate != null) {
        newStatus = _calculateStatus(expiryDate);
      }

      // Update the item
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (category != null) updateData['category'] = category;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (reminderDate != null) updateData['reminderDate'] = reminderDate;
      if (newStatus != null) updateData['status'] = newStatus;
      if (compartment != null) updateData['compartment'] = compartment;
      if (ignoreExpiry != null) updateData['ignoreExpiry'] = ignoreExpiry;
      if (expiryDate != null) updateData['expiryDate'] = expiryDate;

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

  // Calculate status based on expiry date
  String _calculateStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    // If the item has already expired (past the expiry date)
    if (difference.isNegative) {
      return 'expired';
    }

    // If the item expires within the next3s (including today)
    if (difference.inDays <= 3) {
      return 'almost_expiry';
    }

    // Otherwise, the item is fresh
    return 'fresh';
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
        await deleteImageFromImageKit(itemData['fileId']);
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
    print('updateItemStatus called: itemId=' + itemId + ', status=' + status);
    try {
      // Get the item first
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

      // If status is 'used' or 'clear', add to history and delete from fridge
      if (status == 'used' || status == 'clear') {
        if (status == 'clear' && itemData['status'] != 'expired') {
          return {
            'success': false,
            'message': 'Only expired items can be cleared.',
          };
        }
        // Create history item
        final historyItem = {
          'fridgeId': fridgeId,
          'name': itemData['name'],
          'category': itemData['category'],
          'imageUrl': itemData['imageUrl'],
          'expiryDate': itemData['expiryDate'],
          'reminderDate': itemData['reminderDate'],
          'status': status, // 'used' or 'clear'
          'createdBy': itemData['createdBy'],
          'createdAt': itemData['createdAt'],
          'compartment': itemData['compartment'],
          'ignoreExpiry': itemData['ignoreExpiry'],
          'usedAt': FieldValue.serverTimestamp(),
        };

        // Copy image to history folder if it exists
        String historyImageUrl = itemData['imageUrl'];
        String? historyFileId;
        if (itemData['fileId'] != null &&
            itemData['fileId'].toString().isNotEmpty &&
            itemData['imageUrl'].isNotEmpty) {
          final copyResult = await _copyImageToHistoryFolder(
            itemData['fileId'],
            itemData['imageUrl'],
          );
          if (copyResult != null) {
            historyImageUrl = copyResult['url'];
            historyFileId = copyResult['fileId'];
          }
        }

        // Update history item with new image URL and fileId
        historyItem['imageUrl'] = historyImageUrl;
        if (historyFileId != null) {
          historyItem['fileId'] = historyFileId;
        }

        // Add to history collection
        await _firestore.collection('history_items').add(historyItem);

        // Delete image from ImageKit if fileId exists
        if (itemData['fileId'] != null &&
            itemData['fileId'].toString().isNotEmpty) {
          await deleteImageFromImageKit(itemData['fileId']);
        }

        // Delete the item from fridge
        await _firestore.collection('fridge_items').doc(itemId).delete();

        return {
          'success': true,
          'message': 'Item marked as ' + status + ' and moved to history',
        };
      } else if (status == 'expired') {
        // If status is 'expired', just update the status without moving to history
        await _firestore.collection('fridge_items').doc(itemId).update({
          'status': 'expired',
        });

        return {'success': true, 'message': 'Item marked as expired'};
      } else {
        // For other status updates, use the regular update method
        return updateFridgeItem(itemId: itemId, status: status);
      }
    } catch (e) {
      print('Error updating item status: $e');
      return {'success': false, 'message': 'Failed to update item status: $e'};
    }
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

  // Update all items' status based on their expiry dates
  Future<void> updateAllItemsStatus() async {
    print('updateAllItemsStatus called');
    try {
      // Get all items that are not marked as 'used' or 'ignoreExpiry'
      final querySnapshot = await _firestore
          .collection('fridge_items')
          .where('status', isNotEqualTo: 'used')
          .where('ignoreExpiry', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in querySnapshot.docs) {
        final itemData = doc.data();
        final expiryDate = (itemData['expiryDate'] as Timestamp).toDate();
        final currentStatus = itemData['status'] as String;

        // Calculate new status
        final newStatus = _calculateStatus(expiryDate);

        // Only update if status has changed
        if (newStatus != currentStatus) {
          batch.update(doc.reference, {'status': newStatus});
          updatedCount++;
        }
      }

      // Commit the batch update
      if (updatedCount > 0) {
        await batch.commit();
        print('Updated status for $updatedCount items');
      }
    } catch (e) {
      print('Error updating items status: $e');
    }
  }
}
