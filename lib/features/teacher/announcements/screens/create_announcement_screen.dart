import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;

  // Audience: 'all' | 'students' | 'parents'
  String _selectedAudience = 'all';

  // Scheduling
  bool _scheduleForLater = false;
  DateTime? _scheduledDateTime;

  // Attachments (uploaded file IDs)
  final List<_AttachmentItem> _attachments = [];
  bool _uploadingFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    final picker = ImagePicker();
    // Use file picker — pick any file via gallery (images only for now)
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploadingFile = true);
    try {
      final fileId = await ApiService().uploadProfileImage(file);
      setState(() {
        _attachments.add(_AttachmentItem(
          name: file.name,
          fileId: fileId,
          isImage: true,
        ));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _scheduledDateTime ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _sendAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a message')));
      return;
    }
    if (_scheduleForLater && _scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a schedule date/time')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final yearData = await ApiService().getActiveAcademicYear();
      final yearId = (yearData['id'] ?? yearData['data']?['id']) as String?;
      if (yearId == null || yearId.isEmpty) {
        throw Exception('No active academic year found');
      }

      await ApiService().createAnnouncement({
        'academicYearId': yearId,
        'title': title,
        'body': message,
        'audience': _selectedAudience,
        if (_scheduleForLater && _scheduledDateTime != null)
          'publishAt': _scheduledDateTime!.toUtc().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_scheduleForLater
              ? 'Announcement scheduled for ${DateFormat('MMM d, h:mm a').format(_scheduledDateTime!)}'
              : 'Announcement sent!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'New Announcement',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  const SizedBox(height: 4),
                  _buildMessageField(),
                  const SizedBox(height: 4),
                  _buildCharCount(),
                  const SizedBox(height: 24),
                  _buildTargetAudience(),
                  const SizedBox(height: 24),
                  _buildAttachments(),
                  const SizedBox(height: 24),
                  _buildScheduleSection(theme),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
      decoration: const InputDecoration(
        hintText: 'Enter announcement title...',
        hintStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB0C4DE),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      maxLines: 6,
      maxLength: 500,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Write your message here...',
        hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
      style: const TextStyle(fontSize: 15, height: 1.5),
    );
  }

  Widget _buildCharCount() {
    final count = _messageController.text.length;
    final color = count > 450 ? AppColors.error : Colors.grey.shade500;
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$count / 500',
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Widget _buildTargetAudience() {
    final options = [
      ('all', 'Everyone', Icons.public),
      ('students', 'Students', Icons.school_outlined),
      ('parents', 'Parents', Icons.family_restroom_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('TARGET AUDIENCE'),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final value = opt.$1;
            final label = opt.$2;
            final icon = opt.$3;
            final selected = _selectedAudience == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedAudience = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon,
                          size: 20,
                          color: selected
                              ? Colors.white
                              : Colors.grey.shade600),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('ATTACHMENTS'),
        const SizedBox(height: 12),
        ..._attachments.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      a.isImage ? Icons.image_outlined : Icons.attach_file,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Uploaded ✓',
                          style: TextStyle(
                              fontSize: 11, color: Colors.green.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.grey.shade500, size: 18),
                    onPressed: () =>
                        setState(() => _attachments.remove(a)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _uploadingFile ? null : _pickAndUploadFile,
          icon: _uploadingFile
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.attach_file, size: 18),
          label: Text(_uploadingFile ? 'Uploading...' : 'Add Attachment'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DELIVERY'),
        const SizedBox(height: 12),
        // Send now vs schedule toggle
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _scheduleForLater = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: !_scheduleForLater
                        ? AppColors.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !_scheduleForLater
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded,
                          size: 16,
                          color: !_scheduleForLater
                              ? Colors.white
                              : Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Send Now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_scheduleForLater
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _scheduleForLater = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _scheduleForLater
                        ? AppColors.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _scheduleForLater
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule,
                          size: 16,
                          color: _scheduleForLater
                              ? Colors.white
                              : Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _scheduleForLater
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Date/time picker (shown when schedule is selected)
        if (_scheduleForLater) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickScheduleDateTime,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _scheduledDateTime != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18,
                      color: _scheduledDateTime != null
                          ? AppColors.primary
                          : Colors.grey.shade500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _scheduledDateTime != null
                          ? DateFormat('EEE, MMM d, yyyy  •  h:mm a')
                              .format(_scheduledDateTime!)
                          : 'Tap to pick date & time',
                      style: TextStyle(
                        fontSize: 14,
                        color: _scheduledDateTime != null
                            ? theme.colorScheme.onSurface
                            : Colors.grey.shade500,
                        fontWeight: _scheduledDateTime != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_attachments.isNotEmpty)
            Row(
              children: [
                Icon(Icons.attach_file,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${_attachments.length} file${_attachments.length > 1 ? 's' : ''}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _sendAnnouncement,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    _scheduleForLater ? Icons.schedule : Icons.send,
                    size: 16),
            label: Text(
              _scheduleForLater ? 'Schedule' : 'Send Now',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentItem {
  final String name;
  final String fileId;
  final bool isImage;
  _AttachmentItem(
      {required this.name, required this.fileId, required this.isImage});
}
