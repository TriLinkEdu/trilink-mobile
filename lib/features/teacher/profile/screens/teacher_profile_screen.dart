import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../shared/widgets/role_page_background.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  bool _saving = false;
  String? _error;
  String? _successMessage;

  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _departmentController = TextEditingController();
  final _experienceController = TextEditingController();
  final _homeroomClassController = TextEditingController();
  final _officeRoomController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityStateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _departmentController.dispose();
    _experienceController.dispose();
    _homeroomClassController.dispose();
    _officeRoomController.dispose();
    _countryController.dispose();
    _cityStateController.dispose();
    _postalCodeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _initForm() {
    final user = AuthService().currentUser;
    if (user == null) return;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _subjectController.text = user.subject ?? '';
    _departmentController.text = user.department ?? '';
    _experienceController.text = user.experience ?? '';
    _homeroomClassController.text = user.homeroomClass ?? '';
    _officeRoomController.text = user.officeRoom ?? '';
    _countryController.text = user.country ?? '';
    _cityStateController.text = user.cityState ?? '';
    _postalCodeController.text = user.postalCode ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text.isNotEmpty) {
      if (_currentPasswordController.text.isEmpty) {
        setState(() => _error = 'Current password is required');
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() => _error = 'New passwords do not match');
        return;
      }
      if (_newPasswordController.text.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final user = AuthService().currentUser;
      final updateData = <String, dynamic>{};

      if (user != null) {
        void addIfChanged(String key, String newVal, String? oldVal) {
          if (newVal.trim() != (oldVal ?? '')) {
            updateData[key] = newVal.trim();
          }
        }

        addIfChanged('firstName', _firstNameController.text, user.firstName);
        addIfChanged('lastName', _lastNameController.text, user.lastName);
        addIfChanged('phone', _phoneController.text, user.phone);
        addIfChanged('experience', _experienceController.text, user.experience);
        addIfChanged('homeroomClass', _homeroomClassController.text, user.homeroomClass);
        addIfChanged('officeRoom', _officeRoomController.text, user.officeRoom);
        addIfChanged('country', _countryController.text, user.country);
        addIfChanged('cityState', _cityStateController.text, user.cityState);
        addIfChanged('postalCode', _postalCodeController.text, user.postalCode);
      }

      if (_selectedImage != null) {
        final fileId = await ApiService().uploadProfileImage(_selectedImage!);
        updateData['profileImageFileId'] = fileId;
      }

      if (updateData.isNotEmpty) {
        await ApiService().updateProfile(updateData);
      }

      if (_newPasswordController.text.isNotEmpty) {
        await ApiService().changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
      }

      if (updateData.isNotEmpty || _newPasswordController.text.isNotEmpty) {
        await AuthService().fetchMe();
        if (!mounted) return;
        _initForm();
        setState(() {
          _successMessage = 'Profile updated successfully';
          _isEditing = false;
          _selectedImage = null;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        setState(() => _error = 'No changes to save');
      }
    } catch (e) {
      setState(() => _error = 'Failed to update: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _error = null;
      _successMessage = null;
      _selectedImage = null;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
    _initForm();
  }

  String get _initials {
    final user = AuthService().currentUser;
    if (user == null) return '?';
    return '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _isEditing
            ? IconButton(
                onPressed: _cancelEdit,
                icon: const Icon(Icons.arrow_back),
              )
            : canPop
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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
              onPressed: () => setState(() {
                _isEditing = true;
                _error = null;
                _successMessage = null;
              }),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.teacher,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Messages
                if (_error != null) ...[
                  _MessageBanner(message: _error!, isError: true),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  _MessageBanner(message: _successMessage!, isError: false),
                  const SizedBox(height: 16),
                ],

                _buildAvatar(theme),
                const SizedBox(height: 24),

                if (_isEditing) ...[
                  _buildEditForm(theme),
                ] else ...[
                  _buildSectionTitle('Professional Information', theme),
                  const SizedBox(height: 12),
                  _buildInfoCard(theme, [
                    _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: AuthService().currentUser?.fullName ?? ''),
                    _InfoRow(icon: Icons.email_outlined, label: 'Email', value: AuthService().currentUser?.email ?? ''),
                    _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: AuthService().currentUser?.phone ?? 'Not provided'),
                    _InfoRow(icon: Icons.book_outlined, label: 'Subject', value: AuthService().currentUser?.subject ?? 'Not provided'),
                    _InfoRow(icon: Icons.business_outlined, label: 'Department', value: AuthService().currentUser?.department ?? 'Not provided'),
                    _InfoRow(icon: Icons.workspace_premium_outlined, label: 'Experience', value: AuthService().currentUser?.experience ?? 'Not provided'),
                    _InfoRow(icon: Icons.class_outlined, label: 'Homeroom Class', value: AuthService().currentUser?.homeroomClass ?? 'Not provided'),
                    _InfoRow(icon: Icons.meeting_room_outlined, label: 'Office Room', value: AuthService().currentUser?.officeRoom ?? 'Not provided'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Address', theme),
                  const SizedBox(height: 12),
                  _buildInfoCard(theme, [
                    _InfoRow(icon: Icons.public, label: 'Country', value: AuthService().currentUser?.country ?? 'Not provided'),
                    _InfoRow(icon: Icons.location_city, label: 'City / State', value: AuthService().currentUser?.cityState ?? 'Not provided'),
                    _InfoRow(icon: Icons.markunread_mailbox_outlined, label: 'Postal Code', value: AuthService().currentUser?.postalCode ?? 'Not provided'),
                  ]),
                  const SizedBox(height: 24),
                  _buildLogoutButton(theme),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final user = AuthService().currentUser;
    final fileId = user?.profileImageFileId;
    final imageUrl = fileId != null && fileId.isNotEmpty
        ? '${ApiConstants.fileBaseUrl}/api/files/$fileId/download'
        : null;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : imageUrl != null
                        ? NetworkImage(imageUrl)
                        : null,
                child: (_selectedImage == null && imageUrl == null)
                    ? Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
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
                            color: theme.colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
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
          if ((user?.subject ?? '').isNotEmpty)
            Text(
              user!.subject!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              if (i > 0)
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(row.icon,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            row.value,
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
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Details', theme),
        const SizedBox(height: 16),
        _buildField(_firstNameController, 'First Name', Icons.person_outline),
        const SizedBox(height: 12),
        _buildField(_lastNameController, 'Last Name', Icons.person_outline),
        const SizedBox(height: 12),
        _buildField(_phoneController, 'Phone Number', Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 24),
        _buildSectionTitle('Professional Details', theme),
        const SizedBox(height: 16),
        _buildField(_experienceController, 'Experience (e.g. 5 years)',
            Icons.workspace_premium_outlined),
        const SizedBox(height: 12),
        _buildField(_homeroomClassController, 'Homeroom Class',
            Icons.class_outlined),
        const SizedBox(height: 12),
        _buildField(
            _officeRoomController, 'Office Room', Icons.meeting_room_outlined),
        const SizedBox(height: 24),
        _buildSectionTitle('Address', theme),
        const SizedBox(height: 16),
        _buildField(_countryController, 'Country', Icons.public),
        const SizedBox(height: 12),
        _buildField(_cityStateController, 'City / State', Icons.location_city),
        const SizedBox(height: 12),
        _buildField(_postalCodeController, 'Postal Code',
            Icons.markunread_mailbox_outlined),
        const SizedBox(height: 24),
        _buildSectionTitle('Change Password (Optional)', theme),
        const SizedBox(height: 16),
        _buildPasswordField(
            _currentPasswordController, 'Current Password',
            _showCurrentPassword,
            () => setState(() => _showCurrentPassword = !_showCurrentPassword)),
        const SizedBox(height: 12),
        _buildPasswordField(
            _newPasswordController, 'New Password',
            _showNewPassword,
            () => setState(() => _showNewPassword = !_showNewPassword)),
        const SizedBox(height: 12),
        _buildPasswordField(
            _confirmPasswordController, 'Confirm New Password',
            _showConfirmPassword,
            () => setState(
                () => _showConfirmPassword = !_showConfirmPassword)),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancelEdit,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool visible,
    VoidCallback onToggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              size: 20),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
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
                  child: const Text('Logout',
                      style: TextStyle(color: Colors.red)),
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
        icon: Icon(Icons.logout, color: theme.colorScheme.error, size: 18),
        label: Text('Logout',
            style: TextStyle(color: theme.colorScheme.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _MessageBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}
