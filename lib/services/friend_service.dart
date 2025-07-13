import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class FriendService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Send friend request (A sends to B)
  Future<Map<String, dynamic>> sendFriendRequest(String receiverEmail) async {
    try {
      final sender = _auth.currentUser;
      if (sender == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Find receiver by email
      final receiverQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: receiverEmail.trim().toLowerCase())
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) {
        return {'success': false, 'message': 'No user found with this email'};
      }

      final receiverId = receiverQuery.docs.first.id;

      // Check if trying to add self
      if (receiverId == sender.uid) {
        return {
          'success': false,
          'message': 'You cannot add yourself as a friend',
        };
      }

      // Check if already friends
      final senderDoc = await _firestore
          .collection('users')
          .doc(sender.uid)
          .get();
      final senderFriends = List<String>.from(
        senderDoc.data()?['friends'] ?? [],
      );

      if (senderFriends.contains(receiverId)) {
        return {'success': false, 'message': 'Already friends with this user'};
      }

      // Check if request already exists
      final existingRequest = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: sender.uid)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return {'success': false, 'message': 'Friend request already sent'};
      }

      // Create friend request
      await _firestore.collection('friend_requests').add({
        'senderId': sender.uid,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Create notification for the receiver
      final senderUserDoc = await _firestore
          .collection('users')
          .doc(sender.uid)
          .get();
      final senderName = senderUserDoc.data()?['displayName'] ?? 'Unknown User';

      await _notificationService.createFriendRequestNotification(
        senderId: sender.uid,
        receiverId: receiverId,
        senderName: senderName,
      );

      return {'success': true, 'message': 'Friend request sent successfully'};
    } catch (e) {
      print('Error sending friend request: $e');
      return {'success': false, 'message': 'Failed to send friend request'};
    }
  }

  // Get pending friend requests for current user (B sees requests)
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

  // Approve friend request (B approves A's request)
  Future<Map<String, dynamic>> acceptFriendRequest(String requestId) async {
    try {
      // Get the request
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        return {'success': false, 'message': 'Request not found'};
      }

      final data = requestDoc.data() as Map<String, dynamic>;
      final currentUserId = _auth.currentUser?.uid;

      // Check if current user is the receiver
      if (currentUserId != data['receiverId']) {
        return {
          'success': false,
          'message': 'You can only accept requests sent to you',
        };
      }

      // Check if request is still pending
      if (data['status'] != 'pending') {
        return {'success': false, 'message': 'Request already handled'};
      }

      final senderId = data['senderId'];
      final receiverId = data['receiverId'];

      // Add both users as friends
      await _firestore.collection('users').doc(senderId).update({
        'friends': FieldValue.arrayUnion([receiverId]),
      });

      await _firestore.collection('users').doc(receiverId).update({
        'friends': FieldValue.arrayUnion([senderId]),
      });

      // Delete the request
      await _firestore.collection('friend_requests').doc(requestId).delete();

      return {'success': true, 'message': 'Friend request accepted'};
    } catch (e) {
      print('Error accepting friend request: $e');
      return {'success': false, 'message': 'Failed to accept friend request'};
    }
  }

  // Reject friend request (B rejects A's request)
  Future<Map<String, dynamic>> rejectFriendRequest(String requestId) async {
    try {
      // Get the request
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        return {'success': false, 'message': 'Request not found'};
      }

      final data = requestDoc.data() as Map<String, dynamic>;
      final currentUserId = _auth.currentUser?.uid;

      // Check if current user is the receiver
      if (currentUserId != data['receiverId']) {
        return {
          'success': false,
          'message': 'You can only reject requests sent to you',
        };
      }

      // Check if request is still pending
      if (data['status'] != 'pending') {
        return {'success': false, 'message': 'Request already handled'};
      }

      // Delete the request
      await _firestore.collection('friend_requests').doc(requestId).delete();

      return {'success': true, 'message': 'Friend request rejected'};
    } catch (e) {
      print('Error rejecting friend request: $e');
      return {'success': false, 'message': 'Failed to reject friend request'};
    }
  }

  // Get friends list
  Stream<List<Map<String, dynamic>>> getFriends() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((
      snapshot,
    ) async {
      if (!snapshot.exists) {
        return [];
      }

      final friendIds = List<String>.from(snapshot.data()?['friends'] ?? []);
      if (friendIds.isEmpty) {
        return [];
      }

      final friends = <Map<String, dynamic>>[];
      for (final friendId in friendIds) {
        final friendDoc = await _firestore
            .collection('users')
            .doc(friendId)
            .get();
        if (friendDoc.exists) {
          friends.add({
            'uid': friendId,
            ...friendDoc.data() as Map<String, dynamic>,
          });
        }
      }

      return friends;
    });
  }

  // Get friends as UserModel objects (for compatibility with existing code)
  Stream<List<UserModel>> getFriendsAsUserModels() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((
      snapshot,
    ) async {
      if (!snapshot.exists) {
        return [];
      }

      final friendIds = List<String>.from(snapshot.data()?['friends'] ?? []);
      if (friendIds.isEmpty) {
        return [];
      }

      final friends = <UserModel>[];
      for (final friendId in friendIds) {
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

  // Remove friend
  Future<Map<String, dynamic>> removeFriend(String friendId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Remove from both users' friend lists
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      return {'success': true, 'message': 'Friend removed successfully'};
    } catch (e) {
      print('Error removing friend: $e');
      return {'success': false, 'message': 'Failed to remove friend'};
    }
  }

  // Search for users by email (for adding contributors)
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      final searchEmail = email.trim().toLowerCase();
      if (searchEmail.isEmpty) {
        return [];
      }

      // Search for users whose email contains the search term
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchEmail)
          .where('email', isLessThan: '${searchEmail}z')
          .limit(10)
          .get();

      final List<UserModel> users = [];
      final currentUserId = _auth.currentUser?.uid;

      for (var doc in userQuery.docs) {
        // Skip current user
        if (doc.id != currentUserId) {
          final userData = doc.data() as Map<String, dynamic>;
          users.add(UserModel.fromMap({'uid': doc.id, ...userData}));
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
