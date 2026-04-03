import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
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
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(),
            );
          }
          final list = state.data?.insights ?? [];
          if (list.isEmpty) {
            return const EmptyStateWidget(
              illustration: BrainIllustration(),
              icon: Icons.analytics_rounded,
              title: 'No evaluation insights',
              subtitle: 'Complete assessments to see your evaluation here.',
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
      separatorBuilder: (_, _) => AppSpacing.gapSm,
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapSm,
            Text(summary),
            AppSpacing.gapSm,
            Text('Recommendation: $recommendation'),
          ],
        ),
      ),
    );
  }
}
