import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/presentation/bloc/states/todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  final ITodoRepository _repository;

  TodoCubit(this._repository) : super(TodoInitial());

  void loadTodos() {
    try {
      final todos = _repository.getAll();
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void addTodo(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    try {
      _repository.add(Todo(title: trimmed));
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void toggleTodo(int index) {
    try {
      final todo = _repository.getAll()[index];
      _repository.update(index, todo.copyWith(isCompleted: !todo.isCompleted));
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void deleteTodo(int index) {
    try {
      _repository.remove(index);
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void updateTodo(int index, String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    try {
      final todo = _repository.getAll()[index];
      _repository.update(index, todo.copyWith(title: trimmed));
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }
}
