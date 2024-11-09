// firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_data.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(UserData userData) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    final userId = user.uid; // Get the authenticated user ID

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData.toMap(), SetOptions(merge: true));
      print("User data saved successfully!");
    } catch (e) {
      print("Failed to save user data: $e");
    }
  }
}
