import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../services/fridge_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class AddContributorDialog extends StatefulWidget {
  final String fridgeId;

  const AddContributorDialog({super.key, required this.fridgeId});

  @override
  State<AddContributorDialog> createState() => _AddContributorDialogState();
}

class _AddContributorDialogState extends State<AddContributorDialog> {
  final FriendService _friendService = FriendService();
  final FridgeService _fridgeService = FridgeService();
  bool _isLoading = false;
  final List<UserModel> _selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contributors'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _buildFriendsTab(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedUsers.isEmpty || _isLoading
              ? null
              : _addContributors,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text('Add  ${_selectedUsers.length}'),
        ),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _friendService.getFriendsAsUserModels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading friends:  ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No friends yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Add friends to share your fridge with them',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Select friends to add as contributors:',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isSelected = _selectedUsers.contains(friend);

                  return CheckboxListTile(
                    title: Text(friend.displayName ?? 'User'),
                    subtitle: Text(friend.email),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedUsers.add(friend);
                        } else {
                          _selectedUsers.remove(friend);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundColor: AppColors.secondary.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addContributors() async {
    if (_selectedUsers.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add each selected user as a contributor
      for (final user in _selectedUsers) {
        await _fridgeService.addContributor(
          fridgeId: widget.fridgeId,
          contributorId: user.uid,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added  ${_selectedUsers.length} contributor${_selectedUsers.length > 1 ? 's' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contributors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
