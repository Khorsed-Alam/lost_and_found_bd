import 'package:flutter/material.dart';

import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  // =========================================================
  // SERVICE
  // =========================================================

  final ProfileService _profileService =
  ProfileService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController
  _usernameController =
  TextEditingController();

  final TextEditingController
  _fullNameController =
  TextEditingController();

  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _phoneController =
  TextEditingController();

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    try {
      final user =
          _profileService.currentUser;

      if (user == null) {
        throw Exception(
          'User is not logged in.',
        );
      }

      // -----------------------------------------------------
      // EMAIL FROM FIREBASE AUTH
      // -----------------------------------------------------

      _emailController.text =
          user.email ?? '';

      // -----------------------------------------------------
      // GET FIRESTORE PROFILE
      // -----------------------------------------------------

      final snapshot =
      await _profileService
          .getUserProfile();

      if (snapshot.exists) {
        final data =
        snapshot.data();

        _usernameController.text =
            data?['username']
                ?.toString() ??
                '';

        _fullNameController.text =
            data?['fullName']
                ?.toString() ??
                user.displayName ??
                '';

        _phoneController.text =
            data?['phone']
                ?.toString() ??
                user.phoneNumber ??
                '';
      } else {
        // ---------------------------------------------------
        // CREATE INITIAL PROFILE
        // ---------------------------------------------------

        await _profileService
            .createProfile(
          username: '',
          fullName:
          user.displayName ?? '',
          phone:
          user.phoneNumber ?? '',
        );

        _usernameController.text =
        '';

        _fullNameController.text =
            user.displayName ?? '';

        _phoneController.text =
            user.phoneNumber ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Failed to load profile.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _saveProfile() async {
    final username =
    _usernameController.text.trim();

    final fullName =
    _fullNameController.text.trim();

    final phone =
    _phoneController.text.trim();

    // -------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------

    if (username.isEmpty) {
      _showMessage(
        'Please enter your username.',
      );
      return;
    }

    if (fullName.isEmpty) {
      _showMessage(
        'Please enter your full name.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // -----------------------------------------------------
      // UPDATE FIREBASE
      // -----------------------------------------------------

      await _profileService
          .updateProfile(
        username: username,
        fullName: fullName,
        phone: phone,
      );

      if (!mounted) return;

      setState(() {
        _editing = false;
        _saving = false;
      });

      _showMessage(
        'Profile updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      final message =
      e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      _showMessage(message);
    }
  }

  // =========================================================
  // CANCEL EDIT
  // =========================================================

  Future<void> _cancelEdit() async {
    setState(() {
      _editing = false;
      _loading = true;
    });

    await _loadProfile();
  }

  // =========================================================
  // START EDITING
  // =========================================================

  void _startEditing() {
    setState(() {
      _editing = true;
    });
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      // No custom background color.
      // Uses the project's existing theme.
      body: SafeArea(
        child: _loading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : Column(
          children: [
            _buildHeader(),

            Expanded(
              child:
              SingleChildScrollView(
                padding:
                const EdgeInsets
                    .all(18),
                child:
                _buildProfileCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Column(
      children: [
        // ---------------------------------------------------
        // TOP BAR
        // ---------------------------------------------------

        Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),

          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },

                icon: const Icon(
                  Icons.arrow_back,
                ),
              ),

              IconButton(
                onPressed:
                _startEditing,

                icon: const Icon(
                  Icons.menu,
                ),
              ),
            ],
          ),
        ),

        // ---------------------------------------------------
        // PROFILE ICON
        // ---------------------------------------------------

        Container(
          width: 82,
          height: 82,

          decoration:
          BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface,
              width: 2,
            ),
          ),

          child: Icon(
            Icons.person,
            size: 52,

            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          'Profile',
          style: Theme.of(context)
              .textTheme
              .titleMedium,
        ),

        const SizedBox(
          height: 18,
        ),
      ],
    );
  }

  // =========================================================
  // PROFILE CARD
  // =========================================================

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(24),

      decoration: BoxDecoration(
        // Uses existing project theme.
        color: Theme.of(context)
            .colorScheme
            .surface,

        borderRadius:
        BorderRadius.circular(10),

        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.08,
            ),

            blurRadius: 5,

            offset:
            const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [
          // =================================================
          // USERNAME
          // =================================================

          _buildLabel(
            'User Name',
          ),

          const SizedBox(
            height: 8,
          ),

          _buildTextField(
            controller:
            _usernameController,
            enabled: _editing,
            hint: 'Enter username',
          ),

          const SizedBox(
            height: 24,
          ),

          // =================================================
          // FULL NAME
          // =================================================

          _buildLabel(
            'Full Name',
          ),

          const SizedBox(
            height: 8,
          ),

          _buildTextField(
            controller:
            _fullNameController,
            enabled: _editing,
            hint: 'Enter full name',
          ),

          const SizedBox(
            height: 24,
          ),

          // =================================================
          // EMAIL
          // =================================================

          _buildLabel(
            'Email',
          ),

          const SizedBox(
            height: 8,
          ),

          _buildTextField(
            controller:
            _emailController,
            enabled: false,
            hint: 'Email',
          ),

          const SizedBox(
            height: 24,
          ),

          // =================================================
          // PHONE
          // =================================================

          _buildLabel(
            'Phone Number',
          ),

          const SizedBox(
            height: 8,
          ),

          _buildTextField(
            controller:
            _phoneController,
            enabled: _editing,
            hint: 'Enter phone number',
          ),

          const SizedBox(
            height: 30,
          ),

          // =================================================
          // NORMAL MODE
          // =================================================

          if (!_editing)
            SizedBox(
              width: double.infinity,
              height: 48,

              child:
              FilledButton(
                onPressed:
                _startEditing,

                child: const Text(
                  'EDIT PROFILE',
                ),
              ),
            ),

          // =================================================
          // EDIT MODE
          // =================================================

          if (_editing) ...[
            SizedBox(
              width: double.infinity,
              height: 48,

              child:
              FilledButton(
                onPressed:
                _saving
                    ? null
                    : _saveProfile,

                child: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,

                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'SAVE CHANGES',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width: double.infinity,
              height: 48,

              child:
              OutlinedButton(
                onPressed:
                _saving
                    ? null
                    : _cancelEdit,

                child: const Text(
                  'CANCEL',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // LABEL
  // =========================================================

  Widget _buildLabel(
      String text,
      ) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .bodyLarge,
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController
    controller,
    required bool enabled,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,

      decoration:
      InputDecoration(
        hintText: hint,

        filled: true,

        // Uses project's existing
        // input/theme colors.
        fillColor: Theme.of(context)
            .inputDecorationTheme
            .fillColor,

        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
        ),
      ),
    );
  }
}