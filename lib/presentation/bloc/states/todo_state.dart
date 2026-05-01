import 'package:gemma_local/core/models/todo.dart';

sealed class TodoState {}

final class TodoInitial extends TodoState {}

final class TodoLoaded extends TodoState {
  final List<Todo> todos;
  const TodoLoaded(this.todos);
}

final class TodoError extends TodoState {
  final String message;
  const TodoError(this.message);
}
