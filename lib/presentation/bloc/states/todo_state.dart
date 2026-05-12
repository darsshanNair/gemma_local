import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/models/todo_category.dart';

sealed class TodoState {
  const TodoState();
}

final class TodoInitial extends TodoState {}

final class TodoLoaded extends TodoState {
  final Map<TodoCategory, List<Todo>> groupedTodos;
  const TodoLoaded(this.groupedTodos);
}

final class TodoError extends TodoState {
  final String message;
  const TodoError(this.message);
}
