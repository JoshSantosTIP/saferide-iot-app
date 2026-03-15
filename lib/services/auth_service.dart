import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Stream of user auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user profile from DB
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final snapshot = await _db.ref().child('users').child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return UserProfile.fromMap(data, uid);
      }
    } catch (e) {
      print("Error fetching user profile: \$e");
    }
    return null;
  }

  // Create a default user profile if none exists
  Future<UserProfile> _ensureUserProfile(User user) async {
    UserProfile? profile = await getUserProfile(user.uid);
    if (profile == null) {
      // Create default profile for new user mapping them as "user" (passenger)
      profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
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
  Future<UserProfile?> signUpWithEmail(String email, String password) async {
      try {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          return await _ensureUserProfile(credential.user!);
        }
      } catch (e) {
        print("Email Sign Up Error: \$e");
        rethrow;
      }
      return null;
  }

  // Sign In with Google
  Future<UserProfile?> signInWithGoogle() async {
    // Check BEFORE try-catch so the exception propagates to the caller (login screen).
    final googleSignIn = gsi.GoogleSignIn.instance;
    if (!googleSignIn.supportsAuthenticate()) {
      throw Exception(
        "Google Sign-In is not available on this platform. "
        "Please use Email & Password, or test on an Android device.",
      );
    }

    try {
      // Trigger the interactive sign-in flow.
      final gsi.GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // In v7.x, GoogleSignInAuthentication only has idToken, no accessToken.
      final gsi.GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create Firebase credential using idToken only.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase.
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        return await _ensureUserProfile(userCredential.user!);
      }
    } catch (e) {
      print("Google Sign In Error: $e");
      rethrow; // Let the login screen handle and display all errors.
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await gsi.GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
