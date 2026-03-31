import 'package:flutter/material.dart';

class StudentSyncStatusScreen extends StatelessWidget {
  const StudentSyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Access & Sync',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                title: Text('Last Sync'),
                subtitle: Text('Today, 08:45 AM'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                title: Text('Pending Uploads'),
                subtitle: Text('2 items waiting for connection'),
                trailing: Icon(Icons.sync_problem, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync started (mock).')),
                  );
                },
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
