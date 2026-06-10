import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recipify/models/meal_entry.dart';
import 'package:recipify/models/user_profile.dart';
import 'package:recipify/providers/auth_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserRecord(User user, String authProvider) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) return;

    await docRef.set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'authProvider': authProvider,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
    });
  }

  Future<void> createUserProfile(UserProfile profile) async {
    final batch = _db.batch();

    batch.set(
      _db
          .collection('users')
          .doc(profile.userId)
          .collection('profile')
          .doc('data'),
      profile.toMap(),
    );

    batch.set(_db.collection('users').doc(profile.userId), {
      'profileComplete': true,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(userId)
        .child('avatar.jpg');

    final uploadTask = await storageRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> updateProfilePhoto(String userId, String photoURL) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('data')
        .update({'photoURL': photoURL});
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

  Future<void> logMeal(String userId, MealEntry entry) async {
    final today = entry.loggedAt;
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final batch = _db.batch();

    final entryRef = _db
        .collection('users')
        .doc(userId)
        .collection('mealLogs')
        .doc(dateKey)
        .collection('entries')
        .doc();

    batch.set(entryRef, entry.toMap());

    final dayRef = _db
        .collection('users')
        .doc(userId)
        .collection('mealLogs')
        .doc(dateKey);

    batch.set(dayRef, {
      'totalCalories': FieldValue.increment(entry.totalCalories),
      'totalProtein': FieldValue.increment(entry.totalProtein),
      'totalCarbs': FieldValue.increment(entry.totalCarbs),
      'totalFat': FieldValue.increment(entry.totalFat),
      'date': dateKey,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<DailyLog> watchTodayLog(String userId) {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _db
        .collection('users')
        .doc(userId)
        .collection('mealLogs')
        .doc(dateKey)
        .collection('entries')
        .orderBy('loggedAt')
        .snapshots()
        .asyncMap((snapshot) async {
          final dayDoc = await _db
              .collection('users')
              .doc(userId)
              .collection('mealLogs')
              .doc(dateKey)
              .get();

          final dayData = dayDoc.data() ?? {};
          final entries = snapshot.docs
              .map((doc) => MealEntry.fromMap(doc.id, doc.data()))
              .toList();

          return DailyLog(
            date: dateKey,
            totalCalories: (dayData['totalCalories'] as num?)?.toDouble() ?? 0,
            totalProtein: (dayData['totalProtein'] as num?)?.toDouble() ?? 0,
            totalCarbs: (dayData['totalCarbs'] as num?)?.toDouble() ?? 0,
            totalFat: (dayData['totalFat'] as num?)?.toDouble() ?? 0,
            entries: entries,
          );
        });
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
