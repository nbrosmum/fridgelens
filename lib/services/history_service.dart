import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/history_item_model.dart';
import '../models/fridge_item_model.dart';
import 'fridge_service.dart';
import '../utils/imagekit_config.dart';

class HistoryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FridgeService _fridgeService = FridgeService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add item to history (when marked as used)
  Future<Map<String, dynamic>> addToHistory(FridgeItemModel item) async {
    try {
      // Check if user has access to the fridge
      final hasAccess = await _fridgeService.hasAccessToFridge(item.fridgeId);
      if (!hasAccess) {
        return {
          'success': false,
          'message': 'You do not have access to this fridge',
        };
      }

      // Create history item
      final historyItem = {
        'fridgeId': item.fridgeId,
        'name': item.name,
        'category': item.category,
        'imageUrl': item.imageUrl,
        'expiryDate': item.expiryDate,
        'reminderDate': item.reminderDate,
        'status': 'used',
        'createdBy': item.createdBy,
        'createdAt': item.createdAt,
        'compartment': item.compartment,
        'ignoreExpiry': item.ignoreExpiry,
        'usedAt': FieldValue.serverTimestamp(),
      };

      // Add to history collection
      await _firestore.collection('history_items').add(historyItem);

      return {'success': true, 'message': 'Item added to history successfully'};
    } catch (e) {
      print('Error adding item to history: $e');
      return {'success': false, 'message': 'Failed to add item to history: $e'};
    }
  }

  // Get all history items for a user (across all accessible fridges)
  Stream<List<HistoryItemModel>> getUserHistory() {
    return _firestore
        .collection('history_items')
        .where('createdBy', isEqualTo: currentUserId)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return HistoryItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get history items for a specific fridge
  Stream<List<HistoryItemModel>> getFridgeHistory(String fridgeId) {
    return _firestore
        .collection('history_items')
        .where('fridgeId', isEqualTo: fridgeId)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return HistoryItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get history items by category
  Stream<List<HistoryItemModel>> getHistoryByCategory(String category) {
    return _firestore
        .collection('history_items')
        .where('createdBy', isEqualTo: currentUserId)
        .where('category', isEqualTo: category)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return HistoryItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get history items by date range
  Stream<List<HistoryItemModel>> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('history_items')
        .where('createdBy', isEqualTo: currentUserId)
        .where('usedAt', isGreaterThanOrEqualTo: startDate)
        .where('usedAt', isLessThanOrEqualTo: endDate)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return HistoryItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Delete history item
  Future<Map<String, dynamic>> deleteHistoryItem(String itemId) async {
    try {
      // Get the item first to check access
      final itemDoc = await _firestore
          .collection('history_items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) {
        return {'success': false, 'message': 'Item not found'};
      }

      final itemData = itemDoc.data() as Map<String, dynamic>;
      final String createdBy = itemData['createdBy'];

      // Check if user is the creator of the item
      if (createdBy != currentUserId) {
        return {
          'success': false,
          'message': 'You can only delete your own history items',
        };
      }

      // Delete image from ImageKit if fileId exists
      if (itemData['fileId'] != null &&
          itemData['fileId'].toString().isNotEmpty) {
        final deleteSuccess = await _deleteImageFromImageKit(
          itemData['fileId'],
        );
        if (!deleteSuccess) {
          print(
            'Warning: Failed to delete image from ImageKit for history item: ${itemData['name']}',
          );
        }
      }

      // Delete the item from Firestore
      await _firestore.collection('history_items').doc(itemId).delete();

      return {'success': true, 'message': 'History item deleted successfully'};
    } catch (e) {
      print('Error deleting history item: $e');
      return {'success': false, 'message': 'Failed to delete history item: $e'};
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
}
