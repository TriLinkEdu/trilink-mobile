import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/validation/validators.dart';

/// Teacher → Broadcast a notification to a class
/// (`POST /notifications/broadcast` with `audience: "class"`).
class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends State<BroadcastNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;

  List<Map<String, dynamic>> _classes = const [];
  String? _classOfferingId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final year = await ApiService().getActiveAcademicYear();
      final yearId =
          (year['id'] ?? (year['data'] as Map?)?['id']) as String? ?? '';
      final list = await ApiService().getMyClassOfferings(yearId);
      if (!mounted) return;
      setState(() {
        _classes = list.whereType<Map<String, dynamic>>().toList();
        _classOfferingId = _classes.isNotEmpty
            ? _classes.first['id'] as String?
            : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your classes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }
    if (_classOfferingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a class first.')));
      return;
    }
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    setState(() => _sending = true);
    try {
      await ApiService().broadcastNotification(
        title: title,
        body: body,
        audience: 'class',
        classOfferingId: _classOfferingId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Broadcast sent.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Broadcast failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast to a class')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _classOfferingId,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'] as String?,
                              child: Text(_classLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _classOfferingId = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.text(
                        label: 'Title',
                        min: 3,
                        max: 100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyCtrl,
                      maxLines: 6,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.text(
                        label: 'Body',
                        min: 1,
                        max: 2000,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_sending ? 'Sending…' : 'Send broadcast'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _classLabel(Map<String, dynamic> c) {
    final subj = c['subjectName'] ?? c['subject']?['name'] ?? '';
    final grade = c['gradeName'] ?? c['grade']?['name'] ?? '';
    final section = c['sectionName'] ?? c['section']?['name'] ?? '';
    final parts = [
      if ((subj as String).isNotEmpty) subj,
      if ((grade as String).isNotEmpty) grade,
      if ((section as String).isNotEmpty) 'Sec $section',
    ];
    return parts.isEmpty ? (c['id'] as String? ?? 'Class') : parts.join(' • ');
  }
}
