import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipify/models/meal_entry.dart';
import 'package:recipify/providers/auth_provider.dart';
import 'package:recipify/providers/user_profile_provider.dart';

final todayLogProvider = StreamProvider<DailyLog>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(
      DailyLog(
        date: '',
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        entries: [],
      ),
    );
  }

  return ref.read(firestoreServiceProvider).watchTodayLog(userId);
});
