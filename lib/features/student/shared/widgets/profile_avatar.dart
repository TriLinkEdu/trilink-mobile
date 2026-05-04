import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/di/injection_container.dart';

/// Reusable profile avatar that automatically updates when profile image changes
class ProfileAvatar extends StatefulWidget {
  final double radius;
  final String? userId;
  final String? profileImagePath;
  final String? fallbackText;

  const ProfileAvatar({
    super.key,
    this.radius = 20,
    this.userId,
    this.profileImagePath,
    this.fallbackText,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _imagePath;
  final StorageService _storage = sl<StorageService>();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImagePath != widget.profileImagePath) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    if (widget.profileImagePath != null) {
      setState(() {
        _imagePath = widget.profileImagePath;
      });
      return;
    }

    // Load from storage if not provided AND no userId specified (current user only)
    if (widget.userId == null) {
      try {
        final user = await _storage.getUser();
        final path = user?['profileImagePath'] as String?;
        if (mounted && path != null && path.isNotEmpty) {
          setState(() {
            _imagePath = path;
          });
        }
      } catch (e) {
        // Ignore errors, will show fallback
      }
    }
    // For other users (when userId is provided), don't load current user's image
    // Just show initials fallback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(
          _imagePath!.startsWith('http') ? _imagePath! : '${ApiConstants.fileBaseUrl}$_imagePath',
        ),
        onBackgroundImageError: (_, __) {
          // Fallback to initials on error
          setState(() {
            _imagePath = null;
          });
        },
      );
    }

    // Fallback to initials
    final text = widget.fallbackText ?? 'U';
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        text.isNotEmpty ? text[0].toUpperCase() : '?',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
