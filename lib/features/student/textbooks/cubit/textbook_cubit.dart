import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/textbook_model.dart';
import '../repositories/textbook_repository.dart';

enum TextbookStatus { initial, loading, success, error }

class TextbookState {
  final TextbookStatus status;
  final List<TextbookModel> textbooks;
  final List<TextbookModel> filteredTextbooks;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedSubject;
  final List<String> availableSubjects;

  const TextbookState({
    this.status = TextbookStatus.initial,
    this.textbooks = const [],
    this.filteredTextbooks = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.selectedSubject,
    this.availableSubjects = const [],
  });

  /// Get displayed textbooks (filtered based on search and subject)
  List<TextbookModel> get displayedTextbooks =>
      filteredTextbooks.isEmpty && searchQuery.isEmpty && selectedSubject == null
          ? textbooks
          : filteredTextbooks;

  TextbookState copyWith({
    TextbookStatus? status,
    List<TextbookModel>? textbooks,
    List<TextbookModel>? filteredTextbooks,
    String? errorMessage,
    String? searchQuery,
    String? selectedSubject,
    List<String>? availableSubjects,
  }) {
    return TextbookState(
      status: status ?? this.status,
      textbooks: textbooks ?? this.textbooks,
      filteredTextbooks: filteredTextbooks ?? this.filteredTextbooks,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      availableSubjects: availableSubjects ?? this.availableSubjects,
    );
  }
}

class TextbookCubit extends Cubit<TextbookState> {
  final TextbookRepository _repository;

  TextbookCubit(this._repository) : super(const TextbookState());

  Future<void> loadTextbooks({String? subject, int? grade}) async {
    emit(state.copyWith(status: TextbookStatus.loading));
    try {
      final textbooks = await _repository.fetchTextbooks(subject: subject, grade: grade);
      
      // Extract unique subjects for filtering
      final subjects = <String>{};
      for (final textbook in textbooks) {
        subjects.add(textbook.subject);
      }
      
      emit(state.copyWith(
        status: TextbookStatus.success,
        textbooks: textbooks,
        availableSubjects: subjects.toList()..sort(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TextbookStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadTextbookById(String id) async {
    emit(state.copyWith(status: TextbookStatus.loading));
    try {
      final textbook = await _repository.fetchTextbookById(id);
      if (textbook != null) {
        emit(state.copyWith(status: TextbookStatus.success, textbooks: [textbook]));
      } else {
        emit(state.copyWith(
          status: TextbookStatus.error,
          errorMessage: 'Textbook not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TextbookStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Search textbooks by title or subject
  void searchTextbooks(String query) {
    final filtered = _filterTextbooks(query, state.selectedSubject);
    emit(state.copyWith(
      searchQuery: query,
      filteredTextbooks: filtered,
    ));
  }

  /// Filter textbooks by subject
  void filterBySubject(String? subject) {
    final filtered = _filterTextbooks(state.searchQuery, subject);
    emit(state.copyWith(
      selectedSubject: subject,
      filteredTextbooks: filtered,
    ));
  }

  /// Clear all filters and search
  void clearFilters() {
    emit(state.copyWith(
      searchQuery: '',
      selectedSubject: null,
      filteredTextbooks: [],
    ));
  }

  /// Internal method to apply both search and filter
  List<TextbookModel> _filterTextbooks(String searchQuery, String? selectedSubject) {
    var results = state.textbooks;

    // Apply subject filter
    if (selectedSubject != null && selectedSubject.isNotEmpty) {
      results = results.where((t) => t.subject == selectedSubject).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      results = results.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.subject.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return results;
  }
}
