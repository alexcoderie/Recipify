import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:recipify/models/user_profile.dart';
import 'package:recipify/providers/auth_provider.dart';
import 'package:recipify/providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  DietaryGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;
  Sex? _selectedSex;
  bool _isLoading = false;
  bool _initialized = false;
  File? _pickedImage;
  bool _isUploadingPhoto = false;

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _nameController = TextEditingController(text: profile.displayName);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(text: profile.heightCm.toString());
    _weightController = TextEditingController(text: profile.weightKg.toString());
    _selectedGoal = profile.goal;
    _selectedActivityLevel = profile.activityLevel;
    _selectedSex = profile.sex;
    _initialized = true;
  }

  Future<void> _saveChanges(UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider)!;

      final updated = UserProfile.calculate(
        userId: userId,
        displayName: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        weightKg: double.parse(_weightController.text),
        heightCm: double.parse(_heightController.text),
        goal: _selectedGoal ?? currentProfile.goal,
        activityLevel: _selectedActivityLevel ?? currentProfile.activityLevel,
        sex: _selectedSex ?? currentProfile.sex,
      );

      await ref.read(firestoreServiceProvider).createUserProfile(updated);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Colors.green),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.green),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),

            if(_pickedImage != null)
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('Remove photo',
                  style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pickedImage = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() => _pickedImage = File(picked.path));

    await _uploadPhoto();
  }

  Future<void> _uploadPhoto() async {
    if (_pickedImage == null) return;
    setState(() => _isUploadingPhoto = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      final photoURL = await firestoreService.uploadProfilePhoto(
        userId!,
        _pickedImage!,
      );

      await firestoreService.updateProfilePhoto(userId, photoURL);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildAvatarCard(UserProfile profile) {
    return _Card(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: _buildAvatar(profile),
                ),
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: _isUploadingPhoto
                      ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      LucideIcons.camera,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ref.watch(authStateProvider).value?.email ?? '',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    if (_pickedImage != null) {
      return Image.file(_pickedImage!, fit: BoxFit.cover);
    }

    if (profile.photoURL != null && profile.photoURL!.isNotEmpty) {
      return Image.network(
        profile.photoURL!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    return _initialsAvatar(profile);
  }

  Widget _initialsAvatar(UserProfile profile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(profile.displayName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future <void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _ageController.dispose();
      _heightController.dispose();
      _weightController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error in profile page: $e')),
      ),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        _initFromProfile(profile);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAvatarCard(profile),
                    const SizedBox(height: 16),

                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoField(
                            icon: LucideIcons.mail,
                            label: 'Email',
                            controller: TextEditingController(
                              text: ref
                                  .watch(authStateProvider)
                                  .value
                                  ?.email ??
                                  '',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          _InfoField(
                            icon: LucideIcons.calendar,
                            label: 'Age',
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final age = int.tryParse(v ?? '');
                              if (age == null || age < 1 || age > 120) {
                                return 'Enter a valid age';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _InfoField(
                            icon: LucideIcons.ruler,
                            label: 'Height (cm)',
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final h = double.tryParse(v ?? '');
                              if (h == null || h < 100 || h > 250) {
                                return 'Enter a valid height';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _InfoField(
                            icon: LucideIcons.weight,
                            label: 'Weight (kg)',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final w = double.tryParse(v ?? '');
                              if (w == null || w < 20 || w > 300) {
                                return 'Enter a valid weight';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goals',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _InfoField(
                            icon: LucideIcons.target,
                            label: 'Daily Calorie Goal',
                            controller: TextEditingController(
                              text: profile.dailyCalorieGoal.toString(),
                            ),
                            readOnly: true,
                            suffix: const Text(
                              'auto',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.green),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Activity level dropdown
                          _DropdownField(
                            icon: LucideIcons.activity,
                            label: 'Activity Level',
                            value: _selectedActivityLevel,
                            items: const [
                              DropdownMenuItem(
                                value: ActivityLevel.sedentary,
                                child: Text('Sedentary'),
                              ),
                              DropdownMenuItem(
                                value: ActivityLevel.lightlyActive,
                                child: Text('Lightly Active'),
                              ),
                              DropdownMenuItem(
                                value: ActivityLevel.moderatelyActive,
                                child: Text('Moderately Active'),
                              ),
                              DropdownMenuItem(
                                value: ActivityLevel.veryActive,
                                child: Text('Very Active'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedActivityLevel = v),
                          ),
                          const SizedBox(height: 12),

                          _DropdownField(
                            icon: LucideIcons.target,
                            label: 'Goal',
                            value: _selectedGoal,
                            items: const [
                              DropdownMenuItem(
                                value: DietaryGoal.loseWeight,
                                child: Text('Lose Weight'),
                              ),
                              DropdownMenuItem(
                                value: DietaryGoal.maintenance,
                                child: Text('Maintain Weight'),
                              ),
                              DropdownMenuItem(
                                value: DietaryGoal.buildMuscle,
                                child: Text('Build Muscle'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedGoal = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : () => _saveChanges(profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(LucideIcons.logOut, size: 20),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                DropdownButtonFormField<T>(
                  initialValue: value,
                  items: items,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  icon: Icon(
                    LucideIcons.chevronsUpDown,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}