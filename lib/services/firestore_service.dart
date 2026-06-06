import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipify/models/user_profile.dart';
import 'package:recipify/providers/auth_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserRecord(User user, String authProvider) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if(doc.exists) return;

    await docRef.set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'authProvider': authProvider,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
    });
  }

  Future<void> createUserProfile(
      UserProfile profile
  ) async {
    await _db
        .collection('users')
        .doc(profile.userId)
        .collection('profile')
        .doc('data')
        .set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('data')
        .get();

    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  Stream<UserProfile?> watchUserProfile(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('data')
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromMap(doc.data()!) : null);
  }

  Future<void> markProfileComplete(String userId) async {
    await _db.collection('users').doc(userId).update({
      'profileComplete': true,
    });
  }

  Future<void> logMeal(String userId, Map<String, dynamic> mealData) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _db
        .collection('users')
        .doc(userId)
        .collection('mealLogs')
        .doc(dateKey)
        .collection('entries')
        .add(mealData);
  }

  Stream<QuerySnapshot> getTodaysMeals(String userId) {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _db
        .collection('users')
        .doc(userId)
        .collection('mealLogs')
        .doc(dateKey)
        .collection('entries')
        .orderBy('loggedAt', descending: false)
        .snapshots();
  }
}
