import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  GoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Launches the Google account picker and exchanges credentials with Firebase.
  /// Returns null if the user cancels.
  Future<User?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Upserts the Firebase user's profile into the Firestore `users` collection
  /// so other users can discover and chat with them.
  Future<void> saveUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'name': user.displayName ?? 'SAFEE User',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'avatarUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  User? get currentUser => _auth.currentUser;
}
