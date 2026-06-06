import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipify/models/user_profile.dart';
import 'package:recipify/providers/auth_provider.dart';
import 'package:recipify/providers/user_profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  DietaryGoal _selectedGoal = DietaryGoal.maintenance;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  Sex _selectedSex = Sex.male;
  bool _isLoading = false;
  int _currentStep = 0;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider)!;

      final profile = UserProfile.calculate(
        userId: userId,
        displayName: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        weightKg: double.parse(_weightController.text),
        heightCm: double.parse(_heightController.text),
        goal: _selectedGoal,
        activityLevel: _selectedActivityLevel,
        sex: _selectedSex,
      );

      await ref.read(firestoreServiceProvider).createUserProfile(profile);
      await ref.read(firestoreServiceProvider).markProfileComplete(userId);

      ref.invalidate(userProfileProvider);
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Set up your profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if(_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _saveProfile();
            }
          },
          onStepCancel: () {
            if(_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : Text(_currentStep == 2 ? 'Save' : 'Continue'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            Step(
              title: const Text('Basic Info'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Your Name', Icons.person_outline),
                    validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Age', Icons.cake_outlined),
                    validator: (v) {
                      final age = int.tryParse(v ?? '');
                      if(age == null || age < 1 || age > 120) {
                        return 'Enter a valid age';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('What is your sex?', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...[
                    (Sex.female, 'Female'),
                    (Sex.male, 'Male'),
                  ].map((item) => _SexTile(
                    label: item.$2,
                    selected: _selectedSex == item.$1,
                    onTap: () => setState(() => _selectedSex = item.$1),
                  )),
                ],
              ),
            ),

            Step(
              title: const Text('Body Measurements'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Weight (kg)', Icons.monitor_weight_outlined),
                    validator: (v) {
                      final w = double.tryParse(v ?? '');
                      if (w == null || w < 20 || w > 300) {
                        return 'Enter a valid weight';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Height (cm)', Icons.height_outlined),
                    validator: (v) {
                      final h = double.tryParse(v ?? '');
                      if (h == null || h < 100 || h > 250) {
                        return 'Enter a valid height';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            Step(
              title: const Text('Your Goals'),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What is your goal?',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...[
                    (DietaryGoal.loseWeight, 'Lose Weight'),
                    (DietaryGoal.buildMuscle, 'Build Muscle'),
                    (DietaryGoal.maintenance, 'Maintenance'),
                  ].map((item) => _GoalTile(
                    label: item.$2,
                    selected: _selectedGoal == item.$1,
                    onTap: () => setState(() => _selectedGoal = item.$1),
                  )),

                  const SizedBox(height: 20),
                  const Text('Activity Level',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...[
                    (ActivityLevel.sedentary, 'Sedentary', 'Little or no exercise'),
                    (ActivityLevel.lightlyActive, 'Lightly Active', '1-3 days/week'),
                    (ActivityLevel.moderatelyActive, 'Moderately Active', '3-5 days/week'),
                    (ActivityLevel.veryActive, 'Very Active', '6-7 days/week'),
                  ].map((item) => _ActivityTile(
                    label: item.$2,
                    subtitle: item.$3,
                    selected: _selectedActivityLevel == item.$1,
                    onTap: () => setState(() => _selectedActivityLevel = item.$1),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}

class _SexTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SexTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            const Spacer(),
            if(selected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GoalTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            const Spacer(),
            if(selected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}