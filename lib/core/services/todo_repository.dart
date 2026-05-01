import '../models/todo.dart';
import 'i_todo_repository.dart';

class TodoRepository implements ITodoRepository {
  final List<Todo> _todos = [];

  @override
  List<Todo> getAll() => List.unmodifiable(_todos);

  @override
  void add(Todo todo) => _todos.add(todo);

  @override
  void update(int index, Todo todo) => _todos[index] = todo;

  @override
  void remove(int index) => _todos.removeAt(index);
}
