import 'package:flutter/material.dart';

/// Question bank for reusing exam questions.
class ExamBankScreen extends StatelessWidget {
  const ExamBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Bank')),
      body: const Center(child: Text('TODO: Searchable question bank')),
    );
  }
}
