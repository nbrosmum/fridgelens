import 'package:flutter/material.dart';
import '../widgets/profile/edit_profile_form.dart';
import '../utils/constants.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(16.0), child: EditProfileForm()),
      ),
    );
  }
}
