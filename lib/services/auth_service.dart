import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_profile.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Stream of user auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user profile from DB
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      // First try direct UID lookup
      final snapshot = await _db.ref().child('users').child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return UserProfile.fromMap(data, uid);
      }

      // Fallback: search by email (for users created via admin panel with name-based keys)
      final currentUser = _auth.currentUser;
      if (currentUser?.email != null) {
        final searchEmail = currentUser!.email!.toLowerCase();
        final allUsersSnapshot = await _db.ref().child('users').get();
        if (allUsersSnapshot.exists && allUsersSnapshot.value != null) {
          final allUsers = allUsersSnapshot.value as Map<dynamic, dynamic>;
          print("[AuthService] Fallback search: total users in DB = ${allUsers.length}");
          for (var entry in allUsers.entries) {
            final userData = entry.value;
            if (userData is Map) {
              final userEmail = (userData['email'] ?? '').toString().toLowerCase();
              if (userEmail == searchEmail) {
                print("[AuthService] Found match for email: $searchEmail under key: ${entry.key}");
                final data = Map<dynamic, dynamic>.from(userData);
                // If name is missing or "Unknown", try using the key (e.g., "Joshua Santos")
                if (data['name'] == null || data['name'] == 'Unknown' || data['name'] == 'Unknown User') {
                  data['name'] = entry.key.toString();
                }
                return UserProfile.fromMap(data, entry.key.toString());
              }
            }
          }
        }
      }
    } catch (e) {
      print("[AuthService] Exception in getUserProfile: $e");
    }
    print("[AuthService] getUserProfile: Returning default profile for UID: $uid");
    // Final fallback to avoid "Passenger" if user wants "Unknown"
    return UserProfile(uid: uid, email: _auth.currentUser?.email ?? '', name: 'Unknown User', role: 'user');
  }

  // Create a default user profile if none exists
  Future<UserProfile> _ensureUserProfile(User user, {String? name}) async {
    UserProfile? profile = await getUserProfile(user.uid);
    if (profile == null) {
      // Create default profile for new user mapping them as "user" (passenger)
      profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: name ?? user.displayName ?? user.email?.split('@').first ?? 'User',
        role: 'user', 
      );
      await _db.ref().child('users').child(user.uid).set(profile.toMap());
    }
    return profile;
  }

  // Sign In with Email & Password
  Future<UserProfile?> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return await _ensureUserProfile(credential.user!);
      }
    } catch (e) {
      print("Email Sign In Error: \$e");
      rethrow;
    }
    return null;
  }

  // Sign Up with Email & Password
  Future<UserProfile?> signUpWithEmail(String email, String password, {String? name}) async {
      try {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          return await _ensureUserProfile(credential.user!, name: name);
        }
      } catch (e) {
        print("Email Sign Up Error: \$e");
        rethrow;
      }
      return null;
  }

  // Sign In with Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Native Firebase Auth popup for Flutter Web.
        final googleProvider = GoogleAuthProvider();
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          return await _ensureUserProfile(userCredential.user!);
        }
      } else {
        // Mobile platform code (google_sign_in v7.2.0+)
        final googleSignIn = GoogleSignIn.instance;
        final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          return await _ensureUserProfile(userCredential.user!);
        }
      }
    } catch (e) {
      print("Google Sign In Error: $e");
      rethrow; // Let the login screen handle and display all errors.
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    print("[AuthService] signOut requested");
    try {
      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
      }
    } catch (e) {
      print("[AuthService] Google Sign-In signOut failed (expected on web if not signed in via Google): $e");
    }
    await _auth.signOut();
    // Small delay to ensure firebase state propagages on web
    await Future.delayed(const Duration(milliseconds: 500));
    print("[AuthService] signOut completed");
  }
}
