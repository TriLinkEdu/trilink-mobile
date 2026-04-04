import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/action_plan_cubit.dart';
import '../cubit/action_plan_state.dart';
import '../repositories/student_analytics_repository.dart';

class StudentActionPlanScreen extends StatelessWidget {
  const StudentActionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ActionPlanCubit(sl<StudentAnalyticsRepository>(), sl())..loadPlan(),
      child: const _StudentActionPlanView(),
    );
  }
}

class _StudentActionPlanView extends StatelessWidget {
  const _StudentActionPlanView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Action Plan')),
      body: StudentPageBackground(
        child: BlocBuilder<ActionPlanCubit, ActionPlanState>(
          builder: (context, state) {
            if (state.status == ActionPlanStatus.loading ||
                state.status == ActionPlanStatus.initial) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              );
            }

            if (state.status == ActionPlanStatus.error) {
              return AppErrorWidget(
                message: state.errorMessage ?? 'Unable to load action plan.',
                onRetry: () => context.read<ActionPlanCubit>().loadPlan(),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => AppSpacing.gapSm,
              itemBuilder: (context, index) {
                final item = state.items[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: item.done,
                        onChanged: (_) =>
                            context.read<ActionPlanCubit>().toggleDone(item.id),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: item.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            AppSpacing.gapXxs,
                            Text(
                              item.reason,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              '${item.effortMinutes} min • ${item.category}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.routeName != null)
                        IconButton(
                          tooltip: 'Open',
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              item.routeName!,
                              arguments: item.routeArgs,
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
