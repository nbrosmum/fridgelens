import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'add_friend_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    final userId = _friendService.currentUserId;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Friends', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friends List Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your Friends',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Builder(
              builder: (context) {
                print('Current user UID: $userId');
                return StreamBuilder<List<UserModel>>(
                  stream: _friendService.getFriends(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final friends = snapshot.data ?? [];
                    print('Fetched friends count: ${friends.length}');
                    for (final f in friends) {
                      print('Friend: ${f.uid}, ${f.displayName}, ${f.email}');
                    }
                    if (friends.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('You have no friends yet.'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(friend.displayName ?? 'User'),
                          subtitle: Text(friend.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showRemoveFriendDialog(friend),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            // Received Requests Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Friend Requests You Received',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _friendService.getPendingFriendRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data ?? [];
                print('Fetched received requests count: ${requests.length}');
                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('No received friend requests.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(req['senderId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const ListTile(title: Text('Loading...'));
                        }
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        final displayName =
                            userData?['displayName'] ?? 'Unknown';
                        final email = userData?['email'] ?? '';
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_add),
                          ),
                          title: Text(displayName),
                          subtitle: Text(email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _acceptFriendRequest(req['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Accept'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    _rejectFriendRequest(req['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            // Sent Requests Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Friend Requests You Sent',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: userId == null
                  ? null
                  : FirebaseFirestore.instance
                        .collection('friend_requests')
                        .where('senderId', isEqualTo: userId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                print('Fetched sent requests count: ${docs.length}');
                for (final doc in docs) {
                  print('Sent request: ${doc.data()}');
                }
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('No sent friend requests.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final req = docs[index].data() as Map<String, dynamic>;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(req['receiverId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const ListTile(title: Text('Loading...'));
                        }
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        final displayName =
                            userData?['displayName'] ?? 'Unknown';
                        final email = userData?['email'] ?? '';
                        final status = req['status'] ?? 'pending';
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(displayName),
                          subtitle: Text(email),
                          trailing: Text(
                            status,
                            style: TextStyle(
                              color: status == 'accepted'
                                  ? Colors.green
                                  : status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      final result = await _friendService.acceptFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      final result = await _friendService.rejectFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.orange : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRemoveFriendDialog(UserModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.displayName ?? friend.email} from your friends list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final result = await _friendService.removeFriend(friend.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success']
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing friend: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
