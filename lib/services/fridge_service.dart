import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fridge_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../utils/imagekit_config.dart';
import 'fridge_item_service.dart';

class FridgeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new fridge
  Future<Map<String, dynamic>> createFridge({
    required String name,
    required String type, // "chiller", "freezer", or "both"
  }) async {
    try {
      if (currentUserId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Create the fridge document
      final docRef = await _firestore.collection('fridges').add({
        'name': name,
        'type': type,
        'ownerId': currentUserId,
        'contributors': [], // Start with no contributors
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Fridge created successfully',
        'fridgeId': docRef.id,
      };
    } catch (e) {
      print('Error creating fridge: $e');
      return {'success': false, 'message': 'Failed to create fridge: $e'};
    }
  }

  // Update fridge details
  Future<Map<String, dynamic>> updateFridge({
    required String fridgeId,
    String? name,
    String? type,
  }) async {
    try {
      // Check if user is owner of the fridge
      final fridgeDoc = await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .get();

      if (!fridgeDoc.exists) {
        return {'success': false, 'message': 'Fridge not found'};
      }

      final fridgeData = fridgeDoc.data() as Map<String, dynamic>;

      if (fridgeData['ownerId'] != currentUserId) {
        return {
          'success': false,
          'message': 'Only the owner can update fridge details',
        };
      }

      // Update the fridge
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (type != null) updateData['type'] = type;

      await _firestore.collection('fridges').doc(fridgeId).update(updateData);

      return {'success': true, 'message': 'Fridge updated successfully'};
    } catch (e) {
      print('Error updating fridge: $e');
      return {'success': false, 'message': 'Failed to update fridge: $e'};
    }
  }

  // Delete a fridge
  Future<Map<String, dynamic>> deleteFridge(String fridgeId) async {
    try {
      // Check if user is owner of the fridge
      final fridgeDoc = await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .get();

      if (!fridgeDoc.exists) {
        return {'success': false, 'message': 'Fridge not found'};
      }

      final fridgeData = fridgeDoc.data() as Map<String, dynamic>;

      if (fridgeData['ownerId'] != currentUserId) {
        return {
          'success': false,
          'message': 'Only the owner can delete the fridge',
        };
      }

      // Delete all items in the fridge first
      final itemsQuery = await _firestore
          .collection('fridge_items')
          .where('fridgeId', isEqualTo: fridgeId)
          .get();

      // 1. Check if any items are in history and copy their images to history folder
      final historyQuery = await _firestore
          .collection('history_items')
          .where('fridgeId', isEqualTo: fridgeId)
          .get();

      for (var doc in historyQuery.docs) {
        final itemData = doc.data();
        final fileId = itemData['fileId'];
        final imageUrl = itemData['imageUrl'];

        // If the image is still in the original fridge folder, copy it to history folder
        if (fileId != null &&
            fileId.toString().isNotEmpty &&
            imageUrl.isNotEmpty &&
            imageUrl.contains('/$fridgeId/')) {
          try {
            final copyResult = await _copyImageToHistoryFolder(
              fileId,
              imageUrl,
            );
            if (copyResult != null) {
              await _firestore.collection('history_items').doc(doc.id).update({
                'imageUrl': copyResult['url'],
                'fileId': copyResult['fileId'],
              });
            }
          } catch (e) {
            print('Error copying image to history folder: $e');
          }
        }
      }

      // 2. Delete all images in ImageKit folder
      for (var doc in itemsQuery.docs) {
        final itemData = doc.data();
        final fileId = itemData['fileId'];
        if (fileId != null && fileId.toString().isNotEmpty) {
          try {
            await FridgeItemService.deleteImageFromImageKit(fileId);
          } catch (e) {
            print('Error deleting image from ImageKit: $e');
          }
        }
      }

      // 2. Delete the ImageKit folder (if API supported, pseudo code)
      try {
        final folderPath = '/fridge_items/$fridgeId';
        final url = Uri.parse('https://api.imagekit.io/v1/folder');
        // Wait a while to ensure ImageKit sync
        await Future.delayed(const Duration(milliseconds: 500));
        final response = await http.delete(
          url,
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('${ImageKitConfig.privateKey}:'))}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'folderPath': folderPath}),
        );
        print(
          'Delete folder response: ${response.statusCode} ${response.body}',
        );
      } catch (e) {
        print('Error deleting ImageKit folder: $e');
      }

      // 3. Delete Firestore data
      final batch = _firestore.batch();
      for (var doc in itemsQuery.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('fridges').doc(fridgeId));
      await batch.commit();

      return {
        'success': true,
        'message': 'Fridge and all items deleted successfully',
      };
    } catch (e) {
      print('Error deleting fridge: $e');
      return {'success': false, 'message': 'Failed to delete fridge: $e'};
    }
  }

  // Add a contributor to a fridge
  Future<Map<String, dynamic>> addContributor({
    required String fridgeId,
    required String contributorId,
  }) async {
    try {
      // Check if user is owner of the fridge
      final fridgeDoc = await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .get();

      if (!fridgeDoc.exists) {
        return {'success': false, 'message': 'Fridge not found'};
      }

      final fridgeData = fridgeDoc.data() as Map<String, dynamic>;

      if (fridgeData['ownerId'] != currentUserId) {
        return {
          'success': false,
          'message': 'Only the owner can add contributors',
        };
      }

      // Check if user is already a contributor
      final List<dynamic> contributors = fridgeData['contributors'] ?? [];
      if (contributors.contains(contributorId)) {
        return {
          'success': false,
          'message': 'User is already a contributor to this fridge',
        };
      }

      // Add the contributor
      await _firestore.collection('fridges').doc(fridgeId).update({
        'contributors': FieldValue.arrayUnion([contributorId]),
      });

      return {'success': true, 'message': 'Contributor added successfully'};
    } catch (e) {
      print('Error adding contributor: $e');
      return {'success': false, 'message': 'Failed to add contributor: $e'};
    }
  }

  // Remove a contributor from a fridge
  Future<Map<String, dynamic>> removeContributor({
    required String fridgeId,
    required String contributorId,
  }) async {
    try {
      // Check if user is owner of the fridge
      final fridgeDoc = await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .get();

      if (!fridgeDoc.exists) {
        return {'success': false, 'message': 'Fridge not found'};
      }

      final fridgeData = fridgeDoc.data() as Map<String, dynamic>;

      if (fridgeData['ownerId'] != currentUserId) {
        return {
          'success': false,
          'message': 'Only the owner can remove contributors',
        };
      }

      // Remove the contributor
      await _firestore.collection('fridges').doc(fridgeId).update({
        'contributors': FieldValue.arrayRemove([contributorId]),
      });

      return {'success': true, 'message': 'Contributor removed successfully'};
    } catch (e) {
      print('Error removing contributor: $e');
      return {'success': false, 'message': 'Failed to remove contributor: $e'};
    }
  }

  // Get all fridges for current user (owned or contributing)
  Stream<List<FridgeModel>> getFridges() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('fridges')
        .where(
          Filter.or(
            Filter('ownerId', isEqualTo: currentUserId),
            Filter('contributors', arrayContains: currentUserId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FridgeModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get a specific fridge
  Stream<FridgeModel?> getFridge(String fridgeId) {
    return _firestore.collection('fridges').doc(fridgeId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return null;
      }
      return FridgeModel.fromMap(doc.data()!, doc.id);
    });
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

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ImageKitConfig.authenticationEndpoint),
      );

      // Add authorization header
      request.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('${ImageKitConfig.privateKey}:'))}';

      // Add fields
      request.fields['fileName'] =
          '${DateTime.now().millisecondsSinceEpoch}_history_$originalFileId';
      request.fields['folder'] = historyFolderPath;

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', tempFile.path),
      );

      // Send request
      var uploadResponse = await request.send();
      var responseData = await uploadResponse.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      // Clean up temp file
      await tempFile.delete();
      await tempDir.delete();

      if (uploadResponse.statusCode == 200) {
        return {'url': jsonResponse['url'], 'fileId': jsonResponse['fileId']};
      } else {
        print(
          'Failed to upload image to history folder: ${jsonResponse['message'] ?? 'Upload failed'}',
        );
        return null;
      }
    } catch (e) {
      print('Error copying image to history folder: $e');
      return null;
    }
  }

  // Check if user has access to a fridge
  Future<bool> hasAccessToFridge(String fridgeId) async {
    if (currentUserId == null) {
      return false;
    }

    final fridgeDoc = await _firestore
        .collection('fridges')
        .doc(fridgeId)
        .get();

    if (!fridgeDoc.exists) {
      return false;
    }

    final fridgeData = fridgeDoc.data() as Map<String, dynamic>;

    // User is either the owner or a contributor
    return fridgeData['ownerId'] == currentUserId ||
        (fridgeData['contributors'] as List<dynamic>).contains(currentUserId);
  }
}
