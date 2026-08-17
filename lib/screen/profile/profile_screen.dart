import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/supabase_services.dart';
import '../dashboard/my_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _photoUrl;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _profileService.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      _emailController.text = user.email ?? '';
      _photoUrl = user.photoURL;

      final snapshot = await _profileService.getUserProfile();

      if (snapshot.exists) {
        final data = snapshot.data();
        _usernameController.text = data?['username']?.toString() ?? '';
        _fullNameController.text = data?['fullName']?.toString() ??
            data?['name']?.toString() ??
            user.displayName ??
            '';
        _phoneController.text =
            data?['phone']?.toString() ?? user.phoneNumber ?? '';
        if (data?['photoUrl'] != null &&
            data!['photoUrl'].toString().isNotEmpty) {
          _photoUrl = data['photoUrl'];
        }
      } else {
        await _profileService.createProfile(
          username: '',
          fullName: user.displayName ?? '',
          phone: user.phoneNumber ?? '',
          photoUrl: user.photoURL,
        );

        _usernameController.text = '';
        _fullNameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load profile.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final user = _profileService.currentUser;
    if (user == null) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (file == null) return;

      setState(() => _uploadingPhoto = true);

      final Uint8List bytes = await file.readAsBytes();
      final String ext = file.name.split('.').last;

      // Upload to Supabase Storage profiles folder
      final String publicUrl = await _supabaseService.uploadProfileAvatar(
        uid: user.uid,
        bytes: bytes,
        extension: ext,
      );

      // Save to Firestore and Firebase Auth
      await _profileService.updateProfilePhoto(publicUrl);

      if (!mounted) return;

      setState(() {
        _photoUrl = publicUrl;
        _uploadingPhoto = false;
      });

      _showMessage('Profile photo updated successfully! 📸');
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        _showMessage('Failed to upload profile photo: $e');
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EEF9),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.indigo),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EEF9),
                    child: Icon(Icons.photo_library_rounded, color: Colors.indigo),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty) {
      _showMessage('Please enter your username.');
      return;
    }

    if (fullName.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _profileService.updateProfile(
        username: username,
        fullName: fullName,
        phone: phone,
        photoUrl: _photoUrl,
      );

      if (!mounted) return;

      setState(() {
        _editing = false;
        _saving = false;
      });

      _showMessage('Profile updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      final message = e.toString().replaceFirst('Exception: ', '');
      _showMessage(message);
    }
  }

  Future<void> _cancelEdit() async {
    setState(() {
      _editing = false;
      _loading = true;
    });

    await _loadProfile();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
    });
  }

  Future<void> _deleteProfile() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Profile Data'),
          content: const Text(
            'Are you sure you want to delete your profile information from Firestore?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _authService.deleteUserProfile();
      if (!mounted) return;
      _showMessage('Profile data deleted.');
      await _loadProfile();
    } catch (e) {
      _showMessage('Failed to delete profile: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to permanently delete your account?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete Permanently',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showMessage('Please login again before deleting your account.');
      } else {
        _showMessage(e.message ?? 'Failed to delete account.');
      }
    } catch (e) {
      _showMessage('Failed to delete account: $e');
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_loading && !_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: _startEditing,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 20),
                    _buildProfileCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Avatar
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.indigo.shade400,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.indigo.shade100,
                            child: const Icon(Icons.person, size: 54, color: Colors.indigo),
                          ),
                        )
                      : Container(
                          color: Colors.indigo.shade100,
                          child: const Icon(Icons.person, size: 54, color: Colors.indigo),
                        ),
                ),
              ),

              // Uploading spinner overlay
              if (_uploadingPhoto)
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),

              // Camera Icon Button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _showPhotoOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _fullNameController.text.isNotEmpty
                ? _fullNameController.text
                : 'User Profile',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_usernameController.text.isNotEmpty)
            Text(
              '@${_usernameController.text}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _usernameController,
            enabled: _editing,
            label: 'Username',
            hint: 'e.g. khorsed_bd',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _fullNameController,
            enabled: _editing,
            label: 'Full Name',
            hint: 'e.g. Khorsed Alam',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            enabled: false,
            label: 'Email',
            hint: 'Email Address',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            enabled: _editing,
            label: 'Phone Number',
            hint: '+8801...',
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 24),

          // EDIT / SAVE BUTTONS
          if (_editing) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _saving ? null : _cancelEdit,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('CANCEL'),
              ),
            ),
          ],

          if (!_editing) ...[
            const Divider(height: 32),

            // My Reported Items shortcut
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.list_alt_rounded, color: Colors.indigo),
              ),
              title: const Text('My Reported Items', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('View and manage your lost & found posts'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                );
              },
            ),

            const Divider(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: const Icon(Icons.person_remove_outlined, color: Colors.orange),
              ),
              title: const Text('Clear Profile Information'),
              subtitle: const Text('Delete your Firestore info'),
              onTap: _deleteProfile,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              ),
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently remove your account'),
              onTap: _deleteAccount,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: const Icon(Icons.logout_rounded, color: Colors.grey),
              ),
              title: const Text('Log Out'),
              onTap: _logout,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool enabled,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: enabled
                ? Theme.of(context).colorScheme.surfaceContainerLow
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}