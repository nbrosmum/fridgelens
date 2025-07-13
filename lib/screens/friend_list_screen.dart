import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/friend_service.dart';
import '../utils/constants.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('Friends', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _friendService.getPendingFriendRequests(),
              builder: (context, snapshot) {
                final hasRequests =
                    snapshot.hasData && snapshot.data!.isNotEmpty;
                return hasRequests
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${snapshot.data?.length ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendService.getPendingFriendRequests(),
        builder: (context, requestsSnapshot) {
          if (requestsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingRequests = requestsSnapshot.data ?? [];
          final hasRequests = pendingRequests.isNotEmpty;

          return Column(
            children: [
              // Friend Requests Section - Only show when there are requests
              if (hasRequests) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: const Text(
                    'Friend Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(request['senderId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(title: Text('Loading...'));
                          }

                          final userData =
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          final displayName =
                              userData?['displayName'] ?? 'Unknown';
                          final email = userData?['email'] ?? '';

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(displayName),
                            subtitle: Text(email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      _acceptRequest(request['id']),
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
                                      _rejectRequest(request['id']),
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
                  ),
                ),
              ],

              // Friends List Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: const Text(
                  'Your Friends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: hasRequests
                    ? 1
                    : 2, // Give more space to friends when no requests
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _friendService.getFriends(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final friends = snapshot.data ?? [];

                    if (friends.isEmpty) {
                      return const Center(
                        child: Text('No friends yet. Add some friends!'),
                      );
                    }

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(friend['displayName'] ?? 'Unknown'),
                          subtitle: Text(friend['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeFriend(friend['uid']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Friend\'s Email',
            hintText: 'Enter email address',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendFriendRequest();
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter an email address', isError: true);
      return;
    }

    final result = await _friendService.sendFriendRequest(email);
    _showMessage(result['message'], isError: !result['success']);
    _emailController.clear();
  }

  Future<void> _acceptRequest(String requestId) async {
    final result = await _friendService.acceptFriendRequest(requestId);
    _showMessage(result['message'], isError: !result['success']);
  }

  Future<void> _rejectRequest(String requestId) async {
    final result = await _friendService.rejectFriendRequest(requestId);
    _showMessage(result['message'], isError: !result['success']);
  }

  Future<void> _removeFriend(String friendId) async {
    final result = await _friendService.removeFriend(friendId);
    _showMessage(result['message'], isError: !result['success']);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
