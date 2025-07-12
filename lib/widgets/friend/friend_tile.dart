import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class FriendTile extends StatelessWidget {
  final UserModel friend;
  final VoidCallback? onRemove;

  const FriendTile({super.key, required this.friend, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withOpacity(0.1),
          radius: 24,
          child: const Icon(Icons.person, color: AppColors.secondary, size: 24),
        ),
        title: Text(
          friend.displayName ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  friend.email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            if (friend.phoneNumber != null && friend.phoneNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      friend.phoneNumber!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: onRemove != null
            ? IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                onPressed: onRemove,
              )
            : null,
      ),
    );
  }
}
