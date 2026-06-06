enum DietaryGoal { loseWeight, buildMuscle, maintenance }

enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive }

enum Sex { male, female }

class UserProfile {
  final String userId;
  final String displayName;
  final int age;
  final double weightKg;
  final double heightCm;
  final DietaryGoal goal;
  final ActivityLevel activityLevel;
  final Sex sex;
  final int dailyCalorieGoal;
  final int dailyProteinGoal;
  final int dailyCarbsGoal;
  final int dailyFatGoal;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.activityLevel,
    required this.sex,
    required this.dailyCalorieGoal,
    required this.dailyProteinGoal,
    required this.dailyCarbsGoal,
    required this.dailyFatGoal,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'goal': goal.name,
    'activityLevel': activityLevel.name,
    'sex': sex.name,
    'dailyCalorieGoal': dailyCalorieGoal,
    'dailyProteinGoal': dailyProteinGoal,
    'dailyCarbsGoal': dailyCarbsGoal,
    'dailyFatGoal': dailyFatGoal,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    userId: map['userId'],
    displayName: map['displayName'],
    age: map['age'],
    weightKg: (map['weightKg'] as num).toDouble(),
    heightCm: (map['heightCm'] as num).toDouble(),
    goal: DietaryGoal.values.byName(map['goal']),
    activityLevel: ActivityLevel.values.byName(map['activityLevel']),
    sex: Sex.values.byName(map['sex']),
    dailyCalorieGoal: map['dailyCalorieGoal'],
    dailyProteinGoal: map['dailyProteinGoal'],
    dailyCarbsGoal: map['dailyCarbsGoal'],
    dailyFatGoal: map['dailyFatGoal'],
  );

  static UserProfile calculate({
    required String userId,
    required String displayName,
    required int age,
    required double weightKg,
    required double heightCm,
    required DietaryGoal goal,
    required ActivityLevel activityLevel,
    required Sex sex,
  }) {
    double bmr;

    if(sex == Sex.male) {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    final multipliers = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.lightlyActive: 1.375,
      ActivityLevel.moderatelyActive: 1.55,
      ActivityLevel.veryActive: 1.725,
    };

    double tdee = bmr * multipliers[activityLevel]!;

    int calories;
    switch(goal) {
      case DietaryGoal.loseWeight:
        calories = (tdee - 500).round();
        break;
      case DietaryGoal.buildMuscle:
        calories = (tdee + 300).round();
        break;
      case DietaryGoal.maintenance:
        calories = tdee.round();
        break;
    }

    int protein = (weightKg * 2.0).round();
    int fat = ((calories * 0.25) / 9).round();
    int carbs = ((calories - (protein * 4) - (fat * 9)) / 4).round();

    return UserProfile(
      userId: userId,
      displayName: displayName,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      goal: goal,
      activityLevel: activityLevel,
      sex: sex,
      dailyCalorieGoal: calories,
      dailyProteinGoal: protein,
      dailyCarbsGoal: carbs,
      dailyFatGoal: fat,
    );
  }
}