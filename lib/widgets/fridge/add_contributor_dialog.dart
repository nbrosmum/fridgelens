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
  final List<UserModel> _selectedFriends = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contributors'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<UserModel>>(
          stream: _friendService.getFriends(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading friends: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final friends = snapshot.data ?? [];

            if (friends.isEmpty) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select friends to add as contributors:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = _selectedFriends.contains(friend);

                      return CheckboxListTile(
                        title: Text(friend.displayName ?? 'User'),
                        subtitle: Text(friend.email),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedFriends.add(friend);
                            } else {
                              _selectedFriends.remove(friend);
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedFriends.isEmpty || _isLoading
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
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addContributors() async {
    if (_selectedFriends.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add each selected friend as a contributor
      for (final friend in _selectedFriends) {
        await _fridgeService.addContributor(
          fridgeId: widget.fridgeId,
          contributorId: friend.uid,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_selectedFriends.length} contributor${_selectedFriends.length > 1 ? 's' : ''}',
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
