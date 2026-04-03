part of 'course_list_cubit.dart';

enum CourseListStatus { initial, loading, loaded, error }

class CourseListState extends Equatable {
  final CourseListStatus status;
  final List<SubjectModel> subjects;
  final CourseListStatus topicsStatus;
  final List<TopicModel> topics;
  final String? errorMessage;

  const CourseListState({
    this.status = CourseListStatus.initial,
    this.subjects = const [],
    this.topicsStatus = CourseListStatus.initial,
    this.topics = const [],
    this.errorMessage,
  });

  CourseListState copyWith({
    CourseListStatus? status,
    List<SubjectModel>? subjects,
    CourseListStatus? topicsStatus,
    List<TopicModel>? topics,
    String? errorMessage,
  }) {
    return CourseListState(
      status: status ?? this.status,
      subjects: subjects ?? this.subjects,
      topicsStatus: topicsStatus ?? this.topicsStatus,
      topics: topics ?? this.topics,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, subjects, topicsStatus, topics, errorMessage];
}
