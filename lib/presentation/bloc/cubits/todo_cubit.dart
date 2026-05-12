import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/models/todo_category.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/presentation/bloc/states/todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  static const _categoryOrder = [
    TodoCategory.general,
    TodoCategory.work,
    TodoCategory.personal,
    TodoCategory.health,
    TodoCategory.finances,
  ];

  final ITodoRepository _repository;

  TodoCubit(this._repository) : super(TodoInitial());

  void loadTodos() {
    try {
      emit(TodoLoaded(_groupByCategory(_repository.getAll())));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void addTodo(String title, {TodoCategory? category}) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    try {
      final todo = Todo.create(title: trimmed, category: category);
      _repository.add(todo);
      emit(TodoLoaded(_groupByCategory(_repository.getAll())));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void toggleTodo(String id) {
    try {
      final todo = _repository.getById(id);
      if (todo == null) return;
      _repository.update(id, todo.copyWith(isCompleted: !todo.isCompleted));
      emit(TodoLoaded(_groupByCategory(_repository.getAll())));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void deleteTodo(String id) {
    try {
      _repository.remove(id);
      emit(TodoLoaded(_groupByCategory(_repository.getAll())));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void updateTodo(String id, String newTitle, {TodoCategory? category}) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    try {
      final todo = _repository.getById(id);
      if (todo == null) return;
      _repository.update(id, todo.copyWith(title: trimmed, category: category));
      emit(TodoLoaded(_groupByCategory(_repository.getAll())));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Map<TodoCategory, List<Todo>> _groupByCategory(List<Todo> todos) {
    final map = <TodoCategory, List<Todo>>{};

    for (final category in _categoryOrder) {
      final inCategory = todos
          .where((t) => (t.category ?? TodoCategory.general) == category)
          .toList();
      if (inCategory.isNotEmpty) {
        map[category] = inCategory;
      }
    }

    return map;
  }
}
