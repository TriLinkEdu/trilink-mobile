import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../shared/widgets/role_page_background.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMessage;

  List<_LinkedChild> _children = [];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityStateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Profile image
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Password visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Edit mode
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeFormData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityStateController.dispose();
    _postalCodeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    final user = AuthService().currentUser;
    print('DEBUG FORM: Initializing form data with user: $user');
    if (user != null) {
      print('DEBUG FORM: Setting form fields:');
      print('  firstName: "${user.firstName}"');
      print('  lastName: "${user.lastName}"');
      print('  phone: "${user.phone ?? ''}"');
      print('  country: "${user.country ?? ''}"');
      print('  cityState: "${user.cityState ?? ''}"');
      print('  postalCode: "${user.postalCode ?? ''}"');

      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone ?? '';
      _countryController.text = user.country ?? '';
      _cityStateController.text = user.cityState ?? '';
      _postalCodeController.text = user.postalCode ?? '';

      print('DEBUG FORM: Form fields updated');
    } else {
      print('DEBUG FORM: No user data available');
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Use new API to get children
      final children = await ApiService().getMyChildren();

      if (!mounted) return;
      setState(() {
        _children = children.map<_LinkedChild>((child) {
          final student = child['student'] as Map<String, dynamic>?;
          final name =
              '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'
                  .trim();
          final grade = student?['grade'] as String? ?? '';
          return _LinkedChild(name: name, grade: grade, school: '');
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _initials {
    final user = AuthService().currentUser;
    if (user == null) return '??';
    final f = user.firstName;
    final l = user.lastName;
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
  }

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await StorageService().accessToken;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate password fields if changing password
    if (_newPasswordController.text.isNotEmpty) {
      if (_currentPasswordController.text.isEmpty) {
        setState(() {
          _error = 'Current password is required to set a new password';
        });
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _error = 'New passwords do not match';
        });
        return;
      }

      if (_newPasswordController.text.length < 6) {
        setState(() {
          _error = 'New password must be at least 6 characters';
        });
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      // Prepare update data
      final updateData = <String, dynamic>{};

      // Add basic profile fields
      final user = AuthService().currentUser;
      if (user != null) {
        print('DEBUG: Current user data:');
        print('  firstName: "${user.firstName}"');
        print('  lastName: "${user.lastName}"');
        print('  phone: "${user.phone ?? ''}"');
        print('  country: "${user.country ?? ''}"');
        print('  cityState: "${user.cityState ?? ''}"');
        print('  postalCode: "${user.postalCode ?? ''}"');

        print('DEBUG: Form data:');
        print('  firstName: "${_firstNameController.text.trim()}"');
        print('  lastName: "${_lastNameController.text.trim()}"');
        print('  phone: "${_phoneController.text.trim()}"');
        print('  country: "${_countryController.text.trim()}"');
        print('  cityState: "${_cityStateController.text.trim()}"');
        print('  postalCode: "${_postalCodeController.text.trim()}"');

        if (_firstNameController.text.trim() != user.firstName) {
          updateData['firstName'] = _firstNameController.text.trim();
          print(
            'DEBUG: Adding firstName to update: "${_firstNameController.text.trim()}"',
          );
        }
        if (_lastNameController.text.trim() != user.lastName) {
          updateData['lastName'] = _lastNameController.text.trim();
          print(
            'DEBUG: Adding lastName to update: "${_lastNameController.text.trim()}"',
          );
        }
        if (_phoneController.text.trim() != (user.phone ?? '')) {
          updateData['phone'] = _phoneController.text.trim();
          print(
            'DEBUG: Adding phone to update: "${_phoneController.text.trim()}"',
          );
        }
        if (_countryController.text.trim() != (user.country ?? '')) {
          updateData['country'] = _countryController.text.trim();
          print(
            'DEBUG: Adding country to update: "${_countryController.text.trim()}"',
          );
        }
        if (_cityStateController.text.trim() != (user.cityState ?? '')) {
          updateData['cityState'] = _cityStateController.text.trim();
          print(
            'DEBUG: Adding cityState to update: "${_cityStateController.text.trim()}"',
          );
        }
        if (_postalCodeController.text.trim() != (user.postalCode ?? '')) {
          updateData['postalCode'] = _postalCodeController.text.trim();
          print(
            'DEBUG: Adding postalCode to update: "${_postalCodeController.text.trim()}"',
          );
        }
      }

      // Profile image file id
      if (_selectedImage != null) {
        print('DEBUG: Uploading profile image...');
        final profileImageFileId = await ApiService().uploadProfileImage(
          _selectedImage!,
        );
        updateData['profileImageFileId'] = profileImageFileId;
        print('DEBUG: Profile image uploaded with ID: $profileImageFileId');
      }

      print('DEBUG: Final update data: $updateData');

      if (updateData.isNotEmpty) {
        print('DEBUG: Calling API updateProfile...');
        final response = await ApiService().updateProfile(updateData);
        print('DEBUG: API response: $response');
      }

      // Handle password change separately if needed
      if (_newPasswordController.text.isNotEmpty) {
        print('DEBUG: Calling API changePassword...');
        await ApiService().changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
        print('DEBUG: Password changed successfully');
      }

      if (updateData.isNotEmpty || _newPasswordController.text.isNotEmpty) {
        // Refresh profile data after any profile updates
        if (updateData.isNotEmpty || _newPasswordController.text.isNotEmpty) {
          print('DEBUG: Refreshing user data...');
          await AuthService().fetchMe();
          print('DEBUG: User data refreshed');
          print('DEBUG: Updated profileImagePath: "${AuthService().currentUser?.profileImagePath}"');

          // Force UI rebuild with updated data
          setState(() {
            // Re-initialize form data with updated user data
            _initializeFormData();
          });
          print('DEBUG: UI updated with new user data');
        }

        setState(() {
          _successMessage = 'Profile updated successfully';
          _isEditing = false;
          _selectedImage = null;
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          // Force rebuild to show updated data
        });
      } else {
        setState(() {
          _error = 'No changes to save';
        });
        print('DEBUG: No changes detected');
      }
    } catch (e) {
      print('DEBUG: Error updating profile: $e');
      setState(() {
        _error = 'Failed to update profile: $e';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _error = null;
      _successMessage = null;
      _selectedImage = null;
      // Reset form data
      _initializeFormData();
      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _isEditing
            ? IconButton(
                onPressed: _cancelEdit,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _error = null;
                  _successMessage = null;
                });
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && !_isEditing
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show messages
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_successMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildAvatarSection(),
                      const SizedBox(height: 24),

                      if (_isEditing) ...[
                        _buildEditForm(),
                      ] else ...[
                        _buildSectionTitle('Personal Information'),
                        const SizedBox(height: 12),
                        _buildPersonalInfoCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Linked Children'),
                        const SizedBox(height: 12),
                        if (_children.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'No children linked',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ..._children.map(_buildChildCard),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;
    
    print('DEBUG AVATAR: Building avatar with:');
    print('  profileImagePath: "${user?.profileImagePath}"');
    print('  profileImageFileId: "${user?.profileImageFileId}"');
    print('  selectedImage: $_selectedImage');
    print('  fileBaseUrl: "${ApiConstants.fileBaseUrl}"');
    if (user?.profileImagePath != null) {
      print('  Full image URL: "${ApiConstants.fileBaseUrl}${user!.profileImagePath}"');
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              FutureBuilder<Map<String, String>?>(
                future: _getAuthHeaders(),
                builder: (context, snapshot) {
                  return CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (user?.profileImagePath != null && user!.profileImagePath!.isNotEmpty && snapshot.hasData)
                            ? NetworkImage(
                                '${ApiConstants.fileBaseUrl}${user.profileImagePath}',
                                headers: snapshot.data,
                              )
                            : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('DEBUG AVATAR: Failed to load profile image: $exception');
                    },
                    child: (_selectedImage == null && (user?.profileImagePath == null || user!.profileImagePath!.isEmpty))
                        ? Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  );
                },
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
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
            user?.fullName ?? '',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account Settings'),
        const SizedBox(height: 12),

        // Phone field
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),

        // Password section
        _buildSectionTitle('Change Password (Optional)'),
        const SizedBox(height: 12),

        TextFormField(
          controller: _currentPasswordController,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
              icon: Icon(
                _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          obscureText: !_showCurrentPassword,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
              icon: Icon(
                _showNewPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          obscureText: !_showNewPassword,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          obscureText: !_showConfirmPassword,
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancelEdit,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;

    print('DEBUG UI: Building personal info card with user data:');
    print('  user: $user');
    print('  user?.phone: "${user?.phone}"');
    print('  user?.country: "${user?.country}"');
    print('  user?.cityState: "${user?.cityState}"');
    print('  user?.postalCode: "${user?.postalCode}"');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: user?.fullName ?? '',
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '',
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user?.phone ?? 'Not provided',
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _buildInfoRow(
            icon: Icons.public,
            label: 'Country',
            value: user?.country ?? 'Not provided',
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _buildInfoRow(
            icon: Icons.location_city,
            label: 'City/State',
            value: user?.cityState ?? 'Not provided',
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _buildInfoRow(
            icon: Icons.markunread_mailbox,
            label: 'Postal Code',
            value: user?.postalCode ?? 'Not provided',
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: 'Parent',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(_LinkedChild child) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
            child: Text(
              child.name
                  .split(' ')
                  .map((p) => p.isNotEmpty ? p[0] : '')
                  .take(2)
                  .join(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  child.grade,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, RouteNames.login);
              }
            },
            icon: const Icon(Icons.logout, size: 18, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkedChild {
  final String name;
  final String grade;
  final String school;

  _LinkedChild({required this.name, required this.grade, required this.school});
}
