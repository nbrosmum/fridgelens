import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor to set persistence
  AuthService() {
    // Set persistence to LOCAL (keeps the user logged in even after app restart)
    // This is done asynchronously but we can't use 'await' in constructor
    try {
      _auth.setPersistence(Persistence.LOCAL);
      print('Auth persistence set to LOCAL');
    } catch (e) {
      print('Error setting auth persistence: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Convert Firebase User to UserModel
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    try {
      if (_auth.currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap({
          'uid': _auth.currentUser!.uid,
          'email': _auth.currentUser!.email ?? '',
          'displayName': _auth.currentUser!.displayName,
          'phoneNumber': data['phoneNumber'],
          'dateOfBirth': data['dateOfBirth'],
        });
      } else {
        return _userFromFirebaseUser(_auth.currentUser);
      }
    } catch (e) {
      print('Error getting user data: $e');
      return _userFromFirebaseUser(_auth.currentUser);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? dateOfBirth,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      // Update display name in Firebase Auth if provided
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Update additional fields in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName ?? user.displayName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      print('User signed in with persistence: ${user?.uid}');

      // Check if user exists in Firestore, if not create a record
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return await getUserData();
    } catch (e) {
      print('Error signing in: $e');
      rethrow; // Re-throw to be handled by the UI
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Check if email already exists
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message:
              'This email address is already registered. Please use a different email.',
        );
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Update display name
      await user?.updateDisplayName(name);

      // Create a new document for the user in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      print('Error registering: ${e.code} - ${e.message}');
      rethrow; // Re-throw to be handled by the UI
    } catch (e) {
      print('Error registering: $e');
      rethrow; // Re-throw to be handled by the UI
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Update password for logged in user
  Future<bool> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('Firebase error updating password: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  // Reauthenticate user (required for sensitive operations)
  Future<bool> reauthenticateUser(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Create credentials
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        // Attempt to reauthenticate
        await user.reauthenticateWithCredential(credential);
        print('Reauthentication successful');
        return true;
      } else {
        print('No current user or email is null');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      print('Firebase error reauthenticating: ${e.code} - ${e.message}');
      if (e.code == 'wrong-password') {
        // Handle wrong password specifically
        print('Wrong password provided');
      }
      return false;
    } catch (e) {
      print('Error reauthenticating: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Signing out user: ${_auth.currentUser?.uid ?? 'No user'}');
      // Ensure all Firebase auth instances are cleared
      await _auth.signOut();

      // Force reset cached auth state
      await _auth.authStateChanges().first;

      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow; // Re-throw to be handled by UI
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      String uid = user.uid;

      // First delete the user data from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Then delete the user from Firebase Auth
      await user.delete();

      print('User account and data deleted successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      // This might happen if the user needs to be re-authenticated
      print('Firebase error deleting account: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        // User needs to re-authenticate before deleting account
        print('User needs to re-authenticate before deleting account');
      }
      rethrow;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Delete user account with re-authentication
  Future<bool> deleteAccountWithPassword(String password) async {
    try {
      // First re-authenticate the user
      bool isAuthenticated = await reauthenticateUser(password);
      if (!isAuthenticated) {
        print('Failed to re-authenticate user');
        return false;
      }

      User? user = _auth.currentUser;
      if (user == null) return false;

      String uid = user.uid;

      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete any other collections related to this user
      // For example, if you have user-specific collections:
      // await _deleteUserRelatedCollections(uid);

      // Then delete the user from Firebase Auth
      await user.delete();

      print('User account and all related data deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
