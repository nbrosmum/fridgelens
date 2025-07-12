import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FriendService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add friend by email
  Future<Map<String, dynamic>> addFriendByEmail(String email) async {
    try {
      email = email.trim().toLowerCase();
      // Check if user is trying to add themselves
      if (_auth.currentUser?.email?.toLowerCase() == email) {
        return {
          'success': false,
          'message': 'You cannot add yourself as a friend',
        };
      }

      // Find user by email
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {'success': false, 'message': 'No user found with this email'};
      }

      final String friendId = userQuery.docs.first.id;

      // Check if already friends
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final List<dynamic> currentFriends =
          (currentUserDoc.data() as Map<String, dynamic>)['friends'] ?? [];

      if (currentFriends.contains(friendId)) {
        return {
          'success': false,
          'message': 'This user is already in your friends list',
        };
      }

      // Add friend to current user's friends list
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });

      return {'success': true, 'message': 'Friend added successfully'};
    } catch (e) {
      print('Error adding friend: $e');
      return {'success': false, 'message': 'Failed to add friend: $e'};
    }
  }

  // Remove friend
  Future<Map<String, dynamic>> removeFriend(String friendId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      return {'success': true, 'message': 'Friend removed successfully'};
    } catch (e) {
      print('Error removing friend: $e');
      return {'success': false, 'message': 'Failed to remove friend: $e'};
    }
  }

  // Get all friends
  Stream<List<UserModel>> getFriends() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (!snapshot.exists) {
            return [];
          }

          final List<dynamic> friendIds = snapshot.data()?['friends'] ?? [];

          if (friendIds.isEmpty) {
            return [];
          }

          // Fetch all friend user documents
          final List<UserModel> friends = [];

          for (String friendId in friendIds) {
            final friendDoc = await _firestore
                .collection('users')
                .doc(friendId)
                .get();

            if (friendDoc.exists) {
              final friendData = friendDoc.data() as Map<String, dynamic>;
              friends.add(UserModel.fromMap({'uid': friendId, ...friendData}));
            }
          }

          return friends;
        });
  }

  // Search for users by email (for adding friends)
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      email = email.trim().toLowerCase();
      if (email.isEmpty) {
        return [];
      }

      // Find users whose email starts with the search term
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThan: '${email}z')
          .limit(10)
          .get();

      final List<UserModel> users = [];

      for (var doc in userQuery.docs) {
        final userData = doc.data() as Map<String, dynamic>;

        // Skip current user
        if (doc.id != currentUserId) {
          users.add(UserModel.fromMap({'uid': doc.id, ...userData}));
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Send a friend request
  Future<Map<String, dynamic>> sendFriendRequest(String receiverEmail) async {
    try {
      final sender = _auth.currentUser;
      if (sender == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      final receiverQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: receiverEmail.trim().toLowerCase())
          .limit(1)
          .get();
      if (receiverQuery.docs.isEmpty) {
        return {'success': false, 'message': 'No user found with this email'};
      }
      final receiverId = receiverQuery.docs.first.id;
      if (receiverId == sender.uid) {
        return {
          'success': false,
          'message': 'You cannot add yourself as a friend',
        };
      }
      // Check if request already exists
      final existing = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: sender.uid)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'message': 'Friend request already sent'};
      }
      // Create friend request
      await _firestore.collection('friend_requests').add({
        'senderId': sender.uid,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'message': 'Friend request sent'};
    } catch (e) {
      print('Error sending friend request: $e');
      return {'success': false, 'message': 'Failed to send friend request: $e'};
    }
  }

  // Accept a friend request
  Future<Map<String, dynamic>> acceptFriendRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) {
        return {'success': false, 'message': 'Request not found'};
      }
      final data = requestDoc.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
        return {'success': false, 'message': 'Request already handled'};
      }
      final senderId = data['senderId'];
      final receiverId = data['receiverId'];
      // Add each other as friends
      await _firestore.collection('users').doc(senderId).update({
        'friends': FieldValue.arrayUnion([receiverId]),
      });
      await _firestore.collection('users').doc(receiverId).update({
        'friends': FieldValue.arrayUnion([senderId]),
      });
      // Update request status
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'accepted',
        'handledAt': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'message': 'Friend request accepted'};
    } catch (e) {
      print('Error accepting friend request: $e');
      return {
        'success': false,
        'message': 'Failed to accept friend request: $e',
      };
    }
  }

  // Reject a friend request
  Future<Map<String, dynamic>> rejectFriendRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) {
        return {'success': false, 'message': 'Request not found'};
      }
      final data = requestDoc.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
        return {'success': false, 'message': 'Request already handled'};
      }
      // Update request status to rejected
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
        'handledAt': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'message': 'Friend request rejected'};
    } catch (e) {
      print('Error rejecting friend request: $e');
      return {
        'success': false,
        'message': 'Failed to reject friend request: $e',
      };
    }
  }

  // Get pending friend requests for current user
  Stream<List<Map<String, dynamic>>> getPendingFriendRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
