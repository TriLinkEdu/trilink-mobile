import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';

class EvaluateMeScreen extends StatelessWidget {
  final List<EvaluateInsightModel>? insights;

  const EvaluateMeScreen({super.key, this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights != null && insights!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evaluate Me')),
        body: _EvaluateMeList(insights: insights!),
      );
    }
    return BlocProvider(
      create: (_) => AiAssistantCubit(sl<StudentAiAssistantRepository>())
        ..loadAssistantData(suppressError: true),
      child: const _EvaluateMeBlocView(),
    );
  }
}

class _EvaluateMeBlocView extends StatelessWidget {
  const _EvaluateMeBlocView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluate Me')),
      body: BlocBuilder<AiAssistantCubit, AiAssistantState>(
        builder: (context, state) {
          final loading = state.status == AiAssistantStatus.initial ||
              state.status == AiAssistantStatus.loading;
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = state.data?.insights ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text('No evaluation insights available.'),
            );
          }
          return _EvaluateMeList(insights: list);
        },
      ),
    );
  }
}

class _EvaluateMeList extends StatelessWidget {
  final List<EvaluateInsightModel> insights;

  const _EvaluateMeList({required this.insights});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final insight = insights[index];
        return _InsightCard(
          title: insight.title,
          summary: insight.summary,
          recommendation: insight.recommendation,
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String summary;
  final String recommendation;

  const _InsightCard({
    required this.title,
    required this.summary,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(summary),
            const SizedBox(height: 8),
            Text('Recommendation: $recommendation'),
          ],
        ),
      ),
    );
  }
}
