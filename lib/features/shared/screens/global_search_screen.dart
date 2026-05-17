import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';

/// Shared → Global search across users, class offerings, subjects
/// (`GET /search?q=`).
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  Map<String, dynamic> _results = const {};

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _results = const {});
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(v));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().globalSearch(q.trim());
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const {};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ((_results['users'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final classes = ((_results['classOfferings'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final subjects = ((_results['subjects'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search users, classes, subjects…',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _loading
          ? const LinearProgressIndicator()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (users.isNotEmpty) ...[
                  _Section(title: 'People'),
                  ...users.map((u) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(u['title']?.toString() ?? '-'),
                          subtitle: Text(u['subtitle']?.toString() ?? ''),
                        ),
                      )),
                ],
                if (classes.isNotEmpty) ...[
                  _Section(title: 'Classes'),
                  ...classes.map((c) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.class_outlined),
                          title: Text(c['title']?.toString() ?? '-'),
                          subtitle: Text(c['subtitle']?.toString() ?? ''),
                        ),
                      )),
                ],
                if (subjects.isNotEmpty) ...[
                  _Section(title: 'Subjects'),
                  ...subjects.map((s) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(s['title']?.toString() ?? '-'),
                          subtitle: Text(s['subtitle']?.toString() ?? ''),
                        ),
                      )),
                ],
                if (users.isEmpty &&
                    classes.isEmpty &&
                    subjects.isEmpty &&
                    _ctrl.text.trim().length >= 2 &&
                    !_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No results.')),
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
