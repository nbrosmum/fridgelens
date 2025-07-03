import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      photoURL: user.photoURL,
    );
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
      return _userFromFirebaseUser(user);
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

      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      print('Error registering: ${e.code} - ${e.message}');
      throw e; // Re-throw to be handled by the UI
    } catch (e) {
      print('Error registering: $e');
      throw e; // Re-throw to be handled by the UI
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
}
