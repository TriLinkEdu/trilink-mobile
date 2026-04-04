import 'package:equatable/equatable.dart';

import '../models/student_growth_models.dart';

enum ActionPlanStatus { initial, loading, loaded, error }

class ActionPlanState extends Equatable {
  final ActionPlanStatus status;
  final List<StudentActionItem> items;
  final String? errorMessage;

  const ActionPlanState({
    this.status = ActionPlanStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  ActionPlanState copyWith({
    ActionPlanStatus? status,
    List<StudentActionItem>? items,
    String? errorMessage,
  }) {
    return ActionPlanState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
