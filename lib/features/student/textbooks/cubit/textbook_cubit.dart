import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/textbook_model.dart';
import '../repositories/textbook_repository.dart';

enum TextbookStatus { initial, loading, success, error }

class TextbookState {
  final TextbookStatus status;
  final List<TextbookModel> textbooks;
  final String? errorMessage;

  const TextbookState({
    this.status = TextbookStatus.initial,
    this.textbooks = const [],
    this.errorMessage,
  });

  TextbookState copyWith({
    TextbookStatus? status,
    List<TextbookModel>? textbooks,
    String? errorMessage,
  }) {
    return TextbookState(
      status: status ?? this.status,
      textbooks: textbooks ?? this.textbooks,
      errorMessage: errorMessage ?? this.errorMessage,
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
      emit(state.copyWith(status: TextbookStatus.success, textbooks: textbooks));
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
}
