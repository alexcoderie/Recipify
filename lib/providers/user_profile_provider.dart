import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipify/models/user_profile.dart';
import 'package:recipify/providers/auth_provider.dart';
import 'package:recipify/services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.watchUserProfile(userId);
});
